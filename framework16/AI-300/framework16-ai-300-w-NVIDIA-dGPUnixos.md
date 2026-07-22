# Adding NVIDIA dGPU Support (Framework Laptop 16, AMD Ryzen AI 300 Series)

If your Framework Laptop 16 has the NVIDIA dGPU expansion module, use the nixos-hardware NVIDIA submodule instead of setting driver options manually. It enables hybrid graphics with PRIME offload: the AMD iGPU runs by default for better battery life, and the NVIDIA dGPU is used on demand via the `nvidia-offload` command. This submodule already includes the base AMD Ryzen AI 300 Series module, so you only need to add this one, not both.

**Important:** the PCI bus IDs for your GPUs vary depending on installed expansion cards and NVMe drives. You must override them for your specific system.

```bash
nix-shell -p pciutils --run 'lspci | grep -E "VGA|3D|Display"'
```

## Channel-based (default from graphical installer)

```bash
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --update
```

```nix
# /etc/nixos/configuration.nix
imports = [
  ./hardware-configuration.nix
  <nixos-hardware/framework/16-inch/amd-ai-300-series/nvidia>
];

hardware.nvidia.prime = {
  # Replace these with your own system's bus IDs from the lspci command above
  amdgpuBusId = "PCI:XXX:YY:Z";
  nvidiaBusId = "PCI:AAA:BB:C";
};
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
  nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
];
```

```nix
# In your system configuration
hardware.nvidia.prime = {
  # Replace these with your own system's bus IDs from the lspci command above
  amdgpuBusId = "PCI:XXX:YY:Z";
  nvidiaBusId = "PCI:AAA:BB:C";
};
```

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```
