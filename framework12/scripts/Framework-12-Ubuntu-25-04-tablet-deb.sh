#!/usr/bin/env bash
set -euo pipefail

DEB_URL="https://launchpad.net/ubuntu/+source/iio-sensor-proxy/3.5-1build2/+build/27983927/+files/iio-sensor-proxy_3.5-1build2_amd64.deb"
PKG_FILE="iio-sensor-proxy_3.5-1build2_amd64.deb"

# Ensure we have a downloader
if ! command -v wget &>/dev/null; then
  echo "Error: wget is required but not installed." >&2
  exit 1
fi

echo "Downloading iio-sensor-proxy..."
wget --progress=bar:force -O "$PKG_FILE" "$DEB_URL"

echo
echo "Installing iio-sensor-proxy (requires sudo)..."
sudo dpkg -i "$PKG_FILE"

echo
echo "Fixing and installing any missing dependencies..."
sudo apt-get update
sudo apt-get install -f -y

echo
echo "Cleaning up..."
rm -f "$PKG_FILE"

echo "✅ iio-sensor-proxy has been installed."
