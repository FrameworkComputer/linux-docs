#!/bin/bash

# Script to create and enable a systemd service to disable wakeup for specific devices at boot
# Compatible with Fedora and Ubuntu

# Define the systemd service file path
SERVICE_FILE="/etc/systemd/system/disable-wakeup.service"

# Step 1: Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Step 2: Create the systemd service file
echo "Creating systemd service file at $SERVICE_FILE..."
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Disable Wakeup on Devices
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo disabled > /sys/devices/platform/AMDI0010:03/i2c-1/i2c-PIXA3854:00/power/wakeup"
ExecStartPost=/bin/bash -c "for device in /sys/bus/usb/devices/*/power/wakeup; do echo disabled > \"$device\"; done"
ExecStartPost=/bin/bash -c "find /sys/devices -type f -name 'wakeup' | grep -i PNP0C0D | awk '{print \"echo disabled | sudo tee \" $0}' | bash"

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service file created."

# Step 3: Reload systemd daemon to recognize the new service
echo "Reloading systemd daemon..."
systemctl daemon-reload
if [[ $? -ne 0 ]]; then
  echo "Failed to reload systemd daemon. Exiting."
  exit 1
fi

# Step 4: Enable the service to run at boot
echo "Enabling the service to run at boot..."
systemctl enable disable-wakeup.service
if [[ $? -ne 0 ]]; then
  echo "Failed to enable the service. Exiting."
  exit 1
fi

# Step 5: Optionally start the service immediately
echo "Starting the service to apply changes now..."
systemctl start disable-wakeup.service
if [[ $? -ne 0 ]]; then
  echo "Failed to start the service. Check the service logs for details."
  exit 1
fi

# Final Step: Notify the user
echo "Setup complete. The disable-wakeup.service is now active and will run at each boot."
echo "To verify the status of the service, use: sudo systemctl status disable-wakeup.service"
echo "To view logs, use: journalctl -u disable-wakeup.service"

