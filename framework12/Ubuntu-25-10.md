# This is for Ubuntu 25.10 on Framework Laptop 12 ONLY.


## This will:

- Update your Ubuntu install's packages.
- Walk you getting tablet mode setup for Ubuntu 25.10 (ONLY)

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

- **Then reboot**

&nbsp; &nbsp; &nbsp;

## Tablet mode on Ubuntu


- Only works on 25.04+ (and up)
- Needs below fixup until they have updated iio-sensor-proxy to 3.8: [![Ubuntu 25.10 package](https://repology.org/badge/version-for-repo/ubuntu_25_10/iio-sensor-proxy.svg)](https://repology.org/project/iio-sensor-proxy/versions)
- [This script will get tablet mode set up and running fast](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-accel-ubuntu25.10.md#ubuntu-2504-tablet-mode-setup-udev-edit). 
- Onscreen keyboard only appears when you call for it by interacting in a text area.

![Tablet Mode](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/images/tablet2.png)

&nbsp; &nbsp; &nbsp;


### Bonus Step (for former Mac users) Reduce Font Scaling to Match Your Needs

We received feedback that for users coming from OS X, installing GNOME Tweaks, browsing to Fonts, and reducing the font size from 1.00 to 0.80 may be preferred. This will vary greatly how you have your fractional scaling setup in the Displays settings area.

- Goto Displays, set scaling to 200%. This will look too large, so let's fix the fonts.
- Install with:
  
```
sudo apt update && sudo apt install gnome-tweaks -y
```

- Open Tweaks by using the "Super" or Windows key, search tweaks, and enter.

- At the top, select fonts. Now in that panel, scroll all the way down. Look for Size. Change from 1.00 to 0.80. Close Tweaks.

  Note: This is for the displays for the laptop only. This will look super odd on external displays and likely too large even still.

### Install issues

If you run into an installation issue where the previous release; 25.04 installed fine. We would recommend installing the previous release and then upgrading in place.


**Update**
```
sudo apt update && sudo apt upgrade
```

**Change to allow non-LTS upgrades**
```
sudo nano /etc/update-manager/release-upgrades
```
Change: Prompt=lts
To: Prompt=normal

**Upgrade to previous release first (required step)**
```
sudo do-release-upgrade
```

**After reboot, upgrade to 25.10 (current release)**
```
sudo do-release-upgrade
```



  
