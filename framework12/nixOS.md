# Adding the NixOS-Hardware Module (Framework 12, 13th Gen Intel Core)

This provides the hardware channel steps for the [NixOS on the Framework Laptop 12 Guide](https://guides.frame.work/Guide/NixOS+on+the+Framework+Laptop+12/412?lang=en)

## Channel-based (default from graphical installer)

```bash
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --update
```

```nix
# /etc/nixos/configuration.nix
imports = [
  ./hardware-configuration.nix
  <nixos-hardware/framework/12-inch/13th-gen-intel>
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
  nixos-hardware.nixosModules.framework-12-13th-gen-intel
];
```

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```


## Enabling the accelerometer and tablet mode
Tablet mode signals the desktop environment that the keyboard is folded back. libinput disables the keyboard and touchpad - firmware also does that. And GNOME/KDE enable screen rotation based on the accelerometer, see below.

NixOS 26.05 as of kernel release 7.0.12 (early testing with 7.1 appears to be the same as well in local testing from unstable)


Enable the following:

```nix
# Framework 12 tablet mode.
  boot.initrd.kernelModules = [ "pinctrl_tigerlake" ];
  hardware.sensor.iio.enable = true;
```
