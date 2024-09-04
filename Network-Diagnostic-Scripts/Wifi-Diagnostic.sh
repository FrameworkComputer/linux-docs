#!/bin/bash

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

# Function to print the script title in yellow and bold at the top of the terminal
print_title() {
    echo "${BOLD}${YELLOW}Integrated Wi-Fi Diagnostic Script${RESET}"
    echo "---------------------------------"
}

# Ensure necessary packages are installed on Ubuntu and Fedora before proceeding
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi speedtest-cli || { echo "${YELLOW}Package installation failed on Ubuntu.${RESET}"; exit 1; }
            ;;
        fedora)
            sudo dnf install -y -q pciutils iw inxi speedtest-cli || { echo "${YELLOW}Package installation failed on Fedora.${RESET}"; exit 1; }
            ;;
        *)
            echo "${YELLOW}Unsupported distribution: $ID${RESET}"
            exit 1
            ;;
    esac
else
    echo "${YELLOW}Could not detect the OS distribution.${RESET}"
    exit 1
fi

# Clear the screen and ensure title is always printed at the top
clear
print_title

# Configuration for thresholds
SIGNAL_THRESHOLD=-65
QUALITY_THRESHOLD=50

# Log file for diagnostics
LOGFILE="$HOME/wifi_diagnosis.log"

# Global variables to store network environment data
SSID=""
SIGNAL_STRENGTH=""
SIGNAL_LEVEL=""
WIFI_FREQUENCY=""
VPN_ACTIVE=""
VPN_TYPE=""
VPN_INTERFACE=""
POWER_SAVE=""

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

# Check for internet connectivity and display ping results
check_internet_connection() {
    log_and_display_plain "Performing ping test to 8.8.8.8..."
    PING_RESULTS=$(ping -c 4 8.8.8.8 2>&1)
    echo "$PING_RESULTS" >> "$LOGFILE"
    log_and_display_plain "$PING_RESULTS"
    log_and_display_plain
    if echo "$PING_RESULTS" | grep -q "0% packet loss"; then
        return 0
    else
        log_and_display_plain "No network detected. Exiting."
        log_and_display_plain "rfkill Status:"
        RFKILL_STATUS=$(rfkill list)
        log_and_display_plain "$RFKILL_STATUS"
        
        log_and_display "Final Recommendations"
        log_and_display "====================="
        
        # Explain rfkill status
        log_and_display_plain "rfkill status explanation:"
        if echo "$RFKILL_STATUS" | grep -q "Soft blocked: yes"; then
            log_and_display_plain "- Soft blocked: Yes. This means the Wi-Fi is disabled by software. To unblock, run: ${YELLOW}rfkill unblock wifi${RESET}"
        fi
        if echo "$RFKILL_STATUS" | grep -q "Hard blocked: yes"; then
            log_and_display_plain "- Hard blocked: Yes. This means the Wi-Fi is disabled by a physical switch. Check for a Wi-Fi switch on your device and turn it on."
        fi
        if echo "$RFKILL_STATUS" | grep -q "Soft blocked: no" && echo "$RFKILL_STATUS" | grep -q "Hard blocked: no"; then
            log_and_display_plain "- Wi-Fi is not blocked by rfkill. The issue might be related to drivers or hardware."
        fi
        
        log_and_display_plain "- After addressing these issues, rerun the script to perform a full diagnosis."
        exit 1
    fi
}

# Function to run commands with elevated privileges if available
run_elevated() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    else
        log_and_display_plain "Neither sudo nor doas is available. Some features may be limited."
        "$@"
    fi
}

# Function to check if a command/package is installed
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and install required tools
check_and_install_tools() {
    tools="iw speedtest-cli dig ping lspci ethtool nmcli systemctl resolvectl net-tools dmesg grep awk sed bc"
    missing_tools=""

    for tool in $tools; do
        if ! is_installed "$tool"; then
            missing_tools="$missing_tools $tool"
        fi
    done

    if [ -z "$missing_tools" ]; then
        log_and_display_plain "All required tools are already installed."
        return
    fi

    log_and_display_plain "The following tools need to be installed:$missing_tools"
    for tool in $missing_tools; do
        install_package "$tool"
    done

    log_and_display_plain "Tool installation complete."
    # Clear the screen after tool installation and re-print the title
    clear
    print_title
}

