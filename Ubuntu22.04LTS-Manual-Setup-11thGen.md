# This is for 11th Gen ONLY.


## This will:

- Update your Ubuntu install's packages.
- Install the recommended OEM kernel. Now recommending a new OEM kernel.




##  *****COPY AND PASTE THIS CODE BELOW INTO A TERMINAL*****


- Browse to Activities in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Left click and drag to highlight and copy the code below in the gray box, right click/paste to copy it into the terminal window.



**Then press the enter key, password, reboot.**


``
sudo apt update && sudo apt upgrade -y && sudo snap refresh && sudo apt-get install linux-oem-22.04c -y
``


**Reboot**, then paste this into the terminal and press enter:


``
sudo sed -i 's/GRUB_DEFAULT=[0-9]/GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.1.0-1019-oem"/' /etc/default/grub && sudo update-grub
``


**Reboot** again.


## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


---------

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:

### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04c``

### Append the following to the GRUB_CMDLINE_LINUX_DEFAULT="quiet splash section.


``
GRUB_DEFAULT="o"

``

into

``
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.1.0-1019-oem"
``

### Then run
``sudo update-grub``




