# Flatpaks, what are they?

By design of Flatpaks they have limited access to your home folder and system in general. For most applications this is perfectly fine though in some cases this may limit access that you need such as a webcam or microphone for Zoom or a directory outside of your home folder as an external drive such as a flash/thumb drive. This access can be extented with Flatseal which can be installed though Flatpak itself

## Setting up Flatseal

- Step 1

```bash
sudo apt install curl -y && curl -O https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/flatpaks/flatseal-installer.sh && bash flatseal-installer.sh
```

![Flatseal main page](https://raw.githubusercontent.com/ahoneybun/linux-docs/blob/flatseal-steps/flatpaks/images/flatseal.png)

## Mission Center Installer for Ubuntu 24.04

- Step 1

```bash
sudo apt install curl -y && curl -O https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/flatpaks/mission-center-installer.sh && bash mission-center-installer.sh
```

- Step 2

  Log out, log back in or reboot

  ![image](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/flatpaks/images/mission.png)
