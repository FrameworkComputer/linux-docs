# Ubuntu 25.04+ Tablet Mode Setup Udev Edit
## 25.04 and 25.10 both apply to this guide

This guide will help set up screen rotation support for your laptop on Ubuntu 25.04, giving you an experience similar to what Fedora 42 and Bazzite offer out of the box.

> Rather not deal with this at all? [Bazzite](https://guides.frame.work/Guide/Bazzite+Installation+on+the+Framework+Laptop+12/409?lang=en) and [Fedora](https://guides.frame.work/Guide/Fedora+42+Installation+on+the+Framework+Laptop+12/410?lang=en) are ready to go out of the box, zero configuration.

Ubuntu 25.04 currently ships with iio-sensor-proxy 3.7 that has [a bug](https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/-/issues/411) preventing it from delivering accelerometer events from kernel to userspace (GNOME, KDE, ...).

We have [submitted a bug](https://bugs.launchpad.net/ubuntu/+source/iio-sensor-proxy/+bug/2117530) to backport the upstream fix or update to 3.8.
In the meanwhile you can use the following workaround:

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


---------------------------------------------------

### Temporary workaround for a 25.10 tablet mode bug

I will be getting this in front of engineering, _but in the meantime_. this is a workaround based [on this thread](https://community.frame.work/t/ubuntu-25-10-on-framework-laptop-12/77416/16?u=matt_hartley).

This has been heavily tested and provides an immediate workaround for now.

Terminal, paste, enter, password when prompted, done. **No ./script stuff.**

**Enable workaround**

```
sudo bash -c '

echo "Creating /usr/local/sbin/reload-soc-module.sh..."
{
    mkdir -p /usr/local/sbin &&
    cat << "EOF" > /usr/local/sbin/reload-soc-module.sh
#!/bin/bash
echo "Removing soc_button_array..."
if ! rmmod soc_button_array 2>/dev/null; then
    echo "Warning: soc_button_array was not loaded or could not be removed."
fi

echo "Loading soc_button_array..."
if ! modprobe soc_button_array; then
    echo "ERROR: Failed to load soc_button_array module."
    exit 1
fi

echo "soc_button_array reloaded successfully."
EOF
} || { echo "ERROR: Failed to create reload-soc-module.sh"; exit 1; }

chmod +x /usr/local/sbin/reload-soc-module.sh

echo "Creating systemd service..."
{
    cat << "EOF" > /etc/systemd/system/reload-soc-module.service
[Unit]
Description=Ubuntu 25.10 workaround to reload soc_button_array
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/reload-soc-module.sh

[Install]
WantedBy=multi-user.target
EOF
} || { echo "ERROR: Failed to create systemd service file"; exit 1; }

echo "Reloading systemd..."
if ! systemctl daemon-reload; then
    echo "ERROR: systemctl daemon-reload failed."
    exit 1
fi

echo "Enabling service..."
if ! systemctl enable reload-soc-module.service; then
    echo "ERROR: Failed to enable reload-soc-module.service"
    exit 1
fi

echo "Starting service..."
if ! systemctl start reload-soc-module.service; then
    echo "ERROR: Failed to start reload-soc-module.service"
    exit 1
fi

echo "SUCCESS: soc_button_array reload service installed and running."

'
```

**Later on when a fix has been provided, this is the undo method**

```
sudo bash -c '

echo "Stopping reload-soc-module.service..."
if ! systemctl stop reload-soc-module.service 2>/dev/null; then
    echo "Warning: Service was not running or could not be stopped."
fi

echo "Disabling reload-soc-module.service..."
if ! systemctl disable reload-soc-module.service 2>/dev/null; then
    echo "Warning: Service could not be disabled (may not exist)."
fi

echo "Removing service file..."
if ! rm -f /etc/systemd/system/reload-soc-module.service; then
    echo "ERROR: Could not remove /etc/systemd/system/reload-soc-module.service"
    exit 1
fi

echo "Removing /usr/local/sbin/reload-soc-module.sh..."
if ! rm -f /usr/local/sbin/reload-soc-module.sh; then
    echo "ERROR: Could not remove /usr/local/sbin/reload-soc-module.sh"
    exit 1
fi

echo "Reloading systemd..."
if ! systemctl daemon-reload; then
    echo "ERROR: systemctl daemon-reload failed."
    exit 1
fi

echo "Undo complete: soc reload workaround fully removed - REBOOT."

'
```
