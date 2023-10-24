# This is for 11th Gen Intel® Core™ Framework Laptop 13 ONLY

## This Fedora guide will assist with:

- Getting  your laptop fully updated.
- Enable improved fractional scaling support Fedora's GNOME environment using Wayland.
- Enabling tap to click on the touchpad.


### Make sure to update your packages first

```
sudo dnf upgrade
```

**Reboot**


### If you want to enable fractional scaling on Wayland:

```
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```

### If you want to enable tap-to-click on the touchpad:

- Settings, Mouse and Touchpad

- Touchpad option at the top

- Under "Clicking", select Tap to Click and enable it.
