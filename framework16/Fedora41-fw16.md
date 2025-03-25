# This is for the Framework Laptop 16 (AMD Ryzen™ 7040 Series) ONLY.

## This will:

- Getting  your laptop fully updated.
- Allow both CPU and platform drivers to be simultaneously active.
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
- Look for "Scale", set it to your preference, click Apply.

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

----------------------------------------
----------------------------------------
## Workarounds below are no longer needed

## ~~MediaTek Bluetooth with s2idle workaround~~
(**UPDATED:** No longer is this needed)

- ~~[Simply visit this page](https://github.com/FrameworkComputer/linux-docs/blob/main/hibernation/kernel-6-11-workarounds/suspend-hibernate-bluetooth-workaround.md#workaround-for-suspendhibernate-black-screen-on-resume-kernel-611) (new tab), copy/paste the one liner, reboot. Now Bluetooth will stop for suspend and resume when you resume from s2idle suspend.~~

&nbsp;
&nbsp;
&nbsp;

### (No Longer Needed) USB-C Video Out from dGPU directly
(**UPDATED:** CURRENT FIRMWARE MAKES THIS UNNEEDED, JUST MAKE SURE [YOUR FIRMWARE IS CURRENT](https://guides.frame.work/Guide/Fedora+41+Installation+on+the+Framework+Laptop+16/394?lang=en#s2261).
**With the latest firmware, just connect your display**.

~~By default, when you attach a USB-C cable to the dGPU port, it will not come out of D3cold - this is by design and is to preserve your battery life during everyday usage.~~

~~But you may find instances where you wish to connect to this port (HDMI/DP dongle to USB-C for example). There are a few ways to bring the dGPU out of D3cold.~~

- ~~[Mission Center](https://missioncenter.io/)~~ or ``lspci -v``
- ~~Installing nvtop, then using this method.~~

```
sudo dnf install nvtop
```
~~Create a script with the following:~~

```
sudo nano /usr/local/bin/external_video.sh
```
~~Paste in:~~

```
#!/bin/bash
echo "USB device connected. Running nvtop for 2 seconds."

timeout 2 nvtop

echo "nvtop run completed."
```
~~Save the file. Then set it to executable.~~

```
sudo chmod +x /usr/local/bin/external_video.sh
```

~~Now setup a udev rule.~~
```
sudo nano /etc/udev/rules.d/99-external_video.rules
```

~~Paste in.~~

```
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/local/bin/external_video.sh"
```

~~Save the file, then run these commands.~~

``sudo udevadm control --reload-rules``
~~then~~
``sudo udevadm trigger``

- ~~Plug in your adapter into the USB-C port on your dGPU port on the back, your display will come on.~~
- ~~NOTE: If you are using HDMI, USB-C or DP explansion cards in the expansion bays on the side of the laptop, this is not needed.~~

&nbsp;
&nbsp;
&nbsp;

## (**NO LONGER NEEDED**): ~~Optional and *only if needed* - current AMD Ryzen 7040 Series workarounds to common issues~~
(**UPDATED:** CURRENT FIRMWARE MAKES THIS UNNEEDED, JUST MAKE SURE [YOUR FIRMWARE IS CURRENT](https://guides.frame.work/Guide/Fedora+41+Installation+on+the+Framework+Laptop+16/394?lang=en#s2261).

### ~~To prevent graphical artifacts from appearing:~~
~~(Note, this workaround may be unneeded as it is difficult to reproduce, however, if you find you're experiencing [the issue described here](https://bugzilla.redhat.com/show_bug.cgi?id=2247154#c3), you can implement this boot parameter)~~


- ~~Browse to the horizontal line in the upper left corner, click to open it.~~
- ~~Type out the word terminal, click to open it.~~
- ~~Then press the enter key, user password, enter key.~~

```
sudo grubby --update-kernel=ALL --args="amdgpu.sg_display=0"
```
> ~~**TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.~~


**Reboot**

## (NO LONGER NEEDED) ~~Addtionally, we recommend the following as well if you are experiencing graphical artifacts from appearing~~
(**UPDATED:** CURRENT FIRMWARE MAKES THIS UNNEEDED, JUST MAKE SURE [YOUR FIRMWARE IS CURRENT](https://guides.frame.work/Guide/Fedora+41+Installation+on+the+Framework+Laptop+16/394?lang=en#s2261).
**With the latest firmware, just connect your display**.

- ~~Please follow the steps outlined in this guide:
  https://knowledgebase.frame.work/allocate-additional-ram-to-igpu-framework-laptop-13-amd-ryzen-7040-series-BkpPUPQa~~


----------------------------------------

## (NO LONGER NEEDED) ~~Framework Laptop 16 not providing all of the expected refresh rates.~~

~~[Framework Laptop 16 not providing all of the expected refresh rates ](https://github.com/FrameworkComputer/linux-docs/blob/main/amdgpu-workarounds/amdgpu_freesync_video/amdgpu_freesync_video.md#amdgpufreesync_video1-parameter-workaround-franework-laptop-16-only)~~

&nbsp;
&nbsp;
&nbsp;&nbsp;
&nbsp;
&nbsp;
