# Ethernet and Wi-Fi Diagnostic Scripts


### Install Curl

Curl should already be installed, but just in case:

### Fedora
```
sudo dnf install curl -y
```

or

### Ubuntu
```
sudo apt install curl -y
```



------------------------------------------------------------------------------------------------------------------------------

## To Install Ethernet Diagnostic Script, simply run:
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Network-Diagnostic-Scripts/Ethernet-Diagnostic.sh -o Ethernet-Diagnostic.sh && clear && bash Ethernet-Diagnostic.sh
```

Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash Ethernet-Diagnostic.sh
```
![Ethernet-Diagnostic](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Network-Diagnostic-Scripts/images/Ethernet-Diag.png)

- Detects and installs necessary packages based on the Linux distribution
- Creates a log file for storing diagnostic results
- Formats output with bold and yellow text for better readability
- Detects Ethernet interfaces and retrieves network information
- Checks IP address and gateway
- Determines link speed
- Detects active VPN connections (OpenVPN or WireGuard)
- Runs a speed test using speedtest-cli
- Provides a progress bar for the speed test
- Summarizes findings including Ethernet interface, IP, gateway, link speed, and VPN status
- Offers insights on network performance based on speed test results
- Checks and displays system information (OS, kernel, CPU, RAM, last update)
- Lists USB devices, focusing on Ethernet/LAN devices
- Performs a ping test to 8.8.8.8
- Provides final recommendations based on the diagnostic results
- Compares actual internet speeds with Ethernet link speed
- Suggests updating network drivers and router firmware
- Advises contacting ISP if speeds are consistently lower than expected
- Notes the potential impact of VPN on network performance
- Saves complete diagnostic results to a log file
- Suggests further troubleshooting steps (testing cables and expansion slots)

------------------------------------------------------------------------------------------------------------------------------




## To Install Wi-Fi Diagnostic Script, simply run:
```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Network-Diagnostic-Scripts/Wifi-Diagnostic.sh -o Wifi-Diagnostic.sh && clear && bash Wifi-Diagnostic.sh
```

Running the script in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.

```
bash Wifi-Diagnostic.sh
```
![Wi-Fi-Diagnostic](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/Network-Diagnostic-Scripts/images/WiFi_Diag.png)

- Detects and installs necessary packages based on the Linux distribution (Ubuntu or Fedora)
- Creates a log file for storing diagnostic results
- Formats output with bold and yellow text for better readability
- Checks for internet connectivity with a ping test to 8.8.8.8
- Provides rfkill status and recommendations if no network is detected
- Checks and installs required tools if missing
- Performs system information check (OS, kernel, CPU, RAM, last update)
- Detects Wi-Fi card information
- Checks Wi-Fi interfaces and retrieves detailed network information
- Monitors Wi-Fi signal strength and quality
- Detects active VPN connections (OpenVPN or WireGuard)
- Performs a network speed test using speedtest-cli
- Displays a loading bar during the speed test
- Checks network status and connection speed using nmcli and iw
- Summarizes findings including Wi-Fi interface, speed test results, and network environment
- Provides insights on system information, Wi-Fi interface, speed test results, and network environment
- Analyzes signal strength, transmission rate, and connection quality
- Interprets speed test results (ping, download, and upload speeds)
- Checks and explains power save mode status
- Provides VPN-specific insights if a VPN is active
- Suggests further actions based on diagnostic results
- Saves complete diagnostic results to a log file

------------------------------------------------------------------------------------------------------------------------------


### FAQ

- Does this fix anything with networking?
>This is a tool to give you and if need be, Framework Support an idea of what your network looks like. It also provides critical guidence on power save state, VPN usage, speed testing results, and overall network environment which may indicate where a problem is happening.


- Will this tell me why my network is so slow?

>Indirectly, yes. It can indicate items such as frequency, crowded wifi channels, among a number of other variables to examine. VPNs are a huge one.
