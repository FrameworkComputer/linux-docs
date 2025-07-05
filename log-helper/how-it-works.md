## How it works

**[BACK TO MAIN PAGE](https://github.com/FrameworkComputer/linux-docs/tree/main/log-helper#framework-log-helper-aka-combinedsh)**

### Main Features:
- **Intelligent System Analysis**: Automatically detects Framework laptop models and applies model-specific diagnostics
- **Advanced Log Processing**: Gathers logs from dmesg (kernel messages) and journalctl (system logs) with intelligent noise filtering
- **Real-time Hardware Monitoring**: Checks current temperatures, network connectivity, power status, and battery health
- **Plain English Recommendations**: Translates technical errors into understandable explanations with actionable solutions
- **Framework-Specific Features**: Validates Linux distribution compatibility, applies appropriate thermal thresholds, and provides model-specific recommendations
- **Pattern Analysis**: Tracks recurring issues like WiFi drops, USB reconnections, and thermal cycling
- **Context-Aware Error Detection**: Identifies error sequences and hardware failure patterns rather than isolated events

### How it's used:
1. **Choose from four options:**
   - Collect logs from the last X minutes
   - Collect logs from the last 24 hours
   - Collect logs for a specific time range
   - Filter a previously created log file

2. **For new log collection (options 1-3):**
   - **System Detection**: Automatically identifies your Framework model (Laptop 12/13/16, Desktop) and applies appropriate diagnostics
   - **Hardware Analysis**: Gathers detailed system information including CPU, GPU, WiFi card, RAM, and storage details
   - **Real-time Status Checks**: Tests internet connectivity, checks current temperatures with model-specific thresholds, monitors power/battery status
   - **Distribution Compatibility**: Validates if your Linux distribution is officially supported by Framework for your specific model
   - **Intelligent Log Processing**: Collects and analyzes logs while filtering out harmless system noise (GNOME UI messages, normal systemd operations)
   - **Smart Error Analysis**: Identifies actual problems vs routine system operations, translates technical errors into plain English
   - **Pattern Recognition**: Tracks device state changes, USB connections, thermal events, and recurring issues
   - **Actionable Recommendations**: Generates severity-based recommendations (🔴 Immediate, 🟠 Urgent, 🟡 Important, 🔵 Informational, 🟢 Preventive)

3. **For filtering an existing log file (option 4):**
   - Looks for "combined_log.txt" in the current directory
   - Allows searching for specific keywords or phrases within the log
   - Saves filtered results to "filtered_log.txt"

4. **Progress Indicators**: Displays visual progress bars with context-aware status messages during analysis

5. **Comprehensive Output Structure:**
   - **System Information**: Hardware detection, Framework model identification, real-time status
   - **Intelligent Recommendations**: Prioritized by severity with plain English explanations
   - **Critical Error Summary**: Filtered list of actual problems requiring attention
   - **Complete Log Analysis**: Full dmesg and journalctl output with noise filtering

### Key Benefits:
- **Framework-Optimized**: Specifically designed for Framework laptops with model-specific knowledge
- **User-Friendly**: Plain English explanations instead of technical jargon
- **Intelligent Filtering**: Distinguishes between actual problems and normal system operations
- **Real-time Analysis**: Shows current system status, not just historical logs
- **Actionable Intelligence**: Provides specific solutions and recommendations
- **Pattern Detection**: Identifies recurring issues and provides targeted fixes
- **Distribution Awareness**: Validates Linux compatibility and suggests supported distributions

### Framework-Specific Intelligence:

#### **Thermal Management**
- **AMD Ryzen AI 300 Series**: Recognizes these run hotter by design (95°C is normal)
- **AMD 7040 Series**: Appropriate thresholds for Framework Laptop 16
- **Intel Processors**: Conservative thermal limits for Intel-based Framework laptops
- **Real-time Monitoring**: Current CPU/GPU temperatures with model-appropriate warnings

#### **Power System Analysis**
- **Charger Verification**: Recommends correct wattage (60W for Laptop 13, 180W for Laptop 16)
- **USB-C Power Delivery**: Monitors PD negotiation issues
- **Battery Health**: Comprehensive battery condition assessment

#### **Distribution Compatibility**
- **Official Support**: Validates against Framework's supported distributions
- **Version-Specific**: Ensures correct versions (Fedora 42, Ubuntu 24.04+, etc.)
- **Community Support**: Recognizes community-supported distributions

### Output Sections:

```
===== System Information =====
Hardware detection, Framework model identification, distribution compatibility

===== INTELLIGENT RECOMMENDATIONS =====
🔴 IMMEDIATE Actions Required:
🟠 URGENT Actions Required:
🟡 IMPORTANT Actions Required:
🔵 INFORMATIONAL Status:
🟢 PREVENTIVE Actions Required:

===== dmesg output starts =====
Kernel messages with intelligent filtering

===== journalctl output starts =====
System service logs with noise reduction

===== Critical Error Summary =====
Actual system errors requiring attention

===== All Error/Warning Messages (excluding noise) =====
Comprehensive issue analysis

===== DIAGNOSTIC COMPLETION SUMMARY =====
Scan statistics and completion details
```

### Plain English Error Translation Examples:
- `amdgpu ring timeout` → "Your computer's graphics stopped working and might have crashed"
- `thermal critical temperature` → "Your computer got dangerously hot and will shut down to protect itself"
- `USB device not accepting address` → "A USB device couldn't connect properly"
- `nvme I/O timeout` → "Your main storage drive is having trouble responding"

--------------------------------------

## Troubleshooting

**If you find the script is not working right or taking over 10 minutes**, you can run this to trim down your journal to make it easier to manage:

```bash
sudo journalctl --vacuum-time=30d --vacuum-size=500M
```
(Then reboot and run the script again)

**Your log file keeps getting overwritten:**
> This is by design. If you wish to keep previous logs, copy your combined_log.txt file to another location before running the script again.

**Missing required tools on NixOS:**
> The script will show you which packages to add to your configuration.nix file and rebuild your system.

**Script shows "Package installation failed":**
> Ensure you have internet connectivity and proper sudo permissions. The script automatically installs required diagnostic tools.

**No temperature readings shown:**
> Run `sudo sensors-detect` and answer 'yes' to all questions, then reboot and try again.

**[BACK TO MAIN PAGE](https://github.com/FrameworkComputer/linux-docs/tree/main/log-helper#framework-log-helper-aka-combinedsh)**
