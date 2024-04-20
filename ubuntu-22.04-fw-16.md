# This is for the Framework Laptop 16 (AMD Ryzen™ 7040 Series) ONLY.

### OEM kernel and recommended configuration

- [Install OEM D kernel](#step-1)
- [Allow both CPU and platform drivers to be simultaneously active](#step-3-allow-both-cpu-and-platform-drivers-to-be-simultaneously-active)
- [Prevent graphical artifacts from appearing](#additionally-we-recommend-the-following-as-well-if-you-are-experiencing-graphical-artifacts-from-appearing)

### Optional and only if needed - current AMD Ryzen 7040 Series workarounds to common issues

- [MediaTek WiFi Dropout on WiFi 6E routers fix](#mediatek-wifi-dropout-on-wifi-6e-routers)
- [Suspend wakes up unexpectedly or fails to remain in a suspend state](#suspend-keeps-waking-up-or-fails-to-suspend)


## Install OEM D kernel

This will:

- Install the recommended OEM kernel and provide you with an alert should the OEM kernel needing updating.
- Allow both CPU and platform drivers to be simultaneously active.


### Step 1

- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Click on the small copy clipboard ![copy clipboard icon](images/copy-icon.png) icon to the right of the following text box. Right click/paste it into the terminal window.
  ```bash
  sudo apt update && sudo apt upgrade -y && sudo snap refresh \
  && sudo apt-get install linux-oem-22.04d -y
  ```
- Then press the enter key, user password, enter key, **reboot.**


### Step 2

- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Click on the small copy clipboard ![copy clipboard icon](images/copy-icon.png) icon to the right of the following text box. Right click/paste it into the terminal window.
  ```bash
  latest_oem_kernel=$(ls /boot/vmlinuz-* | grep '6.5.0-10..-oem' | sort -V | tail -n1 | awk -F'/' '{print $NF}' | sed 's/vmlinuz-//') \
  && sudo sed -i.bak '/^GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux '"$latest_oem_kernel"'"' /etc/default/grub \
  && sudo update-grub \
  && sudo apt install zenity \
  && mkdir -p ~/.config/autostart \
  && [ ! -f ~/.config/autostart/kernel_check.desktop ] \
  && echo -e "[Desktop Entry]\nType=Application\nExec=bash -c \"latest_oem_kernel=\$(ls /boot/vmlinuz-* | grep '6.5.0-10..-oem' | sort -V | tail -n1 | awk -F'/' '{print \\\$NF}' | sed 's/vmlinuz-//') && current_grub_kernel=\$(grep '^GRUB_DEFAULT=' /etc/default/grub | sed -e 's/GRUB_DEFAULT=\\\"Advanced options for Ubuntu>Ubuntu, with Linux //g' -e 's/\\\"//g') && [ \\\"\\\${latest_oem_kernel}\\\" != \\\"\\\${current_grub_kernel}\\\" ] && zenity --text-info --html --width=300 --height=200 --title=\\\"Kernel Update Notification\\\" --filename=<(echo -e \\\"A newer OEM D kernel is available than what is set in GRUB. <a href='https://github.com/FrameworkComputer/linux-docs/blob/main/22.04-OEM-D.md'>Click here</a> to learn more.\\\")\"\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=Kernel check\nName=Kernel check\nComment[en_US]=\nComment=" \
  >~/.config/autostart/kernel_check.desktop
  ```
- Then press the enter key, user password, enter key, **reboot.**

#### What the above code does.
- Ensures GRUB is using the latest OEM D kernel at every boot.
- Creates a desktop file as an autostart to check for OEM kernel status.
- If an update comes about for the OEM kernel, is installed, but GRUB still has the older version - an alert box will provide you with a link to get this corrected.

#### What does the OEM Kernel alert looks like:

> **Note:** This will appear if the code below is pasted into the terminal, enter key pressed and system rebooted.
When a new version of the OEM kernel is ready, this will alert you at bootup - if you're *on the current OEM D kernel* AND you have *followed my above directions*, then and only then **you will not be alerted**. 

![What does the OEM Kernel alert looks like](oem-d-alert.png)

<details>
<summary>Here are the separated commands and steps for <b>advanced users</b>.</summary>

> If you are someone who is not super comfortable with the command line, **please use the steps above instead**.
> Additionally, if a new OEM kernel is released, **you will be NOT be alerted** if you use the advanced method as nothing is checking for updates to alert you.

If you would rather enter the commands individually **instead** of using the code block provided previously:

1. Install OEM kernel.

    ```bash
    # Update packages.
    sudo apt update && sudo apt upgrade -y
    # Install the recommended OEM kernel.
    sudo apt install linux-oem-22.04d

    # Reboot the machine and then check your oem kernel in the last command.
    sudo reboot
    ```

    Identify the name of the OEM kernel. This will is use in step 2.

    ```bash
    ls /boot/vmlinuz-* | sort -V | tail -n 1 | awk -F'vmlinuz-' '{print $2}'
    ```

    *For example, the current oem kernel is `6.5.0.1009-oem`, but this may become out of date in the future.*

2. Configure GRUB to use the OEM kernel.

    Open the file for editing with nano:

    ```bash
    sudo nano /etc/default/grub
    ```

    Change `GRUB_DEFAULT="0"` to `GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.5.0.1009-oem"`.

    *To save the file and exit nano, press `Ctrl-X`, then `y`, then `Enter`.*

3. Update GRUB.

    ```bash
    sudo update-grub
    ```

4. Reboot.

### Follow Step 3 below

For the best experience possible, it is important that you [complete step 3](#step-3-allow-both-cpu-and-platform-drivers-to-be-simultaneously-active), if you haven't already.

</details>

### Step 3 Allow both CPU and platform drivers to be simultaneously active

To do this on Ubuntu LTS, we'll use a [PPA maintained by AMD](https://launchpad.net/~superm1/+archive/ubuntu/ppd/+packages).

Copy and paste this into a terminal next, pressing enter after.


You can learn more about what this does from [this link](https://gitlab.freedesktop.org/upower/power-profiles-daemon/-/merge_requests/127).


Copy and paste the PPA code below into a terminal, press enter after.
```bash
sudo add-apt-repository ppa:superm1/ppd
```

Then next, paste this into a terminal, press enter after.
```bash
sudo apt update && sudo apt upgrade -y
```

Then reboot.

## Additionally, we recommend the following as well if you are experiencing graphical artifacts from appearing

- Please follow the steps outlined in this guide:
  https://knowledgebase.frame.work/allocate-additional-ram-to-igpu-framework-laptop-13-amd-ryzen-7040-series-BkpPUPQa


---


## Optional and *only if needed* - current AMD Ryzen 7040 Series workarounds to common issues

### MediaTek WiFi Dropout on WiFi 6E routers

1. Run the following in a terminal:

    ```bash
    sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ jammy-proposed main restricted universe multiverse" \
    && sudo apt update \
    && sudo apt install linux-firmware/jammy-proposed \
    && sudo sed -i 's/^deb http:\/\/archive.ubuntu.com\/ubuntu\/ jammy-proposed/# &/' /etc/apt/sources.list \
    && sudo apt update \
    && sudo rm /lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin \
    && sudo rm /lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin \
    && cd /tmp \
    && wget https://gitlab.com/kernel-firmware/linux-firmware/-/raw/0a18a7292a66532633d9586521f0b954c68a9fbc/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin \
    && wget https://gitlab.com/kernel-firmware/linux-firmware/-/raw/0a18a7292a66532633d9586521f0b954c68a9fbc/mediatek/WIFI_RAM_CODE_MT7922_1.bin \
    && sudo mv WIFI_MT7922_patch_mcu_1_1_hdr.bin /lib/firmware/mediatek/ \
    && sudo mv WIFI_RAM_CODE_MT7922_1.bin /lib/firmware/mediatek/ \
    && sudo update-initramfs -u
    ```
2. Reboot
3. After rebooting, run the following in a terminal to check that the correct firmware was loaded:

    ```bash
    sudo dmesg | grep mt7921e
    ```

    *Build time in dmesg confirms this worked. 20230627143702a and 202330627143946*

<details>
<summary>Here are the separated commands and steps for <b>advanced users</b>.</summary>

```bash
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ jammy-proposed main restricted universe multiverse"
sudo apt update && sudo apt install linux-firmware/jammy-proposed 
sudo sed -i 's/^deb http:\/\/archive.ubuntu.com\/ubuntu\/ jammy-proposed/# &/' /etc/apt/sources.list
sudo apt update

sudo rm /lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin
sudo rm /lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin

cd /tmp
wget https://gitlab.com/kernel-firmware/linux-firmware/-/raw/0a18a7292a66532633d9586521f0b954c68a9fbc/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin
wget https://gitlab.com/kernel-firmware/linux-firmware/-/raw/0a18a7292a66532633d9586521f0b954c68a9fbc/mediatek/WIFI_RAM_CODE_MT7922_1.bin
sudo mv WIFI_MT7922_patch_mcu_1_1_hdr.bin /lib/firmware/mediatek/
sudo mv WIFI_RAM_CODE_MT7922_1.bin /lib/firmware/mediatek/
sudo update-initramfs -u

# Reboot and then check the firmware loaded with the following line:
sudo dmesg | grep mt7921e
```
</details>

----------------------------------------------

### Suspend keeps waking up or fails to suspend

1. Add `rtc_cmos.use_acpi_alarm=1` to `GRUB_CMDLINE_LINUX_DEFAULT` in the `/etc/default/grub` file.

    Open the file for editing with nano:

    ```bash
    sudo nano /etc/default/grub
    ```

    Change `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"` to `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rtc_cmos.use_acpi_alarm=1"`

    *To save the file and exit nano, press `Ctrl-X`, then `y`, then `Enter`.*

2. Update GRUB.

    ```bash
    sudo update-grub
    ```

3. Reboot.
