# This is for 13th Gen Intel® Core™ Framework Laptop 13 ONLY.


## This will:

- Update your Linux Mint install's packages.
- Install the recommended OEM kernel. Now recommending a new OEM kernel.
- Workaround needed to get the best suspend battery life for SSD power drain.
- Disable the ALS sensor so that your brightness keys work.
- Enable headset mic input.

##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Go to the Linux Mint Launcher or press the super key.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.
- **Then press the enter key, password, reboot.**


``
sudo apt update && sudo apt upgrade -y && sudo apt-get install linux-oem-22.04c -y && echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf && sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub nvme.noacpi=1"/g' /etc/default/grub && sudo update-grub && echo "[connection]" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf && echo "wifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
``

## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


**Pasted code will look similar to the image below:**
![Example of what pasted code will look like](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/paste-code.png)


-----

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04c``

### Enable headset mic input.
``echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf``

### Disable the ALS sensor so that your brightness keys work, 13th gen only.
``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
This will address your brightness keys.

``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub"
``

### Then run
``sudo update-grub``

### Workaround needed to get the best suspend battery life for SSD power drain.
``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvme.noacpi=1"
``

### Then run
``sudo update-grub``

### Preventing wifi drop offs.
``sudo gedit /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf``

### Change 3 into a 2
``wifi.powersave = 2``
