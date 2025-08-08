# Arch Linux Tablet Mode Setup

This guide will help you enable automatic screen rotation on Arch Linux and its derivatives. On many systems, the required package is not installed by default, and the available version may require a workaround to function correctly.

> Rather not deal with this at all? [Bazzite](https://guides.frame.work/Guide/Bazzite+Installation+on+the+Framework+Laptop+12/409?lang=en) and [Fedora](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+12/410?lang=en) have this working out of the box, with zero configuration required.

On a standard Arch Linux installation, the `iio-sensor-proxy` package that manages accelerometer data is not installed. Furthermore, some repositories may provide version 3.7, which has [a bug](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/-/issues/411) preventing it from delivering sensor events to your desktop environment (GNOME, KDE, etc.).

The following steps will guide you through installing the package and applying the necessary fix.

### Step 1: Install `iio-sensor-proxy`

First, open a terminal and install the package using `pacman`.

```bash
sudo pacman -S iio-sensor-proxy
````

### Step 2: Apply the udev Workaround

Next, apply the one-line command to fix the bug. This command comments out the problematic rule and reloads the system services.

```bash
sed 's/.*iio-buffer-accel/#&/' /usr/lib/udev/rules.d/80-iio-sensor-proxy.rules | sudo tee /etc/udev/rules.d/80-iio-sensor-proxy.rules
sudo udevadm trigger --settle
sudo systemctl restart iio-sensor-proxy
```

### Step 3: Verify the Fix

Finally, you can check if screen rotation is working correctly.

```bash
monitor-sensor --accel
```

You should see the following output, confirming the accelerometer is detected:

```
    Waiting for iio-sensor-proxy to appear
+++ iio-sensor-proxy appeared
=== Has accelerometer (orientation: normal)
```

> Tablet rotation mode should now work immediately. However, if for some reason it does not, reboot your computer and then test rotation again. Remember to flip the screen completely back to test rotation properly.

```
```