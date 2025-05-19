#!/bin/bash
# Version v1.1 “Update-Safe”

echo "=== Framework Laptop 12 Auto-Rotation and On-Screen Keyboard Setup Script for Ubuntu ==="
echo "This script will set up auto-rotation and on-screen keyboard for Framework Laptop 12"
echo

# Function to check if we're running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Check if we're root
check_root

# Find the current user
ACTUAL_USER=$(who | grep -E '\([[:alnum:]]+\)' | head -n1 | awk '{print $1}')
if [ -z "$ACTUAL_USER" ] && [ -n "$SUDO_USER" ]; then
    ACTUAL_USER=$SUDO_USER
fi
if [ -n "$ACTUAL_USER" ]; then
    USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
    echo "Setting up for user $ACTUAL_USER (home: $USER_HOME)"
fi

# ── VERSION CHECK ─────────────────────────────────────────────────────────────
# only run the Fedora fallback if installed version < REQUIRED_VER
REQUIRED_VER="3.5-7"
INSTALLED_VER=$(dpkg-query -W -f='${Version}' iio-sensor-proxy 2>/dev/null || echo "")
if dpkg --compare-versions "$INSTALLED_VER" ge "$REQUIRED_VER"; then
  echo "Ubuntu’s iio-sensor-proxy ($INSTALLED_VER) ≥ $REQUIRED_VER → skipping Fedora fallback."
  SKIP_FALLBACK=1
else
  echo "Ubuntu’s iio-sensor-proxy ($INSTALLED_VER) < $REQUIRED_VER → running Fedora fallback."
  SKIP_FALLBACK=0
fi
# ───────────────────────────────────────────────────────────────────────────────

echo "1. Setting up iio-sensor-proxy service..."

# Stop and remove services - if this was installed once before
systemctl stop auto-rotate 2>/dev/null || true
systemctl stop Framework-sensor-proxy 2>/dev/null || true
systemctl disable auto-rotate 2>/dev/null || true
systemctl disable Framework-sensor-proxy 2>/dev/null || true
rm -f /etc/systemd/system/auto-rotate.service
rm -f /etc/systemd/system/Framework-sensor-proxy.service
systemctl daemon-reload

# Remove udev rules - if this was installed once before
rm -f /etc/udev/rules.d/61-sensor-local.rules
udevadm control --reload-rules

# ── FALLBACK OR NATIVE ────────────────────────────────────────────────────────
if [ "$SKIP_FALLBACK" -eq 0 ]; then
  echo "2. Purging Ubuntu’s iio-sensor-proxy…"
  apt remove --purge -y iio-sensor-proxy

  echo "3. Downloading & installing Fedora iio-sensor-proxy via alien…"
  wget -q -O /tmp/iio-sensor-proxy.rpm \
    https://kojipkgs.fedoraproject.org//packages/iio-sensor-proxy/3.5/6.fc42/x86_64/iio-sensor-proxy-3.5-6.fc42.x86_64.rpm
  alien --scripts -d /tmp/iio-sensor-proxy.rpm
  dpkg -i /tmp/iio-sensor-proxy_3.5-*.deb

  echo "4. Holding the fallback package…"
  apt-mark hold iio-sensor-proxy

  # cleanup
  rm -f /tmp/iio-sensor-proxy.rpm /tmp/iio-sensor-proxy_3.5-*.deb
else
  echo "2. Leaving Ubuntu’s native iio-sensor-proxy in place."
fi
# ───────────────────────────────────────────────────────────────────────────────

