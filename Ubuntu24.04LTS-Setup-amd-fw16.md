# This is for the AMD Ryzen 7040 Series Framework Laptop 16 ONLY.


## This will:

- Update your Ubuntu install's packages.
- (Optional) Stop buzzing sound from headphone jack if its present.
- We are NOT recommending an OEM kernel at this time, this may change in the future. Default kernel is where you need to be.


&nbsp; &nbsp; &nbsp; &nbsp; 


### Step 1 Get everything updated

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
&nbsp;
&nbsp;


&nbsp; &nbsp; &nbsp; &nbsp; 
