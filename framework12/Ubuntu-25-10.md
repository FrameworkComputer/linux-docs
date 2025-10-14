# Enabling tablet mode in Ubuntu 25.10

For tablet mode to work, the kernel modules `pinctrl_tigerlake` and `soc_button_array` must be loaded in order. Ubuntu 25.10 may load `soc_button_array` first which prevents tablet mode from working. 

To fix this run:
```
echo "force_drivers+=" pinctrl_tigerlake "" | sudo tee /etc/dracut.conf.d/fw12_tablet_mode_fix.conf
sudo update-initramfs -u
```
This makes sure the `pinctrl_tigerlake` module is loaded first by adding it to the initramfs.
