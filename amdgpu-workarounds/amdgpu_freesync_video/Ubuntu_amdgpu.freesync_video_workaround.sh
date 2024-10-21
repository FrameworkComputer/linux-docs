#!/bin/bash

# Backup the current GRUB configuration
sudo cp /etc/default/grub /etc/default/grub.bak

# Add the amdgpu.freesync_video=1 parameter if it's not already present
if grep -q "amdgpu.freesync_video=1" /etc/default/grub; then
  echo "amdgpu.freesync_video=1 is already set in GRUB."
else
  # Check if the GRUB_CMDLINE_LINUX_DEFAULT line exists, then append the parameter
  sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ amdgpu.freesync_video=1"/' /etc/default/grub
  echo "amdgpu.freesync_video=1 has been added to GRUB."
fi

# Update GRUB to apply changes
sudo update-grub

echo "GRUB has been updated. Please reboot for changes to take effect."



## There is a bug reported whereas not all of the refresh rates are being displayed in Display settings (GNOME or Plasma).

The recommended workaround is to append amdgpu.freesync_video=1 to your grub settings.
