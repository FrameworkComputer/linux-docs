# WiFi Mesh Network Analyzer

### 🧪 BETA SOFTWARE - SEEKING TESTERS

#### Table contents

- [INSTALLATION](#installation)
  - [Install system dependencies](#install-system-dependencies)
  - [Download required files](#download-required-files)
  - [Make the files executable](#make-the-files-executable)
  - [Required tools](#required-tools)
- [SYSTEM COMPATIBILITY](#system-compatibility)
- [SETUP](#setup)
- [BASIC USAGE](#basic-usage)
  - [Single Analysis](#single-analysis)
  - [Continuous Monitoring](#continuous-monitoring)
  - [Custom Scan Interval](#custom-scan-interval)
- [ADVANCED OPTIONS](#advanced-options)
- [OUTPUT FILES](#output-files)
- [WHAT YOU GET](#what-you-get)
- [TROUBLESHOOTING](#troubleshooting)
- [CLI Output example](#cli-output-example)
- [HTML report](#html-report)
- [PRO TIPS](#pro-tips)


This is beta software actively seeking testers and feedback!

#### We need your help testing with different:
• Mesh systems (eero, Orbi, Google Nest, Ubiquiti, etc.)
• Linux distributions (Ubuntu, Fedora, Arch, Debian, etc.)
• Network environments (home, office, enterprise)
• WiFi hardware configurations

#### Please report issues, bugs, or suggestions:
• What worked well for you
• What didn't work or was confusing
• Your mesh system brand/model
• Your Linux distribution and version
• Any error messages or unexpected behavior


### PREREQUISITES

Linux system (Ubuntu, Debian, Fedora, Arch, etc.)
Python 3.6+ (pre-installed on most Linux systems)
WiFi interface (built-in or USB adapter)
Root/sudo access (required for WiFi scanning)


### INSTALLATION

**Install system dependencies**
```
sudo apt update && sudo apt install iw                     #Ubuntu/Debian
```
```
sudo dnf install iw                                        #Fedora/RHEL
```
```
sudo pacman -S iw                                          #Arch Linux NetworkManager - Fully supported, iwd (Intel WiFi Daemon) - Not compatible at this time
```

#### Download required files:
```
mkdir mesh_analyzer && cd mesh_analyzer
```
```
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_analyzer.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_html_reporter.py && \
wget https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/MeshAnalyzer/files/mesh_venn_calculator.py
```

#### Make the files executable:
```
chmod +x mesh_analyzer.py && \
chmod +x mesh_html_reporter.py && \
chmod +x mesh_venn_calculator.py
```


#### Required tools:
- iw: WiFi scanning and management
- nmcli: NetworkManager command line (pre-installed on most systems)
✅ Zero Python dependencies – uses only standard library!



### SYSTEM COMPATIBILITY

✅ NetworkManager - Fully supported
❌ iwd (Intel WiFi Daemon) - Not compatible at this time



#### SETUP

Download the files and save these 3 files in the **same directory**:
- mesh_analyzer.py
- mesh_html_reporter.py  
- mesh_venn_calculator.py



### BASIC USAGE

Single Analysis (Most Common)
```
sudo python3 mesh_analyzer.py
```
• Automatically detects WiFi interface
• Scans network and analyzes mesh topology
• Generates HTML report with visualizations
• Provides terminal output with recommendations

Continuous Monitoring
• sudo python3 mesh_analyzer.py --monitor
• Runs continuous analysis every 60 seconds
• Press Ctrl+C to stop

Custom Scan Interval
```
sudo python3 mesh_analyzer.py --monitor --scan-interval 120
```
• Monitor mode with 2-minute intervals



#### ADVANCED OPTIONS
```
sudo python3 mesh_analyzer.py --html-report             #Generate HTML report only
```
```
sudo python3 mesh_analyzer.py --create-archive          #Create compressed log archive
```
```
sudo python3 mesh_analyzer.py --storage-info            #Show data storage information
```
```
sudo python3 mesh_analyzer.py --reset-history           #Reset corrupted history files
```
```
sudo python3 mesh_analyzer.py --archive-only            #Create archive without new analysis
```



#### OUTPUT FILES

Automatic file creation in ~/.mesh_analyzer/:

reports/              - Interactive HTML reports with visualizations
logs/                 - Detailed analysis logs and debugging info
data/                 - Historical BSSID performance tracking



### WHAT YOU GET

Terminal Output:
• Mesh topology analysis
• Signal strength zones
• Historical performance
• Optimization recommendations

HTML Report:
• Interactive mesh topology map
• Signal strength distribution charts
• Venn overlap diagrams
• Coverage issue analysis
• Performance trends



### TROUBLESHOOTING

"No WiFi interface found"
nmcli device status                          #Check available interfaces
ip link show                                 #List all network interfaces

"0 access points found"
• You may be on a restricted enterprise network
• Ensure you have proper WiFi scanning permissions; sudo

Permission errors
• Must run with sudo for WiFi scanning
• Files are automatically created with correct user permissions



### CLI Output example
```
📝 Logging enabled: /home/Redacted/.mesh_analyzer/logs
📊 Loaded history for 1 BSSIDs
📈 Loaded 2 recent connection events
📁 History storage: /home/Redacted/.mesh_analyzer
🧠 WiFi Mesh Network Analyzer
============================================================
🔍 Analysis: Signal Intelligence • Mesh Topology • Historical Tracking • Pattern Recognition • Venn Overlap
============================================================
📡 Interface: wlp5s0
🔗 Connected: Redacted | D8:8E:D4:7D:2E:C8 | 7015 MHz | -49 dBm

📊 NETWORK SCANNING
────────────────────────────────────────────────────────────
🔍 Scanning networks with historical analysis...
📡 Found 16 access points

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
📶 Mesh Topology: 🟠 Topology Issues (Quality Score: 60/100)
   📊 Analysis: 4 nodes detected - excellent for comprehensive coverage but significant coverage gaps detected

🗺️  SPATIAL COVERAGE ANALYSIS:
   📍 Coverage Zones & Your Connection:
      🟢 Primary Zone: 2 nodes (-44 to -31dBm)
         └─ Excellent coverage area (same room/very close)
      🔴 Fringe Zone: 2 nodes (-88 to -80dBm)
         └─ Maximum range coverage (basement/garage/far areas)
📡 Bands: 2.4GHz, 5GHz, 6GHz

📊 HISTORICAL PERFORMANCE
────────────────────────────────────────────────────────────
📈 Current BSSID Performance Analysis (D8:8E:D4:7D:2E:C8):
   🟢 Stability Score: 100.0/100 (Excellent)
   🔄 Connection History: 3 total attempts
   ✅ Success Rate: 100.0%

📊 PROBLEM DETECTION
────────────────────────────────────────────────────────────
✅ No problematic patterns detected

📊 RECOMMENDATIONS
────────────────────────────────────────────────────────────
💡 PERFORMANCE OPTIMIZATION OPPORTUNITY:
   🎯 Recommended BSSID: D8:8E:D4:7D:2E:C6
   📈 Expected improvement: +18dB signal strength
   🏆 Quality rating: EXCELLENT

🌐 GENERATING HTML REPORT
────────────────────────────────────────────────────────────
📊 Analyzing mesh topology...
🔍 Evaluating alternatives...
📈 Gathering historical data...
🚨 Detecting problems...
📝 Generating HTML visualization with mesh overlap analysis...
✅ HTML Report Generated Successfully!
   📁 Location: /home/Redacted/.mesh_analyzer/reports/mesh_analysis_2025-06-11_16-19-11.html
   🌐 Open in browser: file:///home/Redacted/.mesh_analyzer/reports/mesh_analysis_2025-06-11_16-19-11.html
   📊 Report includes: mesh topology, signal analysis, Venn overlap diagram, recommendations, historical data
```


### HTML report

![Example Report](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/MeshAnalyzer/images/mesh_screenshot-min.png)



### PRO TIPS

• Best results: Connect to the mesh network you want to analyze
• Large mesh networks: May take longer to scan (15-30 seconds)
**• Enterprise networks: Some corporate networks block WiFi scanning**
• Multiple runs: Historical data improves recommendations over time

