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

Enable the following:

```nix
# Framework 12 tablet mode.
  boot.initrd.kernelModules = [ "pinctrl_tigerlake" ];
  hardware.sensor.iio.enable = true;

# On-screen keyboard (KDE Plasma).
  environment.systemPackages = with pkgs; [ kdePackages.plasma-keyboard ];
```

`plasma-keyboard` is the KDE Plasma on-screen keyboard, so this applies to Plasma sessions. With the physical keyboard and touchpad disabled in tablet mode, it gives you a way to type when the display is folded back. GNOME ships its own on-screen keyboard, so this package isn't needed there.



---
---




# Manual NixOS Configuration (Framework 12, Intel Core Series 3)

This provides the manual configuration steps for the [NixOS on the Framework Laptop 12 Guide](https://guides.frame.work/Guide/NixOS+on+the+Framework+Laptop+12/412?lang=en)

There is no nixos-hardware profile for the Framework 12 (Intel Core Series 3) at this time. Unlike the 13th Gen model, which has `<nixos-hardware/framework/12-inch/13th-gen-intel>`, there is no equivalent entry for this model yet, so the hardware is configured by hand as shown below.

## Update first

Update before applying the config below. With new hardware, always best to be as current as possible.

```bash
sudo nix-channel --update
sudo nixos-rebuild switch
```

## Channel-based (default from graphical installer)

```nix
# /etc/nixos/configuration.nix
imports = [
  ./hardware-configuration.nix
];
```

```bash
sudo nixos-rebuild switch
```


## Enabling the accelerometer and tablet mode
Tablet mode signals the desktop environment that the keyboard is folded back. libinput disables the keyboard and touchpad - firmware also does that. And GNOME/KDE enable screen rotation based on the accelerometer, see below.

Enable the following:

```nix
# Framework 12 (Dahlia) tablet mode + rotation
  boot.initrd.kernelModules = [ "pinctrl_intel_platform" ];

  boot.extraModprobeConfig = ''
    softdep soc_button_array pre: pinctrl_intel_platform
  '';

# Screen auto-rotation (accelerometer)
  hardware.sensor.iio.enable = true;

# On-screen keyboard (KDE Plasma) + sensor CLI tool
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-keyboard
    iio-sensor-proxy
  ];
```

`pinctrl_intel_platform` brings up the pin controller early, and the `softdep` loads it before `soc_button_array` so mode detection has its pins at boot. `plasma-keyboard` is the KDE Plasma on-screen keyboard, so this applies to Plasma sessions; GNOME ships its own. `iio-sensor-proxy` provides the sensor service and the `monitor-sensor` CLI for testing rotation.
