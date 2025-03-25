#!/bin/bash

# Script to restore wakeup functionality and remove custom disable-wakeup.service
# Compatible with Fedora and Ubuntu

# Define the systemd service file path
SERVICE_FILE="/etc/systemd/system/disable-wakeup.service"

# Step 1: Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Step 2: Stop and disable the service
echo "Stopping and disabling the disable-wakeup.service..."
systemctl stop disable-wakeup.service 2>/dev/null
systemctl disable disable-wakeup.service 2>/dev/null

if [[ $? -eq 0 ]]; then
  echo "Service stopped and disabled successfully."
else
  echo "The service may not exist or was not running. Proceeding..."
fi

# Step 3: Remove the systemd service file
if [[ -f "$SERVICE_FILE" ]]; then
  echo "Removing the systemd service file at $SERVICE_FILE..."
  rm -f "$SERVICE_FILE"
  if [[ $? -eq 0 ]]; then
    echo "Service file removed."
  else
    echo "Failed to remove the service file. Please check permissions."
    exit 1
  fi
else
  echo "Service file not found. Skipping removal."
fi

# Step 4: Reload systemd daemon
echo "Reloading systemd daemon to apply changes..."
systemctl daemon-reload

# Step 5: Restore default wakeup settings
echo "Restoring default wakeup settings for devices..."
for device in /sys/bus/usb/devices/*/power/wakeup; do
  if [[ -f "$device" ]]; then
    echo "enabled" > "$device"
    echo "Restored default wakeup for $device"
  fi
done

if [[ -f "/sys/devices/platform/AMDI0010:03/i2c-1/i2c-PIXA3854:00/power/wakeup" ]]; then
  echo "enabled" > /sys/devices/platform/AMDI0010:03/i2c-1/i2c-PIXA3854:00/power/wakeup
  echo "Restored default wakeup for AMDI0010 device."
fi

find /sys/devices -type f -name 'wakeup' | grep -i PNP0C0D | while read -r wakeup_file; do
  echo "enabled" > "$wakeup_file"
  echo "Restored default wakeup for $wakeup_file"
done

# Final Step: Notify the user
echo "Restoration complete. All changes made by the disable-wakeup.service have been undone."
echo "If issues persist, verify the wakeup settings manually using: find /sys/devices -name 'wakeup'"

