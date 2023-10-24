# This is for 12th Gen Intel® Core™ Framework Laptop 13 ONLY.

## This Fedora guide will assist with:

- Workaround needed to get the best suspend battery life for SSD power drain.
- Enable improved fractional scaling support Fedora's GNOME environment using Wayland.
- Enable tap to click on the touchpad.
- Getting your finger print reader working for Fedora user login.


### Make sure to update your packages first
``sudo dnf upgrade``

### Enable brightness keys
``
sudo grubby --update-kernel=ALL --args="module_blacklist=hid_sensor_hub"
``

### If you want to enable fractional scaling on Wayland:
``
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
``

### If you want to enable tap-to-click on the touchpad:
``
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
``

### Improve power saving for NVMe drives:
``
sudo grubby --update-kernel=ALL --args="nvme.noacpi=1"
``
## If your Fedora 37 install is experiencing freezing, use this to prevent freezing:
``
sudo grubby --update-kernel=ALL --args="i915.enable_psr=0"
``

## Configure the fingerprint reader
This may not always be needed, but as of late, these steps have been needed in Fedora 37 with recent updates.

### Install the needed packages
``
sudo dnf install fprintd fprintd-pam
``

### NEW - Make sure to complete the following.
``
sudo gnome-text-editor /usr/lib/systemd/system/fprintd.service
``

### At the bottom of the file, add:
``
[Install]
WantedBy=multi-user.target
``

### Save the file.
``
systemctl restart fprintd.service
``

### Enable fprintd even if previously enabled, this will make sure it's working after reboot.
``
systemctl enable fprintd.service
``


### Erase any old fingerprints
``
fprintd-delete $USER
``

### Enroll your new fingerprint
``
fprintd-enroll
``

### Verify your new fingerprint
``
fprintd-verify
``

### Make sure PAM is authenticated for your fingerprint
``
sudo authselect enable-feature with-fingerprint
``

``
sudo authselect apply-changes
``

## Verify it that the fingerprint reader is authorized
### This will list what has been authorized.
``
sudo authselect current
``

If authselect looks good, upon reboot, your fingerprint will allow you login.
