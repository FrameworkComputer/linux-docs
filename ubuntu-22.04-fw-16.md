# This is for the Framework Laptop 16 (AMD Ryzen™ 7040 Series) ONLY.


## If you are experiencing graphical artifacts from appearing

- Please follow the steps outlined in this guide:
  https://knowledgebase.frame.work/allocate-additional-ram-to-igpu-framework-laptop-13-amd-ryzen-7040-series-BkpPUPQa

&nbsp;
&nbsp;
&nbsp;

----------------------------------------------

### Suspend keeps waking up or fails to suspend

```
sudo nano /etc/default/grub
```

`Change GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"`
into
`GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rtc_cmos.use_acpi_alarm=1"`

Then

```
sudo update-grub
```

Then

Reboot
