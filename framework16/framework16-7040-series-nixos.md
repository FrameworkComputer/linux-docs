# Adding the NixOS-Hardware Module (Framework Laptop 16, AMD Ryzen 7040 Series)

This provides the hardware channel steps for the NixOS on the Framework Laptop 16 Guide.

It is recommended to use `power-profiles-daemon` over `tlp` for the AMD Framework 16.

## What this module does

- Imports the common AMD and Raphael iGPU hardware configuration
- Enables `services.fwupd.enable`, so firmware updates are handled automatically
- Enables `services.fprintd.enable`, for fingerprint reader support
- Enables `hardware.keyboard.qmk.enable` and adds a libinput quirks override, for the Framework 16 keyboard module
- Enables `hardware.sensor.iio.enable`, needed for desktop environments to detect and manage display brightness
- Adds a udev rule fixing USB autosuspend on the Ethernet expansion card

## Channel-based (default from graphical installer)

```bash
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --update
```

```nix
# /etc/nixos/configuration.nix
imports = [
  ./hardware-configuration.nix
  <nixos-hardware/framework/16-inch/7040-amd>
];
```

```bash
sudo nixos-rebuild switch
```

## Flake-Based

```nix
# flake.nix inputs
inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
```

```nix
# flake.nix modules list
modules = [
  ./configuration.nix
  nixos-hardware.nixosModules.framework-16-7040-amd
];
```

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```
