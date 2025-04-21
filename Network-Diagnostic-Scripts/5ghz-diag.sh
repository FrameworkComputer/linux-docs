#!/bin/bash

# Enhanced WiFi 5GHz Diagnostic Script
# Compatible with immutable distributions (Bazzite, Project Bluefin)

# Function to check if reboot is needed
check_reboot_required() {
    if [ -f /var/run/reboot-required ]; then
        return 0
    elif [ "$IS_IMMUTABLE" -eq 1 ] && rpm-ostree status | grep -q "pending deployment"; then
        return 0
    elif [ -f /usr/bin/needs-restarting ]; then
        needs-restarting -r >/dev/null 2>&1
        if [ $? -eq 1 ]; then
            return 0
        fi
    fi
    return 1
}

# Function to check if we have sudo privileges
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    else
        if sudo -n true 2>/dev/null; then
            return 0
        else
            echo "Note: Some features require sudo privileges for full functionality"
            echo "Consider running: sudo $0"
            return 1
        fi
    fi
}

# Function to run command with proper privileges
run_with_privilege() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        if sudo -n true 2>/dev/null; then
            sudo "$@"
        else
            # Fallback without sudo
            "$@" 2>/dev/null
        fi
    fi
}

# Function to install missing dependencies
install_dependencies() {
    echo "Checking for missing dependencies..."
    MISSING_DEPS=()
    
    # Check required tools
    for cmd in iw nmcli ip; do
        if ! command -v $cmd >/dev/null 2>&1; then
            MISSING_DEPS+=($cmd)
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
        echo "All dependencies are installed."
        return 0
    fi
    
    echo "Missing dependencies: ${MISSING_DEPS[@]}"
    read -p "Would you like to install them? (y/N): " install_confirm
    
    if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
        if [ "$IS_IMMUTABLE" -eq 1 ]; then
            echo "Installing on immutable system..."
            for dep in "${MISSING_DEPS[@]}"; do
                case $dep in
                    "iw")
                        sudo rpm-ostree install iw
                        ;;
                    "nmcli")
                        sudo rpm-ostree install NetworkManager
                        ;;
                    "ip")
                        sudo rpm-ostree install iproute
                        ;;
                esac
            done
            
            echo "Installation complete. A reboot is required for changes to take effect."
            return 1
        else
            # Traditional package installation
            if command -v apt >/dev/null 2>&1; then
                sudo apt update
                sudo apt install -y iw network-manager iproute2
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y iw NetworkManager iproute
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm iw networkmanager iproute2
            fi
        fi
    else
        echo "Skipping dependency installation. Some features may not work."
        return 0
    fi
}