# Clean up any leftover files in home or /tmp
if [ -n "$ACTUAL_USER" ] && [ -d "$USER_HOME" ]; then
    echo "Cleaning up old package files from $USER_HOME..."
    rm -f "$USER_HOME"/iio-sensor-proxy* "$USER_HOME"/*iio-sensor-proxy*
fi
rm -rf /tmp/main.zip /tmp/gnome-shell-extension-screen-autorotate-main
cd /tmp && rm -f iio-sensor-proxy*.rpm iio-sensor-proxy*.deb

echo "5. Installing required packages..."
apt install -y alien rpm libgudev-1.0-0 libsystemd0 dbus wget unzip curl gnome-shell-extension-prefs gnome-tweaks

echo "6. Installing on-screen keyboard packages..."
apt install -y caribou onboard

echo "7. Downloading Fedora's iio-sensor-proxy package (again, for safety)…"
wget -q https://kojipkgs.fedoraproject.org//packages/iio-sensor-proxy/3.5/6.fc42/x86_64/iio-sensor-proxy-3.5-6.fc42.x86_64.rpm

echo "8. Converting and installing the package…"
alien --scripts -d iio-sensor-proxy-3.5-6.fc42.x86_64.rpm
dpkg -i iio-sensor-proxy_3.5-*.deb

echo "9. Creating device nodes and fixing permissions…"
for DEVICE in /sys/devices/platform/cros_ec_lpcs.0/cros-ec-dev.*/cros-ec-sensorhub.*/cros-ec-accel.*/iio:device*; do
    if [ -d "$DEVICE" ]; then
        echo "Found device: $DEVICE"
        chmod -R 660 "$DEVICE/scan_elements" 2>/dev/null || echo "Could not set permissions on scan_elements"
        if [ -f "$DEVICE/dev" ]; then
            MAJOR=$(cut -d: -f1 "$DEVICE/dev")
            MINOR=$(cut -d: -f2 "$DEVICE/dev")
            DEV_NUM=${DEVICE##*iio:device}
            echo "Creating character device /dev/iio:device$DEV_NUM with major:minor $MAJOR:$MINOR"
            rm -f /dev/iio:device$DEV_NUM
            mknod /dev/iio:device$DEV_NUM c $MAJOR $MINOR 2>/dev/null || echo "- Failed to create device"
            chmod 660 /dev/iio:device$DEV_NUM
            chgrp plugdev /dev/iio:device$DEV_NUM 2>/dev/null || echo "- Failed to set group"
        fi
    fi
done

echo "10. Creating udev rule for sensor permissions…"
cat > /etc/udev/rules.d/61-sensor-local.rules << 'EOF'
# Framework sensor permissions
SUBSYSTEM=="iio", KERNEL=="iio:device*", ATTRS{name}=="cros-ec-*", TAG+="systemd", MODE="0660", GROUP="plugdev"
EOF

echo "11. Setting up systemd service for iio-sensor-proxy…"
cat > /etc/systemd/system/Framework-sensor-proxy.service << 'EOF'
[Unit]
Description=Framework IIO Sensor Proxy Service
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/libexec/iio-sensor-proxy
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

if [ -n "$ACTUAL_USER" ]; then
    echo "12. Adding user to plugdev group…"
    usermod -a -G plugdev "$ACTUAL_USER"

    if [ -d "$USER_HOME" ]; then
        echo "13. Installing screen-rotate extension…"
        rm -rf "$USER_HOME/.local/share/gnome-shell/extensions/"{screen-autorotate@klinnex,screen-rotate@shyzus.github.io}
        mkdir -p "$USER_HOME/.local/share/gnome-shell/extensions"
        cd /tmp
        curl -L -o main.zip https://github.com/shyzus/gnome-shell-extension-screen-autorotate/archive/refs/heads/main.zip
        unzip -q main.zip
        EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/screen-rotate@shyzus.github.io"
        rm -rf "$EXT_DIR" && mkdir -p "$EXT_DIR"
        cp -r gnome-shell-extension-screen-autorotate-main/screen-rotate@shyzus.github.io/* "$EXT_DIR/"
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$EXT_DIR"
        chmod -R 755 "$EXT_DIR"
        if [ -d "$EXT_DIR/schemas" ]; then
            (cd "$EXT_DIR/schemas" && glib-compile-schemas .)
        fi

        mkdir -p "$USER_HOME/.config/autostart"
        cat > "$USER_HOME/.config/autostart/enable-rotate-extension.desktop" << EOL
[Desktop Entry]
Type=Application
Name=Enable Screen Rotation Extension
Exec=bash -c "sleep 10 && gnome-extensions enable screen-rotate@shyzus.github.io"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOL
        chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/autostart/enable-rotate-extension.desktop"
        chmod 755 "$USER_HOME/.config/autostart/enable-rotate-extension.desktop"
    fi
fi

echo "14. Reload systemd and enable services..."
systemctl daemon-reload
systemctl enable Framework-sensor-proxy
systemctl restart Framework-sensor-proxy

echo "15. Reload udev rules..."
udevadm control --reload-rules
udevadm trigger

echo
echo "=== Installation Complete ==="
echo "Reboot for changes to take effect."