# Function to perform system information check
check_system_info() {
    log_and_display_plain "System Information:"
    log_and_display_plain "Operating System: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)"
    log_and_display_plain "Kernel Version: $(uname -r)"
    log_and_display_plain "CPU: $(lscpu 2>/dev/null | grep 'Model name' | cut -d':' -f2 | xargs)"
    log_and_display_plain "Total RAM: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}')"
    log_and_display_plain "Last System Update: $(ls -lct /var/log 2>/dev/null | grep -E 'dpkg|dnf' | tail -1 | awk '{print $6, $7, $8}')"
    log_and_display_plain "Wi-Fi Card installed: $(run_elevated lspci | grep -E 'Network controller')"
}

# Function to check Wi-Fi interfaces
check_wifi_interfaces() {
    log_and_display_plain "Wi-Fi Interface Information:"
    iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | while read -r interface; do
        log_and_display_plain "Interface: $interface"
        iw dev "$interface" info 2>/dev/null | tee -a "$LOGFILE"
        link_info=$(iw dev "$interface" link 2>/dev/null)
        log_and_display_plain "$link_info"
        
        if echo "$link_info" | grep -q "Not connected"; then
            SSID="N/A"
            SIGNAL_STRENGTH="N/A"
            WIFI_FREQUENCY="N/A"
        else
            SSID=$(echo "$link_info" | awk '/SSID/{print $2}')
            SIGNAL_STRENGTH=$(echo "$link_info" | awk '/signal/{print $2 " " $3}')
            WIFI_FREQUENCY=$(echo "$link_info" | awk '/freq/{print $2}')
            
            freq=$(echo "$link_info" | awk '/freq/{print $2}')
            
            signal=$(echo "$link_info" | awk '/signal/{print $2}')
            log_and_display_plain "Signal Strength: $signal dBm"
            signal_abs=$(echo "$signal" | tr -d '-')
            
            tx_bitrate=$(echo "$link_info" | awk '/tx bitrate/{print $3}')
            log_and_display_plain "Transmission Rate: $tx_bitrate"
        fi

        # Check power save mode
        power_save=$(iw dev "$interface" get power_save 2>/dev/null)
        if [ $? -eq 0 ]; then
            POWER_SAVE="$power_save"
            log_and_display_plain "$POWER_SAVE"
        else
            POWER_SAVE="Unable to determine"
            log_and_display_plain "$POWER_SAVE"
        fi

        # Write POWER_SAVE to log file for later retrieval
        echo "POWER_SAVE=$POWER_SAVE" >> "$LOGFILE"

        log_and_display_plain
    done

    # Check for VPN (tun0 or wg0) interfaces
    if ip link show tun0 &>/dev/null; then
        VPN_ACTIVE="Yes"
        VPN_TYPE="OpenVPN"
        VPN_INTERFACE="tun0"
        log_and_display_plain "VPN (tun0) detected: Active (OpenVPN)"
    elif ip link show wg0 &>/dev/null; then
        VPN_ACTIVE="Yes"
        VPN_TYPE="WireGuard"
        VPN_INTERFACE="wg0"
        log_and_display_plain "VPN (wg0) detected: Active (WireGuard)"
    else
        VPN_ACTIVE="No"
        VPN_TYPE="None"
        VPN_INTERFACE="None"
        log_and_display_plain "VPN (tun0/wg0) detected: Not active"
    fi
}

# Function to display a loading bar
show_loading_bar() {
    local duration=$1
    local width=50
    local interval=0.1
    local progress=0
    local full_bar=$(printf "%${width}s" | tr ' ' '=')
    
    while [ $progress -lt $width ]; do
        local bar=$(printf "%.*s" $progress "$full_bar")
        printf "\r[%-${width}s] %d%%" "$bar" $((progress*2))
        sleep $interval
        progress=$((progress+1))
    done
    printf "\n"
}

