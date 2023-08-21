## Install fwupd

``
sudo apt update && sudo apt install fwupd -y
``

## Check firmware with

``
sudo fwupdtool get-devices --plugins goodixmoc
``

## Install with

There might be a transfer error at the end. Can be safely ignored.

## Download this cab to your home directory path.

Download from here: https://github.com/FrameworkComputer/linux-docs/raw/main/goodix-moc-609c-v01000330.cab

``
sudo fwupdtool install --allow-reinstall --allow-older goodix-moc-609c-v01000330.cab
``

## Check firmware again and should be 01000330

Reboot

## If the device is not detected, you'll have to add a quirk (when fwupd is older than 1.8.8):

Check the version with:

``
fwupdmgr --version
``

Top line of the output will show something like compile  org.freedesktop.fwupd  1.8.17
If it is indeed, older than is older than 1.8.8, follow the next steps.


``
echo '[USB\VID_27C6&PID_609C]' | sudo tee -a /usr/share/fwupd/quirks.d/goodixmoc.quirk ; echo 'Plugin = goodixmoc' | sudo tee -a /usr/share/fwupd/quirks.d/goodixmoc.quirk
``

Check to make sure the quirk was created correctly:

``
sudo cat /usr/share/fwupd/quirks.d/goodixmoc.quirk
``

Should see both lines added.


Reboot

## Now check again:

``
sudo fwupdtool get-history
``

## Should see New version:      01000330
