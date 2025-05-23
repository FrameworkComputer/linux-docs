# This is for Framework Laptop 12 ONLY.


## This will:

- Update your Ubuntu install's packages.

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

### Bonus Step - Correct blurry text rendering in the Chrome browser

  - Open your Chrome browser, browse to chrome://flags/ and press enter.
  - Look for the search box at the top of the page, type in the words _ozone platform_ then press the enter key.
  - Look for the box marked Default, change it to Auto.
  - With this changed to Auto, relaunch your Chrome browser.
  
![ozone platform](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/images/oszone.png)


