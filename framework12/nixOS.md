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

iio-sensor-proxy reads the accelerometer data from the kernel and passes it to the desktop environment via dbus.

Version 3.7 has a bug, making it incompatible with Framework 12.
NixOS 25.05 and NixOS 25.11 (unstable) are patched:

- https://github.com/NixOS/nixpkgs/pull/427476
- https://github.com/NixOS/nixpkgs/pull/427853


If you haven't got the patched version yet, you can apply the following workaround:

```nix
nixpkgs.overlays = [
  (final: prev: {
    iio-sensor-proxy = prev.iio-sensor-proxy.overrideAttrs (oldAttrs: {
      postPatch = oldAttrs.postPatch + ''
      sed -i -e 's/.*iio-buffer-accel/#&/' data/80-iio-sensor-proxy.rules
      '';
    });
  })
];
```
