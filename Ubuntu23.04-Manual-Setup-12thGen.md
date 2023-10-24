# This is for 12th Gen Intel® Core™ Framework Laptop 13 ONLY.


## This will:

- Update your Ubuntu install's packages.
- Workaround needed to get the best suspend battery life for SSD power drain.
- Disable the ALS sensor so that your brightness keys work.
- Enable improved fractional scaling support for Ubuntu's GNOME environment using Wayland.
- Enable headset mic input.




##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.
- **Then press the enter key, password, reboot.**


``
sudo apt update && sudo apt upgrade -y && sudo snap refresh && echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf && gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" && sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub nvme.noacpi=1"/g' /etc/default/grub && sudo update-grub && echo "[connection]" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf && echo "wifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
``

## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


**Pasted code will look similar to the image below:**
![Example of what pasted code will look like](https://github.com/FrameworkComputer/linux-docs/blob/main/23.04-term.png?raw=true)


-----

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Enable headset mic input.
``echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf``

### Enable improved fractional scaling support for Ubuntu's GNOME environment using Wayland.
``
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
``

### Disable the ALS sensor so that your brightness keys work, 12th gen only.
``sudo gnome-text-editor /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"
``

### Then run
``sudo update-grub``

### Workaround needed to get the best suspend battery life for SSD power drain.
``sudo gnome-text-editor /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
This is an ACPI parameter that helps ensure compatibility by disabling ACPI support for NVMe.
Advanced Linux users: You're welcome to remove it if you feel it's not needed for any reason and sudo update-grub.
``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvme.noacpi=1"
``

### Then run
``sudo update-grub``

### Preventing wifi drop offs.
``sudo gedit /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf``

### Change 3 into a 2
``wifi.powersave = 2``
