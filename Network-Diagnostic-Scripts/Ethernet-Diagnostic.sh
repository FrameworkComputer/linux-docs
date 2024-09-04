#!/bin/bash

# USB-C Expansion Card Ethernet Diagnostic Script

# Terminal formatting
if [ -t 1 ]; then
    BOLD=$(tput bold)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    BOLD=""
    YELLOW=""
    RESET=""
fi

# Log file for diagnostics
LOGFILE="$HOME/ethernet_diagnosis.log"

# Global variables to store network environment data
ETH_INTERFACE=""
IP_ADDRESS=""
GATEWAY=""
LINK_SPEED=""
VPN_ACTIVE=""
VPN_TYPE=""

# Function to log and display output
log_and_display() {
    echo "${BOLD}${YELLOW}$@${RESET}"
    echo "$@" >> "$LOGFILE"
}

# Function to log and display output without formatting
log_and_display_plain() {
    echo "$@" | tee -a "$LOGFILE"
}

# Check for and remove previous log file
if [ -f "$LOGFILE" ]; then
    log_and_display_plain "Removing previous diagnostic log file..."
    rm "$LOGFILE"
fi

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "Unknown"
    fi
}

# Function to install necessary packages quietly if not already installed
install_packages() {
    distro=$(detect_distro)
    case $distro in
        ubuntu)
            sudo apt-get update -qq > /dev/null 2>&1
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq network-manager iproute2 speedtest-cli usbutils ethtool inxi > /dev/null 2>&1
            ;;
        fedora)
            sudo dnf install -y -q NetworkManager iproute speedtest-cli usbutils ethtool inxi > /dev/null 2>&1
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Function to provide deep insights
provide_insights() {
    log_and_display_plain "Ethernet Interface: $1"
    log_and_display_plain "Detailed Network Information:"
    nmcli device show "$1" | grep -E 'GENERAL.STATE|IP4.ADDRESS|IP4.GATEWAY'
    log_and_display_plain "Network Route Information:"
    ip route show dev "$1"
}

# Function to display a progress bar
show_progress() {
    local duration=$1
    local steps=20
    local sleep_duration=$(echo "scale=2; $duration / $steps" | bc)
    
    for ((i=0; i<=steps; i++)); do
        local percentage=$((i * 100 / steps))
        local completed=$((i * 20 / steps))
        local remaining=$((20 - completed))
        printf "\r[%-20s] %d%%" "$(printf '#%.0s' $(seq 1 $completed))$(printf ' %.0s' $(seq 1 $remaining))" "$percentage"
        sleep $sleep_duration
    done
    echo
}

# Function to run speed test
run_speedtest() {
    log_and_display_plain "Running speed test...(may appear to stop at 75% which is normal)"
    show_progress 30 &
    progress_pid=$!
    speedtest_output=$(speedtest-cli --simple 2>/dev/null)
    kill $progress_pid 2>/dev/null
    wait $progress_pid 2>/dev/null
    printf "\033[1A\033[K"  # Move cursor up and clear the line
    log_and_display_plain "Speed Test Results:"
    echo "$speedtest_output" | while IFS= read -r line; do
        log_and_display_plain "$line"
    done
    
    # Extract values for later use
    ping=$(echo "$speedtest_output" | awk '/Ping:/ {print $2}')
    download=$(echo "$speedtest_output" | awk '/Download:/ {print $2}')
    upload=$(echo "$speedtest_output" | awk '/Upload:/ {print $2}')
}

