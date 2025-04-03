# This is for Framework Desktop ONLY

## This will:

- Getting  your desktop fully updated.
- Enable improved fractional scaling support Fedora's GNOME environment using Wayland.
  
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


### Bonus Step (for former Mac users) Reduce Font Scaling to Match Your Needs

We received feedback that for users coming from OS X, installing GNOME Tweaks, browsing to Fonts, and reducing the font size from 1.00 to 0.80 may be preferred. Your own display may vary, so note any changes made if you need to revert back.

- Goto Displays, set scaling to 200%. This will look too large, so let's fix the fonts.
  
- Install with:
  
```
sudo dnf install gnome-tweaks -y
```

- Open Tweaks by using the "Super" or Windows key, search tweaks, and enter.

- At the top, select fonts. Now in that panel, scroll all the way down. Look for Size. Change from 1.00 to 0.80. Close Tweaks. This will vary depending on what you are using for fractional scaling under Displays.



&nbsp;
&nbsp;
&nbsp;
