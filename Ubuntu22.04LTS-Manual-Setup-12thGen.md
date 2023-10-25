# This is for 12th Gen Intel® Core™ Framework Laptop 13 ONLY.


## This will:

- Update your Ubuntu install's packages.
- Install the recommended OEM kernel and provide you with an alert should the OEM kernel needing updating.
- Disable the ALS sensor so that your brightness keys work.

## What does the OEM Kernel alert looks like:
Note: This will appear if the code below is pasted into the terminal, enter key pressed and system rebooted.
When a new version of the OEM kernel is ready, this will alert you at bootup - if you're current, you will not be alerted. 

![What does the OEM Kernel alert looks like](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/3.png)


##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.



**Then press the enter key, password, reboot.**


``
sudo apt update && sudo apt upgrade -y && sudo snap refresh && sudo apt-get install linux-oem-22.04c -y
``

**Reboot**, then paste this into the terminal and press enter:

- Ensures GRUB is using the latest OEM C kernel at every boot.
- Creates a desktop file as an autostart to check for OEM kernel status.
- If an update comes about for the OEM kernel, is installed, but GRUB still has the older version - an alert box will provide you with a link to get this corrected.

![Copy Code Like This](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/copied.png)


```
latest_oem_kernel=$(ls /boot/vmlinuz-* | grep '6.1.0-10..-oem' | awk -F"-" '{split($0, a, "-"); version=a[3]; if (version>max) {max=version; kernel=a[2] "-" a[3] "-" a[4]}} END{print kernel}')
sudo sed -i.bak '/^GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux '"$latest_oem_kernel"'"' /etc/default/grub
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"/g' /etc/default/grub
sudo update-grub && sudo apt install zenity && mkdir -p ~/.config/autostart && [ ! -f ~/.config/autostart/kernel_check.desktop ] && echo -e "[Desktop Entry]\nType=Application\nExec=bash -c \"latest_oem_kernel=\$(ls /boot/vmlinuz-* | grep '6.1.0-10..-oem' | sort -V | tail -n1 | awk -F'/' '{print \\\$NF}' | sed 's/vmlinuz-//') && current_grub_kernel=\$(grep '^GRUB_DEFAULT=' /etc/default/grub | sed -e 's/GRUB_DEFAULT=\\\"Advanced options for Ubuntu>Ubuntu, with Linux //g' -e 's/\\\"//g') && [ \\\"\\\${latest_oem_kernel}\\\" != \\\"\\\${current_grub_kernel}\\\" ] && zenity --text-info --html --width=300 --height=200 --title=\\\"Kernel Update Notification\\\" --filename=<(echo -e \\\"A newer OEM C kernel is available than what is set in GRUB. <a href='https://github.com/FrameworkComputer/linux-docs/blob/main/22.04-OEM-C.md'>Click here</a> to learn more.\\\")\"\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=Kernel check\nName=Kernel check\nComment[en_US]=\nComment=" > ~/.config/autostart/kernel_check.desktop
```

**Reboot** again.

## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


-----

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04c``

**Reboot**

### Disable the ALS sensor so that your brightness keys work, 12th gen only.
``sudo gedit /etc/default/grub``

### Indentify your OEM C kernel

```
ls /boot/vmlinuz-* | grep '6.1.0-20..-oem' | awk -F"-" '{split($0, a, "-"); version=a[3]; if (version>max) {max=version; kernel=a[2] "-" a[3] "-" a[4]}} END{print kernel}'
```

Right now, this is **6.1.0-1020-oem** - but this may evolve in the future.



### Change the following.


``
GRUB_DEFAULT="0"
``

into

``
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.1.0-1020-oem"
``

Next, add module_blacklist=hid_sensor_hub to GRUB_CMDLINE_LINUX_DEFAULT= to make sure the backlighting is working.

``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"
``


### Then run
``sudo update-grub``