# Function to perform speed test
perform_speed_test() {
    log_and_display_plain "Network Speed Test:"
    log_and_display_plain "Running speed test, please wait... ${YELLOW}(Note: The test may appear to hang at 98% for a few minutes. This is normal - wait patiently.)${RESET}"
    
    # Start the loading bar in the background
    show_loading_bar 60 &
    loading_pid=$!

    # Run the speed test
    speed_test=$(speedtest-cli --simple 2>/dev/null)
    speed_test_exit_code=$?

    # Stop the loading bar
    kill $loading_pid 2>/dev/null
    wait $loading_pid 2>/dev/null
    printf "\r%$(tput cols)s\r"  # Clear the line

    if [ $speed_test_exit_code -eq 0 ]; then
        log_and_display_plain "$speed_test"
        
        ping=$(echo "$speed_test" | awk '/Ping/{print $2}')
        download=$(echo "$speed_test" | awk '/Download/{print $2}')
        upload=$(echo "$speed_test" | awk '/Upload/{print $2}')
        
        log_and_display_plain
    else
        log_and_display_plain "Failed to perform speed test. Please check your internet connection and try again."
    fi
    log_and_display_plain
}

# Function to check network status with nmcli
check_nmcli_status() {
    log_and_display_plain "Checking network status with nmcli..."
    nmcli dev status 2>/dev/null | tee -a "$LOGFILE"
    nmcli dev wifi list 2>/dev/null | tee -a "$LOGFILE"

    # Check connection speed using iw
    connection_speed=$(iw dev $(iw dev | awk '$1=="Interface"{print $2}') link | grep 'tx bitrate' | awk '{print $3, $4}')

    if [[ -n "$connection_speed" ]]; then
        log_and_display_plain "Current connection speed: $connection_speed"
        
        # Extract the numeric value from the speed string (handle decimals correctly)
        speed_value=$(echo "$connection_speed" | awk '{print int($1)}')
        if (( speed_value < 20 )); then
            log_and_display_plain "Note: Connection speed is below 20 Mbit/s"
        fi
    else
        log_and_display_plain "No active Wi-Fi connection detected or speed not available."
    fi
}

# Function to monitor signal and quality using nmcli
monitor_signal_quality() {
    log_and_display_plain "Monitoring Wi-Fi signal and quality with nmcli..."

    # Get active Wi-Fi connection details
    wifi_info=$(nmcli -f IN-USE,SSID,SIGNAL dev wifi list 2>/dev/null | grep '^*')
    if [[ -z "$wifi_info" ]]; then
        log_and_display_plain "No active Wi-Fi connection found."
        SIGNAL_LEVEL="N/A"
        return
    fi

    # Extract signal strength and quality
    SSID=$(echo "$wifi_info" | awk '{print $2}')
    SIGNAL_LEVEL=$(echo "$wifi_info" | awk '{print $NF}')

    log_and_display_plain "Connected to SSID: $SSID"
    log_and_display_plain "Signal level: ${SIGNAL_LEVEL:-N/A}%"

    if [[ -n "$SIGNAL_LEVEL" && "$SIGNAL_LEVEL" =~ ^[0-9]+$ ]]; then
        if [ "$SIGNAL_LEVEL" -lt "$QUALITY_THRESHOLD" ]; then
            log_and_display_plain "Note: Signal quality is below ${QUALITY_THRESHOLD}%"
        fi
    fi
}

