# This is for Framework Laptop 12 ONLY
### Fedora Workstation (GNOME)

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

- At the top, select fonts. Now in that panel, scroll all the way down. Look for Size. Change from 1.00 to 0.80. Close Tweaks. This will vary depending on what you are using for fractional scaling under Displays.

  Note: This is for the displays for the laptop only. This will look super odd on external displays and likely too large even still.



&nbsp;
&nbsp;
&nbsp;

--------------------------------

## Tablet mode Fedora 44 Bug Workaround

### The Service method - a bit overkill, but works

If tablet mode is not rotating when fully folded back, **verify** that [this is the cause first](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/debugging.md#check-that-the-kernel-recognized-the-tabletmode-gpio). 
If journalctl -k | grep gpio-keys comes back empty, then we can implement a systemd service to provide a workaround until this is reoslved.

Using your prefered text editor:
Create the file `/etc/systemd/system/reload-soc-button-array.service`

In that file, paste in:

```
[Unit]
Description=Reload soc_button_array module
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/modprobe -r soc_button_array
ExecStart=/usr/sbin/modprobe soc_button_array

[Install]
WantedBy=multi-user.target
```

Now let's activate it.

```
sudo systemctl daemon-reload
sudo systemctl enable reload-soc-button-array.service

sudo systemctl daemon-reload
sudo systemctl enable reload-soc-button-array.service

sudo systemctl start reload-soc-button-array.service
```

Later when we're ready to remove this service after a fix is released.

```
sudo systemctl stop reload-soc-button-array.service
sudo systemctl disable reload-soc-button-array.service
sudo rm /etc/systemd/system/reload-soc-button-array.service
sudo systemctl daemon-reload
```

### The Proper method - should work, but it it does not, use the service method
```
sudo nano /etc/dracut.conf.d/fw12-tablet-mode.conf
```

(Add)
```
force_drivers+=" pinctrl_tigerlake soc_button_array "
```

```
sudo dracut -f --regenerate-all -v
```


