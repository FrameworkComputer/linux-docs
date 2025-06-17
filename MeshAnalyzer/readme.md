# WiFi Mesh Network Analyzer

### Why does the WiFi Mesh Network Analyzer exist?

Modern mesh Wi-Fi networks promise better coverage, seamless roaming, and smarter performance—but when something goes wrong, most users are left guessing. The WiFi Mesh Network Analyzer exists to fill that gap. It gives Linux users real insight into how their mesh network is actually behaving: how nodes are connected, where overlap happens, which connections are weak, and how your device is steering between access points.

Mesh networks aren't always transparent. Commercial mesh systems often hide diagnostics behind limited apps or cloud dashboards, making it hard to understand why performance drops or devices fail to roam correctly. This tool was created to surface that data directly from the network and make it human-readable—without needing vendor lock-in or proprietary software.

It's especially helpful for troubleshooting issues like:

- Devices sticking to weak access points
- Random roaming between nodes
- Coverage dead zones or overlap
- Signal strength instability
- Micro-dropouts and connection interruptions
- WiFi power management problems causing false disconnects

Whether you're a developer, power user, or just someone trying to improve home or office Wi-Fi, the WiFi Mesh Network Analyzer provides a practical, no-nonsense way to visualize and understand your wireless environment using tools that respect Linux-first workflows.

In short: it exists because mesh Wi-Fi is powerful—but only if you can actually see what's going on.

#### Table of Contents

