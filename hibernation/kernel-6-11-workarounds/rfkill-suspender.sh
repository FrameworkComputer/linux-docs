#!/bin/bash

# Define service files and paths
SUSPEND_SERVICE="/etc/systemd/system/bluetooth-rfkill-suspend.service"
RESUME_SERVICE="/etc/systemd/system/bluetooth-rfkill-resume.service"

# Create and configure the suspend service
echo "Setting up bluetooth-rfkill-suspend.service..."
sudo tee "$SUSPEND_SERVICE" > /dev/null <<EOF
[Unit]
Description=Soft block Bluetooth on suspend/hibernate
Before=sleep.target
StopWhenUnneeded=yes

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill block bluetooth
ExecStartPost=/bin/sleep 3
RemainAfterExit=yes

[Install]
WantedBy=suspend.target hibernate.target suspend-then-hibernate.target
EOF

# Create and configure the resume service
echo "Setting up bluetooth-rfkill-resume.service..."
sudo tee "$RESUME_SERVICE" > /dev/null <<EOF
[Unit]
Description=Unblock Bluetooth on resume
After=suspend.target hibernate.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock bluetooth

[Install]
WantedBy=suspend.target hibernate.target suspend-then-hibernate.target
EOF

# Reload systemd to recognize the new services
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable both services
echo "Enabling bluetooth-rfkill-suspend.service..."
sudo systemctl enable bluetooth-rfkill-suspend.service

echo "Enabling bluetooth-rfkill-resume.service..."
sudo systemctl enable bluetooth-rfkill-resume.service

# Suggest reboot to finalize setup
echo "Both Bluetooth rfkill services have been set up and enabled successfully."
echo "It's recommended to reboot now to apply the changes."

# Prompt for reboot confirmation
read -p "Would you like to reboot now? (y/n): " response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    sudo reboot
else
    echo "Reboot skipped. Please remember to reboot later to finalize the setup."
fi
