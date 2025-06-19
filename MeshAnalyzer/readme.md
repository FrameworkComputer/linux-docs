# 📡 WiFi Mesh Network Analyzer

> **Linux-first mesh network diagnostics with roaming analysis, power management detection, and visual reporting**

[![Python](https://img.shields.io/badge/Python-3.6+-blue.svg)](https://python.org)
[![NetworkManager](https://img.shields.io/badge/NetworkManager-Required-green.svg)]()
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-brightgreen.svg)]()

Real insight into how your mesh network actually behaves. See node connections, identify weak spots, track roaming performance, and diagnose power management issues - all without vendor lock-in or proprietary software.

## ⚠️ Framework Support Disclaimer

**Before implementing any power management changes recommended by this tool, please verify with Framework Support first.**

While the WiFi Mesh Network Analyzer provides valuable diagnostic information and generates safe configuration scripts, power management settings should only be modified when addressing specific connectivity issues. The tool may recommend disabling PCIe ASPM (Active State Power Management) or NetworkManager power saving features, but these changes should only be applied if:

- You are experiencing actual WiFi connectivity problems (disconnections, micro-dropouts, poor roaming)

- The analysis clearly identifies power management as the root cause

- Framework Support has reviewed your specific situation and confirmed the recommendation

### Why This Matters
Power management features exist for good reasons - they extend battery life and reduce heat generation. Disabling them unnecessarily can impact your system's efficiency without providing any benefits. The diagnostic tools help identify potential power management conflicts, but not every detection requires action.

### Recommended Workflow

- Run the analysis to identify potential issues: Run the script per the instructions.
  
- Document your specific symptoms (connection drops, poor performance, etc.)

- Contact Framework Support with both your symptoms and the tool's findings
- Apply recommended changes only after confirmation from Support
- Test thoroughly and revert changes if they don't resolve your specific issues

### Contact Framework Support

[Contact](https://framework.kustomer.help/contact/support-request-ryon9uAuq) - Ask to send your findings to the Linux Support Team

Remember: _These diagnostic tools are designed to help identify issues, not automatically fix them. Always verify recommendations with Framework Support before making system changes._

## 📚 Table of Contents

- [🚀 Key Features](#-key-features)
- [🎯 Why This Tool?](#-why-this-tool)
- [📋 Quick Start](#-quick-start)
- [🎛️ Main Features](#️-main-features)
- [📊 What You Get](#-what-you-get)
- [🔧 Advanced Usage](#-advanced-usage)
- [🛡️ Compatibility](#️-compatibility)
- [🔍 Troubleshooting](#-troubleshooting)
- [📱 Example Output](#-example-output)
- [💡 Pro Tips](#-pro-tips)
- [🔗 Related Tools](#-related-tools)

## 🚀 Key Features

### 🔍 **Mesh Intelligence**
- **Topology Mapping** - Visual mesh node detection and relationship analysis
- **Brand Recognition** - 500+ OUI database covering Eero, Orbi, Google Nest, Ubiquiti, enterprise systems
- **Coverage Analysis** - Spatial zone mapping with signal strength distribution
- **Overlap Detection** - Venn diagram analysis of node coverage areas

### 🔄 **Roaming Analysis**
- **Micro-dropout Detection** - Catch 50ms connection drops your system misses
- **Handoff Quality Testing** - Measure real roaming performance while walking around
- **Transition Monitoring** - Real-time tracking of problematic node switches
- **Pattern Recognition** - Identify roaming loops and sticky client issues

### 🔋 **Power Management**
- **WiFi Power Saving Detection** - Find power management causing disconnects
- **Driver-Specific Analysis** - Intel, MediaTek, Qualcomm, Atheros optimization
- **USB Autosuspend Checking** - Detect USB WiFi adapter suspension problems
- **Automated Fix Generation** - Create executable scripts to resolve power issues

### 📊 **Professional Reporting**
- **Interactive HTML Reports** - Modern dark theme with glassmorphism design
- **Real-time Visualizations** - Hover effects, click-to-copy BSSIDs, smooth animations
- **Mobile-Responsive** - Optimized for all devices with responsive layout
- **Historical Tracking** - Performance trends and stability scoring over time

## 🎯 Why This Tool?

### **Mesh Networks Are Opaque**
Commercial mesh systems hide diagnostics behind limited apps or cloud dashboards. When performance drops or devices won't roam correctly, you're left guessing. This tool surfaces that data directly from the network.

### **Common Problems It Solves**
- Devices sticking to weak access points instead of roaming
- Random disconnections and connection drops  
- Coverage dead zones or excessive overlap
- Power management issues causing false disconnects
- Micro-dropouts during streaming or gaming
- Poor handoff performance between nodes

### **Linux-First Approach**
No vendor lock-in, no cloud dependencies, no proprietary software. Uses standard Linux WiFi tools with intelligent analysis on top.

## 📋 Quick Start

### Prerequisites
```
# Ubuntu/Debian
sudo apt update && sudo apt install iw

# Fedora/RHEL  
sudo dnf install iw

# Arch Linux (NetworkManager required - not iwd compatible)
sudo pacman -S iw
```

### Installation
```
mkdir mesh_analyzer && cd mesh_analyzer
```

```
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_analyzer.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_html_reporter.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_venn_calculator.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_roaming_detector.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_power_detective.py
```

```
chmod +x *.py
```

### Basic Analysis
```
sudo python3 mesh_analyzer.py
```

### Complete Analysis (Recommended) (run both lines below to include an archive for support)
```
sudo python3 mesh_analyzer.py --check-power --detect-dropouts --roaming-test --html-report
```
then
```
sudo python3 mesh_analyzer.py --create-archive
```

## 🎛️ Main Features

| Feature | Command | Description |
|---------|---------|-------------|
| **Basic Analysis** | `sudo python3 mesh_analyzer.py` | Topology mapping and signal analysis |
| **HTML Report** | `--html-report` | Interactive visual report with charts |
| **Roaming Test** | `--roaming-test` | Walk-around handoff quality testing |
| **Micro-dropouts** | `--detect-dropouts` | 30-second connection stability test |
| **Power Check** | `--check-power` | WiFi power management issue detection |
| **Continuous Monitor** | `--monitor` | Real-time monitoring every 60 seconds |
| **Archive Creation** | `--create-archive` | Compressed analysis logs |

## 📊 What You Get

### **Terminal Output**
- Comprehensive mesh topology with node relationships
- Signal strength zone mapping (Primary/Secondary/Tertiary/Fringe)
- Historical performance tracking with stability scores
- Venn overlap analysis with quality scoring
- Roaming quality assessment and micro-dropout detection
- Power management issue identification with automated fixes
- Intelligent optimization recommendations

### **HTML Report**
- Professional dark theme with modern glassmorphism design
- Interactive mesh topology visualization with hover effects
- Advanced signal strength distribution charts
- Visual Venn overlap diagrams with SVG rendering
- Comprehensive coverage analysis with spatial zones
- Performance trends and historical data tracking
- Click-to-copy BSSID functionality
- Mobile-responsive design optimized for all devices

### **Example Analysis Results**
```
🏷️  Brand: Eero
🔧 Type: Tri-Band Mesh  
🏠 Topology: 4 nodes, 8 radios
📶 Mesh Quality: Good Topology (Score: 70/100)
🔄 Coverage Overlap: Excellent (Score: 100/100)
🔋 Power Issues: 1 found (PCIe ASPM)
📈 Current BSSID Stability: 100/100 (Excellent)
```

## 🔧 Advanced Usage

### **Roaming Analysis**
```
# Detect micro-dropouts (30 seconds) with visual report
sudo python3 mesh_analyzer.py --html-report --detect-dropouts
```
```
# Test roaming quality while walking with comprehensive reporting
sudo python3 mesh_analyzer.py --html-report --roaming-test
```
```
# Continuous roaming monitoring with real-time HTML updates
sudo python3 mesh_analyzer.py --html-report --monitor-roaming
```

### **Power Management**
```
# Check for power issues
sudo python3 mesh_analyzer.py --html-report --check-power
```

### **Monitoring & Logging**
```
# Continuous monitoring (60s intervals)
sudo python3 mesh_analyzer.py --monitor
```
```
# Custom scan interval (2 minutes)
sudo python3 mesh_analyzer.py --monitor --scan-interval 120
```
```
# Show storage information
sudo python3 mesh_analyzer.py --storage-info
```

### **Data Management**
```
# Reset corrupted history files
sudo python3 mesh_analyzer.py --reset-history
```
```
# Create archive without new analysis
sudo python3 mesh_analyzer.py --archive-only
```

## 🛡️ Compatibility

### **Supported Systems**
- **Linux Distributions**: Ubuntu, Debian, Fedora, Arch, openSUSE, Pop!_OS, Mint
- **Network Managers**: NetworkManager (iwd support not yet implemented)
- **WiFi Hardware**: Intel, MediaTek, Qualcomm, Broadcom, Atheros, Realtek
- **Mesh Systems**: Eero, Orbi, Google Nest, ASUS, TP-Link, Linksys, Ubiquiti, enterprise systems

### **Requirements**
- Python 3.6+ (standard on most Linux systems)
- NetworkManager (not compatible with iwd)
- Root/sudo access for WiFi scanning
- Active mesh network connection for best results

### **Zero Dependencies**
Uses only Python standard library - no pip installs required!

## 🔍 Troubleshooting

### **Common Issues**

**"No WiFi interface found"**
```
nmcli device status    # Check available interfaces
ip link show          # List all network interfaces
```

**"0 access points found"**
- Ensure you have sudo privileges for WiFi scanning
- Try moving closer to mesh nodes
- Some enterprise networks restrict scanning

**"Permission denied"**
- Must run with `sudo` for WiFi scanning capabilities
- Files are automatically created with correct user permissions

**Module import errors**
- Ensure all 5 Python files are in the same directory
- Check file permissions with `ls -la *.py`
- Optional modules will gracefully degrade if missing

### **Why Some Nodes Don't Appear**

Not all mesh nodes will always show up in scans. This is normal due to:

- **Band Steering** - Mesh systems hide certain bands or backhaul links
- **Scan Timing** - Nodes may broadcast intermittently or reduce beaconing when idle  
- **Power Management** - Nodes in power-saving modes reduce visibility
- **Driver Limitations** - Some WiFi chipsets don't report all frequencies reliably
- **DFS Channels** - Regulatory restrictions on 5GHz channels
- **Distance/Interference** - Remote nodes may be too weak to detect

**Solutions**: Run multiple scans, use roaming analysis features, or reposition your device.

## 📱 Example Output

### **Terminal Analysis**
```
🧠 WiFi Mesh Network Analyzer
============================================================
📡 Interface: wlp5s0
🔗 Connected: Slower | D8:8E:D4:7D:2E:C8 | 7015 MHz | -53 dBm

🏷️  Brand: Eero
🔧 Type: Tri-Band Mesh
🏠 Topology: 4 nodes, 8 radios
📶 Mesh Topology: 🟢 Good Topology (Quality Score: 70/100)

🗺️  SPATIAL COVERAGE ANALYSIS:
   🟢 Primary Zone: 2 nodes (-44 to -33dBm)
   🟠 Tertiary Zone: 1 nodes (-70 to -70dBm)  
   🔴 Fringe Zone: 1 nodes (-89 to -89dBm)

🔄 VENN OVERLAP ANALYSIS:
   🟢 Coverage Overlap Quality: Excellent (Score: 100/100)
   📊 Excellent mesh overlap - 6/6 node pairs overlapping

📈 Current BSSID Performance Analysis:
   🟢 Stability Score: 100.0/100 (Excellent)
   ✅ Success Rate: 100.0%

✅ No micro-dropouts detected in 30 seconds
🔋 Power Issues: 1 found - PCIe ASPM configuration
```

### **HTML Report Preview**
![Mesh Analysis Report](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/MeshAnalyzer/images/mesh_screenshot-new.png)

## 💡 Pro Tips

### **For Best Results**
- Connect to the mesh network you want to analyze before running
- Run multiple analyses over time for better historical data
- Use `--roaming-test` while walking around different areas
- Check `--detect-dropouts` if experiencing connection issues

### **Performance Optimization**
- Large mesh networks may take 15-30 seconds to scan completely
- Use `--monitor` for long-term network health tracking
- HTML reports work best in modern browsers with JavaScript enabled
- All analysis data is saved locally for privacy

### **Troubleshooting Workflow**
1. Start with basic analysis to identify topology
2. Use `--check-power` if experiencing frequent disconnects
3. Run `--detect-dropouts` to catch micro-interruptions
4. Use `--roaming-test` while moving between coverage areas
5. Generate `--html-report` for comprehensive visual analysis

### **Safety Notes**
- Always review generated power management fix scripts before execution
- Enterprise networks may block some WiFi scanning capabilities
- Tool respects Linux-first workflows and privacy (no cloud dependencies)

## 🔗 Related Tools

### **General WiFi Diagnostics**
- **[Enhanced WiFi Analyzer](https://github.com/FrameworkComputer/linux-docs/tree/main/Enhanced-WiFi-Analyzer#-enhanced-wifi-analyzer)** - Comprehensive WiFi diagnostics with DFS monitoring, VPN integration, and modern chipset support

### **When to Use Which Tool**
| Scenario | WiFi Mesh Analyzer | Enhanced WiFi Analyzer |
|----------|-------------------|------------------------|
| **Mesh network optimization** | ✅ Specialized analysis | ⚪ Basic detection |
| **Node topology mapping** | ✅ Visual mesh analysis | ⚪ Not covered |
| **Roaming performance** | ✅ Detailed testing | ⚪ Limited coverage |
| **General WiFi issues** | ⚪ Basic coverage | ✅ Comprehensive |
| **DFS disconnections** | ⚪ Not specialized | ✅ Expert analysis |
| **VPN conflicts** | ⚪ Not covered | ✅ Modern VPN support |
| **Chipset optimization** | ⚪ Limited | ✅ Advanced detection |

### **Complementary Workflow**
1. **WiFi issues first** - Use Enhanced WiFi Analyzer for connectivity problems, DFS issues, VPN conflicts
2. **Mesh optimization** - Use WiFi Mesh Analyzer for topology analysis and roaming performance
3. **Best coverage** - Both tools together provide complete WiFi environment understanding

---

**🔧 Production-ready software actively seeking feedback! Please test with different mesh systems, Linux distributions, and network environments.**
