# 🧠 Enhanced WiFi Analyzer

> **Advanced WiFi diagnostics and troubleshooting for Linux with WiFi 7, DFS monitoring, and modern VPN support**

[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![WiFi 7](https://img.shields.io/badge/WiFi-7%20Ready-blue.svg)]()
[![DFS Monitor](https://img.shields.io/badge/DFS-Monitoring-red.svg)]()

A comprehensive WiFi analysis and troubleshooting tool that diagnoses connectivity issues, optimizes performance, and provides distribution-specific fixes for modern Linux systems. Features DFS radar interference detection, WiFi 7/6E support, and modern VPN integration.

## 📚 Table of Contents

- [🚀 Key Features](#-key-features)
- [🎯 Why Use This Tool?](#-why-use-this-tool)
- [📋 Quick Start](#-quick-start)
- [🎛️ Main Menu Options](#️-main-menu-options)
- [🔧 Common Use Cases](#-common-use-cases)
- [📊 Example Analysis Output](#-example-analysis-output)
- [🚀 Advanced Features](#-advanced-features)
- [💡 Pro Tips](#-pro-tips)
- [🔍 Troubleshooting Matrix](#-troubleshooting-matrix)
- [🛡️ Safety & Compatibility](#️-safety--compatibility)
- [📈 Future Development](#-future-development)
- [🔗 Related Tools](#-related-tools)
- [🤝 Contributing](#-contributing)

## 🚀 Key Features

### 🔬 **Advanced Diagnostics**
- **Complete WiFi Health Analysis** - Full system assessment with scoring
- **Modern Chipset Detection** - Supports WiFi 7, 6E, MLO, and new hardware
- **Real-time Connectivity Testing** - Tests actual data flow beyond basic connection status
- **Distribution-Aware Analysis** - Tailored for Fedora, Ubuntu, Arch (NetworkManager), Debian, openSUSE, and immutable systems

### 📡 **DFS Radar Interference Monitoring**
- **Radar Event Detection** - Identifies DFS channel issues causing sudden disconnections
- **Smart Channel Switching** - Automated migration to non-DFS safe channels
- **Environment Analysis** - Maps DFS usage patterns in your area
- **6GHz Migration Path** - Recommendations for DFS-free 6GHz operation

### 🔒 **Modern VPN Integration**
- **Advanced VPN Detection** - Supports Tailscale, ZeroTier, Nebula, WireGuard, commercial VPNs
- **VPN-WiFi Conflict Resolution** - Diagnoses and fixes VPN-related connectivity issues
- **Split Tunneling Optimization** - Configures optimal routing for modern mesh VPNs
- **MTU Optimization** - Automatic sizing for VPN tunnels

### 🌐 **WiFi 6E/7 Optimization**
- **6GHz Band Analysis** - Clean spectrum identification and optimization
- **320MHz Channel Width** - Ultra-wide channel support for maximum throughput
- **MLO (Multi-Link Operation)** - WiFi 7 multi-band aggregation support
- **Regulatory Domain Optimization** - Proper power limits and channel availability

### 🛠️ **Interactive Troubleshooting**
- **Guided Problem Solving** - Step-by-step fixes for common issues
- **Emergency Repair Mode** - Quick fixes for critical failures
- **Distribution-Specific Commands** - Tailored solutions for your Linux distribution
- **Thermal Management** - Overheating detection and fixes

### ⚡ **Performance Optimization**
- **Band Switching Automation** - Intelligent 2.4/5/6GHz selection
- **Signal Strength Analysis** - RF environment mapping and optimization
- **Power Management** - Battery life vs performance balancing
- **Channel Width Optimization** - Maximizes throughput while maintaining stability

## 🎯 Why Use This Tool?

### **Solves Real Problems**
- **DFS Disconnections**: Identifies and fixes mysterious 30+ second WiFi drops caused by radar interference
- **Modern VPN Issues**: Resolves connectivity problems with Tailscale, ZeroTier, and other mesh VPNs
- **WiFi 7 Optimization**: Optimizes cutting-edge WiFi hardware within driver/firmware limitations
- **Distribution Chaos**: Provides correct commands for your specific Linux distribution

### **Beyond Basic Tools**
- Most WiFi tools only check connection status - this analyzes actual data flow
- Detects issues that `nmcli` and GUI tools miss
- Provides root cause analysis, not just symptoms
- Includes proactive recommendations to prevent future issues

### **Expert Knowledge Built-In**
- Incorporates knowledge of MediaTek, Intel, and Qualcomm chipset quirks
- Understands regulatory domain impacts on performance
- Knows which channels are safe vs DFS across different regions
- Includes thermal management strategies for high-performance WiFi cards

## 📋 Quick Start

### Prerequisites
```bash
# Required tools (install via package manager)
sudo apt install iw wireless-tools curl  # Ubuntu/Debian
sudo dnf install iw wireless-tools curl  # Fedora
sudo pacman -S iw wireless_tools curl    # Arch (NetworkManager required - not iwd compatible)
```

### Installation
```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

If already downloaded, just run:
```bash
sudo bash wifi_diagnostic.sh
```

### Quick Analysis
Download and run (first time):
```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

If already downloaded:
```bash
sudo bash wifi_diagnostic.sh
```

Then choose your option:
- Option 1: Complete analysis (recommended first run)
- Option 4: DFS-specific monitoring for radar interference
- Option 9: Emergency fixes for immediate solutions

## 🎛️ Main Menu Options

| Option | Feature | Use Case |
|--------|---------|----------|
| **1** | 🎯 **Complete Analysis** | Full system health check with all modern features |
| **2** | 🚨 **Error Analysis** | Deep dive into logs and failure patterns |
| **3** | 🛠️ **Interactive Troubleshooting** | Guided problem-solving with custom solutions |
| **4** | 📡 **DFS Channel Monitor** | Dedicated radar interference analysis |
| **5** | 🧪 **TX Power Band Test** | Diagnose power limitations and optimize range |
| **6** | 📡 **Manual Band Switching** | Direct CLI commands for 2.4/5/6GHz control |

## 🔧 Common Use Cases

### **Scenario 1: Mysterious Disconnections**
Symptoms: WiFi drops for 30+ seconds randomly

```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

→ Choose Option 4 (DFS Monitor)
Tool identifies DFS radar interference and provides non-DFS channel solutions

### **Scenario 2: Slow WiFi 7 Performance**
Symptoms: New WiFi 7 card performing poorly

```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

→ Choose Option 1 (Complete Analysis)
Tool detects 6GHz capability and recommends router upgrade/configuration

### **Scenario 3: VPN Breaks WiFi**
Symptoms: WiFi unstable when Tailscale/ZeroTier active

```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

→ Choose Option 3 → Option 4 (VPN conflicts)
Tool provides MTU optimization and split tunneling configuration

### **Scenario 4: Overheating Laptop**
Symptoms: High temperatures, fan noise during WiFi use

```bash
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Enhanced-WiFi-Analyzer/wifi_diagnostic.sh -o wifi_diagnostic.sh && clear && sudo bash wifi_diagnostic.sh
```

→ Choose Option 3 → Option 5 (thermal issues)
Tool provides ASPM fixes and power management optimization

## 📊 Example Analysis Output

```
🧠 === ENHANCED SYSTEM INTELLIGENCE GATHERING ===
🐧 Distribution: Fedora Linux 39
🔍 WiFi Interface: wlp1s0
🔧 WiFi Functional Status: ✅ WORKING
🔧 Hardware: MediaTek Inc. MT7925 WiFi 7 (802.11be)
📊 Chip Analysis:
   Vendor: MediaTek
   Model: MT7925
   Generation: WiFi 7 (802.11be) - 160MHz capable
   Known Issues: Excellent Linux support in kernel 6.8+

📡 === DFS CHANNEL ANALYSIS ===
📍 Regulatory Domain: US
🔍 Current Connection DFS Analysis:
   ⚠️ Currently connected to DFS channel: 100 (5500 MHz)
   🎯 DFS Impact: Medium to High risk of disconnections
🚨 Found 3 DFS/radar events in last 24 hours

🎯 === FINAL ANALYSIS SUMMARY ===
📊 Overall WiFi Health: Fair (DFS risk) (50/100)
🔧 WiFi Status: ✅ Working
📡 DFS Status: ⚠️ Connected to DFS channel (radar risk)
🌟 WiFi 7 Features: Standard WiFi 7

⚠️ DFS RECOMMENDATION: Switch to non-DFS channel for stability
💡 Suggested channels: 36, 40, 44, 48 (low 5GHz) or 149+ (high 5GHz)
```

## 🚀 Advanced Features

### **Advanced Features**
- **Automatic Radar Detection**: Monitors system logs for DFS events
- **Environmental Mapping**: Scans for DFS channel usage in your area  
- **Smart Channel Recommendations**: Suggests optimal non-DFS alternatives
- **6GHz Migration Planning**: Path to DFS-free operation

### **Modern VPN Support**
- **Mesh VPN Optimization**: Tailscale, ZeroTier, Nebula configuration
- **Commercial VPN Fixes**: NordVPN, ExpressVPN, Surfshark compatibility
- **Split Tunneling**: Optimizes traffic routing for better performance
- **DNS Conflict Resolution**: Fixes modern VPN DNS issues

### **WiFi 7 Optimization**
- **6GHz Band Access**: Identifies clean spectrum opportunities
- **320MHz Channels**: Ultra-wide channel detection and recommendations
- **MLO Support**: Multi-Link Operation analysis for maximum throughput
- **Advanced Power Management**: Thermal optimization for high-performance cards

### **Distribution Intelligence**
- **Immutable Systems**: Special handling for Silverblue, Kinoite, Bluefin
- **Package Manager Detection**: Uses correct commands for dnf, apt, pacman, zypper
- **Firmware Management**: Distribution-specific update procedures
- **Kernel Parameter Handling**: Proper GRUB vs rpm-ostree vs bootc configuration

## 💡 Pro Tips

### **For System Administrators**
- Use Option 1 for baseline health assessment of fleet WiFi systems
- Option 4 provides regulatory compliance checking for enterprise environments
- Log outputs to files for trend analysis: `./wifi_diagnostic.sh | tee wifi_analysis.log`

### **For Developers/Power Users**
- Option 6 provides direct CLI commands for automation and scripting
- All temporary fixes can be converted to permanent configurations
- Regulatory domain optimization maximizes performance within legal limits

### **For Gamers/Streamers**
- DFS monitoring eliminates lagspikes from radar interference
- 6GHz optimization provides lowest latency connections
- Thermal management prevents throttling during extended use

## 🔍 Troubleshooting Matrix

| Symptom | Likely Cause | Tool Solution |
|---------|--------------|---------------|
| **Random 30s+ disconnections** | DFS radar interference | Option 4 → Non-DFS channels |
| **WiFi fails after suspend** | Driver power management | Option 3 → Suspend/resume fixes |
| **Slow WiFi 7 speeds** | Wrong band/channel width | Option 1 → 6GHz optimization |
| **VPN breaks WiFi** | MTU/routing conflicts | Option 3 → VPN optimization |
| **Overheating during WiFi** | ASPM/power management | Option 3 → Thermal fixes |
| **Connection fails entirely** | Driver/firmware issues | Option 2 → Distribution fixes |

## 🛡️ Safety & Compatibility

### **Safe Operation**
- All temporary changes revert on reboot
- Permanent changes clearly marked and reversible
- No destructive operations without explicit user confirmation
- Comprehensive logging for audit trails

### **Broad Compatibility**
- **Distributions**: Fedora, Ubuntu, Debian, Arch (NetworkManager only), openSUSE, Pop!_OS, Mint, immutable variants
- **Hardware**: Intel, MediaTek, Qualcomm, Broadcom WiFi chipsets
- **Standards**: WiFi 4/5/6/6E/7, 2.4/5/6GHz bands
- **VPNs**: WireGuard, OpenVPN, modern mesh protocols
- **Network Managers**: NetworkManager (iwd support not yet implemented)

## 📈 Future Development

- [ ] iwd network manager support (currently NetworkManager only)
- [ ] Integration with WiFi 8 (802.11bn) when available
- [ ] Bluetooth coexistence analysis
- [ ] Automated performance benchmarking
- [ ] Web interface for remote diagnostics
- [ ] Integration with network monitoring systems

## 🔗 Related Tools

### **Specialized WiFi Analysis**
- **[Framework WiFi Mesh Network Analyzer](https://github.com/FrameworkComputer/linux-docs/tree/main/MeshAnalyzer#wifi-mesh-network-analyzer)** - Framework's dedicated tool for mesh network performance analysis and optimization

### **When to Use Which Tool**
| Scenario | Enhanced WiFi Analyzer | Framework Mesh Analyzer |
|----------|----------------------|------------------------|
| **General WiFi issues** | ✅ Primary tool | ⚪ Not needed |
| **DFS disconnections** | ✅ Specialized detection | ⚪ Limited coverage |
| **VPN conflicts** | ✅ Modern VPN support | ⚪ Not covered |
| **Framework + Mesh** | ✅ General analysis | ✅ Mesh optimization |
| **Thermal/power issues** | ✅ Comprehensive | ⚪ Not covered |
| **Mesh performance tuning** | ⚪ Basic detection | ✅ Specialized analysis |

### **Complementary Workflow**
1. **Start here** - Run Enhanced WiFi Analyzer for comprehensive system health
2. **Framework + Mesh users** - Follow up with Framework's Mesh Analyzer for specialized optimization
3. **Best results** - Use both tools for complete coverage of modern WiFi challenges

## 🔗 Related Tools

### **Specialized WiFi Analysis**
- **[Framework WiFi Mesh Network Analyzer](https://github.com/FrameworkComputer/linux-docs/tree/main/MeshAnalyzer#wifi-mesh-network-analyzer)** - Framework's dedicated tool for mesh network performance analysis and optimization

### **When to Use Which Tool**
| Scenario | Enhanced WiFi Analyzer | Framework Mesh Analyzer |
|----------|----------------------|------------------------|
| **General WiFi issues** | ✅ Primary tool | ⚪ Not needed |
| **DFS disconnections** | ✅ Specialized detection | ⚪ Limited coverage |
| **VPN conflicts** | ✅ Modern VPN support | ⚪ Not covered |
| **Framework + Mesh** | ✅ General analysis | ✅ Mesh optimization |
| **Thermal/power issues** | ✅ Comprehensive | ⚪ Not covered |
| **Mesh performance tuning** | ⚪ Basic detection | ✅ Specialized analysis |

### **Complementary Workflow**
1. **Start here** - Run Enhanced WiFi Analyzer for comprehensive system health
2. **Framework + Mesh users** - Follow up with Framework's Mesh Analyzer for specialized optimization
3. **Best results** - Use both tools for complete coverage of modern WiFi challenges

## 🤝 Contributing

Contributions welcome! Areas of particular interest:
- Additional chipset quirks and optimizations
- Distribution-specific command improvements  
- VPN protocol support expansion
- Regional regulatory domain data
- Performance optimization techniques

---
