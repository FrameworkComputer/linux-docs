# Firmware Update Manager (fwupd/LVFS)

fwupd currently maintains two branches: 1.9.X and 2.0.X.
The former is the LTS branch that gets most bugs backported.
The latter the development branch where fixes and new features land first.

## Versions in Distributions

- Fedora
  - [![Fedora 42 package](https://repology.org/badge/version-for-repo/fedora_42/fwupd.svg)](https://repology.org/project/fwupd/versions)
  - [![Fedora Rawhide package](https://repology.org/badge/version-for-repo/fedora_rawhide/fwupd.svg)](https://repology.org/project/fwupd/versions)
- NixOS
  - [![nixpkgs stable 25.05 package](https://repology.org/badge/version-for-repo/nix_stable_25_05/fwupd.svg)](https://repology.org/project/fwupd/versions)
  - [![nixpkgs unstable package](https://repology.org/badge/version-for-repo/nix_unstable/fwupd.svg)](https://repology.org/project/fwupd/versions)
- Ubuntu
  - [![Ubuntu 24.04 package](https://repology.org/badge/version-for-repo/ubuntu_24_04/fwupd.svg)](https://repology.org/project/fwupd/versions)
  - [![Ubuntu 25.04 package](https://repology.org/badge/version-for-repo/ubuntu_25_04/fwupd.svg)](https://repology.org/project/fwupd/versions)
  - [![Ubuntu 25.10 package](https://repology.org/badge/version-for-repo/ubuntu_25_10/fwupd.svg)](https://repology.org/project/fwupd/versions)
- [![Arch Linux package](https://repology.org/badge/version-for-repo/arch/fwupd.svg)](https://repology.org/project/fwupd/versions)

## Framework 16 Keyboard Firmware Update

Added in version 2.0.14 by pull request [#9094](https://github.com/fwupd/fwupd/pull/9094).

Below are the links to view the latest available firmware versions:

- [Laptop 16 Keyboard - ANSI](https://fwupd.org/lvfs/devices/work.frame.Laptop16.Inputmodules.ANSI)
- [Laptop 16 Keyboard - ISO](https://fwupd.org/lvfs/devices/work.frame.Laptop16.Inputmodules.ISO)
- [Laptop 16 RGB Macropad](https://fwupd.org/lvfs/devices/work.frame.Laptop16.Inputmodules.Macropad)
- [Laptop 16 Numpad](https://fwupd.org/lvfs/devices/work.frame.Laptop16.Inputmodules.Numpad)

## Framework 12 Touchscreen Controller

Added in version 2.0.14 by pull request [#9163](https://github.com/fwupd/fwupd/pull/9163).

Currently there is no firmware update available - systems ship with the latest version from the factory.

## Framework 12/13/16 Webcam Firmware

Framework 13 and Framework 16 share the same camera module. The 2nd gen is updateable through fwupd.
Framework 12 camera module is also updateable through fwupd.

Support for DFU update has been available in fwupd for a long time.

Currently there is no firmware update available - systems ship with the latest version from the factory.