# Main script
(
    echo "=== WiFi 5GHz Comprehensive Diagnostic Report ==="
    echo "Generated on: $(date)"
    echo ""
    
    # Check sudo status
    check_sudo
    HAS_SUDO=$?
    
    # Detect if running on an immutable distribution
    IS_IMMUTABLE=0
    if [ -f /usr/lib/os-release ]; then
        if grep -qiE "bazzite|bluefin|silverblue|kinoite" /usr/lib/os-release; then
            IS_IMMUTABLE=1
            echo "Detected immutable distribution"
        fi
    fi
    echo ""
    
    # Check and install dependencies
    install_dependencies
    DEPS_INSTALLED=$?
    
    # Check if reboot is required
    if check_reboot_required || [ $DEPS_INSTALLED -eq 1 ]; then
        echo ""
        echo "=== REBOOT REQUIRED ==="
        echo "A system reboot is required to apply changes."
        echo "Please reboot your system and run this script again."
        echo ""
        read -p "Would you like to reboot now? (y/N): " reboot_confirm
        if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
            echo "Rebooting system..."
            sudo reboot
        else
            echo "Please reboot manually when convenient and run this script again."
            exit 0
        fi
    fi
    
    # Regulatory Domain Information
    echo "=== Regulatory Domain Information ==="
    iw reg get
    echo ""
    
    # Interface Detection
    echo "=== Interface Detection ==="
    IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep dev | awk '{print $5}')
    echo "Detected Interface: ${IFACE:-Unknown}"
    echo "Interface Status:"
    ip link show $IFACE 2>/dev/null
    echo ""
    
    # Hardware Capabilities
    echo "=== Hardware Capabilities ==="
    if [ -n "$IFACE" ]; then
        PHY=$(iw dev $IFACE info | grep wiphy | awk '{print $2}')
        echo "Wireless Card Information:"
        lspci -vv -s $(lspci | grep -i network | awk '{print $1}') | grep -E "Network|Subsystem|Kernel driver"
        echo ""
        echo "Supported Bands and Frequencies:"
        iw phy$PHY info | awk '
            /Band [1-4]:/ { band=$0; print band; show=1; next }
            /Band/ && !/Band [1-4]:/ { show=0 }
            show && /Frequencies:|Bitrates:|HT|VHT|HE/ { print $0 }
            show && /\* [0-9]+ MHz/ { print $0 }
        '
        echo ""
        echo "5GHz Band Capabilities:"
        iw phy$PHY info | sed -n '/Band 2:/,/Band [34]/p' | grep -v "Band [34]"
        echo ""
        echo "Active 5GHz Features:"
        iw phy$PHY info | grep -E "HT40|VHT|HE|160MHz|DFS"
    fi
    echo ""
    
    # Current Connection Status
    echo "=== Current Connection Status ==="
    if [ -n "$IFACE" ]; then
        iwconfig $IFACE 2>/dev/null
        echo ""
        echo "Detailed Link Information:"
        iw dev $IFACE link
        echo ""
        echo "Station Info (if connected):"
        iw dev $IFACE station dump
    fi
    echo ""
    
    # 5GHz Network Scan
    echo "=== Scanning for 5GHz Networks ==="
    if [ -n "$IFACE" ]; then
        echo "5GHz Networks Found:"
        
        if [ "$HAS_SUDO" -eq 0 ]; then
            run_with_privilege iw dev $IFACE scan | awk '
                BEGIN { print_in_progress=0 }
                /BSS/ { 
                    if (print_in_progress && freq >= 5000) {
                        printf "  Network: %s\n", ssid
                        printf "    Frequency: %s MHz (Channel %s)\n", freq, channel
                        printf "    Signal: %s dBm\n", signal
                        if (security != "") {
                            printf "    Security:%s\n", security
                        }
                        printf "    BSSID: %s\n\n", bss
                    }
                    bss=$2
                    signal=""
                    security=""
                    freq=""
                    ssid=""
                    channel=""
                    print_in_progress=0
                }
                /freq:/ { freq=$2 }
                /signal:/ { signal=$2 }
                /SSID:/ { 
                    gsub(/^[ \t]*SSID: /, "")
                    ssid=$0
                    print_in_progress=1
                }
                /primary channel:/ { channel=$3 }
                /WPA|RSN/ { security=security " " $0 }
                END {
                    if (print_in_progress && freq >= 5000) {
                        printf "  Network: %s\n", ssid
                        printf "    Frequency: %s MHz (Channel %s)\n", freq, channel
                        printf "    Signal: %s dBm\n", signal
                        if (security != "") {
                            printf "    Security:%s\n", security
                        }
                        printf "    BSSID: %s\n\n", bss
                    }
                }
            '
        else
            echo "Note: Scanning requires sudo privileges"
            echo "For best results, run with: sudo $0"
        fi
    else
        echo "  Interface not detected, cannot scan."
    fi
    echo ""
    
    # Channel Availability
    echo "=== 5GHz Channel Availability ==="
    if [ -n "$IFACE" ]; then
        iw phy$(iw dev $IFACE info | grep wiphy | awk '{print $2}') channels | grep -E "5[0-9]{3} MHz"
    fi
    echo ""
    
    # NetworkManager Configuration
    echo "=== NetworkManager Configuration ==="
    nmcli radio wifi
    nmcli device show $IFACE | grep -E "WIFI-PROPERTIES|GENERAL|CAPABILITIES"
    echo ""
    echo "Current Connection Profile (if connected):"
    CURRENT_CONNECTION=$(nmcli device show $IFACE | grep GENERAL.CONNECTION | awk '{print $2}')
    if [ "$CURRENT_CONNECTION" != "--" ]; then
        nmcli connection show "$CURRENT_CONNECTION" | grep -E "802-11-wireless|ipv4|ipv6|frequency"
    fi
    echo ""
    
    # Firmware Information
    echo "=== Firmware Information ==="
    echo "Distribution Type: $(if [ "$IS_IMMUTABLE" -eq 1 ]; then echo "Immutable"; else echo "Traditional"; fi)"
    echo ""
    echo "Linux Firmware Package Version:"
    if [ "$IS_IMMUTABLE" -eq 1 ]; then
        # For immutable distributions - get linux-firmware version directly
        if command -v rpm-ostree >/dev/null 2>&1; then
            # Get version from rpm database
            FIRMWARE_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' linux-firmware 2>/dev/null || true)
            if [ -n "$FIRMWARE_VERSION" ]; then
                echo "  linux-firmware: $FIRMWARE_VERSION"
            else
                # Fallback to rpm-ostree status
                rpm-ostree status | grep -A5 "^ \* " | grep -E "linux-firmware|Version" | head -2 || echo "  Not found"
            fi
        fi
        echo ""
        echo "Using layered packages:"
        rpm-ostree status | grep -A1 "^ \* " | grep LayeredPackages || echo "  None"
    else
        # For traditional distributions
        if command -v dpkg >/dev/null 2>&1; then
            dpkg -l | grep linux-firmware | awk '{print $2 " version: " $3}'
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Q linux-firmware 2>/dev/null
        elif command -v rpm >/dev/null 2>&1; then
            rpm -q --queryformat 'linux-firmware version: %{VERSION}-%{RELEASE}\n' linux-firmware 2>/dev/null || echo "  Not found"
        else
            echo "  Package manager not detected"
        fi
    fi
    echo ""
    echo "Wireless Firmware Files:"
    find /lib/firmware /usr/lib/firmware -path "*/mediatek/*MT7922*" -o -path "*/mediatek/*mt7922*" -o -path "*/mt*" -type f 2>/dev/null | while read file; do 
        if [ -f "$file" ]; then
            stat -c "%n: %y" "$file"
        fi
    done | head -10
    echo ""
    echo "Loaded Firmware Version:"
    if [ -n "$IFACE" ]; then
        # Use dmesg with proper privileges
        run_with_privilege dmesg | grep -i "firmware\|mt7921" | grep -v "Direct firmware load" | tail -5
    fi
    echo ""
    
    # Driver and Module Information
    echo "=== Driver and Module Information ==="
    lspci -nnk 2>/dev/null | grep -A 3 -i network
    echo ""
    if [ -n "$IFACE" ]; then
        MODULE=$(ls -l /sys/class/net/$IFACE/device/driver/module 2>/dev/null | awk -F/ '{print $NF}')
        if [ -n "$MODULE" ]; then
            echo "Wireless Module: $MODULE"
            echo "Module Parameters:"
            for param in /sys/module/$MODULE/parameters/*; do
                if [ -f "$param" ]; then
                    echo "  $(basename $param): $(cat $param 2>/dev/null)"
                fi
            done
            echo ""
            echo "Module Information:"
            modinfo $MODULE 2>/dev/null | grep -E "filename|version|firmware|description"
        fi
    fi
    echo ""
    
    # Connection Event Analysis
    echo "=== Connection Event Analysis (Last 24 Hours) ==="
    echo "Connection Attempts, Successes, and Failures:"
    journalctl -u NetworkManager -u wpa_supplicant --since "24 hours ago" --no-pager 2>/dev/null | \
    grep -Ei 'attempting|associating|authenticating|connected to|successfully|failed|fail|disconnect|error|auth_timeout|deauthenticating|reason|5[0-9]{3}|band|freq|channel' | \
    awk '{print $1,$2,$3,$0}' | tail -50
    echo ""
    
    # Error and Warning Analysis
    echo "=== Recent Errors and Warnings ==="
    journalctl -u NetworkManager -u wpa_supplicant --since "24 hours ago" --no-pager 2>/dev/null | \
    grep -i -E 'error|warning|fail|timeout' | tail -10
    echo ""
    
    # Power Management Settings
    echo "=== Power Management Settings ==="
    if [ -n "$IFACE" ]; then
        echo "Power Saving Status:"
        iw dev $IFACE get power_save
        echo ""
        echo "TLP/Power Management Configuration:"
        if [ -f /etc/tlp.conf ]; then
            grep -E "WIFI|POWER" /etc/tlp.conf 2>/dev/null | grep -v ^#
        else
            echo "  TLP not installed"
        fi
    fi
    echo ""
    
    # Band Steering and Roaming Settings
    echo "=== Band Steering and Roaming Settings ==="
    if [ -n "$IFACE" ]; then
        echo "BSS Transition Management Capability:"
        iw phy$(iw dev $IFACE info | grep wiphy | awk '{print $2}') info | grep -A 5 "Supported extended features:" | grep -E "BSS|FT|FILS"
        echo ""
        echo "Current Roaming Behavior:"
        ip addr show $IFACE 2>/dev/null | grep -E "brd|scope|valid_lft"
        echo ""
        echo "NetworkManager WiFi Backend Configuration:"
        if [ -f /etc/NetworkManager/conf.d/wifi_backend.conf ]; then
            cat /etc/NetworkManager/conf.d/wifi_backend.conf
        else
            echo "  No custom WiFi backend configuration found"
        fi
        echo ""
        echo "WiFi Band Selection Configuration:"
        grep -r "wifi.band-" /etc/NetworkManager/ 2>/dev/null || echo "  No band selection config found"
    fi
    echo ""
    
    # 5GHz Connection Issues
    echo "=== 5GHz Connection Issues ==="
    if [ -n "$IFACE" ]; then
        echo "Checking for 5GHz connection problems:"
        
        # Check if hardware supports 5GHz
        if iw phy$(iw dev $IFACE info | grep wiphy | awk '{print $2}') info | grep -qE "5[0-9][0-9][0-9].*MHz"; then
            echo "✓ Hardware supports 5GHz"
        else
            echo "✗ Hardware does not support 5GHz"
        fi
        
        # Check if connected to 5GHz or 6GHz
        CURRENT_FREQ=$(iw dev $IFACE link 2>/dev/null | grep freq | awk '{print $2}')
        if [ -n "$CURRENT_FREQ" ]; then
            FREQ_NUM=$(echo "$CURRENT_FREQ" | cut -d. -f1)
            if [ "$FREQ_NUM" -ge 5925 ]; then
                echo "✓ Connected to 6GHz/WiFi 6E ($CURRENT_FREQ MHz)"
            elif [ "$FREQ_NUM" -ge 5000 ]; then
                echo "✓ Connected to 5GHz ($CURRENT_FREQ MHz)"
            else
                echo "✗ Connected to 2.4GHz ($CURRENT_FREQ MHz)"
                
                # Check if 5GHz of the same SSID is available
                CURRENT_SSID=$(iw dev $IFACE link 2>/dev/null | grep SSID | awk '{$1=""; print $0}' | sed 's/^ *//')
                if [ -n "$CURRENT_SSID" ] && [ "$HAS_SUDO" -eq 0 ]; then
                    if run_with_privilege iw dev $IFACE scan 2>/dev/null | grep -A5 "$CURRENT_SSID" | grep -q "freq: 5[0-9][0-9][0-9]"; then
                        echo "  5GHz version of '$CURRENT_SSID' is available"
                        echo "  Band steering might be failing or disabled"
                    fi
                fi
            fi
        else
            echo "! Not connected to any network"
        fi
        
        # Check band selection settings
        echo ""
        echo "Band Selection Settings:"
        if nmcli connection show "$CURRENT_SSID" 2>/dev/null | grep -q "wifi.band"; then
            nmcli connection show "$CURRENT_SSID" | grep wifi.band
        else
            echo "  No specific band preference set"
        fi
        
        # Check for DFS issues
        echo ""
        echo "DFS Channel Issues:"
        if journalctl -u NetworkManager --since "24 hours ago" 2>/dev/null | grep -qi "dfs\|radar"; then
            echo "  DFS/Radar events detected in logs"
        else
            echo "  No DFS issues detected"
        fi
        
        # Check driver/firmware issues
        echo ""
        echo "Driver/Firmware Issues:"
        if run_with_privilege dmesg | grep -i mt7921 | grep -qi "error\|fail\|timeout"; then
            echo "  Driver/firmware errors detected"
            run_with_privilege dmesg | grep -i mt7921 | grep -i "error\|fail\|timeout" | tail -3
        else
            echo "  No driver errors detected"
        fi
    fi
    echo ""
    
    # Summary and Recommendations
    echo "=== Summary and Recommendations ==="
    echo ""
    
    # Create formatted summary box
    echo "+----------------------------------------+"
    echo "|        WiFi DIAGNOSTIC SUMMARY         |"
    echo "+----------------------------------------+"
    echo ""
    
    # Connection status with color coding
    if [ -n "$IFACE" ]; then
        CURRENT_SSID=$(iw dev $IFACE link 2>/dev/null | grep SSID | awk '{$1=""; print $0}' | sed 's/^ *//')
        CURRENT_FREQ=$(iw dev $IFACE link 2>/dev/null | grep freq | awk '{print $2}')
        
        echo "🛜 CONNECTION STATUS"
        echo "-------------------"
        if [ -n "$CURRENT_FREQ" ]; then
            FREQ_NUM=$(echo "$CURRENT_FREQ" | cut -d. -f1)
            if [ "$FREQ_NUM" -ge 5925 ]; then
                echo "   ✅ Connected to: $CURRENT_SSID"
                echo "   ✅ Band: WiFi 6E (6GHz - $CURRENT_FREQ MHz)"
                CONNECTION_STATUS="EXCELLENT"
                BAND_TYPE="6GHz"
            elif [ "$FREQ_NUM" -ge 5000 ]; then
                echo "   ✅ Connected to: $CURRENT_SSID"
                echo "   ✅ Band: 5GHz ($CURRENT_FREQ MHz)"
                CONNECTION_STATUS="GOOD"
                BAND_TYPE="5GHz"
            else
                echo "   ⚠️  Connected to: $CURRENT_SSID"
                echo "   ⚠️  Band: 2.4GHz ($CURRENT_FREQ MHz)"
                CONNECTION_STATUS="SUBOPTIMAL"
                BAND_TYPE="2.4GHz"
            fi
            
            # Get signal strength and speed
            SIGNAL=$(iw dev $IFACE link 2>/dev/null | grep signal | awk '{print $2}')
            RX_SPEED=$(iw dev $IFACE link 2>/dev/null | grep "rx bitrate" | awk '{print $3 " " $4}')
            TX_SPEED=$(iw dev $IFACE link 2>/dev/null | grep "tx bitrate" | awk '{print $3 " " $4}')
            
            echo "   📶 Signal: $SIGNAL dBm ($(if [ "${SIGNAL:-0}" -ge -50 ]; then echo "Excellent"; elif [ "${SIGNAL:-0}" -ge -60 ]; then echo "Good"; elif [ "${SIGNAL:-0}" -ge -70 ]; then echo "Fair"; else echo "Poor"; fi))"
            echo "   🚀 Speed: RX $RX_SPEED / TX $TX_SPEED"
        else
            echo "   ❌ Not connected to any network"
            CONNECTION_STATUS="DISCONNECTED"
        fi
        echo ""
        
        # Hardware capabilities
        echo "🔧 HARDWARE STATUS"
        echo "-----------------"
        echo "   Device: $(lspci | grep -i network | sed 's/^.*: //' | head -1)"
        echo "   Driver: $(ls -l /sys/class/net/$IFACE/device/driver/module 2>/dev/null | awk -F/ '{print $NF}' || echo "Unknown")"
        echo "   Firmware: $(rpm -q --queryformat '%{VERSION}-%{RELEASE}' linux-firmware 2>/dev/null || echo "Unknown")"
        echo ""
        
        # Performance analysis
        echo "⚡ PERFORMANCE ANALYSIS"
        echo "---------------------"
        POWER_SAVE=$(iw dev $IFACE get power_save 2>/dev/null | awk '{print $3}')
        if [ "$POWER_SAVE" = "on" ]; then
            echo "   ⚠️  Power saving: ENABLED (may impact performance)"
        else
            echo "   ✅ Power saving: DISABLED"
        fi
        
        if [ "$CONNECTION_STATUS" = "SUBOPTIMAL" ] && [ "$SCAN_COUNT" -gt 0 ]; then
            echo "   ⚠️  Using slower 2.4GHz band but 5GHz networks available"
        fi
        
        # Check for firmware errors
        if run_with_privilege dmesg | grep -qi "error.*mt7921\|mt7921.*error"; then
            echo "   ⚠️  Firmware errors detected in system logs"
        fi
        echo ""
        
        # Recommendations
        echo "💡 RECOMMENDATIONS"
        echo "-----------------"
        RECOMMENDATIONS=0
        
        if [ "$POWER_SAVE" = "on" ]; then
            echo "   1. Disable power saving for better performance:"
            echo -e "      \e[1;32msudo iw dev $IFACE set power_save off\e[0m # Only works for testing"
            echo -e "      To make it permanent: \e[1;32msudo nmcli connection modify \"$CURRENT_SSID\" wifi.powersave 2\e[0m"
            RECOMMENDATIONS=$((RECOMMENDATIONS + 1))
        fi
        
        if [ "$CONNECTION_STATUS" = "SUBOPTIMAL" ] && [ "$SCAN_COUNT" -gt 0 ]; then
            echo "   $((RECOMMENDATIONS + 1)). Force 5GHz/6GHz band connection:"
            echo -e "      \e[1;32mnmcli connection modify \"$CURRENT_SSID\" wifi.band 5GHz\e[0m"
            RECOMMENDATIONS=$((RECOMMENDATIONS + 1))
        fi
        
        # Check if no 5GHz networks are visible despite hardware support
        # Check if no 5GHz networks are visible despite hardware support
        if [ "${SCAN_COUNT:-0}" -eq 0 ] && \
           iw phy$(iw dev "$IFACE" | awk '/phy#/ {print $2}') info | grep -qE "5[0-9]{3}.*MHz"; then
            echo "   $((RECOMMENDATIONS + 1)). No 5GHz networks found! Troubleshooting steps:"
            echo "      a) Check if router has 5GHz enabled and broadcasting"
            echo "      b) Ensure router is in range (5GHz has shorter range than 2.4GHz)"
            echo "      c) Try disabling regulatory domain restrictions:"
            echo -e "         \e[1;32msudo iw reg set 00\e[0m # Temporary test only"
            echo "      d) Verify driver support with:"
            echo -e "         \e[1;32msudo modprobe -r mt7921e && sudo modprobe mt7921e\e[0m"
            echo "      e) If still not working, check dmesg for errors:"
            echo -e "         \e[1;32msudo dmesg | grep -i mt7921\e[0m"
            RECOMMENDATIONS=$((RECOMMENDATIONS + 1))
        fi
        
        if run_with_privilege dmesg | grep -qi "error.*mt7921\|mt7921.*error"; then
            echo "   $((RECOMMENDATIONS + 1)). Update firmware to latest version:"
            if [ "$IS_IMMUTABLE" -eq 1 ]; then
                echo -e "      \e[1;32msudo rpm-ostree upgrade\e[0m"
            else
                if command -v apt >/dev/null 2>&1; then
                    echo -e "      \e[1;32msudo apt update && sudo apt upgrade linux-firmware\e[0m"
                elif command -v dnf >/dev/null 2>&1; then
                    echo -e "      \e[1;32msudo dnf upgrade linux-firmware\e[0m"
                elif command -v pacman >/dev/null 2>&1; then
                    echo -e "      \e[1;32msudo pacman -Syu linux-firmware\e[0m"
                elif command -v zypper >/dev/null 2>&1; then
                    echo -e "      \e[1;32msudo zypper update kernel-firmware\e[0m"
                else
                    echo -e "      \e[1;32mUpdate linux-firmware package using your distribution's package manager\e[0m"
                fi
            fi
            RECOMMENDATIONS=$((RECOMMENDATIONS + 1))
        fi
        
        # Check for 5GHz connection failures
        if journalctl -u NetworkManager --since "24 hours ago" 2>/dev/null | grep -qi "freq.*5[0-9][0-9][0-9].*fail"; then
            echo "   $((RECOMMENDATIONS + 1)). 5GHz connection failures detected. Try:"
            echo "      a) Reset network settings:"
            echo -e "         \e[1;32mnmcli connection delete \"$CURRENT_SSID\"\e[0m"
            echo "         Then reconnect to recreate profile"
            echo "      b) Disable MAC randomization:"
            echo -e "         \e[1;32mnmcli connection modify \"$CURRENT_SSID\" wifi.cloned-mac-address stable\e[0m"
            echo "      c) Use specific channel if DFS issues exist:"
            echo -e "         \e[1;32mnmcli connection modify \"$CURRENT_SSID\" wifi.channel 36\e[0m"
            RECOMMENDATIONS=$((RECOMMENDATIONS + 1))
        fi
        
        if [ $RECOMMENDATIONS -eq 0 ]; then
            echo "   ✅ All systems optimal - no changes recommended!"
        fi
        echo ""
        
        # Quick statistics
        echo "📊 QUICK STATS"
        echo "-------------"
        SCAN_COUNT=$(run_with_privilege iw dev $IFACE scan 2>/dev/null | grep -cE 'freq: [5-6][0-9][0-9][0-9]' || echo "0")
        echo "   Networks found: $SCAN_COUNT (5GHz/6GHz)"
        echo "   Connection quality: $CONNECTION_STATUS"
        echo "   Current band: ${BAND_TYPE:-Unknown}"
        UPTIME=$(iw dev $IFACE station dump 2>/dev/null | grep "connected time" | awk '{print $3}')
        if [ -n "$UPTIME" ]; then
            echo "   Connected for: $((UPTIME / 3600)) hours, $(( (UPTIME % 3600) / 60 )) minutes"
        fi
        echo ""
        
        # Final status
        echo "+----------------------------------------+"
        if [ "$CONNECTION_STATUS" = "EXCELLENT" ] || [ "$CONNECTION_STATUS" = "GOOD" ]; then
            echo "|    🎉 WiFi Performance: $(printf "%-12s" "$CONNECTION_STATUS") 🎉    |"
        elif [ "$CONNECTION_STATUS" = "SUBOPTIMAL" ]; then
            echo "|    ⚠️  WiFi Performance: $(printf "%-12s" "$CONNECTION_STATUS") ⚠️     |"
        else
            echo "|    ❌ WiFi Status: $(printf "%-18s" "$CONNECTION_STATUS") ❌    |"
        fi
        echo "+----------------------------------------+"
    else
        echo "❌ No wireless interface detected!"
        echo ""
        echo "Please check your wireless hardware and drivers."
        echo "+----------------------------------------+"
        echo "|       WiFi Status: NO INTERFACE        |"
        echo "+----------------------------------------+"
    fi
    
) | tee wifi_5ghz_diagnostic_$(date +%Y%m%d_%H%M%S).log
