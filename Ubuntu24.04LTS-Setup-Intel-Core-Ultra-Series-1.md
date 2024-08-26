# This is for Intel® Core™ Ultra Series 1 Framework Laptop 13 ONLY.

#### Requires kernel 6.8.0-40 or better. Officially supporting from Ubuntu 24.04.1
Please use the **"Get everything updated"** section below if you are on standard Ubuntu 24.04 without the the dot 1.

## This will:

- Update your Ubuntu install's packages.
- (ONLY IF NEEDED) Provide an optional workaround for dropped Intel AX210 wifi.
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


&nbsp; &nbsp; &nbsp;


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

### (Only if needed) WiFi Workaround if seeing drops in connecvity with AX210 Intel Wifi.

- Browse to the upper left corner, click the horizontal line to open the menu.
- Type out the word terminal, click to open it.
- Click on the small icon shown in the image below to copy the code below in the gray box, right click/paste it into the terminal window.

```
sudo apt install iw && interface=$(nmcli -t -f active,device d wifi list | grep '^yes' | cut -d':' -f2) && echo -e "\n\033[1;33mInterface:\033[0m $interface" && iw dev $interface get power_save
```
This will indicate if your Wi-Fi power save is on or off. If it's on and you're seeing drops, continue to the next line.

```
sudo sed -i '/^wifi.powersave = 3$/s/3/2/' /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
```

This will change 3 into 2, which will disable powersave.

> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

<p style="text-align: left"><img src="https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/copied.png" alt="Copy The Code Below Like This" title="Copy The Code Above Like This"></p>

**reboot.**

