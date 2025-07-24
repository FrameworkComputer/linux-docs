# Framework 12 - Debugging

Framework 12 has a couple of features not present on our other systems.
They might not work on some installations, these instructions here help you find the root cause and how to fix it.

## Tablet Mode

Kernel drivers required:

- `pinctrl_tigerlake` (Must be built into the kernel or load first)
- [`soc_button_array`](https://github.com/torvalds/linux/blob/master/drivers/input/misc/soc_button_array.c)

### Check that both modules are loaded

```
> sudo lsmod | grep -e pinctrl_tigerlake -e soc_button_array
pinctrl_tigerlake    24576 0
soc_button_array     28672 5
```

If no, you can load them manually:

```
> sudo modprobe pinctrl_tigerlake soc_button_array
```

### Check that the kernel recognized the tabletmode GPIO

```
> journalctl -k | grep gpio-keys
Feb 27 19:14:00 fedora kernel: input: gpio-keys as /devices/platform/INT33D3:00/gpio-keys.1.auto/input/input17
```

If no, then `pinctrl_tigerlake` might have loaded after `soc_button_array`.
Reload them manually in the right order:

```
sudo rmmod soc_button_array
sudo modprobe soc_button_array
```

To make this permanent you can configure your distribution to load
`pinctrl_tigerlake` in initrd.

### Check that libinput can see tablet mode changes

```
 > sudo libinput debug-events | grep SWITCH_TOGGLE
-event13  SWITCH_TOGGLE           	+0.000s   switch tablet-mode state 1
 event13  SWITCH_TOGGLE           	+1.360s   switch tablet-mode state 0
```

We have not seen this fail, if the kernel modules are okay, this should work.
If not, please contact Framework.

## Screen Rotation

GNOME, KDE, Windows all rotate the screen only if the system is in tablet mode,
so please check if that's working first.

If you want to rotate in laptop mode, KDE has a setting and GNOME has a plugin to do that.

The kernel driver
[`cros_ec_sensors`](https://github.com/torvalds/linux/blob/master/drivers/iio/common/cros_ec_sensors/cros_ec_sensors.c)
reads accelerometer from the EC controller. This is supported on Framework 12
since Linux 6.12.

iio-sensor-proxy interprets that accelerometer data as a screen orientation and
forwards it to GNOME/KDE via dbus.

### Check that the EC driver recognizes the system

```
> sudo dmesg | grep cros_ec
[	9.014454] cros_ec_lpcs cros_ec_lpcs.0: loaded with quirks 00000001
[	9.025815] cros_ec_lpcs cros_ec_lpcs.0: Chrome EC device registered
```

If no, likely your kernel is older than 6.12.

### Check that the kernel exposes accelerometer data

```
> cat /sys/bus/iio/devices/iio:device0{name,label,in_accel_{x,y,z}_raw}
cros-ec-accel
accel-display
-192
14400
6672
```

If that is not working, please contact Framework.

### Check that the iio-sensor-proxy daemon is runnning

```
> systemctl status iio-sensor-proxy.service | grep Active
 	Active: active (running) since Thu 2025-02-27 19:14:02 CST; 19h ago
```

If no, make sure the package is installed and the service is enabled and running.


### Check that the daemon can be accessed and recognizes the sensor

```
> monitor-sensor --accel
	Waiting for iio-sensor-proxy to appear
+++ iio-sensor-proxy appeared
=== Has accelerometer (orientation: normal)
	Accelerometer orientation changed: right-up
	Accelerometer orientation changed: normal
```

If not, you are likely running iio-sensor-proxy 3.7.
A fix has been [merged upstream](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/-/merge_requests/400).
Until the next release has reached distributions, you can either downgrade to
3.7 or remove a line in the udev config:

```
sed 's/.*iio-buffer-accel/#&/' /usr/lib/udev/rules.d/80-iio-sensor-proxy.rules | sudo tee /etc/udev/rules.d/80-iio-sensor-proxy.rules
sudo udevadm trigger --settle
sudo systemctl restart iio-sensor-proxy
```

Please see our distribution specific documentation for further details.
