## Framework Enhanced Diagnostic Tool aka "combined.sh"

This intelligent diagnostic script collects and analyzes system logs from your Framework laptop, automatically detecting hardware issues and providing actionable recommendations in plain English. It's specifically designed for Framework laptops with model-aware analysis and Framework-specific troubleshooting guidance.

## Table of Contents

- [TL;DR - Quick Start](#tldr---quick-start)
- [Key Features](#key-features)
- [Which distros does this work on?](#which-distros-does-this-work-on)
- [How to use this tool?](#how-to-use-this-tool)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
- [Diagnostic Options](#diagnostic-options)
  - [1. Last X Minutes](#1-last-x-minutes-)
  - [2. Last 24 Hours](#2-last-24-hours-)
  - [3. Specific Time Range](#3-specific-time-range-)
  - [4. Filter Previously Created Log File](#4-filter-previously-created-log-file-)
- [Understanding the Results](#understanding-the-results)
  - [System Information](#-system-information)
  - [Intelligent Recommendations](#-intelligent-recommendations)
  - [Pattern Analysis](#-pattern-analysis)
  - [Framework-Specific Features](#-framework-specific-features)
- [Example Output](#example-output)
- [When to Contact Support](#when-to-contact-support)
- [Quick Commands](#quick-commands)
- [Framework Resources](#framework-resources)
- [Advanced Information](#advanced-information)

### TL;DR - Quick Start

**Download and run immediately:**
```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/combined.sh -o combined.sh && chmod +x combined.sh && bash combined.sh
```

Choose option 1 or 2, check the "INTELLIGENT RECOMMENDATIONS" section in the output for actionable solutions.

---

### Key Features

- **🔍 Intelligent Issue Detection**: Automatically identifies GPU hangs, thermal problems, WiFi issues, USB connection problems, and more
- **🖥️ Framework-Specific Analysis**: Detects your exact Framework model and provides model-specific recommendations
- **📋 Plain English Recommendations**: Translates technical errors into clear, actionable advice
- **🌡️ Real-Time Hardware Monitoring**: Shows current temperatures, power status, and connectivity
- **⚡ Smart Noise Filtering**: Focuses on actual problems, ignoring routine system operations
- **🔧 Comprehensive Hardware Detection**: Identifies your GPU, WiFi card, storage, RAM, and expansion cards

### Which distros does this work on?

**This tool works with all major Linux distributions and automatically installs required packages:**

- **Ubuntu/Debian/Linux Mint** (officially supported by Framework)
- **Fedora** (officially supported by Framework) 
- **Bazzite/Project Bluefin** (officially supported by Framework)
- **Arch Linux/Manjaro/EndeavourOS** (community supported)
- **openSUSE Tumbleweed/Leap** (community supported)
- **NixOS** (community supported)
- **Pop!_OS** (community supported)

### How to use this tool?

#### Prerequisites

Most systems already have curl installed. If needed:

**Fedora:**
```bash
sudo dnf install curl -y
```

**Ubuntu/Debian:**
```bash
sudo apt install curl -y
```

**Bazzite/Bluefin:** Already included, no installation needed.

#### Quick Start

**Download and run the diagnostic tool:**
```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/log-helper/combined.sh -o combined.sh && chmod +x combined.sh && bash combined.sh
```

**For future runs:**
```bash
./combined.sh
```

### Diagnostic Options

#### 1. Last X Minutes ⏰
**Best for recent issues**

- Select option `1`
- Enter the number of minutes (e.g., `30` for issues that happened 30 minutes ago)
- The tool will analyze logs from that timeframe and provide recommendations

![Last X Minutes](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/log-helper/images/1.png "Last X Minutes")

![Finshed scan](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/log-helper/images/2.png "Finshed scan")

**Example use cases:**
- Graphics crashed while gaming
- WiFi suddenly disconnected
- System became unresponsive
- Thermal throttling during heavy workload

#### 2. Last 24 Hours 📅
**Best for ongoing or intermittent issues**

- Select option `2`
- Analyzes the full day of system logs
- Identifies patterns like recurring WiFi drops or thermal cycling

**Example use cases:**
- Random system freezes throughout the day
- Intermittent USB connection issues
- Gradual performance degradation
- Battery or charging problems

#### 3. Specific Time Range 🎯
**Best when you know exactly when the issue occurred**

- Select option `3`
- Enter start time: `YYYY-MM-DD HH:MM` (24-hour format)
- Enter end time: `YYYY-MM-DD HH:MM`

**Example:**
- Start: `2025-01-15 14:30` (Jan 15, 2:30 PM)
- End: `2025-01-15 15:00` (Jan 15, 3:00 PM)

#### 4. Filter Previously Created Log File 🔍
**For advanced analysis of existing logs**

- Run after creating a log file with options 1-3
- Search for specific keywords or phrases
- Creates `filtered_log.txt` with matching entries

### Understanding the Results

The diagnostic tool creates `combined_log.txt` with several sections:

#### 🔧 System Information
- Framework model detection
- Hardware specifications (GPU, WiFi, RAM, storage)
- Current temperatures and power status
- Linux distribution compatibility status

#### ⚡ Intelligent Recommendations
**Color-coded by severity:**

- **🔴 IMMEDIATE**: Stop using immediately (dangerous temperatures, hardware faults)
- **🟠 URGENT**: Address soon (GPU crashes, memory issues, storage problems)
- **🟡 IMPORTANT**: Should fix (USB issues, WiFi problems, audio issues)
- **🔵 INFORMATIONAL**: Status updates (distro compatibility, normal thermal behavior)
- **🟢 PREVENTIVE**: Proactive suggestions (elevated temperatures, minor issues)

#### 📊 Pattern Analysis
- WiFi stability (tracks disconnection frequency)
- USB connection reliability
- GPU stability monitoring
- Thermal management effectiveness

#### 🎯 Framework-Specific Features

**Model-Aware Recommendations:**
- Framework Laptop 13: 60W charger verification
- Framework Laptop 16: 180W charger verification + GPU module checks
- Framework Desktop: Power supply diagnostics
- Expansion card troubleshooting

**Thermal Management:**
- Modern AMD (7040+ series): Higher temperature tolerance (95°C normal)
- Intel processors: Conservative thresholds (80°C watch point)
- Model-specific cooling guidance

**Hardware Detection:**
- MediaTek WiFi cards (MT7922/MT7925)
- Intel WiFi cards (iwlwifi)
- AMD GPUs (RDNA 2/3)
- Intel integrated graphics
- Framework expansion cards

### Example Output

![Details](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/log-helper/images/4.png "Details")


```
🖥️  Framework Laptop 16 - checking GPU module and enhanced thermal envelope
🌡️  Current CPU: 67°C via Tctl (Modern AMD: runs hot by design - watch at 90°C, throttles at 95°C, critical at 100°C, emergency at 105°C)
✅ No issues detected

🔵 INFORMATIONAL Status:
• [DISTRO_COMPATIBILITY] ✅ Your Linux distribution (fedora 42) is officially supported and tested by Framework for your Framework Laptop 16 → You should have the best experience and full hardware support
```

### When to Contact Support

![Intelligent recommendations](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/log-helper/images/3.png "Intelligent recommendations")

**Contact Framework Support if you see:**
- Multiple 🔴 IMMEDIATE or 🟠 URGENT recommendations
- Repeated GPU crashes or system freezes
- Hardware fault messages (Machine Check, MCE errors)
- Persistent thermal issues despite cleaning

**Include these files with your support ticket:**
- `combined_log.txt` (the full diagnostic report)
- Screenshots of any error messages
- Description of when the issue occurs

### Quick Commands

After running the diagnostic:

```bash
# View full report
cat combined_log.txt

# View only recommendations
grep -A 20 "INTELLIGENT RECOMMENDATIONS" combined_log.txt

# Monitor temperatures in real-time
watch -n 2 sensors

# Check current system status
sensors
```

### Framework Resources

**Support & Documentation:**
- **Support Center**: https://frame.work/support
- **Linux Guides**: https://frame.work/linux
- **Community Forum**: https://community.frame.work/
- **Knowledge Base**: https://knowledgebase.frame.work/categories/linux-S1IUEcFbkx
- **Linux Tools and Scripts**: https://knowledgebase.frame.work/linux-on-framework-tools-and-scripts-rymax1Jdyg
- **Framework Guides**: https://guides.frame.work/
-  **Enhanced WiFi Analyzer**: https://github.com/FrameworkComputer/linux-docs/tree/main/Enhanced-WiFi-Analyzer

### Advanced Information

- [Deep dive into how it works](https://github.com/FrameworkComputer/linux-docs/blob/main/log-helper/how-it-works.md#how-it-works)
- [Troubleshooting common issues](https://github.com/FrameworkComputer/linux-docs/blob/main/log-helper/how-it-works.md#troubleshooting)

**Note:** Each diagnostic run overwrites the previous `combined_log.txt` file. Save important reports before running again.
