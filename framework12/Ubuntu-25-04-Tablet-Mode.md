# Ubuntu 25.04 Tablet Mode Setup

This script will set up tablet mode support for your laptop on Ubuntu 25.04, giving you an experience similar to what Fedora 42 and Bazzite offer out of the box.

What This Script Does

- Installs necessary packages for tablet mode detection
- Sets up automatic screen rotation

## To setup tablet mode compatibility for Ubuntu 25.04 (ONLY), simply run:

Install Curl, copy, paste into a terminal, enter key:
```
sudo apt install curl -y
```

Then run, copy, paste into a terminal, enter key - reboot when prompted at the end:
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/scripts/Framework-12-Ubuntu-25-04-tablet-mode.sh -o Framework-12-Ubuntu-25-04-tablet-mode.sh && clear && sudo bash Framework-12-Ubuntu-25-04-tablet-mode.sh
```

> IMPORTANT: When rebooting, log back in. Wait about 20 second until the desktop loads, it will flash for a second then all is well. This is the extension installing itself and activating. Do not rush this.


Running the script in the future After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved - remember to reboot when prompted at the end.

```
sudo bash Framework-12-Ubuntu-25-04-tablet-mode.sh
```


> IMPORTANT: When rebooting, log back in. Wait about 20 second until the desktop loads, it will flash for a second then all is well. This is the extension installing itself and activating. Do not rush this.


![Running Script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/images/install.png)


-------------------------

## What does this do and why is it using an extension?

### What This Script Does

This script configures auto-rotation and on-screen keyboard functionality for the Framework Laptop 12 running Ubuntu. Here's what it accomplishes:

- Sets up an UPDATED iio-sensor-proxy service - Installs and configures the sensor proxy service that detects device orientation changes
- Installs required packages - Adds necessary dependencies for sensor detection and screen rotation
- Installs Fedora's iio-sensor-proxy package - Uses a version known to work well with the Framework hardware
- Sets up proper device access for sensor hardware
- Configures udev rules - Creates rules to ensure sensors have the right permissions
- Sets up systemd service - Ensures sensor proxy runs automatically at startup
- Installs screen-rotation extension - Adds the GNOME extension that performs the actual rotation

### Why It Uses a GNOME Extension

The script uses a GNOME Shell extension (screen-rotate(at)shyzus.github.io) for several important reasons:

- Integration with GNOME Desktop Environment - The extension hooks into GNOME Shell's display management system to handle rotation properly
- User Interface Integration - The extension provides visual feedback during rotation and handles the UI transform smoothly
- Event Handling - It properly processes sensor events from iio-sensor-proxy and applies the appropriate screen transformations
- We will fork it and maintain it if needed in the future

The extension serves as the crucial interface layer between the low-level sensor drivers (iio-sensor-proxy) and the user-facing desktop environment, allowing the Framework Laptop 12 to function properly as a convertible device with automatic screen rotation when switching between laptop and tablet modes on Ubuntu 25.04.
