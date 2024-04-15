# This is for 13th Gen Intel® Core™ Framework Laptop 13 ONLY

## This will:

- Getting  your laptop fully updated.
- Enable improved fractional scaling support Fedora's GNOME environment using Wayland.
- Enabling tap to click on the touchpad.
- Enabling brightness keys.

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
- Then press the enter key, user password, enter key.
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

### Enable brightness keys

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key, user password, enter key, **reboot.**


```
sudo grubby --update-kernel=ALL --args="module_blacklist=hid_sensor_hub"
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


**Reboot**

&nbsp;
&nbsp;
&nbsp;
