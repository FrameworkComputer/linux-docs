#!/bin/bash
# Framework 13 Fingerprint Wake Fix Installer
# Auto-detects hardware and installs systemd service

set -e

echo "Framework 13 Fingerprint Wake Fix Installer"
echo "============================================"
echo ""

# Remove any existing installation first
if [ -f /etc/systemd/system/run-after-wake-for-fprint.service ]; then
    echo "⚠ Found existing installation - removing..."
    sudo systemctl disable --now run-after-wake-for-fprint.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/run-after-wake-for-fprint.service
    sudo rm -f /etc/local/bin/run-after-wake-for-fprint.sh
    sudo systemctl daemon-reload
    echo "✓ Removed old installation"
    echo ""
fi

# 1. Detect fingerprint reader
echo "[1/6] Detecting fingerprint reader..."
echo ""

FPRINT_DEVICE=$(lsusb | grep -E "Goodix.*Fingerprint|27c6:609c" | head -1)

if [ -z "$FPRINT_DEVICE" ]; then
    echo "✗ NO fingerprint reader found"
    echo ""
    echo "All USB devices detected:"
    lsusb
    echo ""
    echo "Troubleshooting:"
    echo "  • Enable fingerprint reader in BIOS/UEFI"
    echo "  • Check 'dmesg | grep -i fingerprint'"
    exit 1
fi

echo "✓ Found fingerprint reader:"
echo "  $FPRINT_DEVICE"

# 2. Extract device ID
FPRINT_ID=$(echo "$FPRINT_DEVICE" | grep -oP 'ID \K[0-9a-f]{4}:[0-9a-f]{4}')
if [ -z "$FPRINT_ID" ]; then
    echo "✗ Could not parse device ID"
    exit 1
fi

echo "✓ Device ID: $FPRINT_ID"

