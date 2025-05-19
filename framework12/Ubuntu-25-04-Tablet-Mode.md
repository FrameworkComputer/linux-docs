# Ubuntu 25.04 Tablet Mode Setup

This script will set up tablet mode support for your laptop on Ubuntu 25.04, giving you an experience similar to what Fedora 42 and Bazzite offer out of the box.

> Rather not deal with this at all? [Bazzite](https://guides.frame.work/Guide/Bazzite+Installation+on+the+Framework+Laptop+12/409?lang=en) and [Fedora](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+12/410?lang=en) are ready to go out of the box, zero configuration.

What This Script Does

- Installs necessary packages for tablet mode detection
- Sets up automatic screen rotation

### Need to revert these changes back to Ubuntu defaults to test if Ubuntu updates have corrected failure to rotate the screen?
- [Revert to Ubuntu iio-sensor-proxy defaults with Ubuntu's latest version](#undoing-the-tablet-mode-setup).

## To setup tablet mode compatibility for Ubuntu 25.04 (ONLY):

Install Curl, copy, paste into a terminal, enter key:
```
sudo apt install curl -y
```

Copy, paste code below into a terminal, enter key - reboot when prompted at the end - _one and done_:
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

---------------------------

# Revert to Ubuntu's defaults for testing any potencial solutions from Ubuntu updates

If you need to roll back all of the auto-rotation and on-screen keyboard customizations and return to Ubuntu’s vanilla `iio-sensor-proxy`, follow these steps or save the script below as `undo-tablet-mode.sh` and run it under `sudo`.

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/framework12/scripts/Un-do-tablet-customizations.sh -o Un-do-tablet-customizations.sh && clear && sudo bash Un-do-tablet-customizations.sh
```

What the Undo Script Does

This helper script reverses every customization applied by the tablet-mode installer, restoring Ubuntu’s original auto‐rotation setup.

- Unpins the sensor proxy package: Removes any apt-mark hold on iio-sensor-proxy so Ubuntu upgrades can manage it normally again.

- Removes the Fedora/Koji fallback: Purges the alien-converted RPM build of iio-sensor-proxy and reinstalls Ubuntu’s stock version from the official repositories.

- Deletes the custom systemd service: Disables and removes /etc/systemd/system/Framework-sensor-proxy.service, then reloads systemd so only Ubuntu’s default service remains.

- Deletes the custom udev rule: Removes /etc/udev/rules.d/61-sensor-local.rules and triggers udev to reload, restoring default device-node permissions.

- Uninstalls the GNOME screen-rotate extension: Deletes the extension directory under the user’s home (~/.local/share/gnome-shell/extensions/screen-rotate@…) and its autostart desktop file, so GNOME returns to its out-of-the-box state.

- Removes the user from the plugdev group: Optionally removes the user from plugdev if they were added, undoing any group-based permission grants.

- Reloads system daemons: Runs systemctl daemon-reload and udevadm trigger to apply all removals immediately, without requiring manual cleanup or a package-level reboot.

After running the script and **rebooting**, your laptop will be running **Ubuntu’s unmodified iio-sensor-proxy and default tablet-mode behavior** - this is useful for testing whether upstream updates have addressed the rotation issue.
