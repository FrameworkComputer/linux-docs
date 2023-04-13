# This is for 12th Gen ONLY.


## This will:

 - Update your Ubuntu install's packages.
- Install the recommended OEM kernel. Now recommending a new OEM kernel.
- Workaround needed to get the best suspend battery life for SSD power drain.
- Disable the ALS sensor so that your brightness keys work.
- Enable improved fractional scaling support for Ubuntu's GNOME environment using Wayland.
- Enable headset mic input.




##  *****COPY AND PASTE THIS CODE BELOW*****


``
sudo apt update && sudo apt upgrade -y && sudo apt-get install linux-oem-22.04c && echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf && gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" && sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash module_blacklist=hid_sensor_hub nvme.noacpi=1"/g' /etc/default/grub && sudo update-grub && 
echo "[connection]" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf && echo "wifi.powersave = 2" | sudo tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
``

## *****COPY AND PASTE THIS CODE ABOVE*****

### Then press enter key, password, reboot.




# If you would rather enter the commands individually instead:

### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04c``

### Enable headset mic input.
``echo "options snd-hda-intel model=dell-headset-multi" | sudo tee -a /etc/modprobe.d/alsa-base.conf``

### Enable improved fractional scaling support for Ubuntu's GNOME environment using Wayland.
``
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
``

### Disable the ALS sensor so that your brightness keys work, 12th gen only.
``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
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

## Sudo with your fingerprints **if** it doesn't work after being setup under Users.

### To run sudo in a terminal with the fingerprint reader, you need to run this command in a terminal and follow the prompts. 

``sudo pam-auth-update ``         

### Also, if you've previously enrolled fingerprints in Windows or another Linux distro, you may find that fingerprint enrollment errors until you manually force clear the stored fingerprints.
https://knowledgebase.frame.work/en_us/fingerprint-enrollment-rkG6YP7xF


### Additional ways to extend battery life can be found at this link: https://community.frame.work/t/linux-battery-life-tuning/6665
