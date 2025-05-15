# This is for Ubuntu 25.04 on Framework Laptop 12 ONLY.


## This will:

- Update your Ubuntu install's packages.
- Walk you getting tablet mode setup for Ubuntu 25.04 (ONLY)

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


- Only works on 25.04, and even then needs a little help.
- [This script will get tablet mode set up and running fast](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-Tablet-Mode.md#ubuntu-2504-tablet-mode-setup). Copy, paste, enter key (and password as prompted), reboot, wait for 20 seconds, done.
- Onscreen keyboard only appears when you call for it by interacting in a text area.

![Tablet Mode](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/images/tablet.png)

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
