#!/bin/bash
# uninstall-fingerprint-fix.sh - Remove old fingerprint wake fix

echo "Removing existing fingerprint wake fix..."

# Stop and disable service
if systemctl is-enabled run-after-wake-for-fprint.service &>/dev/null; then
    echo "  Disabling service..."
    sudo systemctl disable run-after-wake-for-fprint.service
fi

if systemctl is-active run-after-wake-for-fprint.service &>/dev/null; then
    echo "  Stopping service..."
    sudo systemctl stop run-after-wake-for-fprint.service
fi

# Remove files
echo "  Removing files..."
sudo rm -f /etc/systemd/system/run-after-wake-for-fprint.service
sudo rm -f /etc/local/bin/run-after-wake-for-fprint.sh

# Reload systemd
sudo systemctl daemon-reload

echo "✓ Old installation removed"
echo ""
echo "Now run the new installer to install the auto-detecting version"
