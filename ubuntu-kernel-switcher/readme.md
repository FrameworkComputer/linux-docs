# Ubuntu Kernel Switcher

If you need to rollback a kernel or restore your grub settings, this is the tool for you.

**NOTE:** The ubuntu-grub-defaults.sh tool will strip any custom parameters and bring grub back to its default state. You should not need any custom parameters in current Ubuntu 22.04 or 24.04 fully updated, but just in case - you may need to re-add if you use them. 

### Install Curl

Curl should already be installed, but just in case:

### Fedora
```
sudo dnf install curl -y
```

or

### Ubuntu
```
sudo apt install curl -y
```
&nbsp;
&nbsp;

Both scripts prioritize safety by backing up the original configuration and requiring user confirmation before making changes.

&nbsp;

## Roll back your kernel

This script allows users to pin a specific kernel version in GRUB, effectively rolling back to a previous kernel if needed. It's useful for situations where a newer kernel update causes issues and the user wants to boot consistently with an older, stable kernel.
Key Features:

- Extracts and displays available kernel versions from GRUB configuration
- Allows user to select a specific kernel to pin
- Backs up the current GRUB configuration before making changes
- Modifies GRUB to use the selected kernel as default
- Provides colored output for better readability
- Includes multiple confirmation steps to prevent accidental changes
- Updates GRUB after changes are confirmed

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/ubuntu-grub-rollback.sh -o ubuntu-grub-rollback.sh && bash ubuntu-grub-rollback.sh
```

Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash ubuntu-grub-rollback.sh
```


![ubuntu-grub-rollback](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/images/rollback.png)

-----------------------------------------------------------------------

## Bring grub back to default, use latest kernel installed

This script modifies the GRUB configuration to set default values, primarily aimed at speeding up the boot process by hiding the GRUB menu and setting a minimal timeout. It's useful for users who want a faster, streamlined boot experience without seeing the GRUB menu.
Key Features:

- Backs up the current GRUB configuration before making changes
- Sets GRUB_DEFAULT to 0 (first menu entry)
- Hides the GRUB menu (GRUB_TIMEOUT_STYLE=hidden)
- Sets GRUB_TIMEOUT to 0 for immediate booting
- Sets GRUB_CMDLINE_LINUX_DEFAULT to "quiet splash" for a cleaner boot process
- Displays a colored diff of proposed changes
- Includes confirmation steps before applying changes
- Updates GRUB after changes are confirmed


```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/ubuntu-grub-defaults.sh -o ubuntu-grub-defaults.sh && bash ubuntu-grub-defaults.sh
```


Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash ubuntu-grub-defaults.sh
```


![ubuntu-grub-defaults](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/images/defaults.png)
