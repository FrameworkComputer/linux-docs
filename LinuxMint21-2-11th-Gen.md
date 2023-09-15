# This is for 11th Gen Intel® Core™ Framework Laptop 13 ONLY.


## This will:

- Update your Linux Mint install's packages.
- Install the recommended OEM kernel. Now recommending a new OEM kernel.
- Workaround needed to get the best suspend battery life for SSD power drain.
- Enable headset mic input.

##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Go to the Linux Mint Launcher or press the super key.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.
- **Then press the enter key, password, reboot.**


``
sudo apt update && sudo apt upgrade -y && sudo apt-get install linux-oem-22.04c -y && sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvme.noacpi=1"/g' /etc/default/grub && sudo update-grub
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

### Then run
``sudo update-grub``

### Workaround needed to get the best suspend battery life for SSD power drain.
``sudo gedit /etc/default/grub``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.
This is an ACPI parameter that helps ensure compatibility by disabling ACPI support for NVMe.
Advanced Linux users: You're welcome to remove it if you feel it's not needed for any reason and sudo update-grub.
``
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvme.noacpi=1"
``

### Then run
``sudo update-grub``
