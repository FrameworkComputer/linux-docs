# This is for 12th Gen Framework 13 ONLY.

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

### If you want to enable tap-to-click on the touchpad:
``
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
``

### Improve power saving for NVMe drives:
``
sudo grubby --update-kernel=ALL --args="nvme.noacpi=1"
``

