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
- Type out the word Displays.
- Look for scale you want and select it, click Apply.

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

### Bonus Step (for former Mac users) Reduce Font Scaling to Match Your Needs

We received feedback that for users coming from OS X, installing GNOME Tweaks, browsing to Fonts, and reducing the font size from 1.00 to 0.80 may be preferred. 

- Goto Displays, set scaling to 200%. This will look too large, so let's fix the fonts.
- Install with:
  
```
sudo dnf install gnome-tweaks -y
```

- Open Tweaks by using the "Super" or Windows key, search tweaks, and enter.

- At the top, select fonts. Now in that panel, scroll all the way down. Look for Size. Change from 1.00 to 0.80. Close Tweaks.

  Note: This is for the displays for the laptop only. This will look super odd on external displays and likely too large even still.

&nbsp;
&nbsp;
&nbsp;

## Optional and *only if needed* - current AMD Ryzen 7040 Series workarounds to common issues

### Laggy or stuttering touchpad:
(Customer submitted, not seeing this internally, but if you are, please file a bug so we can get this fixed vs this workaround please)

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Then press the enter key, user password, enter key.

```
sudo grubby --update-kernel=ALL --args="amdgpu.dcdebugmask=0x10"
```
> **TIP:** If you've set other kernel parameters, like from the section above, include both inside `--args=""`.


**Reboot**


### Buzzing sound from 3.5mm jack

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy/paste in the code below (use either the immediate temporary fix or persistent fix).
- Then press the enter key, user password, enter key.

```
# Immediate temporary fix to disable power save for running session (no reboot required)
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
```

```
# Persistent fix to disable power save using Tuned (either change the power profile or reboot to apply)
# Note: Change "balanced" to the profile you want this set on
sudo mkdir -p /etc/tuned/profiles/balanced/
sudo cp /usr/lib/tuned/profiles/balanced/tuned.conf /etc/tuned/profiles/balanced/
sudo sed -i 's/timeout=10/timeout=0/g' /etc/tuned/profiles/balanced/tuned.conf
```

> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


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

&nbsp;
&nbsp;
&nbsp;

-------------------------------------------------------------------------------

## (No Longer Needed) ~~Optional and *only if needed* - current AMD Ryzen 7040 Series workarounds to common issues~~

### ~~To prevent graphical artifacts from appearing:~~
~~(Note, this workaround may be unneeded as it is difficult to reproduce, however, if you find you're experiencing [the issue described here](https://bugzilla.redhat.com/show_bug.cgi?id=2247154#c3), you can implement this boot parameter)~~


- ~~Browse to the horizontal line in the upper left corner, click to open it.~~
- ~~Type out the word terminal, click to open it.~~
- ~~Then press the enter key, user password, enter key.~~

```
sudo grubby --update-kernel=ALL --args="amdgpu.sg_display=0"
```
> ~~**TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.~~


~~**Reboot**~~




## ~~MediaTek Bluetooth with s2idle workaround~~

- ~~[Simply visit this page](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/kernel-6-11-workarounds/suspend-hibernate-bluetooth-workaround.md#workaround-for-suspendhibernate-black-screen-on-resume-kernel-611) (new tab), copy/paste the one liner, reboot. Now Bluetooth will stop for suspend and resume when you resume from s2idle suspend.~~


