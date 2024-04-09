# This is for 13th Gen Intel® Core™ Framework Laptop 13 ONLY.

## This will:

- Update your Ubuntu install's packages.
- Install the recommended OEM kernel and provide you with an alert should the OEM kernel needing updating.
- Disable the ALS sensor so that your brightness keys work.

&nbsp; &nbsp; &nbsp; &nbsp; 


### Step 1

- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Click on the small icon shown in the image below to copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key, user password, enter key, **reboot.**

```
sudo apt update && sudo apt upgrade -y && sudo snap refresh && sudo apt-get install linux-oem-22.04d -y
```

> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

<p style="text-align: left"><img src="https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/copied.png" alt="Copy The Code Below Like This" title="Copy The Code Above Like This"></p>


&nbsp; &nbsp; &nbsp;


### Step 2

- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Click on the small icon shown in the image below to copy the code below in the gray box, right click/paste it into the terminal window.
- Then press the enter key, user password, enter key, **reboot.**


```
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"/g' /etc/default/grub && latest_oem_kernel=$(ls /boot/vmlinuz-* | grep '6.5.0-10..-oem' | sort -V | tail -n1 | awk -F'/' '{print $NF}' | sed 's/vmlinuz-//') && sudo sed -i.bak '/^GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux '"$latest_oem_kernel"'"' /etc/default/grub && sudo update-grub && sudo apt install zenity && mkdir -p ~/.config/autostart && [ ! -f ~/.config/autostart/kernel_check.desktop ] && echo -e "[Desktop Entry]\nType=Application\nExec=bash -c \"latest_oem_kernel=\$(ls /boot/vmlinuz-* | grep '6.5.0-10..-oem' | sort -V | tail -n1 | awk -F'/' '{print \\\$NF}' | sed 's/vmlinuz-//') && current_grub_kernel=\$(grep '^GRUB_DEFAULT=' /etc/default/grub | sed -e 's/GRUB_DEFAULT=\\\"Advanced options for Ubuntu>Ubuntu, with Linux //g' -e 's/\\\"//g') && [ \\\"\\\${latest_oem_kernel}\\\" != \\\"\\\${current_grub_kernel}\\\" ] && zenity --text-info --html --width=300 --height=200 --title=\\\"Kernel Update Notification\\\" --filename=<(echo -e \\\"A newer OEM D kernel is available than what is set in GRUB. <a href='https://github.com/FrameworkComputer/linux-docs/blob/main/22.04-OEM-D.md'>Click here</a> to learn more.\\\")\"\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=Kernel check\nName=Kernel check\nComment[en_US]=\nComment=" > ~/.config/autostart/kernel_check.desktop
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.

<p style="text-align: left"><img src="https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/copied.png" alt="Copy The Code Below Like This" title="Copy The Code Above Like This"></p>

&nbsp; &nbsp; &nbsp; &nbsp; 


## What the above code does.
- Disables the ALS sensor so that your brightness keys work.
- Ensures GRUB is using the latest OEM D kernel at every boot.
- Creates a desktop file as an autostart to check for OEM kernel status.
- If an update comes about for the OEM kernel, is installed, but GRUB still has the older version - an alert box will provide you with a link to get this corrected.

&nbsp; &nbsp; &nbsp; &nbsp; 

## What does the OEM Kernel alert looks like:
&nbsp; &nbsp;
> **Note:** This will appear if the code below is pasted into the terminal, enter key pressed and system rebooted.
When a new version of the OEM kernel is ready, this will alert you at bootup - if you're *on the current OEM D kernel* AND you have *followed my above directions*, then and only then **you will not be alerted**. 

![What does the OEM Kernel alert looks like](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/d8becead412d3858a1f561fb2f827f803ab17c47/oem-d-alert.png)

&nbsp; &nbsp; &nbsp; &nbsp; 


-----

## For Advanced users ONLY: 

> If you are someone who is not super comforable with the command line, **please use the steps above instead**.
> Additionally, if a new OEM kernel is released, **you will be NOT be alerted** if you use the advanced method as nothing is checking for updates to alert you.

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Step 1 (ADVANCED USERS) Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Step 2 (ADVANCED USERS) Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04d``

**Reboot**

### Step 3 (ADVANCED USERS) Disable the ALS sensor so that your brightness keys work.
``sudo gedit /etc/default/grub``

Add module_blacklist=hid_sensor_hub so it looks like:

``GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"``

### Step 4 (ADVANCED USERS) Indentify your OEM D kernel.

```
ls /boot/vmlinuz-* | awk -F"-" '{split($0, a, "-"); version=a[3]; if (version>max) {max=version; kernel=a[2] "-" a[3] "-" a[4]}} END{print kernel}'
```

Right now, this is **6.1.0-1025-oem** - but this may evolve in the future.



### Step 5 (ADVANCED USERS) Change the following.


``
GRUB_DEFAULT="0"
``

into

``
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.1.0-1025-oem"
``


### Step 6 (ADVANCED USERS) Then run.
``sudo update-grub``

**Reboot**
