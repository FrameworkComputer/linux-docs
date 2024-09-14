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
&nbsp;

## Roll back your kernel

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

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/ubuntu-grub-defaults.sh -o ubuntu-grub-defaults.sh && bash ubuntu-grub-defaults.sh
```


Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash ubuntu-grub-defaults.sh
```


![ubuntu-grub-defaults](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/ubuntu-kernel-switcher/images/defaults.png)
