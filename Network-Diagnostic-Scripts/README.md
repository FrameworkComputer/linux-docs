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
&nbsp;
&nbsp;
&nbsp;


**Looking for the [Wi-Fi Diagnostic tool](https://github.com/FrameworkComputer/linux-docs/tree/main/Network-Diagnostic-Scripts#to-install-wi-fi-diagnostic-script-simply-run)? Click here to scroll down.**

**Looking for the [Frequency Diagnostic Tool](https://github.com/FrameworkComputer/linux-docs/tree/main/Network-Diagnostic-Scripts#to-install-5Ghz/6Ghz-frequency-diagnostic-tool)? Click here to scroll down.**

&nbsp;


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

## To Install 5Ghz/6Ghz Frequency Diagnostic Tool, simply run:

```
curl -s https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Network-Diagnostic-Scripts/5ghz-diag.sh -o 5ghz-diag.sh && clear && bash 5ghz-diag.sh
```

Running the tool in the future
After the install, you can run going forward with the following in the HOME directory. So merely opening a terminal and running this will work if the original script has not been moved.


```
bash 5ghz-diag.sh
```

![Frequency Diagnostic Script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Network-Diagnostic-Scripts/images/5gz1.png)

![Frequency Diagnostic Script](https://raw.githubusercontent.com/FrameworkComputer/linux-docs/refs/heads/main/Network-Diagnostic-Scripts/images/5gz2.png)


- Checks for pending reboots: Determines if a system reboot is required, especially relevant after installing dependencies on immutable systems.
- Verifies sudo privileges: Checks if the script is run with administrative privileges, noting that some features require sudo for full functionality.
- Installs missing dependencies: Identifies and offers to install necessary command-line tools (iw, nmcli, ip) using the appropriate package manager for your distribution (immutable or traditional).
- Displays Regulatory Domain Information: Shows the configured wireless regulatory domain, which can impact available channels and power levels.
- Detects Network Interface: Identifies your primary wireless network interface.
- Reports Hardware Capabilities: Provides details about your wireless card, including supported WiFi bands (2.4GHz, 5GHz, 6GHz), frequencies, and features (like HT, VHT, HE, 160MHz, DFS).
- Shows Current Connection Status: Displays information about your current WiFi connection, including SSID, frequency, signal strength, and transfer rates.
- Scans for 5GHz Networks: Lists available 5GHz (and 6GHz) wireless networks in your vicinity, including their frequency, signal strength, security type, and BSSID (requires sudo).
- Lists 5GHz Channel Availability: Shows the 5GHz channels supported by your hardware.
- Examines NetworkManager Configuration: Displays relevant NetworkManager settings, including WiFi radio status, device capabilities, and the configuration of your current connection profile.
- Provides Firmware Information: Reports the version of the linux-firmware package and attempts to show loaded wireless firmware files and recent firmware-related messages from the system log (dmesg).
- Details Driver and Module Information: Shows the wireless driver in use, its parameters, and general module information.
- Analyzes Connection Events: Extracts recent connection attempts, successes, and failures related to NetworkManager and wpa_supplicant from the system journal.
- Reviews Recent Errors and Warnings: Filters the system journal for recent errors and warnings related to NetworkManager and wpa_supplicant.
- Checks Power Management Settings: Reports the current WiFi power saving status and checks for relevant configurations in TLP if installed.
- Investigates Band Steering and Roaming Settings: Displays information about BSS transition management capabilities and NetworkManager's band selection configuration.
- Identifies 5GHz Connection Issues: Performs specific checks to diagnose common 5GHz connection problems, such as hardware support, current connection band, visibility of 5GHz networks, band selection settings, DFS issues, and driver/firmware errors.
- Generates a Summary and Recommendations: Provides a concise summary of the connection status, hardware details, and performance analysis, along with tailored recommendations based on the findings.
- Logs Output: Saves the entire diagnostic report to a timestamped log file.



------------------------------------------------------------------------------------------------------------------------------


### FAQ

- Does this fix anything with networking?
>This is a tool to give you and if need be, Framework Support an idea of what your network looks like. It also provides critical guidence on power save state, VPN usage, speed testing results, and overall network environment which may indicate where a problem is happening.


- Will this tell me why my network is so slow?
>Indirectly, yes. It can indicate items such as frequency, crowded wifi channels, among a number of other variables to examine. VPNs are a huge one.

- Does this support Project Bluefin or Bazzite?
>I have specific scripts in testing for these distros. We will be using Homebrew for them. Will update this repo when they are ready.

- Does this work for a laptop whereas I cannot use the internet at all?
>No. This is for performance issues specifically. That said, if you download the file onto another computer, move it to the Framework Laptop that is lacking internet, the wifi script will provide some hints as to what might be going on and how to fix it.

- My wifi card keeps dropping out.
> Please use [this script](https://github.com/FrameworkComputer/network-tester?tab=readme-ov-file#mediatekintel-wi-fi-drop-tester), run it for one hour. It will tell you when it's done running. Grab both the ping_logfile.log and iw_logfile.log logs it creates in your home directory and send it to support. This should capture the timeout and indicate if there was a signal drop, frequency change or another event.