# Function to check Ethernet interfaces
check_ethernet_interfaces() {
    log_and_display_plain "Ethernet Interface Information:"
    ETH_INTERFACE=$(ip -o link show | awk -F': ' '$2 ~ /^en|^eth/{print $2; exit}')
    
    if [ -z "$ETH_INTERFACE" ]; then
        log_and_display_plain "No Ethernet interface found."
        return
    fi

    log_and_display_plain "Interface: $ETH_INTERFACE"
    
    # Get IP address and gateway
    IP_ADDRESS=$(ip -4 addr show $ETH_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    GATEWAY=$(ip route | awk '/default/ && /'$ETH_INTERFACE'/ {print $3}')
    
    log_and_display_plain "IP Address: $IP_ADDRESS"
    log_and_display_plain "Gateway: $GATEWAY"
    
    # Get link speed
    LINK_SPEED=$(sudo ethtool $ETH_INTERFACE 2>/dev/null | awk '/Speed:/ {print $2}')
    log_and_display_plain "Link Speed: $LINK_SPEED"

    # Check for VPN (tun0 or wg0) interface
    if ip link show tun0 &>/dev/null; then
        VPN_ACTIVE="Yes"
        VPN_TYPE="OpenVPN"
        log_and_display_plain "VPN (tun0) detected: Active (OpenVPN)"
    elif ip link show wg0 &>/dev/null; then
        VPN_ACTIVE="Yes"
        VPN_TYPE="WireGuard"
        log_and_display_plain "VPN (wg0) detected: Active (WireGuard)"
    else
        VPN_ACTIVE="No"
        VPN_TYPE="None"
        log_and_display_plain "VPN detected: Not active"
    fi
}

# Function to summarize findings
summarize_findings() {
    log_and_display_plain
    log_and_display "Ethernet Diagnostic Summary"
    log_and_display "============================"
    
    log_and_display_plain "- Ethernet Interface: $ETH_INTERFACE"
    log_and_display_plain "- IP Address: $IP_ADDRESS"
    log_and_display_plain "- Gateway: $GATEWAY"
    log_and_display_plain "- Link Speed: $LINK_SPEED"
    log_and_display_plain "- VPN Active: $VPN_ACTIVE"
    if [ "$VPN_ACTIVE" == "Yes" ]; then
        log_and_display_plain "- VPN Type: $VPN_TYPE"
    fi
    
    log_and_display_plain "Speed Test Results:"
    log_and_display_plain "- Ping: ${ping} ms"
    log_and_display_plain "- Download: ${download} Mbit/s"
    log_and_display_plain "- Upload: ${upload} Mbit/s"
    
    log_and_display "INSIGHTS"
    log_and_display "========"

    # Ethernet Interface INSIGHTS
    log_and_display_plain "Ethernet Interface:"
    if [ -n "$ETH_INTERFACE" ]; then
        log_and_display_plain "- Connected via interface: $ETH_INTERFACE"
        
        speed_value=$(echo "$LINK_SPEED" | sed 's/[^0-9]*//g')
        if [ -n "$speed_value" ]; then
            if [ "$speed_value" -ge 1000 ]; then
                log_and_display_plain "- Excellent link speed ($LINK_SPEED). This is suitable for very high-bandwidth activities."
            elif [ "$speed_value" -ge 100 ]; then
                log_and_display_plain "- Good link speed ($LINK_SPEED). This is suitable for most high-bandwidth activities."
            else
                log_and_display_plain "- Lower link speed ($LINK_SPEED). You might experience slowdowns with high-bandwidth activities."
            fi
        else
            log_and_display_plain "- Unable to determine link speed."
        fi
    else
        log_and_display_plain "- No active Ethernet interface detected."
    fi

    # Speed Test INSIGHTS
    log_and_display_plain "Speed Test:"
    if [[ -n "$ping" && -n "$download" && -n "$upload" ]]; then
        if (( $(echo "$ping < 20" | bc -l) )); then
            log_and_display_plain "- Excellent ping time. Great for real-time applications like gaming or video calls."
        elif (( $(echo "$ping < 50" | bc -l) )); then
            log_and_display_plain "- Good ping time. Suitable for most online activities."
        else
            log_and_display_plain "- Higher ping time. You might experience lag in real-time applications."
        fi
        
        if (( $(echo "$download > 100" | bc -l) )); then
            log_and_display_plain "- Fast download speed (${download} Mbit/s). Excellent for streaming, large file downloads, and multiple users. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        elif (( $(echo "$download > 25" | bc -l) )); then
            log_and_display_plain "- Good download speed (${download} Mbit/s). Suitable for most online activities and HD streaming. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        else
            log_and_display_plain "- Lower download speed (${download} Mbit/s). You might experience buffering with HD streaming or slow file downloads. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        fi
        
        if (( $(echo "$upload > 20" | bc -l) )); then
            log_and_display_plain "- Good upload speed (${upload} Mbit/s). Suitable for video calls, uploading large files, and online backups."
        else
            log_and_display_plain "- Lower upload speed (${upload} Mbit/s). You might experience issues with video calls or uploading large files."
        fi
    else
        log_and_display_plain "- Speed test results not available. Unable to provide insights on network performance."
    fi

    # VPN INSIGHTS
    log_and_display_plain "VPN Status:"
    if [ "$VPN_ACTIVE" == "Yes" ]; then
        log_and_display_plain "- A VPN ($VPN_TYPE) is active. This may impact your internet speed and latency, but provides increased privacy and security."
    else
        log_and_display_plain "- No VPN detected. Your internet traffic is not being routed through a VPN at the moment."
    fi

    log_and_display_plain
}

# Function to perform system information check
check_system_info() {
    log_and_display_plain "System Information:"
    log_and_display_plain "Operating System: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    log_and_display_plain "Kernel Version: $(uname -r)"
    log_and_display_plain "CPU: $(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)"
    log_and_display_plain "Total RAM: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}')"
    log_and_display_plain "Last System Update: $(ls -lct /var/log 2>/dev/null | grep -E "dpkg|dnf" | tail -1 | awk '{print $6, $7, $8}')"
    
    # Added USB Device Information
    log_and_display_plain "USB Device Information:"
    sudo lsusb | grep -E 'Ethernet|LAN'
    
    log_and_display_plain
}

# Main function to run all checks
run_diagnostics() {
    check_ethernet_interfaces
    run_speedtest
    provide_insights "$ETH_INTERFACE"
    summarize_findings
}

# Script execution starts here
log_and_display "USB-C Expansion Card Ethernet Diagnostic Script"
log_and_display "-------------------------------------"

# Auto-detect distro and install needed packages
install_packages

# Check system information
check_system_info

# Get the Ethernet interface name
ETH_INTERFACE=$(nmcli device status | grep ethernet | awk '{print $1}')

# Check if Ethernet interface was found
if [ -z "$ETH_INTERFACE" ]; then
    log_and_display_plain "No Ethernet interface found. Please ensure your Ethernet device is connected."
    log_and_display_plain "Checking for network devices..."
    sudo lspci | grep -E 'Ethernet'
    sudo lsusb | grep -E 'Ethernet|LAN'
    exit 1
fi

# Check if Ethernet is connected
eth_status=$(nmcli device status | grep "$ETH_INTERFACE" | awk '{print $3}')

if [[ "$eth_status" != "connected" ]]; then
    log_and_display_plain "Ethernet is not connected or online."
    provide_insights "$ETH_INTERFACE"
else
    log_and_display_plain "Ethernet is connected."
    log_and_display_plain "Starting Ethernet Diagnostics..."
    run_diagnostics
fi

# Perform ping test
log_and_display_plain "Ping Results:"
ping_result=$(ping -c 4 8.8.8.8)
log_and_display_plain "$ping_result"

# Final summary
log_and_display "${YELLOW}Final Recommendations${RESET}"
log_and_display "${YELLOW}=====================${RESET}"

if [[ "$eth_status" == "connected" ]]; then
    log_and_display_plain "• Your Ethernet connection speed ($LINK_SPEED) is excellent. It should handle all types of internet activities without any issues."
    log_and_display_plain "• Your download speed (${download} Mbit/s) is good and should handle most online activities well, though it's not fully utilizing your Ethernet link speed."
    log_and_display_plain "• Your upload speed (${upload} Mbit/s) is good and should handle most upload tasks well, though it's not fully utilizing your Ethernet link speed."
    log_and_display_plain "• Your ping (${ping} ms) is good and should provide a responsive experience for most applications."
    log_and_display_plain "• Note: Your actual internet speeds (${download} Mbit/s down / ${upload} Mbit/s up) are lower than your Ethernet link speed ($LINK_SPEED). This is normal, as your internet speed is typically limited by your ISP plan, not your local network capability."
    log_and_display_plain "• Regularly update your network drivers and router firmware to ensure optimal performance."
    log_and_display_plain "• If speeds are consistently lower than expected, contact your ISP to check for any line issues."
else
    log_and_display_plain "• Your Ethernet connection is not active. Please check your cable connection and network settings."
fi

if [ "$VPN_ACTIVE" == "Yes" ]; then
    log_and_display_plain "• Note that your active VPN ($VPN_TYPE) may impact your internet speeds and latency. For accurate network testing, consider temporarily disabling your VPN."
fi

# End of script
log_and_display "${YELLOW}Ethernet Diagnostics Completed${RESET}"
log_and_display "${YELLOW}===============================${RESET}"
log_and_display_plain "Thank you for using this diagnostic tool."
log_and_display_plain "If you continue to experience issues, consider testing different cables and using different expansion slots to isolate where the issue is taking place."
log_and_display_plain "Complete diagnostic results have been saved to: ${YELLOW}$LOGFILE${RESET}"
