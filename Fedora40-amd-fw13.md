
# This is for AMD Ryzen 7040 Series configuration on the Framework Laptop 13 ONLY.

## This will:

- Getting  your laptop fully updated.
- Enable improved fractional scaling support Fedora's GNOME environment using Wayland.
- Enabling tap to click on the touchpad.

&nbsp;
&nbsp;
&nbsp;

### Step 1 Updating your software packages

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key, user password, enter key, **reboot.**


```
sudo dnf upgrade
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


**Reboot**

&nbsp;
&nbsp;
&nbsp;

### Step 2 - If you want to enable fractional scaling on Wayland:

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key.
- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word Displays.
- Look for "Scale", set it to your preference, click Apply.


```
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

&nbsp;
&nbsp;
&nbsp;
### Step 3 -  If you want to enable "tap-to-click" on the touchpad:

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word mouse, look for Mouse and Touchpad, click to open it.
- Click the touchpad option at the top.
- Under "Clicking", select Tap to Click and enable it.
  
&nbsp;
&nbsp;
&nbsp;



## Optional and *only if needed* - current AMD Ryzen 7040 Series workarounds to common issues

### To prevent graphical artifacts from appearing:
(Note, this workaround may be unneeded as it is difficult to reproduce, however, if you find you're experiencing [the issue described here](https://bugzilla.redhat.com/show_bug.cgi?id=2247154#c3), you can implement this boot parameter)


- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Then press the enter key, user password, enter key.

```
sudo grubby --update-kernel=ALL --args="amdgpu.sg_display=0"
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


**Reboot**

### Suspend with lid while attached to power workaround
There is an active bug that occurs for some users, creating a bogus key press when you suspend. This provides a solid workaround.

```
sudo sh -c '[ ! -f /etc/udev/rules.d/20-suspend-fixes.rules ] && echo "ACTION==\"add\", SUBSYSTEM==\"serio\", DRIVERS==\"atkbd\", ATTR{power/wakeup}=\"disabled\"" > /etc/udev/rules.d/20-suspend-fixes.rules'
```
This checks for an existing /etc/udev/rules.d/20-suspend-fixes.rules file, if none is found, creates it and appends ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="atkbd", ATTR{power/wakeup}="disabled" to the file.

**Reboot**

&nbsp; &nbsp; &nbsp; &nbsp;


### Buzzing sound from 3.5mm jack

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy/paste in the following code below.
- Press the enter key, user password, enter key.

```
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


**Reboot**

&nbsp;
&nbsp;
&nbsp;

### 3.5mm jack mic won't work

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy/paste in the following code below.
- Press the enter key, user password, enter key.

```
sudo tee /etc/modprobe.d/alsa.conf <<< "options snd-hda-intel index=1,0 model=auto,dell-headset-multi"
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.
