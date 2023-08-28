# This is for Intel 11th Gen ONLY.


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

```
latest_oem_kernel=$(ls /boot/vmlinuz-* | awk -F"-" '{split($0, a, "-"); version=a[3]; if (version>max) {max=version; kernel=a[2] "-" a[3] "-" a[4]}} END{print kernel}')
sudo sed -i.bak '/^GRUB_DEFAULT=/c\GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux '"$latest_oem_kernel"'"' /etc/default/grub
sudo update-grub
```

**Reboot** again.

## *****COPY AND PASTE THIS CODE ABOVE INTO A TERMINAL*****


---------

# For intermediate to advanced users: 

If you would rather enter the commands individually **instead** of using the code block provided previously:


### Updating packages.
``sudo apt update && sudo apt upgrade -y``

### Install the recommended OEM kernel.
``sudo apt install linux-oem-22.04c``

**Reboot**

``sudo gedit /etc/default/grub``

### Indentify your OEM C kernel

```
ls /boot/vmlinuz-* | awk -F"-" '{split($0, a, "-"); version=a[3]; if (version>max) {max=version; kernel=a[2] "-" a[3] "-" a[4]}} END{print kernel}'
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



### Then run
``sudo update-grub``
