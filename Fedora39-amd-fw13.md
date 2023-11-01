
# This is for AMD Ryzen 7040 Series configuration on the Framework Laptop 13 ONLY.

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

## Optional and only if needed

### To prevent graphical artifacts from appearing:
(Note, this workaround may be unneeded as it is difficult to reproduce, however, if you find you're experiencing [the issue described here](https://bugzilla.redhat.com/show_bug.cgi?id=2247154#c3), you can implement this boot parameter)

Open a terminal window from Activities, paste in the following:

```
sudo grubby --update-kernel=ALL --args="amdgpu.sg_display=0"
```

**Reboot**
