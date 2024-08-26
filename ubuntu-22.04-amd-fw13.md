# This is for AMD Ryzen 7040 Series configuration on the Framework Laptop 13 ONLY.



## If you are experiencing graphical artifacts from appearing

- Please follow the steps outlined in this guide:
  https://knowledgebase.frame.work/allocate-additional-ram-to-igpu-framework-laptop-13-amd-ryzen-7040-series-BkpPUPQa

&nbsp;
&nbsp;
&nbsp;

## Suspend with lid while attached to power workaround
There is an active bug that occurs for some users, creating a bogus key press when you suspend. This provides a solid workaround.

```
sudo sh -c '[ ! -f /etc/udev/rules.d/20-suspend-fixes.rules ] && echo "ACTION==\"add\", SUBSYSTEM==\"serio\", DRIVERS==\"atkbd\", ATTR{power/wakeup}=\"disabled\"" > /etc/udev/rules.d/20-suspend-fixes.rules'
```
This checks for an existing /etc/udev/rules.d/20-suspend-fixes.rules file, if none is found, creates it and appends ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="atkbd", ATTR{power/wakeup}="disabled" to the file.

---------


&nbsp;
&nbsp;
&nbsp;


### Buzzing sound from headphone jack

- Browse to the horizontal line in the upper left corner, click to open it.
- Type out the word terminal, click to open it.
- Copy/paste in the following code below.
- Press the enter key, user password, enter key.

```
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
```
> **TIP:** You can use the little clipboard icon to the right of the code to copy to your clipboard.


Then:

**Reboot**

&nbsp;
&nbsp;
&nbsp;
