# Ubuntu 25.04 Tablet Mode Setup

This guide will help set up screen rotation support for your laptop on Ubuntu 25.04, giving you an experience similar to what Fedora 42 and Bazzite offer out of the box.

> Rather not deal with this at all? [Bazzite](https://guides.frame.work/Guide/Bazzite+Installation+on+the+Framework+Laptop+12/409?lang=en) and [Fedora](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+12/410?lang=en) are ready to go out of the box, zero configuration.

Three options to choose from, all options are for tablet mode on Ubuntu 25.04

#### If you feel strongly about using the iio-sensor-proxy package provided by the 25.04 release, [Udev Edit Option](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-accel-ubuntu25.04.md) is your best option. The other two methods install an older version of iio-sensor-proxy that requires no tweaking at all. 
**Use the method you are most comfortable with.**

- [Manual install](#manual-package-install-option) gives you full control—you download the .deb yourself and run dpkg -i, then you’re done.
> iio-sensor-proxy 3.5-1build2

- [Script install option](#script-option) bundles dependency installation, the download, the install, and even triggers a reboot into a single curl-and-bash command for a one-and-done experience.
> iio-sensor-proxy 3.5-1build2

- [Udev edit option](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-accel-ubuntu25.04.md) skips installing any new package and instead tweaks your existing udev rules so the sensor is recognized automatically, which can be useful if you just need the sensor enabled without adding or upgrading software.
> Default install of iio-sensor-proxy 3.7-1


## Manual package install option

1- Browse to [this page](https://launchpad.net/ubuntu/+source/iio-sensor-proxy/3.5-1build2/+build/27983927), download `iio-sensor-proxy_3.5-1build2_amd64.deb` from the "Built Files" section.

2- Use dpkg to unpack and install the .deb:

```
sudo dpkg -i iio-sensor-proxy_3.5-1build2_amd64.deb
```

3- All Done, tablet mode is ready to go for Ubuntu 25.04

> Unless you choose to hold the package back, it will update automatically - which will means tablet mode may stop working, unless you hold it back.

```
sudo apt-mark hold iio-sensor-proxy
```


--------------------------
## Script option

What This Script Does

- Installs necessary package for tablet mode detection

## To setup tablet mode compatibility for Ubuntu 25.04 (ONLY):

Install Curl, copy, paste into a terminal, enter key:
```
sudo apt install curl -y
```

Copy, paste code below into a terminal, enter key - reboot when prompted at the end - _one and done_:
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/scripts/Framework-12-Ubuntu-25-04-tablet-deb.sh -o Framework-12-Ubuntu-25-04-tablet-deb.sh && clear && sudo bash Framework-12-Ubuntu-25-04-tablet-deb.sh
```

--------------------------

## Udev Edit Option

Browse [to this page](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-accel-ubuntu25.04.md) and follow the directions provided.


-------------------------
