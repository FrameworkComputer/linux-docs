# Ubuntu 25.04 Tablet Mode Setup Udev Edit

This guide will help set up screen rotation support for your laptop on Ubuntu 25.04, giving you an experience similar to what Fedora 42 and Bazzite offer out of the box.

> Rather not deal with this at all? [Bazzite](https://guides.frame.work/Guide/Bazzite+Installation+on+the+Framework+Laptop+12/409?lang=en) and [Fedora](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+12/410?lang=en) are ready to go out of the box, zero configuration.

Ubuntu 25.04 currently ships with iio-sensor-proxy 3.7 that has [a bug](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/-/issues/411) preventing it from delivering accelerometer events from kernel to userspace (GNOME, KDE, ...).

We have [submitted a bug](https://bugs.launchpad.net/ubuntu/+source/iio-sensor-proxy/+bug/2117530) to backport the upstream fix.
In the meanwhile you can use the following workaround.

```
sed 's/.*iio-buffer-accel/#&/' /usr/lib/udev/rules.d/80-iio-sensor-proxy.rules | sudo tee /etc/udev/rules.d/80-iio-sensor-proxy.rules
sudo udevadm trigger --settle
sudo systemctl restart iio-sensor-proxy
```

Then you can check if screen rotation works:

```
> monitor-sensor --accel
    Waiting for iio-sensor-proxy to appear
+++ iio-sensor-proxy appeared
=== Has accelerometer (orientation: normal)
```

> Tablet rotation mode should work immediately. Howver if for some reason it does not, reboot then test rotation again. Remember to flip the the screen completely back to test rotation properly.
