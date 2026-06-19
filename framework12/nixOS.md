# Framework 12 nixOS tweaks

[nixos-hardware](https://github.com/NixOS/nixos-hardware/tree/master/framework/12-inch/13th-gen-intel) repository provides some tweaks for Framework 12. 

It can be enabled by adding the `<nixos-hardware/framework/12-inch/13th-gen-intel>` module to your NixOS modules.

## Enabling tablet mode

Tablet mode signals the desktop environment that the keyboard is folded back.
libinput disables the keyboard and touchpad - firmware also does that.
And GNOME/KDE enable screen rotation based on the accelerometer, see below.

This depends on two modules `pinctrl_tigerlake` and `soc_button_array`.
NixOS does not build `pinctrl_tigerlake` into the kernel, so we have to make
sure it's loaded first by loading it from the initrd.

You can either use the nixos-hardware configuration mentioned above, or
configure it manually:

```
boot.initrd.kernelModules = [ "pinctrl_tigerlake" ];
```

## Enabling the accelerometer

NixOS 26.05 as of kernel release 7.0.12 (early testing with 7.1 appears to be the same as well in local testing from unstable)


Enable the following:

```nix
# Framework 12 tablet mode.
  boot.initrd.kernelModules = [ "pinctrl_tigerlake" ];
  hardware.sensor.iio.enable = true;
```
