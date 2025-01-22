# Disable Accidental Wakeup Script

**Which laptop does this work with:** Framework Laptop 16.

**The problem:** In some instances, Framework Laptop 16 can accidentally come out of its suspend state. This usually occurs when traveling, walking, taking a bus, placing the laptop into a backpack.
Overall the agreed upon cause is that this happens due to keyboard presses while it's in a state of suspend, thus waking it up.

**The workaround:** While our engineering team has it [on their roadmap](https://community.frame.work/t/responded-waking-from-suspend-w-lid-closed/47497/73?u=matt_hartley) to fix this on the BIOS level, but I wanted to make sure there was a solid, reliable workaround available right now.

**What this script does:** This script creates and enables a systemd service that prevents specific devices from waking the laptop from suspend. It disables wakeup functionality for **keyboard presses, touchpad presses, and lid lift events** by modifying the wakeup settings for USB devices and other relevant system devices. However, it ensures the system can still be brought out of suspend with a power button push. 
The script configures the service to run at boot, ensuring these settings are applied consistently, and reloads the systemd daemon to recognize the new service.

**Does this break functionality:** No, this script does not break functionality as long as it is implemented using this script on Ubuntu LTS or Fedora. 
The script ensures that specific wakeup events, such as keyboard presses, touchpad presses, and lid lifts, are disabled, but it leaves the power button functional for resuming the system from suspend.

- Suspend Behavior: The laptop can still enter suspend mode when the lid is closed.
- Resume Behavior: The laptop can be brought out of suspend using the power button.
- Disabled Wakeup Events: Keyboard and touchpad presses, as well as lifting the lid, will no longer wake the system, ensuring the system only resumes through intentional user interaction (e.g., the power button).

**Restoring back to defaults:** Obviously this is not going to be a match for everyone, user habits may change. Therefore wwe also offer a script to restore your suspend configuration back to installation defaults.
This script is provided here as well.

**Will this work on other distros:** Likely yes, I see no reason why it would not assuming paths and so forth match what we are doing here. But it is completely untested.


## Download and activate the Disable Accidental Wakeup Script

Fedora, make sure curl is installed:

```
sudo dnf install curl -y
```

Ubuntu, make sure curl is installed:

```
sudo apt update && sudo apt install curl -y
```

Simply paste in this command into your kernel, press the enter:
(No reboot is needed, it's ready to go after running this script)

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/disable-accidental-wakeup/wakeup.sh -o wakeup.sh && clear && sudo bash wakeup.sh
```

![Download the script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/disable-accidental-wakeup/images/install.png)




## Stop, disable and remove the activate the Disable Accidental Wakeup Script
(Including the removal of disable-wakeup.service) 
(No reboot is needed, it's ready to go after running this script)

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/disable-accidental-wakeup/restore_defaults.sh -o restore_defaults.sh && clear && sudo bash restore_defaults.sh
```

![Removal script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/disable-accidental-wakeup/images/remove.png)


