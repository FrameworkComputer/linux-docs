# Flatpaks, what are they?

By design, Flatpaks have limited access to your home folder and system in general. For most applications, this is perfectly fine, though in some cases this may limit the access you need—such as a webcam or microphone for Zoom, or a directory outside your home folder (for example, an external flash/thumb drive). You can extend this access using Flatseal, which itself can be installed via Flatpak.

## Setting up Flatseal

- Step 1

```
sudo apt install curl -y && \
curl -O https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/flatpaks/flatseal-installer.sh && \
bash flatseal-installer.sh
```

Mission Center Installer for Ubuntu 24.04

- Step 1

```
sudo apt install curl -y && \
curl -O https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/flatpaks/mission-center-installer.sh && \
bash mission-center-installer.sh
```

- Step 2

    Log out, then log back in or reboot.
