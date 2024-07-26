# This is for the AMD Ryzen 7040 Series Framework Laptop 16 ONLY.


## This will:

- Update your Ubuntu install's packages.
- (Optional) Stop buzzing sound from headphone jack if its present.
- We are NOT recommending an OEM kernel at this time, this may change in the future. Default kernel is where you need to be.


&nbsp; &nbsp; &nbsp; &nbsp; 


### Get everything updated

- Browse to the upper left corner, click the horizontal line to open the menu.
- Type out the word terminal, click to open it.
- Click on the small icon shown in the image below to copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key, user password, enter key, **reboot.**

```
sudo apt update && sudo apt upgrade -y && sudo snap refresh
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

<p style="text-align: left"><img src="https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/copied.png" alt="Copy The Code Below Like This" title="Copy The Code Above Like This"></p>

**reboot.**

&nbsp; &nbsp; &nbsp;

### USB-C Video Out from dGPU directly

By default, when you attach a USB-C cable to the dGPU port, it will not come out of [D3cold](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/device-power-states) - this is by design and is to preserve your battery life during everyday usage.

But you may find instances where you wish to connect to this port (HDMI/DP dongle to USB-C for example). There are a few ways to bring the dGPU out of D3cold.

- [Mission Center](https://missioncenter.io/) or ``lspci -v``
- Installing nvtop, then using this method.

```
sudo apt update && sudo apt install install nvtop -y
```
Create a script with the following:

```
sudo /usr/local/bin/external_video.sh
```
Paste in:

```
#!/bin/bash
echo "USB device connected. Running nvtop for 2 seconds."

timeout 2 nvtop

echo "nvtop run completed."
```
Save the file. Now setup a udev rule.
```
sudo nano /etc/udev/rules.d/99-external_video.rules
```

Paste in.

```
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/local/bin/external_video.sh"
```

Save the file, then run these commands.

``sudo udevadm control --reload-rules``
then
``sudo udevadm trigger``

- Plug in your adapter into the USB-C port on your dGPU port on the back, your display will come on.
- NOTE: If you are using HDMI, USB-C or DP explansion cards in the expansion bays on the side of the laptop, this is not needed.

&nbsp;
&nbsp;
&nbsp;

### Optional and only if needed - current AMD Ryzen 7040 Series workarounds to common issues

### Buzzing sound from headphone jack

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy/paste in the following code below.
- Press the enter key, user password, enter key.

```
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


Then:

**Reboot**

&nbsp;

### Bonus Step (for former Mac users) Reduce Font Scaling to Match Your Needs

We received feedback that for users coming from OS X, installing GNOME Tweaks, browsing to Fonts, and reducing the font size from 1.00 to 0.80 may be preferred. 

- Goto Displays, set scaling to 200%. This will look too large, so let's fix the fonts.
- Install with:
  
```
sudo apt update && sudo apt install gnome-tweaks -y
```

- Open Tweaks by using the "Super" or Windows key, search tweaks, and enter.

- At the top, select fonts. Now in that panel, scroll all the way down. Look for Size. Change from 1.00 to 0.80. Close Tweaks.

  Note: This is for the displays for the laptop only. This will look super odd on external displays and likely too large even still.