# 3. Get bus number
BUS_RAW=$(echo "$FPRINT_DEVICE" | awk '{print $2}')
BUS=$((10#$BUS_RAW))

echo "✓ USB Bus: $BUS (raw: $BUS_RAW)"

# 4. Find USB controller in sysfs
echo ""
echo "[2/6] Resolving USB controller path..."
echo ""

USB_DEVICE_PATH="/sys/bus/usb/devices/usb${BUS}"

if [ ! -d "$USB_DEVICE_PATH" ]; then
    echo "✗ USB path not found: $USB_DEVICE_PATH"
    exit 1
fi

echo "✓ USB device path exists: $USB_DEVICE_PATH"

# 5. Follow symlink to PCI controller
USB_PATH=$(readlink -f "$USB_DEVICE_PATH")
echo "✓ Resolved path: $USB_PATH"

PCI_FUNC=$(echo "$USB_PATH" | grep -oP '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]' | tail -1)

if [ -z "$PCI_FUNC" ]; then
    echo "✗ Could not determine PCI controller from path"
    exit 1
fi

echo "✓ PCI Controller: $PCI_FUNC"

# 6. Verify PCI device exists
PCI_DEVICE_PATH="/sys/bus/pci/devices/$PCI_FUNC"

if [ ! -d "$PCI_DEVICE_PATH" ]; then
    echo "✗ PCI device path not found: $PCI_DEVICE_PATH"
    exit 1
fi

echo "✓ PCI device path verified"

# 7. Detect driver
echo ""
echo "[3/6] Detecting driver..."
echo ""

DRIVER_LINK="$PCI_DEVICE_PATH/driver"

if [ ! -L "$DRIVER_LINK" ]; then
    echo "✗ No driver bound to $PCI_FUNC"
    exit 1
fi

DRIVER_NAME=$(basename "$(readlink -f "$DRIVER_LINK")")
DRIVER_PATH="/sys/bus/pci/drivers/$DRIVER_NAME"

echo "✓ Driver detected: $DRIVER_NAME"
echo "✓ Driver path: $DRIVER_PATH"

# 8. Verify it's xHCI
if [[ ! "$DRIVER_NAME" =~ xhci ]]; then
    echo ""
    echo "⚠ WARNING: '$DRIVER_NAME' doesn't look like an xHCI driver"
    echo "  Expected: xhci_hcd or xhci-pci"
    echo "  This script may not work correctly"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
fi

# 9. Check fprintd status
echo ""
echo "[4/6] Checking fprintd status..."
echo ""

if systemctl is-active --quiet fprintd.service; then
    echo "⚠ fprintd service is running (this is not expected and should be reported to support, something might be stuck)"
else
    echo "✓ fprintd service not running (this is correct and expected)"
fi

if command -v fprintd-list &>/dev/null; then
    if fprintd-list 2>/dev/null | grep -q "fingerprint"; then
        echo "✓ fprintd recognizes fingerprint device"
    fi
fi

# 10. Create wake script
echo ""
echo "[5/6] Creating wake script..."
echo ""

sudo mkdir -p /etc/local/bin

sudo tee /etc/local/bin/run-after-wake-for-fprint.sh > /dev/null << EOF
#!/bin/sh
# Framework fingerprint wake fix
# Generated for: $FPRINT_ID on $PCI_FUNC

PCI_FUNC="$PCI_FUNC"
FPRINT_ID="$FPRINT_ID"
DRIVER_PATH="$DRIVER_PATH"

logger -t fp-rebind "Checking fingerprint reader after wake"

sleep 2

if ! lsusb -d "\$FPRINT_ID" >/dev/null 2>&1; then
  logger -t fp-rebind "Fingerprint missing, resetting controller \$PCI_FUNC"
  
  # Unbind
  if ! echo "\$PCI_FUNC" >"\$DRIVER_PATH/unbind" 2>/dev/null; then
    logger -t fp-rebind "ERROR: Unbind failed"
    exit 1
  fi
  
  sleep 1
  
  # Rebind
  if ! echo "\$PCI_FUNC" >"\$DRIVER_PATH/bind" 2>/dev/null; then
    logger -t fp-rebind "ERROR: Rebind failed"
    exit 1
  fi
  
  sleep 2
  systemctl try-restart fprintd.service
  
  if lsusb -d "\$FPRINT_ID" >/dev/null 2>&1; then
    logger -t fp-rebind "SUCCESS: Reader restored"
  else
    logger -t fp-rebind "WARNING: Reader still missing"
  fi
else
  logger -t fp-rebind "Reader present, no action needed"
fi
EOF

sudo chmod +x /etc/local/bin/run-after-wake-for-fprint.sh

echo "✓ Created: /etc/local/bin/run-after-wake-for-fprint.sh"

# 11. Create systemd service
echo ""
echo "[6/6] Creating and enabling systemd service..."
echo ""

sudo tee /etc/systemd/system/run-after-wake-for-fprint.service > /dev/null << 'EOF'
[Unit]
Description=Restore fingerprint reader after system resume
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/etc/local/bin/run-after-wake-for-fprint.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF

echo "✓ Created: /etc/systemd/system/run-after-wake-for-fprint.service"

sudo systemctl daemon-reload
sudo systemctl enable run-after-wake-for-fprint.service

echo "✓ Service enabled"

# 12. Final summary
echo ""
echo "============================================"
echo "✓ Installation Complete!"
echo "============================================"
echo ""
echo "Detection Summary:"
echo "  Device ID:       $FPRINT_ID"
echo "  USB Bus:         $BUS"
echo "  PCI Controller:  $PCI_FUNC"
echo "  Driver:          $DRIVER_NAME"
echo ""
echo "Testing:"
echo "  1. Test now:     sudo systemctl start run-after-wake-for-fprint.service"
echo "  2. Check logs:   journalctl -t fp-rebind -f"
echo "  3. Suspend/wake: systemctl suspend"
echo ""
echo "The service will automatically run after each suspend/resume"
echo ""
