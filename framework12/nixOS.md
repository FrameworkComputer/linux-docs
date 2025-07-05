# Framework 12 nixOS tweaks

[nixos-hardware](https://github.com/NixOS/nixos-hardware/tree/master/framework/12-inch/13th-gen-intel) repository provides some tweaks for Framework 12. 

It can be enabled by adding the `nixos-hardware/framework/12-inch/13th-gen-intel` module to your nixOS modules.

## Enabling the accelerometer

The default configuration is suffering from the same issue as [ubuntu](https://github.com/FrameworkComputer/linux-docs/blob/main/framework12/Ubuntu-25-04-accel-ubuntu25.04.md)

This is the same fix applied on nixos until upstream is fixed:
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

## Gnome autorotate

To enable autorotation you need to install the `screen-rotate` gnome extension:

```nix
environment.systemPackages = [ pkgs.gnomeExtensions.screen-rotate ];
```

You can also in the Screen Rotate extension settings enable on-screen keyboard only in certain orientations.
