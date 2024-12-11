# Tuned-PPD Customizer Script Usage Guide

### Important consideration
Out of the box, by default, Fedora 41 power settings are excellent. However, for those who want more control over their power performance, this script provides a helping hand while remaining with the existing GNOME power profile menu.

## What Does This Script Do?

This script helps you customize how your Fedora system manages power and performance through GNOME's power menu. It lets you change which power management profiles are used when you select "Power Saver" or "Performance" in the GNOME power menu.

## How It Works

1. **GNOME Power Menu**: The menu in your system tray that lets you choose between power modes.
2. **The Configuration File** (`/etc/tuned/ppd.conf`): Stores your power profile settings.
3. **tuned-ppd.service**: Fedora's service that applies these settings when you change power modes.

## What You Can Do With This Script

- Back up your current power settings.
- Download additional power management profiles.
- Change which profile is used for "Power Saver" mode.
- Change which profile is used for "Performance" mode.
- View your current configuration.
- Restore previous settings from backup.

![Launch screen](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/1.png)

## Using the Script

### Install Curl

Curl should already be installed, but just in case:

### Fedora
```
sudo dnf install curl -y
```
&nbsp;
&nbsp;
&nbsp;

## To Install  Tuned-PPD Customizer Script, simply run:
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/tuned-ppd.sh -o tuned-ppd.sh && clear && bash tuned-ppd.sh
```
&nbsp;
&nbsp;
&nbsp;

1. Run the script after later on, from your home directory:
   ```bash
   bash tuned-ppd.sh
   ```

2. Choose from the menu options to:
   - Back up your settings.
   - Apply a different profile.
   - View current settings.
   - Restore previous settings.

## Available Profiles

### Power Saving Profiles

1. **balanced-battery**
   - Balances performance and power consumption.
   - Uses CPU frequency scaling to reduce power usage while maintaining reasonable performance.

2. **cpu-partitioning-powersave**
   - Optimizes power consumption for multi-core systems.
   - Uses CPU frequency scaling and core parking.

3. **desktop-powersave**
   - Prioritizes power saving for desktop systems.
   - Reduces CPU frequency, dims display, powers down idle devices.

4. **laptop-ac-powersave**
   - Balances performance and power for AC-powered laptops.
   - Uses moderate power-saving techniques.

5. **laptop-battery-powersave**
   - Maximizes battery life.
   - Uses aggressive power-saving measures.

6. **powersave**
   - Prioritizes power saving above all else.
   - Uses maximum power-saving techniques.

7. **server-powersave**
   - Optimizes server power consumption.
   - Balances server performance with energy efficiency.

### Performance Profiles

1. **accelerator-performance**
   - Optimizes systems with hardware accelerators (GPUs/FPGAs).
   - Prioritizes accelerator resource allocation.

2. **enterprise-storage**
   - Optimizes enterprise storage system performance.
   - Tunes disk scheduling and I/O operations.

3. **latency-performance**
   - Minimizes system latency.
   - Optimizes for low response times.

4. **network-latency**
   - Reduces network latency.
   - Optimizes network settings for minimal delay.

5. **network-throughput**
   - Maximizes network throughput.
   - Optimizes for high data transfer rates.

6. **throughput-performance**
   - Maximizes system throughput.
   - Optimizes for high data processing rates.

## Recommendations

### For Laptops: Maximum Battery Life
Best profile: `laptop-battery-powersave`
- Optimized specifically for laptop battery operation.
- Aggressively reduces power consumption.
- Manages CPU frequency, screen brightness, and device power states.
- Best choice when you need to maximize battery life.

### For Gaming: Maximum Performance
Best profile: `latency-performance`
- Minimizes system latency.
- Keeps CPU at maximum frequency.
- Optimizes for quick system response.
- Ideal for games where every millisecond counts.

### For High Computational Tasks
Best profile: `accelerator-performance`
- Optimized for GPU and accelerator-heavy workloads, or just general high performance non-specific tasks.
- Ideal for video editing and machine learning tasks.
- Prioritizes accelerator and computational performance.
- Best choice when using CUDA, OpenCL, or similar GPU compute tasks.

## Troubleshooting

You are using tuned-ppd, not PPD or tuneD itself. Fedora 41 by default, is already using tuned-ppd.

If you see the error `Error: /etc/tuned/ppd.conf does not exist!`:

1. Verify the configuration file:
   ```bash
   cat /etc/tuned/ppd.conf
   ```
2. If missing, either:
   - Create the file manually
   - Reinstall the tuned package

3. [Contact support before making additional changes if issues persist](https://framework.kustomer.help/contact/support-request-ryon9uAuq)

## Important Notes and FAQ

- The script is designed for Fedora installations, should work on any distro with tuned-ppd running though with some minor tweaks.
- We get the additional profiles from https://github.com/redhat-performance/tuned/ 
- Changes take effect immediately after applying a new profile.
- Always keep a backup of your settings using this script.
- These recommendations are based on typical use cases; your specific needs may vary.
- The script clears the terminal screen between sections for better readability.
- Why are you using bsdtar vs something else? It's been shown to be more reliable for this script. For Fedora users, it self-installs.
- **For enhanced control**, consider using the [TunedSwitcher](https://flathub.org/apps/org.easycoding.TunedSwitcher) Flatpak (compatible with GNOME/KDE).
- Ubuntu support is planned for future releases.

## Screenshots

![Launch screen](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/1.png)

![Backup](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/2.png)

![Install additional profiles](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/3.png)

![Restore most recent backup](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/4.png)

![Select a profile](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/5.png)

![View powersave and performance configuration](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/6.png)

(Note: my theme just happens to be purple, your default GNOME menu will be used)
![GNOME power menu remains default](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Tuned-PPD-Customizer-Script/images/7.png)
