# This is for 13th Gen Intel® Core™ Framework Laptop 13 ONLY.


## This will:

- Update your Manjaro install's packages.
- Workaround needed to get the best suspend battery life for SSD power drain.
- Disable the ALS sensor so that your brightness keys work.
- Prevent wireless drops.

##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Go to the Manjaro Launcher or press the super key.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.
- **Then press the enter key, password, reboot.**


``
sudo pacman -Syyu --noconfirm && sudo sed -i.bak 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"$/\1 module_blacklist=hid_sensor_hub nvme.noacpi=1"/' /etc/default/grub && sudo update-grub && echo "[connection]" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf && echo "wifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf && sleep 1 && sudo echo -e "\033[1;33mProcess is complete"``

## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


-----

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Updating packages.
``sudo pacman -Syyu --noconfirm``

### Disable the ALS sensor so that your brightness keys work, 13th gen only.
``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
If encrypted, make sure you place this correctly or use the copy/paste command above instead.
``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"
``

### Then run
``sudo update-grub``

### Workaround needed to get the best suspend battery life for SSD power drain.
If encrypted, make sure you place this correctly or use the copy/paste command above instead.

``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
If encrypted, make sure you place this correctly or use the copy/paste command above instead.

This is an ACPI parameter that helps ensure compatibility by disabling ACPI support for NVMe. Advanced Linux users: You're welcome to remove it if you feel it's not needed for any reason and sudo update-grub.

``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvme.noacpi=1"
``

### Then run
``sudo update-grub``

### Preventing wifi drop offs.
``sudo gedit /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf``

### Change 3 into a 2
``wifi.powersave = 2``
