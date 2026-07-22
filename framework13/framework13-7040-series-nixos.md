# Adding the NixOS-Hardware Module (Framework Laptop 13, AMD 7040 Series)

This provides the hardware channel steps for the NixOS on the Framework Laptop 13 Guide.

## Channel-based (default from graphical installer)

```bash
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --update
```

```nix
# /etc/nixos/configuration.nix
imports = [
  ./hardware-configuration.nix
  <nixos-hardware/framework/13-inch/7040-amd>
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
  nixos-hardware.nixosModules.framework-13-7040-amd
];
```

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```
