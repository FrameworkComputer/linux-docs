
# IMPORTANT - Before trying this, please try these guides FIRST.
This guide is for 13th Gen Intel Core and AMD Ryzen 7040 Series

https://knowledgebase.frame.work/en_us/search?q=Fingerprint+troubleshooting

If you are willing to try this now and accept that this may not work and you may end up waiting for the LVFS update anyway, follow below step by step.


## Install fwupd (May already be installed)

Ubuntu LTS 

``
sudo apt update && sudo apt install fwupd -y
``

Fedora

``
sudo dnf install fwupd -y
``

## Check firmware with

``
sudo fwupdtool get-devices --plugins goodixmoc
``

## Download this cab to your home directory path.

Download from here: https://github.com/FrameworkComputer/linux-docs/raw/main/goodix-moc-609c-v01000330.cab

``
sudo fwupdtool install --allow-reinstall --allow-older goodix-moc-609c-v01000330.cab
``

There might be a transfer error at the end. Can be safely ignored.


## Check firmware again and should be 01000330

Reboot

## If the device is not detected, you'll have to add a quirk (when fwupd is older than 1.8.8):

Check the version with:

``
fwupdmgr --version
``

Top line of the output will show something like compile  org.freedesktop.fwupd  1.8.17
If it is indeed older than 1.8.8, follow the next steps.

**Edit:** We have had folks running the echo to quirks command multiple times, adding in extra lines of text. To address this, the updated code below will detect duplication and make the file correct, every time.


``
file="/usr/share/fwupd/quirks.d/goodixmoc.quirk"; sudo sed -i '/\[USB\\VID_27C6&PID_609C\]/d' "$file"; sudo sed -i '/Plugin = goodixmoc/d' "$file"; echo -e '[USB\VID_27C6&PID_609C]\nPlugin = goodixmoc' | sudo tee -a "$file" > /dev/null
``

Check to make sure the quirk was created correctly:

``
sudo cat /usr/share/fwupd/quirks.d/goodixmoc.quirk
``

**Should see both lines added.**


  [USB\VID_27C6&PID_609C]


  Plugin = goodixmoc



**Reboot**

## Now check again:

``
sudo fwupdtool get-history
``

## Should see New version:      01000330

### If it is not working, re-run the fwupdtool install command above again - make sure to reboot each time.
