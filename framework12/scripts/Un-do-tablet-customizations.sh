#!/bin/bash
set -euo pipefail

echo "=== Undo Framework 12 Auto-Rotation Customizations ==="
echo

# 1) Must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Run me as root (sudo)." >&2
  exit 1
fi

# 2) Identify user (same logic as installer)
USER=${SUDO_USER:-$(who | grep -E '\([[:alnum:]]+\)' | head -n1 | awk '{print $1}')}
HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)
echo "Operating on user: $USER (home: $HOME_DIR)"
echo

# 3) Un-hold and reinstall Ubuntu package
echo "1) Unholding any held iio-sensor-proxy…"
apt-mark unhold iio-sensor-proxy || true

echo "2) Purging Fedora/Koji iio-sensor-proxy…"
apt remove --purge -y iio-sensor-proxy

echo "3) Installing Ubuntu’s stock iio-sensor-proxy…"
apt update
apt install -y iio-sensor-proxy

# 4) Remove custom systemd unit
echo "4) Removing custom Framework-sensor-proxy.service…"
systemctl disable Framework-sensor-proxy 2>/dev/null || true
rm -f /etc/systemd/system/Framework-sensor-proxy.service
systemctl daemon-reload

# 5) Remove custom udev rule
echo "5) Removing custom udev rule…"
rm -f /etc/udev/rules.d/61-sensor-local.rules
udevadm control --reload-rules

# 6) Remove GNOME extension and autostart
EXT_DIR="$HOME_DIR/.local/share/gnome-shell/extensions/screen-rotate@shyzus.github.io"
AUTO_FILE="$HOME_DIR/.config/autostart/enable-rotate-extension.desktop"

echo "6) Removing screen-rotate extension and autostart…"
rm -rf "$EXT_DIR"
rm -f "$AUTO_FILE"

# 7) Remove user from plugdev (optional—if they weren’t in it before)
echo "7) Removing $USER from plugdev group…"
gpasswd -d "$USER" plugdev 2>/dev/null || true

# 8) Final reloads
echo "8) Reloading systemd & udev…"
systemctl daemon-reload
udevadm trigger

echo
echo "=== Undo complete ==="
echo "You can now test Ubuntu’s native iio-sensor-proxy without any customizations."