- [INSTALLATION](#installation)
- [SYSTEM COMPATIBILITY](#system-compatibility)
- [SETUP](#setup)
- [BASIC USAGE](#basic-usage)
- [ADVANCED OPTIONS](#advanced-options)
- [ROAMING & POWER ANALYSIS](#roaming--power-analysis)
- [OUTPUT FILES](#output-files)
- [WHAT YOU GET](#what-you-get)
- [TROUBLESHOOTING](#troubleshooting)
- [CLI OUTPUT EXAMPLE](#cli-output-example)
- [HTML REPORT](#html-report)
- [PRO TIPS](#pro-tips)

## FEATURES

### 🔍 Roaming Analysis
- **Micro-dropout detection**: Catch brief connection drops (50ms polling) your system might miss
- **Roaming performance testing**: Measure actual handoff quality as you move around your space
- **Continuous roaming monitoring**: Real-time tracking of mesh transitions with detailed logging
- **Problem transition analysis**: Identify problematic node-to-node handoffs and roaming loops

### 🔋 Power Management Detection
- **WiFi power saving analysis**: Detect power management issues causing periodic disconnects
- **USB autosuspend checking**: Find USB WiFi adapter suspension problems
- **PCIe ASPM detection**: Identify PCIe power management conflicts
- **Driver-specific power issues**: Check Intel, Realtek, MediaTek, Qualcomm, Atheros settings
- **NetworkManager power settings**: Detect problematic WiFi power saving configurations
- **Automated fix generation**: Create executable scripts to resolve detected power issues

### 📊 Enhanced HTML Reports
- **Professional dark theme**: Modern glassmorphism design with responsive layout
- **Interactive visualizations**: Hover effects, click-to-copy BSSIDs, smooth animations
- **Advanced Venn diagrams**: Visual mesh overlap analysis with SVG generation
- **Comprehensive coverage analysis**: Detailed spatial distribution insights with zone mapping
- **Mobile-friendly interface**: Responsive design optimized for all devices
- **Real-time data integration**: Roaming and power analysis results included

### 🏠 Expanded Hardware Support
- **500+ OUI entries**: Comprehensive mesh system detection database (10x larger than before)
- **Enterprise hardware**: Support for Ubiquiti, Ruckus, Aruba, Cisco Meraki, EnGenius
- **Consumer mesh brands**: Enhanced eero, Orbi, Google Nest, ASUS, TP-Link, Linksys detection
- **WiFi 6E/7 systems**: Latest generation mesh hardware recognition
- **Industrial mesh**: Cambium Networks, Cradlepoint, Peplink support

This is production-ready software actively seeking feedback and testing!

#### We need your help testing with different:

- Mesh systems (eero, Orbi, Google Nest, Ubiquiti, ASUS, TP-Link, Linksys, etc.)
- Linux distributions (Ubuntu, Fedora, Arch, Debian, etc.)
- Network environments (home, office, enterprise)
- WiFi hardware configurations (Intel, Realtek, MediaTek, Qualcomm, Atheros)
- Power management scenarios (laptops, desktops, USB adapters)

#### Please report issues, bugs, or suggestions:

- What worked well for you
- What didn't work or was confusing
- Your mesh system brand/model
- Your Linux distribution and version
- Any error messages or unexpected behavior
- Roaming and power analysis results

### PREREQUISITES

Linux system (Ubuntu, Debian, Fedora, Arch, etc.)
Python 3.6+ (pre-installed on most Linux systems)
WiFi interface (built-in or USB adapter)
Root/sudo access (required for WiFi scanning)

### INSTALLATION

**Install system dependencies**

Ubuntu/Debian:
`sudo apt update && sudo apt install iw`

Fedora/RHEL:
`sudo dnf install iw`

Arch Linux:
`sudo pacman -S iw`

**Download required files:**

`mkdir mesh_analyzer && cd mesh_analyzer`

```
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_analyzer.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_html_reporter.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_venn_calculator.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_roaming_detector.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_power_detective.py
```

**Make the files executable:**

`chmod +x *.py`

**Required tools:**
- iw: WiFi scanning and management
- nmcli: NetworkManager command line (pre-installed on most systems)
✅ Zero Python dependencies – uses only standard library!

### SYSTEM COMPATIBILITY

✅ NetworkManager - Fully supported
❌ iwd (Intel WiFi Daemon) - Not compatible at this time

#### SETUP

Download the files and save these 5 files in the **same directory**:
- mesh_analyzer.py (main analyzer)
- mesh_html_reporter.py (HTML report generation)
- mesh_venn_calculator.py (overlap analysis)
- mesh_roaming_detector.py (roaming analysis - NEW)
- mesh_power_detective.py (power management analysis - NEW)

### BASIC USAGE

#### Single Analysis
`sudo python3 mesh_analyzer.py`

#### Run all the features at once
`sudo python3 mesh_analyzer.py --check-power --detect-dropouts --roaming-test --html-report --create-archive`


- Automatically detects WiFi interface
- Scans network and analyzes mesh topology
- Generates comprehensive HTML report with advanced visualizations
- Provides terminal output with detailed recommendations
- Includes roaming and power analysis if modules are available

#### Continuous Monitoring
`sudo python3 mesh_analyzer.py` --monitor

- Runs continuous analysis every 60 seconds
- Press Ctrl+C to stop

#### Custom Scan Interval
sudo python3 mesh_analyzer.py --monitor --scan-interval 120

- Monitor mode with 2-minute intervals

### ADVANCED OPTIONS

`sudo python3 mesh_analyzer.py --html-report`             # Generate HTML report after analysis

`sudo python3 mesh_analyzer.py --create-archive`          # Create compressed log archive

`sudo python3 mesh_analyzer.py --storage-info`            # Show data storage information

`sudo python3 mesh_analyzer.py --reset-history`           # Reset corrupted history files

`sudo python3 mesh_analyzer.py --archive-only`            # Create archive without new analysis

### ROAMING & POWER ANALYSIS

#### Roaming Analysis (NEW)
`sudo python3 mesh_analyzer.py --detect-dropouts`         # Detect micro-dropouts (30 seconds)

`sudo python3 mesh_analyzer.py --roaming-test`            # Test roaming quality (walk test)

`sudo python3 mesh_analyzer.py --monitor-roaming`         # Continuously monitor roaming events

#### Power Management Analysis (NEW)
`sudo python3 mesh_analyzer.py --check-power`             # Check for WiFi power management issues

`sudo python3 mesh_analyzer.py --check-power              # Generate script to fix power issues

#### OUTPUT FILES

Automatic file creation in ~/.mesh_analyzer/:

reports/
- Interactive HTML reports with advanced visualizations
- Dark theme with glassmorphism design and responsive layout
- Roaming and power analysis integration

logs/
- Detailed analysis logs and debugging info
- Roaming event monitoring logs
- Power management issue detection logs

bssid_history.pkl and connection_events.pkl
- Historical BSSID performance tracking
- Connection event history
- Roaming pattern analysis

### WHAT YOU GET

Terminal Output:

- Comprehensive mesh topology analysis with spatial intelligence
- Advanced signal strength zone mapping and coverage analysis
- Historical performance tracking with stability scores
- Intelligent optimization recommendations
- Roaming quality assessment and micro-dropout detection
- Power management issue identification and automated fixes
- Venn overlap analysis with quality scoring

HTML Report:

- Professional dark theme with glassmorphism design
- Interactive mesh topology visualization with hover effects
- Advanced signal strength distribution charts
- Visual Venn overlap diagrams with SVG rendering
- Comprehensive coverage issue analysis with spatial zones
- Performance trends and historical data tracking
- Roaming analysis results and transition quality
- Power management issue reporting with fix recommendations
- Click-to-copy BSSID functionality
- Mobile-responsive design optimized for all devices

### TROUBLESHOOTING

"No WiFi interface found"

`nmcli device status`                          # Check available interfaces
`ip link show`                                 # List all network interfaces

**0 access points found:**

- You may be on a restricted enterprise network
- Ensure you have proper WiFi scanning permissions; sudo
- Try moving closer to mesh nodes or access points

**Permission errors:**

- Must run with sudo for WiFi scanning
- Files are automatically created with correct user permissions
- Roaming and power analysis require elevated privileges

**Module import errors:**

- Ensure all 5 Python files are in the same directory
- Check file permissions and execute bits
- Optional modules (roaming_detector, power_detective) will gracefully degrade if missing

**Roaming analysis issues:**

- Requires active mesh network connection
- Best results when moving between different coverage areas
- May need multiple test runs for comprehensive data

**Power management detection:**

- Some issues require specific hardware configurations
- Results vary by WiFi chipset and driver version
- Generated fix scripts should be reviewed before execution

#### Why some nodes or frequencies might not appear

Not all mesh nodes or Wi-Fi frequencies will always show up in scans. This is expected behavior due to how mesh networks operate and how wireless scanning works on Linux. Some reasons include:

- Background steering and band steering: Mesh systems often hide certain nodes or bands (like 5GHz backhaul links) from active scans to manage traffic automatically.

- Scan timing limitations: Some nodes may only broadcast intermittently or reduce beaconing when idle, so they can be missed in a single scan.

- Driver and chipset behavior: Certain Wi-Fi chipsets or drivers (especially on Linux) may not report all frequencies or channels reliably during passive or active scans.

- DFS channels (Dynamic Frequency Selection): Some 5GHz channels are restricted and may not be immediately visible due to regulatory delays or scanning restrictions.

- Power management: Nodes may be in power-saving modes that reduce visibility.

If you're troubleshooting, try running multiple scans over time, use the new roaming analysis features, or reposition your device to improve visibility. This tool captures what the system can see—but some things are designed to stay just out of sight.

### CLI Output example

```
📝 Logging enabled: /home/matt/.mesh_analyzer/logs
📊 Loaded history for 1 BSSIDs
📈 Loaded 6 recent connection events
📁 History storage: /home/matt/.mesh_analyzer
✅ Roaming detector module loaded
✅ Power detective module loaded

🔍 MICRO-DROPOUT DETECTION
============================================================
🔍 Monitoring for micro-dropouts for 30 seconds...
These are drops your system might not normally notice
💡 Keep using your WiFi normally - browse, stream, etc.

✅ No micro-dropouts detected in 30 seconds
Your mesh is handling connections smoothly!

🚶 ROAMING QUALITY TEST
============================================================
📊 Measuring roaming performance...
🚶 Walk around your space now. Press Ctrl+C when done.
💡 Try to move between different rooms/areas
Press Enter when you're done walking around... 

📊 Roaming Analysis:
   • Seamless roams: 0
   • Disconnection events: 0

🔋 WIFI POWER MANAGEMENT CHECK
============================================================
🔋 WiFi Power Management Detective
============================================================
Scanning for power-related WiFi issues...

📋 POWER MANAGEMENT REPORT
============================================================
Total issues found: 1
Critical issues: 0

🚨 Issues Found:

Pcie Aspm:

  🟡 PCIe ASPM set to: [default] performance powersave powersupersave
     Impact: Can cause latency and brief disconnects
     Fix: Add pcie_aspm=off to kernel boot parameters

📝 Generated fix script: /tmp/fix_wifi_power.sh
Run with: sudo /tmp/fix_wifi_power.sh

💡 Fix script has been generated if issues were found
🧠 WiFi Mesh Network Analyzer
============================================================
🔍 Analysis: Signal Intelligence • Mesh Topology • Historical Tracking • Pattern Recognition • Venn Overlap
============================================================
📡 Interface: wlp5s0
🔗 Connected: Slower | D8:8E:D4:7D:2E:C8 | 7015 MHz | -53 dBm

📊 NETWORK SCANNING
────────────────────────────────────────────────────────────
🔍 Scanning networks with historical analysis...
📡 Found 14 access points

📊 MESH INTELLIGENCE
────────────────────────────────────────────────────────────
🏷️  Brand: Eero
🔧 Type: Tri-Band Mesh
🏠 Topology: 4 nodes, 8 radios
   ℹ️  Note: Only shows nodes visible from your current location
   📊 Why some nodes may be missing:
      • Distant nodes (basement, far rooms) may be too weak to detect
      • Nodes powered off or disconnected from mesh
      • Interference blocking weak signals from remote areas
      • Your device's WiFi antenna limitations
📶 Mesh Topology: 🟢 Good Topology (Quality Score: 70/100)
   📊 Analysis: 4 nodes detected - excellent for comprehensive coverage with minor coverage irregularities

🗺️  SPATIAL COVERAGE ANALYSIS:
   📍 Coverage Zones & Your Connection:
      🟢 Primary Zone: 2 nodes (-44 to -33dBm)
         └─ Excellent coverage area (same room/very close)
      🟠 Tertiary Zone: 1 nodes (-70 to -70dBm)
         └─ Extended coverage area (distant rooms)
      🔴 Fringe Zone: 1 nodes (-89 to -89dBm)
         └─ Maximum range coverage (basement/garage/far areas)
📡 Bands: 2.4GHz, 5GHz, 6GHz

🔄 VENN OVERLAP ANALYSIS:
   🟢 Coverage Overlap Quality: Excellent (Score: 100/100)
   📊 Excellent mesh overlap - 6/6 node pairs overlapping
   🔗 Detected 6 node overlaps
      • Node D4:7D:2E ↔ Node EB:B8:40: 40.0% overlap
      • Node D4:7D:2E ↔ Node EB:B8:D2: 41.2% overlap
      • Node D4:7D:2E ↔ Node EB:A5:10: 12.3% overlap

📊 HISTORICAL PERFORMANCE
────────────────────────────────────────────────────────────
📈 Current BSSID Performance Analysis (D8:8E:D4:7D:2E:C8):
   🟢 Stability Score: 100.0/100 (Excellent)
   🔄 Connection History: 7 total attempts
   ✅ Success Rate: 100.0%

📊 PROBLEM DETECTION
────────────────────────────────────────────────────────────
✅ No problematic patterns detected

📊 RECOMMENDATIONS
────────────────────────────────────────────────────────────
💡 PERFORMANCE OPTIMIZATION OPPORTUNITY:
   🎯 Recommended BSSID: D8:8E:D4:7D:2E:C6
   📈 Expected improvement: +20dB signal strength
   🏆 Quality rating: EXCELLENT

============================================================

🌐 GENERATING HTML REPORT
────────────────────────────────────────────────────────────
📊 Analyzing mesh topology...
🔍 Evaluating alternatives...
📈 Gathering historical data...
🚨 Detecting problems...
📝 Generating HTML visualization with mesh overlap analysis...
✅ HTML Report Generated Successfully!
   📁 Location: /home/matt/.mesh_analyzer/reports/mesh_analysis_20250612_044019.html
   🌐 Open in browser: file:///home/matt/.mesh_analyzer/reports/mesh_analysis_20250612_044019.html
   📊 Report includes: mesh topology, signal analysis, recommendations, historical data
```

### HTML report

![Example Report](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/MeshAnalyzer/images/mesh_screenshot-new.png)

### PRO TIPS

- **Best results**: Connect to the mesh network you want to analyze

- **Large mesh networks**: May take longer to scan (15-30 seconds)

- **Enterprise networks**: Some corporate networks block WiFi scanning

- **Multiple runs**: Historical data improves recommendations over time

- **Roaming analysis**: Use --roaming-test while walking around your space for comprehensive results

- **Test Power management**: Run --check-power if experiencing frequent disconnects or connection drops

- **HTML reports**: Best viewed in modern browsers with JavaScript enabled for full interactivity

- **Mobile viewing**: HTML reports are fully responsive and optimized for mobile devices

- **Data persistence**: All analysis data is saved locally for privacy and historical tracking

- **Background monitoring**: Use --monitor for long-term network health tracking and pattern analysis

- **Micro-dropout detection**: Use --detect-dropouts to catch brief connection issues that might not appear in system logs

- **Fix script safety**: Always review generated power management fix scripts before execution