# Function to summarize findings
summarize_findings() {
    log_and_display_plain
    log_and_display "Wi-Fi Diagnostic Summary"
    log_and_display "========================"
    
    # Summarize Wi-Fi interface information
    log_and_display_plain "Wi-Fi Interface:"
    iw dev 2>/dev/null | awk '$1=="Interface"{print "- " $2}' | tee -a "$LOGFILE"
    
    # Summarize speed test results
    log_and_display_plain "Speed Test Results:"
    if [[ -f "$LOGFILE" ]]; then
        ping=$(grep "Ping:" "$LOGFILE" 2>/dev/null | tail -n1 | awk '{print $2}')
        download=$(grep "Download:" "$LOGFILE" 2>/dev/null | tail -n1 | awk '{print $2}')
        upload=$(grep "Upload:" "$LOGFILE" 2>/dev/null | tail -n1 | awk '{print $2}')
        if [[ -n "$ping" && -n "$download" && -n "$upload" ]]; then
            log_and_display_plain "- Ping: ${ping} ms"
            log_and_display_plain "- Download: ${download} Mbps"
            log_and_display_plain "- Upload: ${upload} Mbps"
        else
            log_and_display_plain "Speed test results not available. The test may have failed or not been performed."
        fi
    else
        log_and_display_plain "Speed test results not available. The log file may be missing."
    fi
    
    # Add Network Environment section
    # Detect the Wi-Fi interface if not set
    if [ -z "$interface" ]; then
        interface=$(iw dev | awk '$1=="Interface"{print $2; exit}')
    fi

    # Get link information
    link_info=$(iw dev "$interface" link)

    # Extract the frequency
    frequency2=$(iw dev "$interface" link | awk '/freq/ {print $2}')

    signal_strength=$(iw dev "$interface" link | awk '/signal:/ {print $2}')

    # Retrieve POWER_SAVE from log file
    POWER_SAVE=$(grep "POWER_SAVE=" "$LOGFILE" | tail -n1 | cut -d'=' -f2)

    # Display the network environment information
    log_and_display "Network Environment"
    log_and_display "===================="
    log_and_display_plain "- SSID: $SSID"
    log_and_display_plain "- Signal Strength: $signal_strength dBm"
    log_and_display_plain "- Signal level: $SIGNAL_LEVEL%"
    log_and_display_plain "- Frequency: $frequency2 MHz"
    log_and_display_plain "- $POWER_SAVE"
    log_and_display_plain "- VPN Active: $VPN_ACTIVE"
    if [ "$VPN_ACTIVE" == "Yes" ]; then
        log_and_display_plain "- VPN Type: $VPN_TYPE ($VPN_INTERFACE)"
    fi

    log_and_display_plain

    # Add INSIGHTS section
    log_and_display "INSIGHTS"
    log_and_display "========"

    # System Information INSIGHTS
    log_and_display_plain "System Information:"
    log_and_display_plain "- Your system specifications are important for Wi-Fi performance. A recent kernel version often includes the latest Wi-Fi drivers and features."

    # Wi-Fi Interface INSIGHTS
    log_and_display_plain "Wi-Fi Interface:"
    if [ "$SSID" != "N/A" ]; then
        log_and_display_plain "- Connected to network: $SSID"
        
        if [ "$(echo "$frequency2 < 2500" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- You are on the 2.4 GHz band. This has better range but might be more congested."
        elif [ "$(echo "$frequency2 >= 5150 && $frequency2 <= 5875" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- You are on the 5 GHz band. This typically provides faster speeds but has shorter range."
        elif [ "$(echo "$frequency2 >= 5925 && $frequency2 <= 7125" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- You are on the 6 GHz band. This typically provides even faster speeds but may have a shorter range."
        else
            log_and_display_plain "- Unknown frequency band. Characteristics are unknown."
        fi
        
        signal_abs=$(echo "$signal_strength" | tr -d '-')
        if [ "$(echo "$signal_abs < 50" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Excellent signal strength. You should experience optimal performance."
        elif [ "$(echo "$signal_abs < 60" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Good signal strength. Should be sufficient for most applications."
        elif [ "$(echo "$signal_abs < 70" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Fair signal strength. You might experience some slowdowns."
        else
            log_and_display_plain "- Poor signal strength. Consider moving closer to your router or checking for obstacles."
        fi
        
        tx_bitrate=$(echo "$link_info" | awk '/tx bitrate/{print $3}')
        if [ "$(echo "$tx_bitrate > 100" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Good transmission rate. Suitable for most high-bandwidth activities."
        else
            log_and_display_plain "- Lower transmission rate. You might experience slowdowns with high-bandwidth activities."
        fi
    else
        log_and_display_plain "- This interface is not connected to any network."
    fi

    # Speed Test INSIGHTS
    log_and_display_plain "Speed Test:"
    if [[ -n "$ping" && -n "$download" && -n "$upload" ]]; then
        if [ "$(echo "$ping < 20" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Excellent ping time. Great for real-time applications like gaming or video calls."
        elif [ "$(echo "$ping < 50" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Good ping time. Suitable for most online activities."
        else
            log_and_display_plain "- Higher ping time. You might experience lag in real-time applications."
        fi
        
        if [ "$(echo "$download > 100" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Fast download speed. Excellent for streaming, large file downloads, and multiple users. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        elif [ "$(echo "$download > 25" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Good download speed. Suitable for most online activities and HD streaming. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        else
            log_and_display_plain "- Lower download speed. You might experience buffering with HD streaming or slow file downloads. Note: Speed test results should be compared to other services such as Fast.com and Google Speed Test if the results feel wrong."
        fi
        
        if [ "$(echo "$upload > 20" | bc -l)" -eq 1 ]; then
            log_and_display_plain "- Good upload speed. Suitable for video calls, uploading large files, and online backups."
        else
            log_and_display_plain "- Lower upload speed. You might experience issues with video calls or uploading large files."
        fi
    else
        log_and_display_plain "- Speed test results not available. Unable to provide insights on network performance."
    fi

    # Network Environment INSIGHTS
    log_and_display_plain "Network Environment:"
    if [[ -n "$SIGNAL_LEVEL" && "$SIGNAL_LEVEL" =~ ^[0-9]+$ ]]; then
        if [ "$SIGNAL_LEVEL" -lt "$QUALITY_THRESHOLD" ]; then
            log_and_display_plain "- Signal quality is below ${QUALITY_THRESHOLD}%. This may impact your Wi-Fi performance."
        else
            log_and_display_plain "- Signal quality is good. This should provide stable Wi-Fi performance."
        fi
    fi

    # Connection Speed INSIGHTS
    if [[ -n "$connection_speed" ]]; then
        speed_value=$(echo "$connection_speed" | awk '{print int($1)}')
        if (( speed_value < 20 )); then
            log_and_display_plain "- Connection speed is below 20 Mbit/s. This may limit your ability to perform high-bandwidth activities."
        else
            log_and_display_plain "- Connection speed is good. This should support most online activities."
        fi
    fi

    # Power Save INSIGHTS
    if [[ "$POWER_SAVE" == *"on"* ]]; then
        log_and_display_plain "- Power save mode is on. This may improve battery life but could potentially impact Wi-Fi performance."
    elif [[ "$POWER_SAVE" == *"off"* ]]; then
        log_and_display_plain "- Power save mode is off. This may provide better Wi-Fi performance but could impact battery life on mobile devices."
    else
        log_and_display_plain "- Unable to determine power save mode. This information may not be available for your Wi-Fi interface."
    fi

    log_and_display_plain

    # VPN INSIGHTS
    log_and_display_plain "VPN Status:"
    if [ "$VPN_ACTIVE" == "Yes" ]; then
        log_and_display_plain "- A VPN ($VPN_TYPE) is active on interface $VPN_INTERFACE. This may impact your internet speed and latency, but provides increased privacy and security."
        if [ "$VPN_TYPE" == "OpenVPN" ]; then
            log_and_display_plain "- OpenVPN is known for its strong security features but may have slightly higher overhead compared to WireGuard."
        elif [ "$VPN_TYPE" == "WireGuard" ]; then
            log_and_display_plain "- WireGuard is known for its efficiency and speed, potentially offering better performance than OpenVPN."
        fi
    else
        log_and_display_plain "- No VPN (tun0 OpenVPN or wg0 WireGuard) detected. Your internet traffic is not being routed through a VPN at the moment."
    fi

    log_and_display_plain
}

# Main function to run all checks
run_diagnostics() {
    check_system_info
    check_wifi_interfaces
    perform_speed_test
    if command -v nmcli >/dev/null 2>&1; then
        check_nmcli_status
        monitor_signal_quality
    else
        log_and_display_plain "nmcli not available. Skipping detailed Wi-Fi checks."
    fi
    summarize_findings
}

# Script execution starts here
clear
print_title

check_and_install_tools
log_and_display_plain

log_and_display_plain "Starting Wi-Fi Diagnostics..."

# Perform ping test and display results immediately after the script title
check_internet_connection

run_diagnostics

log_and_display_plain "Wi-Fi Diagnostics completed. For a full diagnostic report, check the log file at ${YELLOW}$LOGFILE${RESET}"
