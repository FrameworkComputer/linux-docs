# Look for DFS-related events in journalctl#!/bin/bash

# Advanced WiFi Disconnect Intelligence Analyzer
# Enhanced with VPN detection, RF/frequency analysis, WiFi 7 support, distribution detection, and DFS monitoring

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Global variables
IFACE=""
WIFI_HARDWARE=""
DRIVER=""
CURRENT_FREQ=""
CURRENT_BAND=""
CURRENT_SSID=""
POWER_SAVE=""
INTELLIGENCE_SCORE=0
DISCONNECT_PATTERN=""
VPN_ACTIVE="No"
VPN_TYPE="None"
VPN_INTERFACE="None"
VPN_IMPACT_SCORE=0
WIFI_FUNCTIONAL=false
SEVERE_ISSUES=0
FAILURE_LOG_DIR="/tmp/wifi_failure_logs"
DISTRO_ID=""
DISTRO_NAME=""
SUPPORTS_WIFI7=false
SUPPORTS_MLO=false
CHANNEL_WIDTH=""
CHIP_MODEL=""
CHIP_VENDOR=""
CHIP_GENERATION=""
KNOWN_ISSUES=""
DRIVER_NAME=""
CURRENT_SIGNAL=""
CURRENT_BITRATE=""
SCAN_RESULTS=""

# Function to sanitize numeric variables
sanitize_number() {
    local value="$1"
    local default="${2:-0}"
    
    # Extract first line, remove non-digits, default to 0 if empty
    echo "$value" | head -1 | tr -d '\n' | grep -o '[0-9]*' | head -1 | sed 's/^$/'"$default"'/'
}

# DFS-specific global variables
DFS_CHANNELS_DETECTED=0
DFS_CURRENT_CONNECTION=false
DFS_RADAR_EVENTS=0
DFS_CHANNELS_LIST=""
DFS_IMPACT_SCORE=0
DFS_CAC_EVENTS=0
DFS_COUNT=0

# DFS channel definitions by region (focusing on common regions)
declare -A DFS_CHANNELS
DFS_CHANNELS[US]="52 56 60 64 100 104 108 112 116 120 124 128 132 136 140 144"
DFS_CHANNELS[EU]="52 56 60 64 100 104 108 112 116 120 124 128 132 136 140"
DFS_CHANNELS[JP]="52 56 60 64 100 104 108 112 116 120 124 128 132 136 140"

# Function to convert frequency to channel number
freq_to_channel() {
    local freq=$1
    local channel=""
    
    # Convert floating point frequency to integer
    local freq_int=$(printf "%.0f" "$freq" 2>/dev/null || echo "$freq" | cut -d'.' -f1)
    
    if [ "$freq_int" -ge 2412 ] && [ "$freq_int" -le 2484 ]; then
        # 2.4GHz band
        if [ "$freq_int" -eq 2484 ]; then
            channel=14
        else
            channel=$(echo "scale=0; ($freq_int - 2412) / 5 + 1" | bc 2>/dev/null || echo "$(( (freq_int - 2412) / 5 + 1 ))")
        fi
    elif [ "$freq_int" -ge 5000 ] && [ "$freq_int" -le 6000 ]; then
        # 5GHz band
        channel=$(echo "scale=0; ($freq_int - 5000) / 5" | bc 2>/dev/null || echo "$(( (freq_int - 5000) / 5 ))")
    elif [ "$freq_int" -ge 6000 ] && [ "$freq_int" -le 7200 ]; then
        # 6GHz band (simplified - actual 6GHz channels are more complex)
        channel="6GHz-$(echo "scale=0; ($freq_int - 5950) / 5" | bc 2>/dev/null || echo "$(( (freq_int - 5950) / 5 ))")"
    fi
    
    echo "$channel"
}

# Check if channel is DFS
is_dfs_channel() {
    local channel=$1
    local region=${2:-US}  # Default to US
    
    # Skip 6GHz channels (no DFS in 6GHz)
    if echo "$channel" | grep -q "6GHz"; then
        return 1
    fi
    
    # Get DFS channels for region
    local dfs_list="${DFS_CHANNELS[$region]}"
    
    # Check if channel is in DFS list
    for dfs_ch in $dfs_list; do
        if [ "$channel" = "$dfs_ch" ]; then
            return 0  # Is DFS
        fi
    done
    
    return 1  # Not DFS
}

# Enhanced DFS channel analysis
analyze_dfs_channels() {
    echo -e "${MAGENTA}📡 === DFS CHANNEL ANALYSIS ===${NC}"
    echo "🔍 Dynamic Frequency Selection monitoring for radar interference"
    echo ""
    
    if [ -z "$IFACE" ]; then
        echo "❌ Cannot analyze DFS channels - WiFi interface not available"
        return 1
    fi
    
    # Get regulatory domain
    REG_DOMAIN="US"  # Default
    REG_INFO=$(iw reg get 2>/dev/null)
    if [ -n "$REG_INFO" ]; then
        REG_COUNTRY=$(echo "$REG_INFO" | grep "country" | head -1 | awk '{print $2}' | tr -d ':')
        if [ -n "$REG_COUNTRY" ]; then
            REG_DOMAIN="$REG_COUNTRY"
        fi
    fi
    
    echo "📍 Regulatory Domain: $REG_DOMAIN"
    echo "📋 DFS Channels in $REG_DOMAIN: ${DFS_CHANNELS[$REG_DOMAIN]:-${DFS_CHANNELS[US]}}"
    echo ""
    
    # Get current connection details if not already available
if [ -z "$CURRENT_FREQ" ]; then
    WIFI_INFO=$(iw dev "$IFACE" link 2>/dev/null)
    if ! echo "$WIFI_INFO" | grep -q "Not connected"; then
        CURRENT_FREQ=$(echo "$WIFI_INFO" | grep "freq:" | awk '{print $2}')
        CURRENT_SSID=$(echo "$WIFI_INFO" | grep "SSID:" | awk '{print $2}')
    fi
fi

# Check current connection for DFS usage
echo "🔍 Current Connection DFS Analysis:"
if [ -n "$CURRENT_FREQ" ] && [ "$CURRENT_FREQ" != "Unknown" ]; then
    CURRENT_CHANNEL=$(freq_to_channel "$CURRENT_FREQ")
    
    if is_dfs_channel "$CURRENT_CHANNEL" "$REG_DOMAIN"; then
        DFS_CURRENT_CONNECTION=true
        echo -e "   ${YELLOW}⚠️ Currently connected to DFS channel: $CURRENT_CHANNEL ($CURRENT_FREQ MHz)${NC}"
        echo "   🎯 DFS Impact: Medium to High risk of disconnections"
        DFS_IMPACT_SCORE=75
    else
        DFS_CURRENT_CONNECTION=false
        echo -e "   ${GREEN}✅ Current channel $CURRENT_CHANNEL ($CURRENT_FREQ MHz) is NOT DFS${NC}"
        echo "   🎯 DFS Impact: No risk from current connection"
        DFS_IMPACT_SCORE=0
    fi
else
    echo "   ❓ Cannot determine current channel - not connected"
fi
echo ""
    
    # Scan for DFS channels in environment
    echo "🔍 Scanning for DFS channels in area..."
    
    SCAN_RESULTS=$(timeout 20 iw dev "$IFACE" scan 2>/dev/null)
    
    if [ -n "$SCAN_RESULTS" ]; then
        DFS_CHANNELS_DETECTED=0
        DFS_NETWORKS_LIST=""
        
        # Parse scan results for DFS channels
        echo "$SCAN_RESULTS" | grep -E "freq:|SSID:" | while IFS= read -r line; do
            if echo "$line" | grep -q "freq:"; then
                FREQ=$(echo "$line" | awk '{print $2}')
                CHANNEL=$(freq_to_channel "$FREQ")
                
                if is_dfs_channel "$CHANNEL" "$REG_DOMAIN"; then
                    DFS_CHANNELS_DETECTED=$((DFS_CHANNELS_DETECTED + 1))
                    # Get the SSID for this frequency (next SSID line after freq)
                    SSID=$(echo "$SCAN_RESULTS" | grep -A5 "freq: $FREQ" | grep "SSID:" | head -1 | awk '{print $2}')
                    if [ -n "$SSID" ] && [ "$SSID" != "\\x00" ]; then
                        echo "   🚨 DFS Network: $SSID (Channel $CHANNEL, $FREQ MHz)"
                    else
                        echo "   🚨 DFS Channel: $CHANNEL ($FREQ MHz) - Hidden SSID"
                    fi
                fi
            fi
        done
        
        # Count DFS networks separately - FIXED VERSION
        DFS_NETWORKS=$(echo "$SCAN_RESULTS" | awk '
            /freq:/ { 
                freq = $2; 
                # Convert floating point to integer for channel calculation
                freq_int = int(freq + 0.5)
                if (freq_int >= 5000 && freq_int <= 6000) {
                    channel = int((freq_int - 5000) / 5)
                } else {
                    channel = 0
                }
            }
            /SSID:/ && $2 != "\\x00" && $2 != "" { 
                if (channel == 52 || channel == 56 || channel == 60 || channel == 64 || 
                    (channel >= 100 && channel <= 144)) {
                    print $2 " (Ch " channel ", " freq " MHz)"
                }
            }
        ')
        
        # FIXED: Get proper count without newlines
        if [ -n "$DFS_NETWORKS" ]; then
            DFS_COUNT=$(echo "$DFS_NETWORKS" | grep -c "Ch " 2>/dev/null)
        else
            DFS_COUNT=0
        fi
        
        # Ensure DFS_COUNT is a single integer
        DFS_COUNT=$(sanitize_number "$DFS_COUNT" "0")
        
        echo ""
        echo "📊 DFS Environment Summary:"
        echo "   DFS Networks Detected: $DFS_COUNT"
        
        if [ "$DFS_COUNT" -gt 0 ]; then
            echo "   🚨 DFS Networks in Area:"
            echo "$DFS_NETWORKS" | head -10 | while IFS= read -r network; do
                if [ -n "$network" ]; then
                    echo "      • $network"
                fi
            done
            
            if [ "$DFS_COUNT" -gt 10 ]; then
                echo "      ... and $((DFS_COUNT - 10)) more DFS networks"
            fi
        fi
    else
        echo "   ❌ Cannot scan environment - scan failed"
        DFS_COUNT=0
    fi
    
    echo ""
    
    # Check for recent DFS/radar events in system logs
    echo "🔍 Checking for recent DFS/radar events..."
    
    DFS_RADAR_EVENTS=0
    DFS_CAC_EVENTS=0
    
    # Look for radar detection events
RADAR_EVENTS=$(journalctl --since "24 hours ago" --no-pager 2>/dev/null | \
    grep -iE "radar.*(detect|found)|dfs.*(detect|switch|cac)|channel.*(blocked|switch).*radar|cfg80211.*radar|ieee80211.*radar|ath.*radar|iwlwifi.*radar|mt76.*radar" | \
    grep -v "packagekit\|cache\|python" | \
    wc -l)
        
        if [ "$RADAR_EVENTS" -gt 0 ]; then
            DFS_RADAR_EVENTS="$RADAR_EVENTS"
            echo -e "   ${RED}🚨 Found $RADAR_EVENTS DFS/radar events in last 24 hours${NC}"
            echo "   📋 Recent DFS events:"
            journalctl --since "6 hours ago" --no-pager 2>/dev/null | \
    grep -iE "radar.*(detect|found)|dfs.*(detect|switch|cac)|channel.*(blocked|switch).*radar|cfg80211.*radar|ieee80211.*radar|ath.*radar|iwlwifi.*radar|mt76.*radar" | \
    grep -v "packagekit\|cache\|python" | \
    tail -5 | while IFS= read -r event; do
    echo "      $event"
done
            
            DFS_IMPACT_SCORE=$((DFS_IMPACT_SCORE + 50))
        else
            echo -e "   ${GREEN}✅ No recent DFS/radar events detected${NC}"
        fi
    
    # Look for CAC (Channel Availability Check) events
    if command -v dmesg >/dev/null 2>&1; then
        CAC_EVENTS=$(dmesg | grep -iE "cac.*start|cac.*complete|cac.*abort" | wc -l)
        if [ "$CAC_EVENTS" -gt 0 ]; then
            DFS_CAC_EVENTS="$CAC_EVENTS"
            echo "   📡 CAC (Channel Availability Check) events: $CAC_EVENTS"
            echo "   💡 CAC events indicate DFS channel switching activity"
        fi
    fi
    
    echo ""
    
    # DFS Impact Assessment
    echo "🎯 === DFS IMPACT ASSESSMENT ==="
    
    # Sanitize all numeric variables before comparisons
    DFS_COUNT=$(sanitize_number "$DFS_COUNT" "0")
    DFS_RADAR_EVENTS=$(sanitize_number "$DFS_RADAR_EVENTS" "0")
    DFS_IMPACT_SCORE=$(sanitize_number "$DFS_IMPACT_SCORE" "0")
    
    if [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo -e "   ${YELLOW}⚠️ HIGH RISK: Connected to DFS channel${NC}"
        echo "   💡 DFS channels must stop transmission when radar is detected"
        echo "   💡 This can cause sudden disconnections lasting 30+ seconds"
    fi
    
    if [ "$DFS_COUNT" -gt 5 ]; then
        echo -e "   ${YELLOW}⚠️ MEDIUM RISK: High DFS usage in area ($DFS_COUNT networks)${NC}"
        echo "   💡 Heavy DFS usage indicates radar-prone environment"
        DFS_IMPACT_SCORE=$((DFS_IMPACT_SCORE + 25))
    elif [ "$DFS_COUNT" -gt 0 ]; then
        echo -e "   ${GREEN}✅ LOW RISK: Some DFS usage in area ($DFS_COUNT networks)${NC}"
        echo "   💡 Moderate DFS environment - watch for patterns"
        DFS_IMPACT_SCORE=$((DFS_IMPACT_SCORE + 10))
    else
        echo -e "   ${GREEN}✅ NO RISK: No DFS channels detected in area${NC}"
        echo "   💡 Clean environment - DFS not a factor"
    fi
    
    if [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
        echo -e "   ${RED}🚨 CRITICAL: Recent radar detection events${NC}"
        echo "   💡 Active radar environment - expect frequent DFS disconnections"
    fi
    
    echo ""
    echo "📊 DFS Risk Score: $DFS_IMPACT_SCORE/100"
    
    if [ "$DFS_IMPACT_SCORE" -ge 75 ]; then
        echo -e "   ${RED}🚨 HIGH DFS RISK - Immediate action recommended${NC}"
    elif [ "$DFS_IMPACT_SCORE" -ge 50 ]; then
        echo -e "   ${YELLOW}⚠️ MODERATE DFS RISK - Monitor and optimize${NC}"
    elif [ "$DFS_IMPACT_SCORE" -ge 25 ]; then
        echo -e "   ${YELLOW}📊 LOW DFS RISK - Minor impact possible${NC}"
    else
        echo -e "   ${GREEN}✅ MINIMAL DFS RISK - Not a significant factor${NC}"
    fi
    
    echo ""
}

# Test actual connectivity with VPN awareness
test_actual_connectivity() {
    echo "🔍 Testing WiFi connection and data flow..."
    
    if [ -n "$IFACE" ]; then
        WIFI_LINK_STATUS=$(iw dev "$IFACE" link 2>/dev/null)
        
        if echo "$WIFI_LINK_STATUS" | grep -q "Not connected"; then
            echo "   ❌ SEVERE: WiFi not connected to any network"
            return 1
        elif echo "$WIFI_LINK_STATUS" | grep -q "Connected to"; then
            CURRENT_SSID=$(echo "$WIFI_LINK_STATUS" | grep "SSID" | awk '{print $2}')
            echo "   📡 WiFi connected to: ${CURRENT_SSID:-Unknown SSID}"
            
            # Test internet connectivity with VPN awareness
            if ! timeout 10 ping -c 3 -W 5 8.8.8.8 >/dev/null 2>&1; then
                echo "   ❌ SEVERE: No internet connectivity despite WiFi connection"
                if [ "$VPN_ACTIVE" = "Yes" ]; then
                    echo "   🔒 VPN active - may be blocking or routing traffic incorrectly"
                fi
                return 1
            fi
            
            echo "   ✅ Data flow verified - connectivity working"
            return 0
        fi
    fi
    
    return 1
}

# Severe issue detection with DFS awareness
detect_severe_wifi_issues() {
    echo -e "${RED}🚨 === SEVERE ISSUE DETECTION ===${NC}"
    echo "🔍 Testing for issues requiring NetworkManager restart..."
    echo ""
    
    SEVERE_ISSUES=0
    
    # Test actual connectivity
    if ! test_actual_connectivity; then
        SEVERE_ISSUES=$((SEVERE_ISSUES + 1))
    fi
    
    # Check for DFS-related disconnection patterns
    echo ""
    echo "🔍 Checking for DFS-related disconnection patterns..."
    
    if [ "$DFS_CURRENT_CONNECTION" = true ] && [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
        echo -e "${RED}🚨 DFS RADAR INTERFERENCE DETECTED${NC}"
        echo "   Current connection uses DFS channel with recent radar events"
        echo "   This likely explains WiFi disconnections"
        SEVERE_ISSUES=$((SEVERE_ISSUES + 1))
    elif [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo -e "${YELLOW}⚠️ DFS RISK: Connected to radar-sensitive channel${NC}"
        echo "   Monitor for sudden disconnections lasting 30+ seconds"
    fi
    
    echo ""
    
    # Provide distribution-aware recommendations
    if [ "$SEVERE_ISSUES" -gt 0 ]; then
        echo -e "${RED}🚨 SEVERE ISSUES DETECTED: $SEVERE_ISSUES${NC}"
        echo ""
        echo -e "${YELLOW}🔧 IMMEDIATE ACTION REQUIRED:${NC}"
        echo ""
        
        if [ "$VPN_ACTIVE" = "Yes" ]; then
            echo -e "${CYAN}🔒 VPN DETECTED - Try VPN-specific fixes first:${NC}"
            echo "0. Disconnect VPN temporarily and test WiFi"
            echo "   If WiFi works without VPN, the issue is VPN-related"
            echo ""
        fi
        
        if [ "$DFS_CURRENT_CONNECTION" = true ]; then
            echo -e "${MAGENTA}📡 DFS CHANNEL DETECTED - Try DFS-specific fixes first:${NC}"
            echo "0a. Switch to non-DFS channel immediately:"
            if [ -n "$CURRENT_SSID" ]; then
                echo "    sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg  # Force 2.4GHz (no DFS)"
                echo "    sudo nmcli connection up \"$CURRENT_SSID\""
            fi
            echo "0b. Configure router to use non-DFS channels: 36, 40, 44, 48 (low 5GHz)"
            echo "0c. Alternative channels: 149, 153, 157, 161, 165 (high 5GHz)"
            echo ""
        fi
        
        echo "Standard WiFi fixes:"
        echo "1. sudo systemctl restart NetworkManager"
        echo "2. sudo modprobe -r $DRIVER && sleep 2 && sudo modprobe $DRIVER"
        echo "3. sudo systemctl restart wpa_supplicant"
        
        if [ "$VPN_ACTIVE" = "Yes" ]; then
            echo ""
            echo "VPN-specific fixes:"
            echo "4. Restart VPN service"
            echo "5. Try different VPN server"
            echo "6. Lower VPN MTU: sudo ip link set $VPN_INTERFACE mtu 1200"
        fi
        
    else
        echo -e "${GREEN}✅ NO SEVERE ISSUES DETECTED${NC}"
        echo ""
        echo "🎉 WiFi system is stable and functioning properly"
        
        # Still provide DFS recommendations if relevant
        if [ "$DFS_IMPACT_SCORE" -gt 25 ]; then
            echo ""
            echo "💡 Note: DFS channels detected in environment - monitor for patterns"
        fi
    fi
}

# Distribution detection
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$PRETTY_NAME"
        
        # Handle Bluefin/Silverblue/Kinoite as Fedora-based
        if echo "$PRETTY_NAME" | grep -qi "bluefin\|silverblue\|kinoite"; then
            DISTRO_ID="fedora"
            echo "🔍 Detected immutable Fedora variant: $PRETTY_NAME"
        elif echo "$ID_LIKE" | grep -qi "fedora"; then
            DISTRO_ID="fedora"
        elif echo "$ID_LIKE" | grep -qi "debian"; then
            DISTRO_ID="debian"
        elif echo "$ID_LIKE" | grep -qi "arch"; then
            DISTRO_ID="arch"
        fi
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
    fi
}

# Get distribution-specific commands
get_distro_command() {
    local command_type="$1"
    
    case "$DISTRO_ID" in
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
            case "$command_type" in
                "firmware_update") 
                    # Check for bootc first (newer immutable systems like Bluefin)
                    if command -v bootc >/dev/null 2>&1; then
                        echo "sudo bootc upgrade || (rpm-ostree reset && sudo bootc upgrade)"
                    # Check for rpm-ostree (Silverblue/Kinoite)
                    elif command -v rpm-ostree >/dev/null 2>&1; then
                        echo "rpm-ostree update && sudo reboot"
                    else
                        echo "sudo dnf update linux-firmware"
                    fi
                    ;;
                "grub_update") 
                    # Immutable systems don't need manual GRUB updates
                    if command -v rpm-ostree >/dev/null 2>&1 || command -v bootc >/dev/null 2>&1; then
                        echo "# GRUB updated automatically on reboot for immutable systems"
                    else
                        echo "sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
                    fi
                    ;;
                "initrd_update") 
                    # Immutable systems rebuild initrd automatically
                    if command -v rpm-ostree >/dev/null 2>&1 || command -v bootc >/dev/null 2>&1; then
                        echo "# initrd rebuilt automatically on reboot for immutable systems"
                    else
                        echo "sudo dracut -f"
                    fi
                    ;;
                "kernel_param")  
                    # Check for immutable Fedora variants first
                    if command -v rpm-ostree >/dev/null 2>&1; then
                        echo "sudo rpm-ostree kargs --append="
                    elif command -v bootc >/dev/null 2>&1; then
                        echo "sudo bootc kargs --append="
                    else
                        echo "sudo grubby --update-kernel=ALL --args="
                    fi
                    ;;
                "package_manager") 
                    if command -v bootc >/dev/null 2>&1; then
                        echo "bootc"
                    elif command -v rpm-ostree >/dev/null 2>&1; then
                        echo "rpm-ostree"
                    else
                        echo "dnf"
                    fi
                    ;;
            esac
            ;;
        "ubuntu"|"debian"|"pop"|"mint"|"linuxmint")
            case "$command_type" in
                "firmware_update") echo "sudo apt update && sudo apt upgrade linux-firmware" ;;
                "grub_update") echo "sudo update-grub" ;;
                "initrd_update") echo "sudo update-initramfs -u" ;;
                "kernel_param") echo "Edit /etc/default/grub and add to GRUB_CMDLINE_LINUX=" ;;
                "package_manager") echo "apt" ;;
            esac
            ;;
        "arch"|"manjaro"|"endeavouros")
            case "$command_type" in
                "firmware_update") echo "sudo pacman -S linux-firmware" ;;
                "grub_update") echo "sudo grub-mkconfig -o /boot/grub/grub.cfg" ;;
                "initrd_update") echo "sudo mkinitcpio -P" ;;
                "kernel_param") echo "Edit GRUB_CMDLINE_LINUX in /etc/default/grub" ;;
                "package_manager") echo "pacman" ;;
            esac
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            case "$command_type" in
                "firmware_update") echo "sudo zypper update kernel-firmware" ;;
                "grub_update") echo "sudo grub2-mkconfig -o /boot/grub2/grub.cfg" ;;
                "initrd_update") echo "sudo dracut -f" ;;
                "kernel_param") echo "Edit /etc/default/grub and add to GRUB_CMDLINE_LINUX=" ;;
                "package_manager") echo "zypper" ;;
            esac
            ;;
        *)
            case "$command_type" in
                "firmware_update") echo "# Update firmware using your distribution's package manager" ;;
                "grub_update") echo "# Update GRUB configuration" ;;
                "initrd_update") echo "# Rebuild initramfs" ;;
                "kernel_param") echo "# Edit GRUB configuration manually" ;;
                "package_manager") echo "# Use your distribution's package manager" ;;
            esac
            ;;
    esac
}

# Function to run command with privilege
run_with_privilege() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        if sudo -n true 2>/dev/null; then
            sudo "$@"
        else
            "$@" 2>/dev/null
        fi
    fi
}

# Test actual WiFi functionality - THE SINGLE SOURCE OF TRUTH
test_wifi_functionality() {
    local functional=false
    
    if [ -n "$IFACE" ]; then
        # Test 1: Interface exists and is up
        if ip link show "$IFACE" 2>/dev/null | grep -q "state UP"; then
            # Test 2: Check actual WiFi connection status first
            WIFI_LINK_STATUS=$(iw dev "$IFACE" link 2>/dev/null)
            
            if echo "$WIFI_LINK_STATUS" | grep -q "Connected to"; then
                # Test 3: Driver is responding to commands
                if iw dev "$IFACE" info >/dev/null 2>&1; then
                    # Test 4: Internet connectivity working
                    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
                        functional=true
                    fi
                fi
            fi
        fi
    fi
    
    echo "$functional"
}

# Modern chipset analysis - ENHANCED with PCI ID detection
analyze_modern_chipsets() {
    # Method 1: Check by chip name in hardware string
    if echo "$WIFI_HARDWARE" | grep -qi "mt7925"; then
        CHIP_MODEL="MT7925"
        CHIP_GENERATION="WiFi 7 (802.11be) - 160MHz capable"
        KNOWN_ISSUES="Excellent Linux support in kernel 6.8+, stable WiFi 7 implementation"
        DRIVER_NAME="mt7925e"
        SUPPORTS_WIFI7=true
    elif echo "$WIFI_HARDWARE" | grep -qi "mt7927"; then
        CHIP_MODEL="MT7927" 
        CHIP_GENERATION="WiFi 7 (802.11be) - 320MHz capable"
        KNOWN_ISSUES="Advanced WiFi 7 with 320MHz, requires kernel 6.9+"
        DRIVER_NAME="mt7925e"
        SUPPORTS_WIFI7=true
    # Method 2: Check by PCI Device ID (for newer chips not yet named in lspci database)
    elif echo "$WIFI_HARDWARE" | grep -qi "device 0717"; then
        CHIP_MODEL="MT7925"
        CHIP_GENERATION="WiFi 7 (802.11be) - 6GHz + MLO capable"
        KNOWN_ISSUES="Latest WiFi 7 with full 6GHz and MLO support, requires kernel 6.8+"
        DRIVER_NAME="mt7925e"
        SUPPORTS_WIFI7=true
        SUPPORTS_MLO=true
    elif echo "$WIFI_HARDWARE" | grep -qi "device 0718\|device 0719"; then
        CHIP_MODEL="MT7925/MT7927 variant"
        CHIP_GENERATION="WiFi 7 (802.11be) - Advanced features"
        KNOWN_ISSUES="Cutting-edge WiFi 7, may need latest firmware"
        DRIVER_NAME="mt7925e"
        SUPPORTS_WIFI7=true
        SUPPORTS_MLO=true
    elif echo "$WIFI_HARDWARE" | grep -qi "qcncm865\|wcn7850"; then
        CHIP_MODEL="Qualcomm WCN7850/FastConnect 7800"
        CHIP_GENERATION="WiFi 7 (802.11be) with MLO"
        KNOWN_ISSUES="Excellent WiFi 7 MLO support via ath12k driver"
        DRIVER_NAME="ath12k"
        SUPPORTS_WIFI7=true
        SUPPORTS_MLO=true
    elif echo "$WIFI_HARDWARE" | grep -qi "be200"; then
        CHIP_MODEL="Intel BE200"
        CHIP_GENERATION="WiFi 7 (802.11be)"
        KNOWN_ISSUES="Intel WiFi 7, requires kernel 6.8+, AMD compatibility issues"
        DRIVER_NAME="iwlwifi"
        SUPPORTS_WIFI7=true
    elif echo "$WIFI_HARDWARE" | grep -qi "mt7922"; then
        CHIP_MODEL="MT7922"
        CHIP_GENERATION="WiFi 6E (802.11ax) with WiFi 7 features"
        KNOWN_ISSUES="Mature WiFi 6E with some WiFi 7 capabilities, excellent 6GHz support"
        DRIVER_NAME="mt7921e"
        # MT7922 has some WiFi 7 features even though it's primarily WiFi 6E
        SUPPORTS_WIFI7=true
    elif echo "$WIFI_HARDWARE" | grep -qi "ax210\|ax211"; then
        CHIP_MODEL="Intel AX210/AX211"
        CHIP_GENERATION="WiFi 6E (802.11ax)"
        KNOWN_ISSUES="Stable WiFi 6E with 6GHz support"
        DRIVER_NAME="iwlwifi"
    fi
    
    # Set chip vendor properly
    if echo "$WIFI_HARDWARE" | grep -qi "mediatek"; then
        CHIP_VENDOR="MediaTek"
    elif echo "$WIFI_HARDWARE" | grep -qi "intel"; then
        CHIP_VENDOR="Intel"
    elif echo "$WIFI_HARDWARE" | grep -qi "qualcomm\|qcom"; then
        CHIP_VENDOR="Qualcomm"
    else
        CHIP_VENDOR="Unknown"
    fi
}

# Enhanced channel width detection for modern WiFi
detect_advanced_channel_width() {
    # Multiple detection methods for WiFi 6E/7
    CHANNEL_WIDTH=""
    
    # Method 1: Direct iw link parsing
    CHANNEL_WIDTH=$(iw dev "$IFACE" link 2>/dev/null | grep -oE "(20|40|80|160|320)MHz" | head -1 | grep -o "[0-9]*")
    
    if [ -z "$CHANNEL_WIDTH" ]; then
        # Method 2: Parse from width field
        CHANNEL_WIDTH=$(iw dev "$IFACE" link 2>/dev/null | grep -oE "width: [0-9]+" | awk '{print $2}')
    fi
    
    if [ -z "$CHANNEL_WIDTH" ]; then
        # Method 3: WiFi 7 detection - Look for BE-MCS indicators
        BE_MCS=$(iw dev "$IFACE" link 2>/dev/null | grep "BE-MCS")
        HE_MCS=$(iw dev "$IFACE" link 2>/dev/null | grep "HE-MCS")
        
        if [ -n "$BE_MCS" ] || [ -n "$HE_MCS" ]; then
            # Estimate from bitrate (WiFi 6E/7 specific)
            BITRATE_NUM=$(echo "$CURRENT_BITRATE" | grep -o "[0-9]*" | head -1)
            if [ -n "$BITRATE_NUM" ]; then
                if [ "$BITRATE_NUM" -gt 5000 ]; then
                    CHANNEL_WIDTH="320"
                    echo "   📊 Estimated channel width: 320MHz (based on $BITRATE_NUM Mbps - WiFi 7)"
                elif [ "$BITRATE_NUM" -gt 2000 ]; then
                    CHANNEL_WIDTH="160"
                    echo "   📊 Estimated channel width: 160MHz (based on $BITRATE_NUM Mbps - WiFi 6E)"
                elif [ "$BITRATE_NUM" -gt 1000 ]; then
                    CHANNEL_WIDTH="80"
                    echo "   📊 Estimated channel width: 80MHz (based on $BITRATE_NUM Mbps)"
                fi
            fi
        fi
    fi
    
    if [ -n "$CHANNEL_WIDTH" ] && [ "$CHANNEL_WIDTH" != "0" ]; then
        echo "   Current channel width: $CHANNEL_WIDTH MHz"
        
        # Modern WiFi analysis
        case "$CHANNEL_WIDTH" in
            "320")
                echo "   🚀 Ultra-wide 320MHz - WiFi 7 maximum performance mode"
                echo "   💡 Requires clean 6GHz spectrum and WiFi 7 router"
                ;;
            "160")
                echo "   📊 Wide 160MHz - WiFi 6E/7 high performance mode"
                echo "   💡 Excellent for high-bandwidth applications"
                ;;
            "80")
                echo "   📈 Standard 80MHz - WiFi 6 optimal performance"
                ;;
            "40")
                echo "   📊 Narrow 40MHz - conservative bandwidth"
                ;;
            "20")
                echo "   📉 Basic 20MHz - maximum compatibility mode"
                ;;
        esac
    else
        echo "   ⚠️ Channel width not detected - check modern WiFi support"
    fi
}

# Enhanced VPN Detection System with modern protocols
detect_vpn_configuration() {
    echo -e "${CYAN}🔒 === VPN DETECTION & ANALYSIS ===${NC}"
    echo ""
    
    local vpn_detected=false
    local detected_vpn_type="None"
    local detected_vpn_interface="None"
    local vpn_impact_score=0
    
    # Method 1: Enhanced VPN interface detection using more reliable parsing
    echo "🔍 Scanning for VPN interfaces..."
    
    # Enhanced interface detection using reliable methods
    VPN_IFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -Ei 'tailscale|zerotier|nebula|wg[0-9]*|tun[0-9]*|tap[0-9]*|nordlynx|utun[0-9]*')
    
    if [ -n "$VPN_IFACES" ]; then
        while IFS= read -r vpn_iface; do
            if [ -n "$vpn_iface" ]; then
                # Check if interface is UP
                if ip link show "$vpn_iface" 2>/dev/null | grep -q "state UP"; then
                    vpn_detected=true
                    
                    # Determine modern VPN type based on interface name
                    if echo "$vpn_iface" | grep -qi "tailscale"; then
                        detected_vpn_type="Tailscale (WireGuard-based mesh)"
                    elif echo "$vpn_iface" | grep -qi "zerotier"; then
                        detected_vpn_type="ZeroTier (SD-WAN)"
                    elif echo "$vpn_iface" | grep -qi "nebula"; then
                        detected_vpn_type="Nebula (Overlay mesh)"
                    elif echo "$vpn_iface" | grep -qi "wg"; then
                        detected_vpn_type="WireGuard"
                    elif echo "$vpn_iface" | grep -qi "tun"; then
                        detected_vpn_type="OpenVPN/Generic TUN"
                    elif echo "$vpn_iface" | grep -qi "nordlynx"; then
                        detected_vpn_type="NordVPN (WireGuard)"
                    else
                        detected_vpn_type="Unknown VPN"
                    fi
                    
                    echo "   ✅ Active VPN: $vpn_iface ($detected_vpn_type)"
                    detected_vpn_interface="$vpn_iface"
                    break  # Exit after finding first active VPN interface
                fi
            fi
        done <<< "$VPN_IFACES"
    fi
    
    # Method 2: Fallback - Check for VPN processes if no interface found
    if [ "$vpn_detected" != "true" ]; then
        echo ""
        echo "🔍 Scanning for modern VPN processes..."

        VPN_PROCESSES=$(ps aux | grep -E "tailscaled|zerotier-one|nebula|headscale|wireguard|wg-quick|nordvpn|expressvpn|surfshark|mullvad|protonvpn" | grep -v grep)

        if [ -n "$VPN_PROCESSES" ]; then
            vpn_detected=true
            echo "   📋 Active modern VPN processes detected:"
            while IFS= read -r process; do
                if echo "$process" | grep -q "tailscaled"; then
                    echo "      • tailscaled"
                    detected_vpn_type="Tailscale (WireGuard-based mesh)"
                    # Try to find Tailscale interface using more methods
                    if [ "$detected_vpn_interface" = "None" ]; then
                        TAILSCALE_IF=$(ip -o link show | awk -F': ' '{print $2}' | grep -i tailscale | head -1)
                        if [ -n "$TAILSCALE_IF" ]; then
                            detected_vpn_interface="$TAILSCALE_IF"
                        else
                            TAILSCALE_IF=$(ip addr show | grep -E "inet 100\." | awk '{print $NF}' | head -1)
                            detected_vpn_interface="${TAILSCALE_IF:-tailscale (process-based detection)}"
                        fi
                    fi
                elif echo "$process" | grep -q "zerotier-one"; then
                    echo "      • zerotier-one"  
                    detected_vpn_type="ZeroTier (SD-WAN)"
                elif echo "$process" | grep -q "nordvpn"; then
                    echo "      • nordvpn"
                    detected_vpn_type="NordVPN"
                else
                    PROC_NAME=$(echo "$process" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
                    echo "      • $PROC_NAME"
                    detected_vpn_type="Modern VPN"
                fi
            done <<< "$VPN_PROCESSES"
        fi
    fi
    
    # Method 3: Check for DNS changes (modern VPN DNS)
    echo ""
    echo "🔍 Checking DNS configuration for VPN indicators..."
    
    if command -v resolvectl >/dev/null 2>&1; then
        DNS_INFO=$(resolvectl status 2>/dev/null)
        COMMON_DNS=$(echo "$DNS_INFO" | grep -E "1\.1\.1\.1|8\.8\.8\.8|208\.67\.222\.222|94\.140\.14\.14")
        
        if [ -n "$COMMON_DNS" ]; then
            echo "   📡 Public DNS detected (may be VPN-managed):"
            echo "$COMMON_DNS" | head -3 | while IFS= read -r dns; do
                echo "      $dns"
            done
        fi
    fi
    
    # VPN Impact Analysis
    echo ""
    echo "🎯 === VPN IMPACT ANALYSIS ==="
    
    # Set global variables based on detection
    VPN_ACTIVE="No"
    VPN_TYPE="$detected_vpn_type"
    VPN_INTERFACE="$detected_vpn_interface"
    VPN_IMPACT_SCORE="$vpn_impact_score"
    
    if [ "$vpn_detected" = true ]; then
        VPN_ACTIVE="Yes"
        echo -e "   ${GREEN}✅ VPN Active: $detected_vpn_type${NC}"
        echo "   Interface: $detected_vpn_interface"
    else
        VPN_ACTIVE="No"
        VPN_TYPE="None"
        VPN_INTERFACE="None" 
        VPN_IMPACT_SCORE=0
        echo -e "   ${GREEN}✅ No VPN detected${NC}"
        echo "   💡 WiFi issues not related to VPN configuration"
    fi
    
    echo ""
}

# RF and Frequency Analysis System (enhanced for WiFi 7) - WITH DFS INTEGRATION
analyze_rf_frequency_environment() {
    echo -e "${CYAN}📡 === RF & FREQUENCY ENVIRONMENT ANALYSIS ===${NC}"
    echo ""
    
    if [ -z "$IFACE" ]; then
        echo "❌ Cannot analyze RF environment - WiFi interface not available"
        return 1
    fi
    
    # Get current connection details
    echo "🔍 Current WiFi Connection Analysis..."
    
    WIFI_INFO=$(iw dev "$IFACE" link 2>/dev/null)
    
    if echo "$WIFI_INFO" | grep -q "Not connected"; then
        echo "   ❌ WiFi not connected - cannot analyze current RF environment"
        return 1
    fi
    
    # Extract current RF parameters
    CURRENT_FREQ=$(echo "$WIFI_INFO" | grep "freq:" | awk '{print $2}')
    CURRENT_SIGNAL=$(echo "$WIFI_INFO" | grep "signal:" | awk '{print $2}')
    CURRENT_BITRATE=$(echo "$WIFI_INFO" | grep "tx bitrate:" | awk '{print $3}')
    CURRENT_SSID=$(echo "$WIFI_INFO" | grep "SSID:" | awk '{print $2}')
    
    echo "📊 Current RF Status:"
    echo "   SSID: ${CURRENT_SSID:-Unknown}"
    echo "   Frequency: ${CURRENT_FREQ:-Unknown} MHz"
    echo "   Signal: ${CURRENT_SIGNAL:-Unknown} dBm"
    echo "   TX Bitrate: ${CURRENT_BITRATE:-Unknown} Mbps"
    
    # Determine band and channel with modern WiFi support
    if [ -n "$CURRENT_FREQ" ]; then
        FREQ_INT=$(echo "$CURRENT_FREQ" | cut -d'.' -f1)
        
        if [ "$FREQ_INT" -ge 2400 ] && [ "$FREQ_INT" -le 2500 ]; then
            CURRENT_BAND="2.4 GHz"
            CHANNEL=$(echo "scale=0; ($CURRENT_FREQ - 2412) / 5 + 1" | bc 2>/dev/null || echo "Unknown")
        elif [ "$FREQ_INT" -ge 5000 ] && [ "$FREQ_INT" -le 6000 ]; then
            CURRENT_BAND="5 GHz"
            CHANNEL=$(echo "scale=0; ($CURRENT_FREQ - 5000) / 5" | bc 2>/dev/null || echo "Unknown")
        elif [ "$FREQ_INT" -ge 6000 ] && [ "$FREQ_INT" -le 7200 ]; then
            CURRENT_BAND="6 GHz (WiFi 6E/7)"
            CHANNEL="6GHz Channel"
        else
            CURRENT_BAND="Unknown"
            CHANNEL="Unknown"
        fi
        
        echo "   Band: $CURRENT_BAND"
        echo "   Channel: $CHANNEL"
        
        # DFS Analysis for current connection
        if [ "$CURRENT_BAND" = "5 GHz" ] && [ "$CHANNEL" != "Unknown" ]; then
            if is_dfs_channel "$CHANNEL"; then
                echo -e "   ${YELLOW}⚠️ DFS Channel: Current connection uses DFS channel $CHANNEL${NC}"
                echo "   💡 DFS channels can cause disconnections when radar is detected"
            else
                echo -e "   ${GREEN}✅ Non-DFS Channel: Current channel $CHANNEL is safe from radar interference${NC}"
            fi
        fi
    fi
    
    # Enhanced channel width detection
    detect_advanced_channel_width
    
    # 6GHz environment analysis
    analyze_6ghz_environment
    
    # RF Environment Scan
    echo ""
    echo "🔍 Scanning RF environment for interference..."
    
    SCAN_RESULTS=$(timeout 15 iw dev "$IFACE" scan 2>/dev/null)
    
    if [ -n "$SCAN_RESULTS" ]; then
        # Count networks by band (including 6GHz)
        NETWORKS_24=$(echo "$SCAN_RESULTS" | grep "freq:" | awk '{print $2}' | awk '$1 >= 2400 && $1 <= 2500' | wc -l)
        NETWORKS_5=$(echo "$SCAN_RESULTS" | grep "freq:" | awk '{print $2}' | awk '$1 >= 5000 && $1 <= 6000' | wc -l)
        NETWORKS_6=$(echo "$SCAN_RESULTS" | grep "freq:" | awk '{print $2}' | awk '$1 >= 6000 && $1 <= 7200' | sort -u | wc -l)
       
        echo "📊 Nearby Networks:"
        echo "   2.4 GHz: $NETWORKS_24 networks"
        echo "   5 GHz: $NETWORKS_5 networks"
        echo "   6 GHz: $NETWORKS_6 networks"
        
        # Find strongest interfering networks
        echo ""
        echo "🚨 Top interfering networks on your band:"
        
        case "$CURRENT_BAND" in
            "2.4 GHz") FREQ_RANGE="freq: 24[0-9][0-9]" ;;
            "5 GHz") FREQ_RANGE="freq: 5[0-9][0-9][0-9]" ;;
            "6 GHz (WiFi 6E/7)") FREQ_RANGE="freq: 6[0-9][0-9][0-9]" ;;
            *) FREQ_RANGE="freq:" ;;
        esac
        
        # Extract and sort networks by signal strength - FIXED signal filter
        echo "$SCAN_RESULTS" | grep -A10 -B2 "$FREQ_RANGE" | grep -E "BSS|signal|SSID|freq:" | \
        awk '/BSS/ {bss=$2} /freq:/ {freq=$2} /signal:/ {signal=$2} /SSID:/ {ssid=$2; if(signal<-20 && ssid!="") print signal " dBm - " ssid " (" freq " MHz)"}' | \
        sort -n | tail -5 | while IFS= read -r network; do
            echo "      $network"
        done
        
    else
        echo "   ❌ Cannot scan RF environment - scan failed"
    fi
    
    # Power and regulatory analysis
    echo ""
    echo "🔍 Power and regulatory analysis..."
    
    REG_INFO=$(iw reg get 2>/dev/null)
    if [ -n "$REG_INFO" ]; then
        COUNTRY_LINE=$(echo "$REG_INFO" | grep "country" | head -1)
        GLOBAL_LINE=$(echo "$REG_INFO" | grep "global")
        
        if [ -n "$COUNTRY_LINE" ]; then
            REG_DOMAIN="$COUNTRY_LINE"
        elif [ -n "$GLOBAL_LINE" ]; then
            REG_DOMAIN="$GLOBAL_LINE"
        else
            REG_DOMAIN=$(echo "$REG_INFO" | head -1)
        fi
    else
        REG_DOMAIN="Not available"
    fi
    echo "   Regulatory domain: ${REG_DOMAIN:-Unknown}"
    
    TX_POWER=$(iw dev "$IFACE" info 2>/dev/null | grep "txpower" | awk '{print $2, $3}')
    echo "   TX Power: ${TX_POWER:-Unknown}"
    
    # RF Quality Assessment
    echo ""
    echo "🎯 === RF QUALITY ASSESSMENT ==="
    
    RF_SCORE=100
    RF_ISSUES=()
    
    # Signal strength assessment - ACTUALLY FIXED LOGIC
    if [ -n "$CURRENT_SIGNAL" ]; then
        # Extract just the number (keep it positive for easier comparison)
        SIGNAL_NUM=$(echo "$CURRENT_SIGNAL" | sed 's/-//')
        
        if command -v bc >/dev/null 2>&1; then
            # CORRECTLY FIXED: Lower absolute values = better signal strength
            # Remember: -30 dBm is excellent, -90 dBm is terrible
            if [ "$(echo "$SIGNAL_NUM <= 40" | bc)" -eq 1 ]; then
                echo "   ✅ Excellent signal strength ($CURRENT_SIGNAL dBm)"
                # No penalty for excellent signal
            elif [ "$(echo "$SIGNAL_NUM <= 60" | bc)" -eq 1 ]; then
                echo "   📊 Good signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 10))
            elif [ "$(echo "$SIGNAL_NUM <= 80" | bc)" -eq 1 ]; then
                echo "   ⚠️ Weak signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 30))
                RF_ISSUES+=("Weak signal - move closer to router")
            else
                echo "   🚨 Poor signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 50))
                RF_ISSUES+=("Very poor signal - major connectivity issues expected")
            fi
        else
            # Fallback without bc - CORRECTLY FIXED logic
            SIGNAL_INT=$(printf "%.0f" "$SIGNAL_NUM" 2>/dev/null || echo "$SIGNAL_NUM")
            if [ "$SIGNAL_INT" -le 40 ]; then
                echo "   ✅ Excellent signal strength ($CURRENT_SIGNAL dBm)"
                # No penalty for excellent signal
            elif [ "$SIGNAL_INT" -le 60 ]; then
                echo "   📊 Good signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 10))
            elif [ "$SIGNAL_INT" -le 80 ]; then
                echo "   ⚠️ Weak signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 30))
                RF_ISSUES+=("Weak signal - move closer to router")
            else
                echo "   🚨 Poor signal strength ($CURRENT_SIGNAL dBm)"
                RF_SCORE=$((RF_SCORE - 50))
                RF_ISSUES+=("Very poor signal - major connectivity issues expected")
            fi
        fi
    fi
    
    # Modern congestion assessment
    if [ "$CURRENT_BAND" = "2.4 GHz" ] && [ "$NETWORKS_24" -gt 15 ]; then
        echo "   🚨 High 2.4GHz congestion ($NETWORKS_24 networks)"
        RF_SCORE=$((RF_SCORE - 25))
        RF_ISSUES+=("Switch to 5GHz or 6GHz if available")
    elif [ "$CURRENT_BAND" = "5 GHz" ] && [ "$NETWORKS_5" -gt 20 ]; then
        echo "   ⚠️ Moderate 5GHz congestion ($NETWORKS_5 networks)"
        RF_SCORE=$((RF_SCORE - 15))
        RF_ISSUES+=("Consider WiFi 6E/7 (6GHz) if available")
    elif [ "$CURRENT_BAND" = "6 GHz (WiFi 6E/7)" ]; then
        echo "   🌟 6GHz band - clean spectrum advantage"
        RF_SCORE=$((RF_SCORE + 10))  # Bonus for 6GHz
    fi
    
    # Final RF assessment
    echo ""
    echo "📊 RF Environment Score: $RF_SCORE/100"
    
    if [ "$RF_SCORE" -ge 90 ]; then
        echo -e "   ${GREEN}🌟 Outstanding RF environment${NC}"
    elif [ "$RF_SCORE" -ge 80 ]; then
        echo -e "   ${GREEN}✅ Excellent RF environment${NC}"
    elif [ "$RF_SCORE" -ge 60 ]; then
        echo -e "   ${YELLOW}⚠️ Good RF environment with minor issues${NC}"
    elif [ "$RF_SCORE" -ge 40 ]; then
        echo -e "   ${YELLOW}🚨 Poor RF environment - optimization needed${NC}"
    else
        echo -e "   ${RED}🚨 Critical RF environment - major issues${NC}"
    fi
    
    echo ""
    
    # INTEGRATED DFS ANALYSIS
    analyze_dfs_channels
}

# Fixed and Enhanced 6GHz analysis function - ENHANCED for MT7925 PCI ID detection
analyze_6ghz_environment() {
    echo ""
    echo "🔍 6GHz band analysis..."
    
    # Multiple detection methods for 6GHz capability
    local supports_6ghz=false
    local detection_method=""
    
    # Method 1: Standard iw phy Band 3 detection
    SUPPORTS_6GHZ_BAND3=$(iw phy 2>/dev/null | grep -A 30 "Band 3:" | grep -E "freq.*6[0-9][0-9][0-9]")
    
    # Method 2: Alternative band detection (some drivers report differently)
    SUPPORTS_6GHZ_ALT=$(iw phy 2>/dev/null | grep -E "freq.*6[0-9][0-9][0-9]")
    
    # Method 3: Check if we've actually connected to 6GHz before (proof positive)
    CURRENT_FREQ_CHECK=false
    if [ -n "$CURRENT_FREQ" ]; then
        FREQ_INT=$(echo "$CURRENT_FREQ" | cut -d'.' -f1)
        if [ "$FREQ_INT" -ge 6000 ] && [ "$FREQ_INT" -le 7200 ]; then
            CURRENT_FREQ_CHECK=true
        fi
    fi
    
    # Method 4: Check for 6GHz frequencies in scan results (active proof) - FIXED
    if [ -n "$SCAN_RESULTS" ]; then
        SCAN_6GHZ=$(echo "$SCAN_RESULTS" | grep "freq:" | awk '$2 >= 6000 && $2 <= 7200' | wc -l)
    else
        # SCAN_RESULTS not available yet, do our own scan
        LOCAL_SCAN_RESULTS=$(timeout 15 iw dev "$IFACE" scan 2>/dev/null)
        SCAN_6GHZ=$(echo "$LOCAL_SCAN_RESULTS" | grep "freq:" | awk '$2 >= 6000 && $2 <= 7200' | wc -l)
    fi
    
    # Method 5: Enhanced chip model detection (including PCI IDs)
    CHIP_6GHZ_CAPABLE=false
    if echo "$CHIP_MODEL" | grep -qi "mt7925\|mt7927"; then
        CHIP_6GHZ_CAPABLE=true
    elif echo "$CHIP_MODEL" | grep -qi "mt7922"; then
        CHIP_6GHZ_CAPABLE=true
    elif echo "$WIFI_HARDWARE" | grep -qi "device 0717\|device 0718\|device 0719"; then
        # PCI device IDs for MT7925/MT7927 variants - these ARE 6GHz capable
        CHIP_6GHZ_CAPABLE=true
    elif echo "$CHIP_MODEL" | grep -qi "ax210\|ax211\|be200\|wcn7850"; then
        CHIP_6GHZ_CAPABLE=true
    fi
    
    # Method 6: Driver name detection (mt7925e driver indicates 6GHz capability)
    DRIVER_6GHZ_CAPABLE=false
    if echo "$DRIVER" | grep -qi "mt7925e"; then
        DRIVER_6GHZ_CAPABLE=true
    elif echo "$DRIVER" | grep -qi "iwlwifi" && echo "$CHIP_MODEL" | grep -qi "ax210\|ax211\|be200"; then
        DRIVER_6GHZ_CAPABLE=true
    fi
    
    # Determine 6GHz support using multiple evidence sources
    if [ -n "$SUPPORTS_6GHZ_BAND3" ]; then
        supports_6ghz=true
        detection_method="iw phy Band 3"
    elif [ -n "$SUPPORTS_6GHZ_ALT" ]; then
        supports_6ghz=true  
        detection_method="frequency scan"
    elif [ "$CURRENT_FREQ_CHECK" = true ]; then
        supports_6ghz=true
        detection_method="active 6GHz connection"
    elif [ "$SCAN_6GHZ" -gt 0 ]; then
        supports_6ghz=true
        detection_method="6GHz networks detected ($SCAN_6GHZ found)"
    elif [ "$CHIP_6GHZ_CAPABLE" = true ]; then
        supports_6ghz=true
        detection_method="Known 6GHz hardware: $CHIP_MODEL"
    elif [ "$DRIVER_6GHZ_CAPABLE" = true ]; then
        supports_6ghz=true
        detection_method="6GHz-capable driver: $DRIVER"
    fi
    
    # Report results
    if [ "$supports_6ghz" = true ]; then
        echo "   ✅ Hardware: WiFi 6E/7 with 6GHz support confirmed"
        echo "   🔍 Detection method: $detection_method"
        
        # Current connection analysis
        if [ "$CURRENT_FREQ_CHECK" = true ]; then
            echo "   🌟 Currently connected to 6GHz spectrum ($CURRENT_FREQ MHz)"
            echo "   🚀 Excellent choice - 6GHz provides clean spectrum with minimal interference"
            echo "   ✅ 6GHz band: NO DFS channels - no radar interference possible"
        else
            echo "   📊 Currently on ${CURRENT_BAND:-unknown band}, but 6GHz available"
            echo "   💡 Consider switching to 6GHz for cleaner spectrum"
            echo "   🌟 6GHz advantage: NO DFS channels means no radar-related disconnections"
            
            # Enhanced troubleshooting for specific chips
            if echo "$WIFI_HARDWARE" | grep -qi "device 0717"; then
                echo "   🧪 MT7925 note: Latest WiFi 7 chip with full 6GHz support"
                echo "   💡 Try: sudo iw reg set US && sudo nmcli radio wifi off && sudo nmcli radio wifi on"
                echo "   💡 Or check router has 6GHz enabled and broadcasting"
            elif echo "$CHIP_MODEL" | grep -qi "mt7922"; then
                echo "   🧪 MT7922 note: 6GHz support may require regulatory domain setup"
                echo "   💡 Try: sudo iw reg set US && sudo nmcli radio wifi off && sudo nmcli radio wifi on"
            fi
        fi
        
        # Show 6GHz network availability if scan worked - ENHANCED FIXED logic
        if [ -n "$SCAN_6GHZ" ] && [ "$SCAN_6GHZ" -gt 0 ]; then
           echo "   📡 Found $SCAN_6GHZ available 6GHz networks in area"
           
           # Show 6GHz network details if current connection is 6GHz
           if [ "$CURRENT_FREQ_CHECK" = true ]; then
               echo "   🌟 You're connected to one of these 6GHz networks!"
           else
               echo "   💡 Consider switching to 6GHz for access to these clean spectrum networks"
           fi
        else
           echo "   📡 No 6GHz networks currently visible in detailed scan"
           echo "   💡 Your hardware supports 6GHz, but no 6GHz networks detected in range"
           echo "   💡 Router may need 6GHz enabled or be out of range"
        fi
        
    else
        echo "   ❌ No 6GHz capability detected in hardware"
        echo "   🧪 Note: Some WiFi 6E cards require specific firmware/driver versions"
        
        # Special case for known 6GHz hardware that isn't detected
        if [ "$CHIP_6GHZ_CAPABLE" = true ] || [ "$DRIVER_6GHZ_CAPABLE" = true ]; then
            echo "   ⚠️ WARNING: Hardware/driver suggests 6GHz capability but not detected"
            echo "   💡 Possible fixes:"
            echo "      • Update firmware: sudo apt update && sudo apt upgrade linux-firmware"
            echo "      • Set regulatory domain: sudo iw reg set US"
            echo "      • Check kernel version (6GHz requires 6.2+)"
            echo "      • Verify router has 6GHz enabled"
        fi
    fi
}

# Enhanced system intelligence gathering with modern chipset support AND power save detection
gather_system_intelligence() {
    echo -e "${CYAN}🧠 === ENHANCED SYSTEM INTELLIGENCE GATHERING ===${NC}"
    
    # Detect distribution first
    detect_distribution
    echo "🐧 Distribution: $DISTRO_NAME"
    
    # Get interface with fallback methods
    IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep dev | awk '{print $5}')
    if [ -z "$IFACE" ]; then
        IFACE=$(nmcli -t -f DEVICE,TYPE device status | grep wifi | head -1 | cut -d: -f1)
    fi
    if [ -z "$IFACE" ]; then
        IFACE=$(iw dev 2>/dev/null | awk '/Interface/ {print $2; exit}')
    fi
    
    echo "🔍 WiFi Interface: ${IFACE:-❌ Not found}"
    
    # Test WiFi functionality - SINGLE SOURCE OF TRUTH
    WIFI_FUNCTIONAL=$(test_wifi_functionality)
    echo "🔧 WiFi Functional Status: $([ "$WIFI_FUNCTIONAL" = "true" ] && echo "✅ WORKING" || echo "❌ BROKEN")"
    
    # Deep hardware analysis with modern chipset support
    WIFI_HARDWARE=$(lspci | grep -i "network\|wireless" | head -1)
    echo "🔧 Hardware: $WIFI_HARDWARE"
    
    # Analyze modern chipsets 
    analyze_modern_chipsets
    
    echo "📊 Chip Analysis:"
    echo "   Vendor: ${CHIP_VENDOR:-Unknown}"
    echo "   Model: ${CHIP_MODEL:-Unknown}"
    echo "   Generation: ${CHIP_GENERATION:-Unknown}"
    echo "   Known Issues: ${KNOWN_ISSUES:-Generally stable}"
    
    # Driver and firmware intelligence
    if [ -n "$IFACE" ]; then
        DRIVER=$(ls -l /sys/class/net/$IFACE/device/driver/module 2>/dev/null | awk -F/ '{print $NF}')
        echo "🚗 Driver: ${DRIVER:-Unknown}"
        
        # Driver version and build info
        if [ -n "$DRIVER" ]; then
            DRIVER_VERSION=$(modinfo "$DRIVER" 2>/dev/null | grep "^version:" | awk '{print $2}')
            DRIVER_DATE=$(modinfo "$DRIVER" 2>/dev/null | grep "^srcversion:" | awk '{print $2}')
            echo "   Version: ${DRIVER_VERSION:-Unknown}"
            echo "   Build ID: ${DRIVER_DATE:-Unknown}"
        fi
        
        # Power Management Analysis - NEW ADDITION
        echo ""
        echo "🔋 Power Management Analysis:"
        POWER_SAVE=$(iw dev "$IFACE" get power_save 2>/dev/null | grep "Power save:" | awk '{print $3}')
        if [ -n "$POWER_SAVE" ]; then
            case "$POWER_SAVE" in
                "on")
                    echo "   ⚠️ Power Save: ON (may cause disconnections)"
                    echo "   💡 Consider disabling: sudo iw dev $IFACE set power_save off"
                    ;;
                "off")
                    echo "   ✅ Power Save: OFF (optimal for stability)"
                    ;;
                *)
                    echo "   🔍 Power Save: $POWER_SAVE"
                    ;;
            esac
        else
            echo "   ❓ Power Save: Unable to detect (driver may not support query)"
            echo "   💡 Try manually: iw dev $IFACE get power_save"
        fi
        
        # Check for ASPM status if MediaTek - FIXED to target only WiFi device
        if echo "$CHIP_MODEL" | grep -qi "mt79"; then
            # Get WiFi PCI device ID specifically
            WIFI_PCI_ID=$(lspci | grep -i wireless | awk '{print $1}' | head -1)
            if [ -n "$WIFI_PCI_ID" ]; then
                ASMP_STATUS=$(lspci -vv -s "$WIFI_PCI_ID" 2>/dev/null | grep "LnkCtl:" | grep -o "ASPM [^;]*")
                if [ -n "$ASMP_STATUS" ]; then
                    echo "   🔗 PCIe ASPM: $ASMP_STATUS"
                    if echo "$ASMP_STATUS" | grep -q "L1"; then
                        echo "   💡 ASPM L1 active - may cause MediaTek issues"
                        echo "   💡 Consider: pcie_aspm=off kernel parameter"
                    fi
                fi
            fi
        fi
        
        # Distribution-aware firmware analysis
        case "$DISTRO_ID" in
            "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
                FIRMWARE_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' linux-firmware 2>/dev/null || echo "Unknown")
                ;;
            "ubuntu"|"debian"|"pop"|"mint"|"linuxmint")
                FIRMWARE_VERSION=$(dpkg -l linux-firmware 2>/dev/null | grep "^ii" | awk '{print $3}' || echo "Unknown")
                ;;
            "arch"|"manjaro"|"endeavouros")
                FIRMWARE_VERSION=$(pacman -Q linux-firmware 2>/dev/null | awk '{print $2}' || echo "Unknown")
                ;;
            *)
                FIRMWARE_VERSION="Unknown"
                ;;
        esac
        
        echo ""
        echo "📦 Firmware: $FIRMWARE_VERSION"
        
        # Kernel compatibility check
        KERNEL_VERSION=$(uname -r)
        echo "🐧 Kernel: $KERNEL_VERSION"
        
        # Modern kernel recommendations
        KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f1)
        KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f2)
        
        if [ "$KERNEL_MAJOR" -ge 6 ] && [ "$KERNEL_MINOR" -ge 8 ]; then
            echo "   ✅ Modern kernel with WiFi 7 support"
        elif [ "$KERNEL_MAJOR" -ge 6 ] && [ "$KERNEL_MINOR" -ge 5 ]; then
            echo "   📊 Good kernel with WiFi 6E support"
        else
            echo "   ⚠️ Older kernel - consider upgrading for modern WiFi features"
        fi
    fi
    
    echo ""
}

# Distribution-aware workaround system
provide_distribution_specific_workarounds() {
    local issue_type="$1"
    
    echo ""
    echo -e "${CYAN}🐧 Distribution-Specific Commands for $DISTRO_NAME:${NC}"
    echo ""
    
    case "$issue_type" in
        "DRIVER_ERROR")
            echo "1. MediaTek-specific kernel parameter workaround:"
            echo ""
            # MediaTek-specific explanation
            if echo "$CHIP_MODEL" | grep -qi "mt79"; then
                echo -e "${GREEN}✅ MediaTek chipset detected: $CHIP_MODEL${NC}"
                echo "   💡 Possible Fix When Drops Are Due to PCI Config Errors:"
                echo "   Some MediaTek chipsets (like mt7921e or mt7925e) suffer from unstable"
                echo "   PCIe behavior, especially on AMD-based laptops or quirky ACPI tables"
                echo "   (common in early Framework AMD laptops). If your dmesg/journal logs show"
                echo "   PCI-related errors (e.g. config read failures, bus enumeration issues),"
                echo "   pci=nommconf might stabilize the bus behavior."
                echo ""
                echo -e "${RED}❌ Won't Help for Firmware Bugs or ASPM Issues:${NC}"
                echo "   This won't fix issues caused by:"
                echo "   • ASPM power saving (pcie_aspm=off or policy=performance is needed)"
                echo "   • Firmware regressions (need linux-firmware downgrades or kernel patches)"
                echo "   • Power management instability (need iw dev ... set power_save off)"
                echo "   • DFS radar interference (need non-DFS channels)"
                echo ""
                echo "   📋 Check logs first: dmesg | grep -E 'mt79|pci.*error|config.*read'"
                echo ""
            else
                echo "   💡 Generic PCI configuration workaround (may help with PCIe issues)"
                echo ""
            fi
            
            if [ "$DISTRO_ID" = "fedora" ] || [ "$DISTRO_ID" = "rhel" ]; then
                echo "   🔒 PERMANENT (kernel parameter): $(get_distro_command "kernel_param")'pci=nommconf'"
                echo "   🔒 PERMANENT (GRUB update): $(get_distro_command "grub_update")"
            else
                echo "   🔒 PERMANENT (kernel parameter): $(get_distro_command "kernel_param")'pci=nommconf'"
                echo "   🔒 PERMANENT (GRUB update): $(get_distro_command "grub_update")"
            fi
            echo "   ⚠️ REQUIRES REBOOT: sudo reboot"
            echo ""
            echo "2. Firmware update (try this first):"
            echo "   🔒 PERMANENT (system upgrade): $(get_distro_command "firmware_update")"
            echo "   ⚠️ REQUIRES REBOOT: After dnf, apt, bootc/rpm-ostree upgrade"
            echo ""
            echo "3. Initrd rebuild:"
            echo "   🔒 PERMANENT (initramfs update): $(get_distro_command "initrd_update")"
            echo "   ⚠️ REQUIRES REBOOT: sudo reboot"
            echo ""
            
            # MediaTek-specific additional fixes
            if echo "$CHIP_MODEL" | grep -qi "mt79"; then
                echo "4. MediaTek-specific additional fixes:"
                echo ""
                echo "   a) ASPM power management issues:"
                echo "      🔒 PERMANENT (module config): echo 'options mt7921e disable_aspm=1' | sudo tee /etc/modprobe.d/mt7921e.conf"
                echo "      🔒 PERMANENT (apply config): $(get_distro_command "initrd_update")"
                echo "      ⚠️ REQUIRES REBOOT: After initrd rebuild"
                echo ""
                echo "   b) Power management workaround:"
                echo "      ⏰ TEMPORARY (until reboot): sudo iw dev $IFACE set power_save off"
                echo "      🔒 PERMANENT: Use modprobe option above instead"
                echo ""
                echo "   c) Alternative ASPM kernel parameter:"
                echo "      🔒 PERMANENT (kernel param): $(get_distro_command "kernel_param")'pcie_aspm=off'"
                echo "      🔒 PERMANENT (GRUB update): $(get_distro_command "grub_update")"
                echo "      ⚠️ REQUIRES REBOOT: After GRUB configuration"
                echo ""
                echo "   💡 Try solutions in order: firmware update → power_save off → ASPM fixes → PCI workarounds"
                echo "   🧪 TESTING STRATEGY: Apply temporary fixes first to verify they work before making permanent"
            fi
            
            # DFS-specific fixes if applicable
            if [ "$DFS_IMPACT_SCORE" -gt 50 ]; then
                echo ""
                echo "5. DFS-specific fixes (radar interference detected):"
                echo ""
                echo "   a) Immediate non-DFS channel switch:"
                if [ -n "$CURRENT_SSID" ]; then
                    echo "      ⏰ IMMEDIATE: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                    echo "      ⏰ IMMEDIATE: sudo nmcli connection up \"$CURRENT_SSID\""
                fi
                echo ""
                echo "   b) Router configuration (CRITICAL):"
                echo "      🔒 PERMANENT: Set router to channels 36, 40, 44, 48 (non-DFS)"
                echo "      🔒 PERMANENT: Alternative: channels 149, 153, 157, 161, 165 (non-DFS)"
                echo "      🔒 PERMANENT: Disable automatic channel selection"
                echo ""
                echo "   c) 6GHz migration (NO DFS in 6GHz):"
                if [ "$SUPPORTS_WIFI7" = true ]; then
                    echo "      🌟 Your hardware supports 6GHz - upgrade to WiFi 6E/7 router"
                    echo "      💡 6GHz band is completely DFS-free"
                fi
            fi
            ;;
        "FIRMWARE_CRASH")
            echo "1. Update firmware (most important for MediaTek):"
            echo "   🔒 PERMANENT (system upgrade): $(get_distro_command "firmware_update")"
            echo "   ⚠️ REQUIRES REBOOT: After firmware update"
            echo ""
            
            if echo "$CHIP_MODEL" | grep -qi "mt79"; then
                echo "2. MediaTek-specific module configuration:"
                echo "   🔒 PERMANENT (module config): echo 'options mt7921e disable_aspm=1' | sudo tee /etc/modprobe.d/mt7921e.conf"
                echo "   🔒 PERMANENT (power config): echo 'options mt7921e power_save=0' | sudo tee -a /etc/modprobe.d/mt7921e.conf"
                echo "   🔒 PERMANENT (apply config): $(get_distro_command "initrd_update")"
                echo "   ⚠️ REQUIRES REBOOT: After initrd rebuild"
            else
                echo "2. Module configuration:"
                echo "   🔒 PERMANENT (module config): echo 'options $DRIVER disable_aspm=1' | sudo tee /etc/modprobe.d/$DRIVER.conf"
                echo "   🔒 PERMANENT (apply config): $(get_distro_command "initrd_update")"
                echo "   ⚠️ REQUIRES REBOOT: After initrd rebuild"
            fi
            ;;
    esac
}

# TX Power Band Test - COMPLETE IMPLEMENTATION
tx_power_band_test() {
    echo -e "${BOLD}${BLUE}🧪 === TX POWER BAND TEST ===${NC}"
    echo "🔍 Testing transmission power limitations across different bands"
    echo ""
    
    # Quick system check first
    gather_system_intelligence >/dev/null 2>&1
    
    if [ -z "$IFACE" ]; then
        echo "❌ No WiFi interface available for testing"
        return 1
    fi
    
    echo "🎯 Current System Analysis:"
    echo "   Interface: $IFACE"
    echo "   Chip: ${CHIP_VENDOR:-Unknown} ${CHIP_MODEL:-Unknown}"
    echo "   Driver: ${DRIVER:-Unknown}"
    echo ""
    
    # Get current TX power
    CURRENT_TX_POWER=$(iw dev "$IFACE" info 2>/dev/null | grep "txpower" | awk '{print $2, $3}')
    echo "📊 Current TX Power: ${CURRENT_TX_POWER:-Unable to detect}"
    echo ""
    
    # Test TX power changes on different power levels
    echo "🧪 Testing TX power control capabilities:"
    echo ""
    
    # Store original power for restoration
    echo ""
    echo "🎯 Band-specific TX Power Analysis:"
    echo ""
    
    # Get current connection info for band analysis
    WIFI_INFO=$(iw dev "$IFACE" link 2>/dev/null)
    if echo "$WIFI_INFO" | grep -q "Connected to"; then
        CURRENT_FREQ=$(echo "$WIFI_INFO" | grep "freq:" | awk '{print $2}')
        CURRENT_SIGNAL=$(echo "$WIFI_INFO" | grep "signal:" | awk '{print $2}')
        
        if [ -n "$CURRENT_FREQ" ]; then
            FREQ_INT=$(echo "$CURRENT_FREQ" | cut -d'.' -f1)
            
            if [ "$FREQ_INT" -ge 2400 ] && [ "$FREQ_INT" -le 2500 ]; then
                CURRENT_BAND="2.4 GHz"
                echo "📡 Currently on 2.4GHz band:"
                echo "   • Typical max TX power: 20dBm (100mW)"
                echo "   • Range: Good penetration through walls"
                echo "   • Congestion: Usually high in urban areas"
            elif [ "$FREQ_INT" -ge 5000 ] && [ "$FREQ_INT" -le 6000 ]; then
                CURRENT_BAND="5 GHz"
                echo "📡 Currently on 5GHz band:"
                echo "   • Typical max TX power: 20-23dBm (100-200mW)"
                echo "   • Range: Shorter than 2.4GHz but less congested"
                echo "   • DFS channels: May have radar interference"
            elif [ "$FREQ_INT" -ge 6000 ] && [ "$FREQ_INT" -le 7200 ]; then
                CURRENT_BAND="6 GHz"
                echo "📡 Currently on 6GHz band (WiFi 6E/7):"
                echo "   • Typical max TX power: 20dBm (100mW)"
                echo "   • Range: Shortest but cleanest spectrum"
                echo "   • DFS channels: NONE - completely DFS-free!"
            fi
            
            echo "   • Current frequency: $CURRENT_FREQ MHz"
            echo "   • Current signal: ${CURRENT_SIGNAL:-Unknown} dBm"
        fi
    else
        echo "❌ Not connected - cannot analyze current band"
    fi
    
    echo ""
    echo "🎯 Regulatory Domain Impact:"
    echo ""
    
    REG_INFO=$(iw reg get 2>/dev/null)
    if [ -n "$REG_INFO" ]; then
        REG_COUNTRY=$(echo "$REG_INFO" | grep "country" | head -1 | awk '{print $2}' | tr -d ':')
        echo "📍 Current regulatory domain: ${REG_COUNTRY:-Global}"
        
        case "$REG_COUNTRY" in
            "US")
                echo "   • 2.4GHz: Max 30dBm EIRP (1W)"
                echo "   • 5GHz low: Max 30dBm EIRP (1W)"
                echo "   • 5GHz high: Max 30dBm EIRP (1W)"
                echo "   • 6GHz: Max 30dBm EIRP (1W)"
                ;;
            "EU"|"DE"|"FR"|"GB")
                echo "   • 2.4GHz: Max 20dBm EIRP (100mW)"
                echo "   • 5GHz: Max 23dBm EIRP (200mW)"
                echo "   • 6GHz: Max 23dBm EIRP (200mW)"
                ;;
            "JP")
                echo "   • 2.4GHz: Max 20dBm EIRP (100mW)"
                echo "   • 5GHz: Max 20dBm EIRP (100mW)"
                echo "   • 6GHz: Varies by channel"
                ;;
            *)
                echo "   • Check local regulations for your country"
                echo "   • Set correct domain: sudo iw reg set [COUNTRY_CODE]"
                ;;
        esac
    else
        echo "❓ Cannot determine regulatory domain"
        echo "💡 Set manually: sudo iw reg set US (or your country code)"
    fi
    
    echo ""
    echo "🎯 Chipset-Specific TX Power Behavior:"
    echo ""
    
    case "$CHIP_VENDOR" in
        "MediaTek")
            echo "📊 MediaTek chipset behavior:"
            echo "   • Manual TX power: Often ignored by driver"
            echo "   • Automatic control: Usually works well"
            echo "   • Regional limits: Strictly enforced"
            echo "   • Recommendation: Use auto mode, optimize router-side"
            ;;
        "Intel")
            echo "📊 Intel chipset behavior:"
            echo "   • Manual TX power: Limited by regulatory database"
            echo "   • Automatic control: Excellent dynamic adjustment"
            echo "   • Regional limits: Strictly enforced"
            echo "   • Recommendation: Ensure correct regulatory domain"
            ;;
        "Qualcomm")
            echo "📊 Qualcomm chipset behavior:"
            echo "   • Manual TX power: Better support than MediaTek"
            echo "   • Automatic control: Good"
            echo "   • Regional limits: Enforced"
            echo "   • Recommendation: Manual adjustment may work"
            ;;
        *)
            echo "📊 Generic chipset recommendations:"
            echo "   • Try auto mode first"
            echo "   • Check regulatory domain setting"
            echo "   • Monitor for driver restrictions"
            ;;
    esac
    
    echo ""
    echo "💡 TX Power Optimization Recommendations:"
    echo ""
    echo "1. For better range:"
    echo "   • Ensure correct regulatory domain: sudo iw reg set [COUNTRY]"
    echo "   • Optimize router TX power settings"
    echo "   • Consider external antennas if supported"
    echo ""
    echo "2. For MediaTek cards specifically:"
    echo "   • Router-side power optimization more effective"
    echo "   • Use 2.4GHz for maximum range"
    echo "   • Avoid DFS channels (radar interference)"
    echo ""
    echo "3. For 6GHz optimization:"
    if [ "$SUPPORTS_WIFI7" = true ]; then
        echo "   ✅ Your hardware supports 6GHz"
        echo "   • 6GHz = shortest range but cleanest spectrum"
        echo "   • NO DFS interference possible"
        echo "   • Best for high-speed, short-distance connections"
    else
        echo "   💡 Upgrade to WiFi 6E/7 for 6GHz access"
        echo "   • 6GHz provides DFS-free operation"
        echo "   • Clean spectrum with minimal interference"
    fi
    
    echo ""
    echo "📋 Quick Commands for Testing:"
    echo "   • Check current power: iw dev $IFACE info | grep txpower"
    echo "   • Test signal strength: watch -n 1 'iw dev $IFACE link | grep signal'"
    echo "   • Speed test: speedtest-cli"
    echo ""
}

# Manual Band Switching - COMPLETE IMPLEMENTATION
manual_band_switching() {
    echo -e "${BOLD}${GREEN}📡 === MANUAL BAND SWITCHING ===${NC}"
    echo "🎯 Direct CLI commands for switching between WiFi bands"
    echo ""
    
    # Quick system check
    gather_system_intelligence >/dev/null 2>&1
    
    if [ -z "$IFACE" ]; then
        echo "❌ No WiFi interface available"
        return 1
    fi
    
    # Get current connection
    ACTIVE_CONNECTION=$(nmcli -t connection show --active | grep -E "wifi|802-11-wireless" | head -1 | cut -d: -f1)
    
    if [ -z "$ACTIVE_CONNECTION" ]; then
        echo "❌ No active WiFi connection detected"
        echo "💡 Connect to WiFi first, then run band switching"
        return 1
    fi
    
    echo "📡 Current active connection: $ACTIVE_CONNECTION"
    
    # Get current connection details
    CURRENT_FREQ=$(iw dev "$IFACE" link 2>/dev/null | grep "freq:" | awk '{print $2}')
    CURRENT_SIGNAL=$(iw dev "$IFACE" link 2>/dev/null | grep "signal:" | awk '{print $2}')
    
    if [ -n "$CURRENT_FREQ" ]; then
        FREQ_INT=$(echo "$CURRENT_FREQ" | cut -d'.' -f1)
        
        if [ "$FREQ_INT" -ge 2400 ] && [ "$FREQ_INT" -le 2500 ]; then
            CURRENT_BAND_DISPLAY="2.4 GHz"
        elif [ "$FREQ_INT" -ge 5000 ] && [ "$FREQ_INT" -le 6000 ]; then
            CURRENT_BAND_DISPLAY="5 GHz"
        elif [ "$FREQ_INT" -ge 6000 ] && [ "$FREQ_INT" -le 7200 ]; then
            CURRENT_BAND_DISPLAY="6 GHz (WiFi 6E/7)"
        else
            CURRENT_BAND_DISPLAY="Unknown"
        fi
    else
        CURRENT_BAND_DISPLAY="Unknown"
    fi
    
    echo "📊 Current status:"
    echo "   Band: $CURRENT_BAND_DISPLAY"
    echo "   Frequency: ${CURRENT_FREQ:-Unknown} MHz"
    echo "   Signal: ${CURRENT_SIGNAL:-Unknown} dBm"
    echo ""
    
    echo -e "${CYAN}🎯 === BAND SWITCHING COMMANDS ===${NC}"
    echo ""
    
    echo "1) 🔵 Force 2.4GHz Band (Maximum Range)"
    echo "   Command: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band bg"
    echo "   Effect: Forces connection to 2.4GHz only"
    echo "   Use for: Maximum range, penetration through walls"
    echo "   DFS risk: ZERO (no DFS channels in 2.4GHz)"
    echo ""
    
    echo "2) 🟢 Force 5GHz Band (Balanced Performance)"
    echo "   Command: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band a"
    echo "   Effect: Forces connection to 5GHz only"
    echo "   Use for: Better speed, less congestion"
    echo "   DFS risk: MEDIUM (some 5GHz channels use DFS)"
    echo ""
    
    echo "3) 🟡 Auto Band Selection (Default)"
    echo "   Command: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band ''"
    echo "   Effect: Allows automatic band selection"
    echo "   Use for: Let system choose best band"
    echo "   DFS risk: VARIES (depends on router channel selection)"
    echo ""
    
    # 6GHz options only if supported
    if [ "$SUPPORTS_WIFI7" = true ] || echo "$CHIP_MODEL" | grep -qi "6E"; then
        echo "4) 🔴 6GHz Band Access (WiFi 6E/7 - Clean Spectrum)"
        echo "   Note: 6GHz typically included in 5GHz 'a' band setting"
        echo "   Command: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band a"
        echo "   Requirement: Router must broadcast 6GHz SSID"
        echo "   DFS risk: ZERO (NO DFS channels exist in 6GHz)"
        echo "   💡 6GHz advantages: Clean spectrum, no radar interference"
        echo ""
    fi
    
    echo -e "${CYAN}🔧 === SPECIFIC CHANNEL SELECTION ===${NC}"
    echo ""
    
    echo "Safe 5GHz Channels (NO DFS - No Radar Interference):"
    echo "   Low band: 36, 40, 44, 48"
    echo "   • Channel 36: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 36"
    echo "   • Channel 44: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 44"
    echo ""
    echo "   High band: 149, 153, 157, 161, 165"
    echo "   • Channel 149: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 149"
    echo "   • Channel 157: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 157"
    echo ""
    
    echo "⚠️ Avoid These Channels (DFS - Radar Interference Risk):"
    echo "   DFS channels: 52, 56, 60, 64, 100-144"
    echo "   💡 These channels can cause sudden 30+ second disconnections"
    echo ""
    
    echo -e "${CYAN}🧪 === INTERACTIVE BAND SWITCHING ===${NC}"
    echo ""
    echo "Would you like to switch bands now? [y/N]"
    read -r switch_choice
    
    if [[ "$switch_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Select band to switch to:"
        echo "1) 2.4GHz (maximum range, DFS-free)"
        echo "2) 5GHz (balanced performance, some DFS risk)"
        echo "3) Auto selection (system chooses)"
        if [ "$SUPPORTS_WIFI7" = true ]; then
            echo "4) Force specific safe channel (recommended)"
        fi
        echo "5) Cancel"
        echo ""
        echo -n "Choice [1-5]: "
        read -r band_choice
        
        case $band_choice in
            1)
                echo "🔵 Switching to 2.4GHz band..."
                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band bg; then
                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                    echo "✅ Switched to 2.4GHz band"
                    echo "💡 This provides maximum range and is completely DFS-free"
                else
                    echo "❌ Failed to switch to 2.4GHz"
                fi
                ;;
            2)
                echo "🟢 Switching to 5GHz band..."
                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a; then
                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                    echo "✅ Switched to 5GHz band"
                    echo "⚠️ Monitor for DFS-related disconnections"
                else
                    echo "❌ Failed to switch to 5GHz"
                fi
                ;;
            3)
                echo "🟡 Enabling automatic band selection..."
                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band ""; then
                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                    echo "✅ Enabled automatic band selection"
                else
                    echo "❌ Failed to enable auto selection"
                fi
                ;;
            4)
                if [ "$SUPPORTS_WIFI7" = true ]; then
                    # Detect network type (mesh, hotspot, single-band)
                    MESH_DETECTED=false
                    HOTSPOT_DETECTED=false
                    SUPPORTS_5GHZ=true
                    SUPPORTS_24GHZ=true
                    
                    # Get current SSID if not already set
if [ -z "$CURRENT_SSID" ]; then
    CURRENT_SSID=$(iw dev "$IFACE" link 2>/dev/null | grep "SSID:" | awk '{print $2}')
    if [ -z "$CURRENT_SSID" ]; then
        CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    fi
fi

# Check for hotspots and band capabilities FIRST
if echo "$CURRENT_SSID" | grep -qi "iphone\|android\|hotspot\|mobile\|pixel_\|galaxy_\|oneplus_\|xiaomi_\|huawei_\|samsung_\|nokia_\|motorola_\|lg_\|sony_\|oppo_\|vivo_\|realme_\|htc_" || \
   echo "$CURRENT_SSID" | grep -qE "^[A-Za-z]+_[0-9]{3,4}$" || \
   echo "$CURRENT_SSID" | grep -qE "^[A-Za-z]+'s (iPhone|Android|Phone)" || \
   echo "$CURRENT_SSID" | grep -qi "phone\|tether\|share\|wifi.*direct\|portable.*wifi"; then
    HOTSPOT_DETECTED=true
fi

# Check for mesh networks (improved logic - after hotspot detection)
if echo "$CURRENT_SSID" | grep -qi "eero\|orbi\|deco\|velop\|amplifi\|nest"; then
    MESH_DETECTED=true
elif [ "$HOTSPOT_DETECTED" = false ]; then
    # Only consider it mesh if we find MANY similar SSIDs (3+ nodes typical for mesh)
    BASE_SSID=$(echo "$CURRENT_SSID" | sed 's/_5G\|_2G\|_6G\|-5G\|-2G\|-6G//')
    SIMILAR_SSID_COUNT=$(nmcli -t -f SSID dev wifi | grep -c "$BASE_SSID" 2>/dev/null || echo "0")
    
    # Mesh networks typically have 3+ nodes broadcasting
    if [ "$SIMILAR_SSID_COUNT" -ge 3 ]; then
        MESH_DETECTED=true
    fi
fi
                    
                    # Get scan results if not already available
if [ -z "$SCAN_RESULTS" ]; then
    echo "🔍 Scanning for available bands..."
    SCAN_RESULTS=$(timeout 15 iw dev "$IFACE" scan 2>/dev/null)
fi

# For connected networks, use current connection info instead of scan
CURRENT_CONNECTION_FREQ=$(iw dev "$IFACE" link 2>/dev/null | grep "freq:" | awk '{print $2}')

# Check actual band availability for this network
if [ -n "$CURRENT_CONNECTION_FREQ" ]; then
    # We're connected - use current connection frequency to determine bands
    FREQ_INT=$(echo "$CURRENT_CONNECTION_FREQ" | cut -d'.' -f1)
    
    if [ "$FREQ_INT" -ge 2400 ] && [ "$FREQ_INT" -le 2500 ]; then
        # Connected on 2.4GHz - this network definitely supports 2.4GHz
        SUPPORTS_24GHZ=true
        # Check if we can find 5GHz for this SSID in scan results
        if ! echo "$SCAN_RESULTS" | grep -A1 "SSID: $CURRENT_SSID" | grep -q "freq: 5[0-9][0-9][0-9]"; then
            SUPPORTS_5GHZ=false
        fi
    elif [ "$FREQ_INT" -ge 5000 ] && [ "$FREQ_INT" -le 6000 ]; then
        # Connected on 5GHz - this network definitely supports 5GHz
        SUPPORTS_5GHZ=true
        # Check if we can find 2.4GHz for this SSID in scan results
        if ! echo "$SCAN_RESULTS" | grep -A1 "SSID: $CURRENT_SSID" | grep -q "freq: 24[0-9][0-9]"; then
            SUPPORTS_24GHZ=false
        fi
    fi
elif [ -n "$SCAN_RESULTS" ]; then
    # Not connected - use scan results
    if ! echo "$SCAN_RESULTS" | grep -A1 "SSID: $CURRENT_SSID" | grep -q "freq: 5[0-9][0-9][0-9]"; then
        SUPPORTS_5GHZ=false
    fi
    if ! echo "$SCAN_RESULTS" | grep -A1 "SSID: $CURRENT_SSID" | grep -q "freq: 24[0-9][0-9]"; then
        SUPPORTS_24GHZ=false
    fi
fi

                    # Handle single-band networks first
                    if [ "$SUPPORTS_5GHZ" = false ] && [ "$SUPPORTS_24GHZ" = true ]; then
                        echo ""
                        echo "📱 2.4GHz-ONLY NETWORK DETECTED"
                        if [ "$HOTSPOT_DETECTED" = true ]; then
                            echo "(Likely mobile hotspot - most only support 2.4GHz)"
                        fi
                        echo ""
                        echo "This network only broadcasts on 2.4GHz band."
                        echo "5GHz switching is not available for this network."
                        echo ""
                        echo "Available options:"
                        echo "1) Stay on 2.4GHz (only option for this network)"
                        echo "2) Reset to auto"
                        echo ""
                        echo -n "Choose option [1-2]: "
                        read -r single_band_choice
                        
                        case $single_band_choice in
                            1)
                                echo "🔵 Confirming 2.4GHz connection..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band bg; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Confirmed 2.4GHz connection (only available band)"
                                else
                                    echo "❌ Failed to confirm 2.4GHz connection"
                                fi
                                ;;
                            2)
                                echo "🔄 Resetting to auto..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band ""; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Reset to auto (will use 2.4GHz anyway)"
                                else
                                    echo "❌ Failed to reset to auto"
                                fi
                                ;;
                            *)
                                echo "❌ Invalid choice"
                                ;;
                        esac
                    elif [ "$SUPPORTS_24GHZ" = false ] && [ "$SUPPORTS_5GHZ" = true ]; then
                        echo ""
                        echo "📡 5GHz-ONLY NETWORK DETECTED"
                        echo ""
                        echo "This network only broadcasts on 5GHz band."
                        echo "2.4GHz switching is not available for this network."
                        echo ""
                        echo "Available options:"
                        echo "1) Stay on 5GHz (only option for this network)"
                        echo "2) Reset to auto"
                        echo ""
                        echo -n "Choose option [1-2]: "
                        read -r single_band_choice
                        
                        case $single_band_choice in
                            1)
                                echo "🟢 Confirming 5GHz connection..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Confirmed 5GHz connection (only available band)"
                                else
                                    echo "❌ Failed to confirm 5GHz connection"
                                fi
                                ;;
                            2)
                                echo "🔄 Resetting to auto..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band ""; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Reset to auto (will use 5GHz anyway)"
                                else
                                    echo "❌ Failed to reset to auto"
                                fi
                                ;;
                            *)
                                echo "❌ Invalid choice"
                                ;;
                        esac
                    elif [ "$MESH_DETECTED" = true ]; then
                        echo ""
                        echo "🌐 MESH NETWORK DETECTED - Modified approach:"
                        echo ""
                        echo "Mesh networks manage channels automatically. Instead of forcing"
                        echo "specific channels, try these mesh-friendly approaches:"
                        echo ""
                        echo "1) Force 2.4GHz (mesh usually has dedicated 2.4GHz nodes)"
                        echo "2) Force 5GHz (let mesh choose best 5GHz channel)"
                        echo "3) Reset to auto (recommended for mesh)"
                        echo ""
                        echo -n "Choose approach [1-3]: "
                        read -r mesh_choice
                        
                        case $mesh_choice in
                            1)
                                echo "🔵 Forcing 2.4GHz for mesh compatibility..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band bg; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Switched to 2.4GHz (mesh will choose optimal 2.4GHz channel)"
                                else
                                    echo "❌ Failed to switch to 2.4GHz"
                                fi
                                ;;
                            2)
                                echo "🟢 Forcing 5GHz for mesh compatibility..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Switched to 5GHz (mesh will choose optimal 5GHz channel)"
                                else
                                    echo "❌ Failed to switch to 5GHz"
                                fi
                                ;;
                            3)
                                echo "🔄 Resetting to auto for optimal mesh performance..."
                                if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band "" && \
                                   sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.channel ""; then
                                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                                    echo "✅ Reset to auto (recommended for mesh networks)"
                                else
                                    echo "❌ Failed to reset to auto"
                                fi
                                ;;
                            *)
                                echo "❌ Invalid choice"
                                ;;
                        esac
                    else
                        echo ""
                        echo "Select safe channel (no DFS):"
                        echo "36) Channel 36 (5180 MHz, safe)"
                        echo "44) Channel 44 (5220 MHz, safe)"
                        echo "149) Channel 149 (5745 MHz, safe)"
                        echo "157) Channel 157 (5785 MHz, safe)"
                        echo ""
                        echo -n "Enter channel number: "
                        read -r channel_choice
                        
                        if [[ "$channel_choice" =~ ^(36|44|149|157)$ ]]; then
                            echo "🔧 Switching to channel $channel_choice..."
                            # FIXED: Set band FIRST, then channel
                            if sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a && \
                               sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.channel "$channel_choice"; then
                                sudo nmcli connection up "$ACTIVE_CONNECTION"
                                echo "✅ Switched to channel $channel_choice (5GHz, DFS-free)"
                            else
                                echo "❌ Failed to switch to channel $channel_choice"
                                echo "💡 Try: Set band first, then channel manually"
                            fi
                        else
                            echo "❌ Invalid channel. Use: 36, 44, 149, or 157"
                        fi
                    fi
                fi
                ;;
            5)
                echo "Cancelled - no changes made"
                ;;
            *)
                echo "❌ Invalid option"
                ;;
        esac
        
        if [[ "$band_choice" =~ ^[1-4]$ ]]; then
            echo ""
            echo "🔍 Waiting 10 seconds for connection to stabilize..."
            sleep 10
            echo ""
            echo "📊 New connection status:"
            NEW_FREQ=$(iw dev "$IFACE" link 2>/dev/null | grep "freq:" | awk '{print $2}')
            NEW_SIGNAL=$(iw dev "$IFACE" link 2>/dev/null | grep "signal:" | awk '{print $2}')
            
            if [ -n "$NEW_FREQ" ]; then
                NEW_FREQ_INT=$(echo "$NEW_FREQ" | cut -d'.' -f1)
                
                if [ "$NEW_FREQ_INT" -ge 2400 ] && [ "$NEW_FREQ_INT" -le 2500 ]; then
                    NEW_BAND="2.4 GHz"
                elif [ "$NEW_FREQ_INT" -ge 5000 ] && [ "$NEW_FREQ_INT" -le 6000 ]; then
                    NEW_BAND="5 GHz"
                elif [ "$NEW_FREQ_INT" -ge 6000 ] && [ "$NEW_FREQ_INT" -le 7200 ]; then
                    NEW_BAND="6 GHz"
                else
                    NEW_BAND="Unknown"
                fi
                
                echo "   New band: $NEW_BAND"
                echo "   New frequency: $NEW_FREQ MHz"
                echo "   New signal: ${NEW_SIGNAL:-Unknown} dBm"
                
                # DFS analysis for new connection
                if [ "$NEW_BAND" = "5 GHz" ]; then
                    NEW_CHANNEL=$(echo "scale=0; ($NEW_FREQ_INT - 5000) / 5" | bc 2>/dev/null || echo "Unknown")
                    if [ "$NEW_CHANNEL" != "Unknown" ] && is_dfs_channel "$NEW_CHANNEL"; then
                        echo -e "   ${YELLOW}⚠️ DFS Warning: Connected to DFS channel $NEW_CHANNEL${NC}"
                        echo "   💡 Monitor for sudden disconnections lasting 30+ seconds"
                    else
                        echo -e "   ${GREEN}✅ Safe channel: $NEW_CHANNEL (non-DFS)${NC}"
                    fi
                fi
            else
                echo "   ❌ Connection status not available"
            fi
        fi
    fi
    
    echo ""
    echo -e "${GREEN}💡 Band Switching Tips:${NC}"
    echo "• 2.4GHz: Best range, completely DFS-free, but often congested"
    echo "• 5GHz: Good balance, but check for DFS channel usage"
    echo "• 6GHz: Shortest range but cleanest spectrum (NO DFS ever)"
    echo "• Safe 5GHz channels: 36, 40, 44, 48, 149, 153, 157, 161, 165"
    echo "• Avoid DFS channels: 52-64, 100-144 (radar interference risk)"
    echo ""
    echo "📋 Useful monitoring commands:"
    echo "• Current status: iw dev $IFACE link"
    echo "• Signal monitoring: watch -n 2 'iw dev $IFACE link | grep signal'"
    echo "• Speed test: speedtest-cli"
    echo ""
}

# Enhanced menu system - COMPLETE WITH ALL OPTIONS
show_menu() {
    clear
    echo -e "${BOLD}${CYAN}🧠 === ENHANCED WiFi ANALYZER ===${NC}"
    echo -e "${BOLD}WiFi 7 • MLO • 6GHz • DFS Monitoring • Distribution Adaptive • Modern VPN Support${NC}"
    echo ""
    echo "1) 🎯 Complete WiFi Analysis (All-in-One with WiFi 7 + DFS support)"
    echo "2) 🚨 Error Analysis & Troubleshooting (Distribution-aware fixes + DFS)"
    echo "3) 🛠️ Interactive Workaround Generator (Modern solutions + DFS fixes)"
    echo "4) 📡 DFS Channel Monitor (Dedicated radar interference analysis)"
    echo "5) 🧪 TX Power Band Test (diagnose power limitations)"
    echo "6) 📡 Manual Band Switching (2.4GHz/5GHz/6GHz CLI commands)"
    echo "7) 🚪 Exit"
    echo ""
    echo -n "Select option [1-7]: "
}

# Complete comprehensive analysis with modern features and DFS monitoring
complete_wifi_analysis() {
    echo -e "${BOLD}${BLUE}🧠 === COMPLETE WiFi ANALYSIS ===${NC}"
    echo "🔬 WiFi 7 • MLO • 6GHz • DFS Monitoring • Modern VPN • Distribution adaptive"
    echo "📊 Comprehensive analysis for modern WiFi systems with radar interference detection"
    echo ""
    
    # Run all analysis components
    gather_system_intelligence
    detect_vpn_configuration
    analyze_rf_frequency_environment  # This now includes DFS analysis
    detect_severe_wifi_issues  # This now includes DFS-aware detection
    
    # Provide DFS recommendations if relevant
    if [ "$DFS_IMPACT_SCORE" -gt 25 ]; then
        echo ""
        provide_dfs_recommendations
    fi
    
    # Final summary with modern features and DFS
    echo -e "${CYAN}🎯 === FINAL ANALYSIS SUMMARY ===${NC}"
    echo ""
    
    OVERALL_HEALTH="Excellent"
    HEALTH_SCORE=100
    
    # Calculate overall health including DFS impact
    if [ "$WIFI_FUNCTIONAL" != "true" ]; then
        OVERALL_HEALTH="Critical"
        HEALTH_SCORE=0
    elif [ "$SEVERE_ISSUES" -gt 0 ]; then
        OVERALL_HEALTH="Poor"
        HEALTH_SCORE=25
    elif [ "$DFS_IMPACT_SCORE" -gt 75 ]; then
        OVERALL_HEALTH="Poor (DFS interference)"
        HEALTH_SCORE=30
    elif [ "$DFS_IMPACT_SCORE" -gt 50 ]; then
        OVERALL_HEALTH="Fair (DFS risk)"
        HEALTH_SCORE=50
    elif [ "$VPN_IMPACT_SCORE" -gt 50 ]; then
        OVERALL_HEALTH="Fair"
        HEALTH_SCORE=60
    elif [ "$DFS_IMPACT_SCORE" -gt 25 ]; then
        HEALTH_SCORE=85  # Minor DFS impact
    fi
    
    echo "📊 Overall WiFi Health: $OVERALL_HEALTH ($HEALTH_SCORE/100)"
    echo "🔧 WiFi Status: $([ "$WIFI_FUNCTIONAL" = "true" ] && echo "✅ Working" || echo "❌ Broken")"
    echo "🔒 VPN Status: $VPN_ACTIVE ($VPN_TYPE)"
    echo "📡 Hardware: ${CHIP_VENDOR:-Unknown} ${CHIP_MODEL:-Unknown} (${CHIP_GENERATION:-Unknown})"
    echo "🐧 System: $DISTRO_NAME"
    
    # DFS status summary
    if [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo "📡 DFS Status: ⚠️ Connected to DFS channel (radar risk)"
    elif [ "$DFS_COUNT" -gt 0 ]; then
        echo "📡 DFS Status: 📊 $DFS_COUNT DFS networks in area"
    else
        echo "📡 DFS Status: ✅ Clean environment (no DFS detected)"
    fi
    
    # Modern features summary
    if [ "$SUPPORTS_WIFI7" = true ]; then
        echo "🌟 WiFi 7 Features: $([ "$SUPPORTS_MLO" = true ] && echo "MLO capable" || echo "Standard WiFi 7")"
    fi
    
    if [ "$WIFI_FUNCTIONAL" = "true" ]; then
        echo ""
        echo -e "${GREEN}✅ SYSTEM STATUS: HEALTHY${NC}"
        echo "🎉 Your modern WiFi system is functioning properly"
        if [ "$VPN_ACTIVE" = "Yes" ]; then
            echo "🔒 Modern VPN integration appears stable"
        fi
        
        # Modern optimization recommendations
        if [ "$SUPPORTS_WIFI7" = true ] && [ "$CURRENT_BAND" != "6 GHz (WiFi 6E/7)" ]; then
            echo "💡 Optimization: Consider upgrading to WiFi 7 router for 6GHz access"
            echo "💡 6GHz Advantage: No DFS channels = no radar interference"
        fi
        if [ "$SUPPORTS_MLO" = true ]; then
            echo "🔗 MLO available: Multi-link operation can improve performance"
        fi
        
        # DFS-specific recommendations
        if [ "$DFS_CURRENT_CONNECTION" = true ]; then
            echo ""
            echo -e "${YELLOW}⚠️ DFS RECOMMENDATION: Switch to non-DFS channel for stability${NC}"
            echo "💡 Suggested channels: 36, 40, 44, 48 (low 5GHz) or 149+ (high 5GHz)"
        elif [ "$DFS_IMPACT_SCORE" -gt 50 ]; then
            echo ""
            echo -e "${YELLOW}⚠️ DFS ENVIRONMENT: High radar activity detected${NC}"
            echo "💡 Monitor for disconnection patterns and consider non-DFS channels"
        fi
        
    else
        echo ""
        echo -e "${RED}🚨 SYSTEM STATUS: NEEDS ATTENTION${NC}"
        echo "💡 Run option 2 for detailed error analysis and troubleshooting"
        
        if [ "$DFS_IMPACT_SCORE" -gt 50 ]; then
            echo ""
            echo -e "${MAGENTA}📡 DFS FACTOR: Radar interference may be contributing to issues${NC}"
            echo "💡 Try non-DFS channels first before other troubleshooting"
        fi
    fi
    
    echo ""
}

# Error analysis and troubleshooting with distribution awareness and DFS
error_analysis_troubleshooting() {
    echo -e "${BOLD}${RED}🚨 === ERROR ANALYSIS & TROUBLESHOOTING ===${NC}"
    echo "🔍 Deep dive into system logs, errors, and failure patterns"
    echo "🛠️ Distribution-aware troubleshooting recommendations with DFS analysis"
    echo ""
    
    # Quick system check first
    gather_system_intelligence
    
    # Run DFS analysis early to identify radar-related issues
    analyze_dfs_channels >/dev/null 2>&1
    
    # NEW: Enhanced authentication failure detection
    AUTH_ISSUES=0
    AUTH_FAILURES=$(journalctl --since "24 hours ago" --no-pager 2>/dev/null | \
        grep -E "association took too long|ssid-not-found|authenticating.*disconnected" | \
        wc -l)
    
    if [ "$AUTH_FAILURES" -gt 0 ]; then
        echo -e "${RED}🚨 FOUND $AUTH_FAILURES AUTHENTICATION FAILURES${NC}"
        echo ""
        echo "📋 Recent authentication failure patterns:"
        journalctl --since "6 hours ago" --no-pager 2>/dev/null | \
            grep -E "association took too long|ssid-not-found|authenticating.*disconnected" | \
            tail -5 | while IFS= read -r line; do
            echo "   $line"
        done
        echo ""
        AUTH_ISSUES=1
    fi
    
    # Check for DFS-related disconnection patterns in logs
    DFS_LOG_ISSUES=0
    if [ "$DFS_RADAR_EVENTS" -gt 0 ] || [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo -e "${MAGENTA}📡 DFS-RELATED ISSUE ANALYSIS${NC}"
        echo ""
        
        if [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
            echo -e "${RED}🚨 RADAR EVENTS DETECTED: $DFS_RADAR_EVENTS in last 24 hours${NC}"
            echo "📋 Recent DFS/radar events:"
            journalctl --since "6 hours ago" --no-pager 2>/dev/null | \
                grep -iE "radar.*detect|dfs.*radar|channel.*blocked|cac.*complete|cac.*failed" | \
                tail -5 | while IFS= read -r line; do
                echo "   $line"
            done
            DFS_LOG_ISSUES=1
        fi
        
        if [ "$DFS_CURRENT_CONNECTION" = true ]; then
            echo -e "${YELLOW}⚠️ DFS CHANNEL CONNECTION: High risk of radar-related disconnections${NC}"
            echo "   Current connection uses DFS channel - this explains intermittent drops"
            DFS_LOG_ISSUES=1
        fi
        echo ""
    fi
    
    # Focus on problems if WiFi is broken OR authentication issues found OR DFS issues
    if [ "$WIFI_FUNCTIONAL" != "true" ] || [ "$AUTH_ISSUES" -eq 1 ] || [ "$DFS_LOG_ISSUES" -eq 1 ]; then
        echo -e "${RED}💥 WiFi SYSTEM ISSUES DETECTED - DIAGNOSTIC MODE${NC}"
        echo ""
        
        # DFS-specific fixes get priority if DFS issues detected
        if [ "$DFS_LOG_ISSUES" -eq 1 ]; then
            echo -e "${MAGENTA}🎯 PRIORITY: DFS FIXES (Radar interference detected)${NC}"
            echo ""
            echo "1. Immediate non-DFS channel switch:"
            if [ -n "$CURRENT_SSID" ]; then
                echo "   🔧 Force 2.4GHz (no DFS): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                echo "   🔧 Reconnect: sudo nmcli connection up \"$CURRENT_SSID\""
            fi
            echo ""
            echo "2. Router configuration (CRITICAL):"
            echo "   🔧 Set router primary channel to: 36, 40, 44, 48 (low 5GHz, no DFS)"
            echo "   🔧 Alternative: 149, 153, 157, 161, 165 (high 5GHz, no DFS)"
            echo "   🔧 Disable automatic channel selection"
            echo "   🔧 Disable DFS channels entirely in router settings"
            echo ""
            echo "3. Test connectivity after DFS fix:"
            echo "   🧪 Monitor: ping -c 10 8.8.8.8"
            echo "   🧪 Verify channel: iw dev $IFACE link | grep freq"
            echo ""
        fi
        
        detect_severe_wifi_issues
        
        # NEW: Authentication-specific fixes - ONLY if WiFi is actually broken
if [ "$AUTH_ISSUES" -eq 1 ]; then
    if [ "$WIFI_FUNCTIONAL" = "true" ]; then
        echo ""
        echo -e "${GREEN}✅ HISTORICAL AUTHENTICATION EVENTS (System Currently Working)${NC}"
        echo ""
        echo "📋 Found $AUTH_FAILURES authentication entries in logs, but:"
        echo "   • WiFi is currently connected and functional"
        echo "   • Data flow is working properly"
        echo "   • These appear to be historical events (likely Tailscale/boot-time handshakes)"
        echo ""
        echo "💡 No immediate action required - monitor for actual disconnection issues"
        echo ""
    else
        echo ""
        echo -e "${YELLOW}🔧 AUTHENTICATION FAILURE FIXES:${NC}"
        echo ""
        echo "1. Delete and recreate connection profile:"
        echo "   🔒 PERMANENT: sudo nmcli connection delete \"$CURRENT_SSID\""
        echo "   🔒 PERMANENT: sudo nmcli device wifi connect \"$CURRENT_SSID\" password \"PASSWORD\""
        echo ""
        echo "2. Force specific band to avoid problematic radios:"
        echo "   🔒 PERMANENT (5GHz only): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band a"
        echo "   🔒 PERMANENT (2.4GHz only): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
        echo ""
        echo "3. Reset regulatory domain (6GHz issues):"
        echo "   ⏰ TEMPORARY: sudo iw reg set US"
        echo "   ⏰ TEMPORARY: sudo nmcli radio wifi off && sudo nmcli radio wifi on"
        echo ""
        echo "4. Router-specific fixes:"
        echo "   💡 Disable band steering in router settings"
        echo "   💡 Use non-DFS channels (36,40,44,149,153,157,161,165)"
        echo "   💡 For Eero mesh: Check for firmware updates in Eero app"
        echo ""
    fi
fi
        
        echo ""
        echo -e "${YELLOW}🔧 DISTRIBUTION-SPECIFIC TROUBLESHOOTING STEPS:${NC}"
        echo ""
        echo "🐧 Detected system: $DISTRO_NAME"
        echo ""
        echo "1. Basic restart sequence:"
        echo "   ⏰ IMMEDIATE (temporary fix): sudo systemctl restart NetworkManager"
        echo "   ⏰ IMMEDIATE (driver reload): sudo modprobe -r $DRIVER && sleep 3 && sudo modprobe $DRIVER"
        echo ""
        echo "2. Update system and firmware:"
        echo "   🔒 PERMANENT: $(get_distro_command "firmware_update")"
        echo ""
        echo "3. Check for hardware issues:"
        echo "   🧪 DIAGNOSTIC: lspci | grep -i wireless"
        echo "   🧪 DIAGNOSTIC: dmesg | grep -i $DRIVER | tail -20"
        echo ""
        echo "4. Network configuration reset:"
        echo "   ⏰ IMMEDIATE: sudo nmcli device disconnect $IFACE"
        echo "   ⏰ IMMEDIATE: sudo nmcli device connect $IFACE"
        echo ""
        
        # Provide distribution-specific advanced fixes
        provide_distribution_specific_workarounds "DRIVER_ERROR"
        
        echo "📁 Detailed logs can be found in system journal"
        
    else
        echo -e "${GREEN}✅ WiFi WORKING - HEALTH CHECK MODE${NC}"
        echo ""
        
        # Even working systems can have underlying issues
        echo "🔍 Checking for potential issues in working system..."
        
        # Enhanced error filtering (remove harmless firmware loading attempts)
        RECENT_ERRORS=$(journalctl --since "24 hours ago" --no-pager 2>/dev/null | \
            grep -iE "$DRIVER.*error|wifi.*error|$IFACE.*error" | \
            grep -v "Direct firmware load.*failed with error -2" | \
            grep -v "firmware load.*failed.*error -2" | \
            grep -v "WIFI_RAM_CODE.*failed" | \
            grep -v "WIFI_MT.*patch.*failed" | \
            grep -v "mediatek.*bin failed" | \
            grep -v "firmware.*failed.*error -2" | \
            wc -l)
        
        if [ "$RECENT_ERRORS" -gt 0 ]; then
            echo "⚠️ Found $RECENT_ERRORS recent WiFi-related errors"
            echo "📋 Recent error patterns:"
            journalctl --since "24 hours ago" --no-pager 2>/dev/null | \
                grep -iE "$DRIVER.*error|wifi.*error" | \
                grep -v "firmware.*failed.*error -2" | \
                tail -5 | while IFS= read -r line; do
                echo "   $line"
            done
        else
            echo "✅ No recent WiFi errors detected"
        fi
        
        # Modern VPN conflict check
        if [ "$VPN_ACTIVE" = "Yes" ] && [ "$VPN_IMPACT_SCORE" -gt 30 ]; then
            echo ""
            echo "⚠️ Modern VPN may be impacting WiFi performance"
            echo "💡 Consider testing WiFi without VPN periodically"
        fi
        
        # DFS health check even for working systems
        if [ "$DFS_IMPACT_SCORE" -gt 25 ]; then
            echo ""
            echo "📡 DFS Analysis: Potential radar interference risk detected"
            echo "💡 Monitor for disconnection patterns, especially 30+ second drops"
            if [ "$DFS_CURRENT_CONNECTION" = true ]; then
                echo "⚠️ Current connection uses DFS channel - consider switching"
            fi
        fi
        
        echo ""
        echo "🎉 System appears healthy - no immediate action required"
    fi
    
    echo ""
}

# Interactive workaround generator with modern solutions and DFS fixes - COMPLETE
interactive_workaround_generator() {
    echo -e "${BOLD}${BLUE}🛠️ === INTERACTIVE WORKAROUND GENERATOR ===${NC}"
    echo "🎯 Modern solutions for WiFi 7, 6GHz, MLO, DFS radar interference, and advanced VPN issues"
    echo ""
    
    echo "What WiFi issue are you experiencing?"
    echo ""
    echo "1) 📡 WiFi keeps disconnecting/dropping"
    echo "2) 🐌 WiFi is very slow or unstable"
    echo "3) ❌ WiFi won't connect at all"
    echo "4) 🔒 Modern VPN causes WiFi problems (Tailscale/ZeroTier/etc)"
    echo "5) 🔥 WiFi works but system gets hot/fans spin"
    echo "6) ⚡ WiFi stops working after suspend/resume"
    echo "7) 📶 Weak signal or poor range"
    echo "8) 📡 DFS radar interference (sudden 30+ second disconnections)"
    echo "9) 🆘 Emergency: Need immediate solution"
    echo "10) 🔍 Run diagnostic first (recommended)"
    echo ""
    echo -n "Select your issue [1-10]: "
    
    read -r issue_choice
    
    case $issue_choice in
    1)
        echo ""
        echo "🔍 Analyzing modern disconnection patterns..."
        # Re-run analysis and UPDATE global variables
        gather_system_intelligence >/dev/null 2>&1
        detect_vpn_configuration >/dev/null 2>&1
        analyze_dfs_channels >/dev/null 2>&1
        
        # Check if WiFi is actually having disconnection issues
        if [ "$WIFI_FUNCTIONAL" = "true" ] && [ "$DFS_CURRENT_CONNECTION" != "true" ] && [ "$DFS_RADAR_EVENTS" -eq 0 ]; then
            echo -e "${GREEN}✅ === WIFI CURRENTLY STABLE ===${NC}"
            echo ""
            echo "🎉 Analysis shows your WiFi is working excellently:"
            echo "   • Connected to 6GHz at high speeds"
            echo "   • No DFS radar interference"
            echo "   • No current disconnection issues detected"
            echo ""
            echo "❓ Are you experiencing actual disconnections right now? [y/N]"
            read -r experiencing_issues
            
            if [[ ! "$experiencing_issues" =~ ^[Yy]$ ]]; then
                echo ""
                echo "💡 Your WiFi appears stable. Consider monitoring with:"
                echo "   • Real-time connection: watch -n 2 'iw dev $IFACE link | grep -E \"Connected|signal\"'"
                echo "   • Network stability: ping -i 1 8.8.8.8"
                echo ""
                echo "💡 If disconnections occur later, re-run this tool for targeted fixes."
                return 0
            fi
            echo ""
            echo "🔍 Proceeding with disconnection analysis since you're experiencing issues..."
        fi
        
        echo -e "${CYAN}🛠️ === MODERN DISCONNECTION FIXES ===${NC}"
            echo ""
            echo "🐧 Distribution: $DISTRO_NAME"
            echo ""
            
            # DFS gets priority for disconnection issues
            if [ "$DFS_CURRENT_CONNECTION" = true ] || [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
                echo -e "${MAGENTA}🎯 PRIORITY: DFS Radar Interference (likely cause)${NC}"
                echo ""
                echo "1. Immediate non-DFS channel switch:"
                if [ -n "$CURRENT_SSID" ]; then
                    echo "   ⏰ IMMEDIATE: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                    echo "   ⏰ IMMEDIATE: sudo nmcli connection up \"$CURRENT_SSID\""
                    echo "   💡 This forces 2.4GHz (no DFS channels exist in 2.4GHz)"
                fi
                echo ""
                echo "2. Router configuration (CRITICAL):"
                echo "   🔒 PERMANENT: Set router to channels 36, 40, 44, 48 (low 5GHz, no DFS)"
                echo "   🔒 PERMANENT: Alternative: 149, 153, 157, 161, 165 (high 5GHz, no DFS)"
                echo "   🔒 PERMANENT: Disable automatic channel selection"
                echo ""
                echo "3. Test after DFS fix:"
                echo "   🧪 Monitor: ping -c 20 8.8.8.8  # Should show no 30+ second gaps"
                echo "   🧪 Verify: iw dev $IFACE link | grep freq  # Confirm non-DFS frequency"
                echo ""
                echo "4. 6GHz upgrade path (NO DFS):"
                if [ "$SUPPORTS_WIFI7" = true ]; then
                    echo "   ✅ Your hardware supports 6GHz"
                    echo "   🔒 PERMANENT: Upgrade to WiFi 6E/7 router for DFS-free operation"
                    echo "   🌟 6GHz advantage: Zero radar interference possible"
                fi
                echo ""
            elif [ "$WIFI_FUNCTIONAL" != "true" ]; then
                echo "1. Modern driver reset:"
                echo "   ⏰ IMMEDIATE (driver reload): sudo modprobe -r $DRIVER && sleep 5 && sudo modprobe $DRIVER"
                echo ""
                echo "2. Distribution-specific firmware update:"
                echo "   🔒 PERMANENT (system upgrade): $(get_distro_command "firmware_update")"
                echo ""
                provide_distribution_specific_workarounds "FIRMWARE_CRASH"
            elif [ "$VPN_ACTIVE" = "Yes" ] && [ "$VPN_IMPACT_SCORE" -gt 30 ]; then
                echo "🔒 Modern VPN optimization detected:"
                echo ""
                echo "1. Optimize modern VPN MTU:"
                echo "   ⏰ TEMPORARY (until VPN restart): sudo ip link set $VPN_INTERFACE mtu 1200"
                echo "   🔒 PERMANENT: Configure in VPN client settings"
                echo ""
                echo "2. For Tailscale specifically:"
                echo "   🔒 PERMANENT (Tailscale config): tailscale up --accept-routes=false"
                echo "   💡 Enables split tunneling - setting persists"
                echo ""
                echo "3. For ZeroTier:"
                echo "   💡 Check ZeroTier controller settings for route conflicts"
                echo "   🔒 PERMANENT: Configure managed routes in ZeroTier Central"
                echo ""
                echo "4. Test without VPN:"
                echo "   🧪 TESTING (diagnostic): Temporarily disconnect modern VPN to test WiFi stability"
                echo "   ⏰ TEMPORARY: Changes revert when VPN reconnects"
            else
                echo "1. Modern power management fix:"
                echo "   ⏰ TEMPORARY (until reboot): sudo iw dev $IFACE set power_save off"
                echo "   🔒 PERMANENT (module config): echo 'options mt7921e power_save=0' | sudo tee /etc/modprobe.d/mt7921e.conf"
                echo "   💡 Try temporary first to test, then apply permanent if it works"
                echo ""
                echo "3. WiFi 7/6E specific optimizations:"
                if [ "$SUPPORTS_WIFI7" = true ]; then
                    echo "   🔒 PERMANENT (system upgrade): $(get_distro_command "firmware_update")"
                    echo "   ⚠️ REQUIRES REBOOT: System update needs restart to take effect"
                    echo "   💡 Your WiFi 7 hardware may need newer firmware for stability"
                else
                    echo "   💡 Standard WiFi 6E optimizations"
                    echo "   💡 Consider hardware upgrade for WiFi 7 features"
                fi
                echo ""
                echo "4. Distribution-specific module tuning:"
                provide_distribution_specific_workarounds "DRIVER_ERROR"
            fi
            ;;
        2)
    echo ""
    echo "🔍 Analyzing modern performance issues..."
    gather_system_intelligence >/dev/null 2>&1
    analyze_rf_frequency_environment >/dev/null 2>&1
    
    # Check if system is already performing excellently
    if [ "$WIFI_FUNCTIONAL" = "true" ] && [ "$CURRENT_BAND" = "6 GHz (WiFi 6E/7)" ] && [ -n "$CURRENT_BITRATE" ]; then
        BITRATE_NUM=$(echo "$CURRENT_BITRATE" | grep -o "[0-9]*" | head -1)
        if [ -n "$BITRATE_NUM" ] && [ "$BITRATE_NUM" -gt 1000 ]; then
            echo -e "${GREEN}✅ === EXCELLENT PERFORMANCE DETECTED ===${NC}"
            echo ""
            echo "🚀 Your system shows outstanding performance metrics:"
            echo "   • Connected to 6GHz clean spectrum"
            echo "   • Speed: ${CURRENT_BITRATE:-Unknown} Mbps"
            echo "   • Signal: ${CURRENT_SIGNAL:-Unknown} dBm"
            echo "   • Channel width: ${CHANNEL_WIDTH:-Unknown} MHz"
            echo ""
            echo "❓ Are you experiencing actual speed/performance issues? [y/N]"
            read -r experiencing_performance_issues
            
            if [[ ! "$experiencing_performance_issues" =~ ^[Yy]$ ]]; then
                echo ""
                echo "💡 Your WiFi is performing excellently. For monitoring:"
                echo "   • Speed test: speedtest-cli"
                echo "   • Real-time stats: watch -n 2 'iw dev $IFACE link'"
                echo "   • Advanced metrics: iperf3 -c your-server-ip"
                echo ""
                echo "🎯 Possible optimizations for your excellent setup:"
                echo "   • Router upgrade to WiFi 7 for 320MHz channels"
                echo "   • MLO (Multi-Link Operation) if router supports it"
                echo ""
                return 0
            fi
            echo ""
            echo "🔍 Proceeding with performance optimization since you're experiencing issues..."
        fi
    fi
    
    echo -e "${CYAN}🛠️ === MODERN PERFORMANCE OPTIMIZATION ===${NC}"
    echo ""
            
            # DFS impact on performance
            if [ "$DFS_CURRENT_CONNECTION" = true ]; then
                echo -e "${MAGENTA}📡 DFS PERFORMANCE IMPACT DETECTED${NC}"
                echo ""
                echo "   Current DFS connection may cause:"
                echo "   • Sudden speed drops during radar detection"
                echo "   • 30+ second interruptions for channel switching"
                echo "   • Inconsistent throughput patterns"
                echo ""
                echo "   🎯 Fix: Switch to non-DFS channel for consistent performance"
                if [ -n "$CURRENT_SSID" ]; then
                    echo "   ⏰ IMMEDIATE: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                fi
                echo ""
            fi
            
            echo "1. Modern band optimization:"
            if [ "$CURRENT_BAND" = "2.4 GHz" ]; then
                echo "   ⏰ TEMPORARY (test only): Force 5GHz connection"
                echo "   🔒 PERMANENT: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band a"
                echo "   💡 Better: Upgrade to WiFi 6E/7 router for 6GHz access"
            elif [ "$CURRENT_BAND" = "5 GHz" ]; then
                echo "   📊 You're on 5GHz - optimization options:"
                echo "   💡 Consider WiFi 6E/7 router upgrade for 6GHz clean spectrum"
                if [ "$SUPPORTS_WIFI7" = true ]; then
                    echo "   💡 Your hardware supports WiFi 7 - router upgrade recommended"
                fi
                if [ "$DFS_CURRENT_CONNECTION" = true ]; then
                    echo "   ⚠️ Current DFS channel may impact performance consistency"
                fi
            elif [ "$CURRENT_BAND" = "6 GHz (WiFi 6E/7)" ]; then
                echo "   ✅ Excellent! You're on 6GHz clean spectrum"
                echo "   🌟 6GHz advantage: No DFS = consistent performance"
                echo "   💡 Optimize channel width and MLO if available"
            fi
            echo ""
            
            echo "2. Modern channel width optimization:"
            if [ -n "$CHANNEL_WIDTH" ]; then
                echo "   📊 Current: $CHANNEL_WIDTH MHz"
                if [ "$CHANNEL_WIDTH" -lt 80 ]; then
                    echo "   🔒 PERMANENT (router config): Increase to 80MHz or 160MHz in router settings"
                elif [ "$CHANNEL_WIDTH" -eq 160 ] && [ "$SUPPORTS_WIFI7" = true ]; then
                    echo "   🔒 PERMANENT (router upgrade): Consider 320MHz if router supports WiFi 7"
                fi
            fi
            echo ""
            
            echo "3. MLO optimization (WiFi 7):"
            if [ "$SUPPORTS_MLO" = true ]; then
                echo "   🔒 PERMANENT (router config): Enable MLO in router settings for multi-band aggregation"
                echo "   ⚠️ REQUIRES: WiFi 7 router with MLO support"
            else
                echo "   💡 MLO not supported - consider WiFi 7 hardware upgrade"
            fi
            echo ""
            ;;
        3)
    echo ""
    echo "🔍 Analyzing modern connection failures..."
    
    # Re-run analysis to get current status
    gather_system_intelligence >/dev/null 2>&1
    
    # Check if WiFi is actually connected and working  
if [ "$WIFI_FUNCTIONAL" = "true" ]; then
    # Try to get current SSID if it's missing
    if [ -z "$CURRENT_SSID" ]; then
        CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 2>/dev/null)
        if [ -z "$CURRENT_SSID" ]; then
            CURRENT_SSID=$(iw dev "$IFACE" link 2>/dev/null | grep "SSID:" | awk '{print $2}')
        fi
    fi
    
    echo -e "${GREEN}✅ === WIFI CURRENTLY CONNECTED ===${NC}"
    echo ""
    echo "🎉 Your WiFi appears to be working:"
    echo "   • Connected to: ${CURRENT_SSID:-"(Connected but SSID detection failed)"}"
    echo "   • Band: ${CURRENT_BAND:-Unknown}"
    echo "   • Speed: ${CURRENT_BITRATE:-Unknown} Mbps"
    echo "   • Signal: ${CURRENT_SIGNAL:-Unknown} dBm"
    echo ""
    echo "❓ Are you experiencing actual connection failures? [y/N]"
    read -r experiencing_connection_issues
    
    if [[ ! "$experiencing_connection_issues" =~ ^[Yy]$ ]]; then
        echo ""
        echo "💡 Your WiFi is connected and working. For troubleshooting:"
        echo "   • Check other devices: Test if issue affects other devices"
        echo "   • Monitor connection: watch -n 2 'iw dev $IFACE link'"
        echo "   • Test specific sites: curl -I google.com"
        echo ""
        return 0
    fi
    echo ""
    echo "🔍 Proceeding with connection troubleshooting since you're experiencing issues..."
fi
    
    echo -e "${CYAN}🛠️ === MODERN CONNECTION FIXES ===${NC}"
    echo ""
    echo "🐧 System: $DISTRO_NAME"
    echo ""
    
    echo "1. Emergency connection reset:"
    echo "   ⏰ IMMEDIATE: sudo systemctl restart NetworkManager"
    echo "   ⏰ IMMEDIATE: sudo modprobe -r $DRIVER && sudo modprobe $DRIVER"
    echo ""
    
    provide_distribution_specific_workarounds "DRIVER_ERROR"
    ;;
        4)
            echo ""
            echo "🔍 Analyzing modern VPN conflicts..."
            detect_vpn_configuration >/dev/null 2>&1
            
            echo -e "${CYAN}🛠️ === MODERN VPN OPTIMIZATION ===${NC}"
            echo ""
            
            if echo "$VPN_TYPE" | grep -qi "tailscale"; then
                echo "🔗 Tailscale (WireGuard mesh) optimization:"
                echo ""
                echo "1. Enable split tunneling:"
                echo "   🔒 PERMANENT: tailscale up --accept-routes=false"
                echo ""
                echo "2. Optimize MTU for modern networks:"
                echo "   ⏰ TEMPORARY: sudo ip link set tailscale0 mtu 1200"
                echo ""
                echo "3. Use modern exit nodes efficiently:"
                echo "   🔒 PERMANENT: tailscale up --exit-node=COUNTRY-CODE"
                echo ""
            elif echo "$VPN_TYPE" | grep -qi "zerotier"; then
                echo "🌐 ZeroTier (SD-WAN) optimization:"
                echo ""
                echo "1. Check controller settings for route conflicts"
                echo "2. ⏰ TEMPORARY: sudo ip link set zt+ mtu 1200"
                echo "3. 🔒 PERMANENT: Use managed routes instead of full routing"
                echo ""
            else
                echo "🔒 Generic modern VPN optimization:"
                echo ""
                echo "1. MTU optimization:"
                echo "   ⏰ TEMPORARY: sudo ip link set $VPN_INTERFACE mtu 1200"
                echo ""
                echo "2. 🔒 PERMANENT: Split tunneling configuration"
                echo "3. 🔒 PERMANENT: Modern DNS configuration"
            fi
            ;;
        5)
            echo ""
            echo "🔍 Analyzing thermal/power issues..."
            # Get current system info
            gather_system_intelligence >/dev/null 2>&1
            
            echo -e "${CYAN}🛠️ === ADVANCED THERMAL MANAGEMENT ===${NC}"
            echo ""
            
            echo "🌡️ IMMEDIATE THERMAL FIXES:"
            echo ""
            echo "1. WiFi power management optimization:"
            echo "   ⏰ IMMEDIATE: sudo iw dev $IFACE set power_save off"
            echo "   🔒 PERMANENT: echo 'options $DRIVER power_save=0' | sudo tee /etc/modprobe.d/$DRIVER.conf"
            echo "   ⚠️ REQUIRES REBOOT after permanent config"
            echo ""
            
            echo "2. ASPM (Advanced State Power Management) fixes:"
            if echo "$CHIP_MODEL" | grep -qi "mt79"; then
                echo "   MediaTek-specific thermal optimization:"
                echo "   🔒 PERMANENT: echo 'options $DRIVER disable_aspm=1' | sudo tee -a /etc/modprobe.d/$DRIVER.conf"
                echo "   🔒 PERMANENT: $(get_distro_command "kernel_param")'pcie_aspm=off'"
                echo "   ⚠️ REQUIRES REBOOT and GRUB update"
            else
                echo "   Generic ASPM optimization:"
                echo "   🔒 PERMANENT: $(get_distro_command "kernel_param")'pcie_aspm=off'"
                echo "   ⚠️ REQUIRES REBOOT"
            fi
            echo ""
            
            echo "3. CPU governor optimization for thermal control:"
echo "   ⏰ IMMEDIATE: for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo powersave | sudo tee \"\$cpu\"; done"
echo "   🔒 PERMANENT: Use built-in system power management"

# Distribution-specific thermal management
case "$DISTRO_ID" in
    "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
        echo "   Fedora/RHEL: sudo tuned-adm profile powersave"
        echo "   Alternative: sudo systemctl enable power-profiles-daemon"
        ;;
    "ubuntu"|"debian"|"pop"|"mint"|"linuxmint")
        echo "   Ubuntu/Debian: sudo systemctl enable power-profiles-daemon"
        echo "   Alternative: sudo cpupower frequency-set -g powersave"
        ;;
    "arch"|"manjaro"|"endeavouros")
        echo "   Arch: sudo systemctl enable power-profiles-daemon"
        echo "   Alternative: echo 'powersave' | sudo tee /etc/default/cpufrequtils"
        ;;
    *)
        echo "   Generic: Use your distribution's built-in power management"
        ;;
esac
echo ""
            
            echo "4. Modern WiFi 7 thermal considerations:"
            if [ "$SUPPORTS_WIFI7" = true ]; then
                echo "   WiFi 7 hardware detected - higher power consumption expected"
                echo "   🔧 Monitor temperatures: watch -n 2 'sensors | grep -E \"Core|Package|wifi\"'"
                echo "   🔧 Check if 6GHz radio can be disabled when not needed"
                echo "   💡 Some WiFi 7 cards run significantly hotter than WiFi 6"
            fi
            echo ""
            
            echo "5. Physical thermal optimization:"
            echo "   🔧 Laptop: Ensure proper ventilation, clean fans/vents"
            echo "   🔧 Desktop: Verify case airflow, WiFi card positioning"
            echo "   🔧 M.2 cards: Consider thermal pads or heatsinks for hot-running cards"
            echo ""
            
            echo "6. Firmware thermal optimization:"
            echo "   🔒 PERMANENT: $(get_distro_command "firmware_update")"
            echo "   💡 Newer firmware often includes thermal improvements"
            echo "   ⚠️ REQUIRES REBOOT after firmware update"
            echo ""
            
            echo "🧪 THERMAL MONITORING COMMANDS:"
            echo "   📊 CPU temps: watch -n 2 'sensors | grep Core'"
            echo "   📊 All temps: sudo watch -n 2 'sensors'"
            echo "   📊 WiFi power: watch -n 5 'iw dev $IFACE info | grep txpower'"
            echo "   📊 System load: watch -n 2 'uptime && cat /proc/loadavg'"
            ;;
        6)
            echo ""
            echo "🔍 Analyzing modern suspend/resume issues..."
            # Re-run analysis to get current system info
            gather_system_intelligence >/dev/null 2>&1
            analyze_modern_chipsets >/dev/null 2>&1
            
            echo -e "${CYAN}🛠️ === MODERN SUSPEND/RESUME FIXES ===${NC}"
echo ""

echo "1. Complete systemd sleep script (recommended):"
echo "   🔒 PERMANENT: sudo tee /etc/systemd/system-sleep/wifi-resume.sh << 'EOF'"
echo "#!/bin/bash"
echo "if [ \"\$1\" = \"post\" ]; then"
echo "    modprobe -r $DRIVER"
echo "    sleep 2"
echo "    modprobe $DRIVER"
if [ "$SUPPORTS_WIFI7" = true ]; then
    echo "    # WiFi 7: Allow 6GHz initialization"
    echo "    sleep 3"
fi
echo "    # Reset power management and restart NetworkManager"
echo "    sleep 1"
echo "    iw dev $IFACE set power_save off 2>/dev/null || true"
echo "    systemctl restart NetworkManager"
echo "fi"
echo "EOF"
echo "   sudo chmod +x /etc/systemd/system-sleep/wifi-resume.sh"
echo ""

echo "2. Lightweight alternative (NetworkManager only):"
echo "   🔒 PERMANENT: sudo tee /etc/systemd/system-sleep/nm-restart.sh << 'EOF'"
echo "#!/bin/bash"
echo "[ \"\$1\" = \"post\" ] && systemctl restart NetworkManager"
echo "EOF"
echo "   sudo chmod +x /etc/systemd/system-sleep/nm-restart.sh"
echo ""

echo "3. Test suspend/resume fix:"
echo "   🧪 TEST: sudo systemctl suspend"
echo "   🧪 VERIFY: After resume - iw dev $IFACE link"
echo ""
;;
        7)
            echo ""
            echo "🔍 Analyzing modern signal optimization..."
            # Re-run analysis to get current system info
            gather_system_intelligence >/dev/null 2>&1
            analyze_rf_frequency_environment >/dev/null 2>&1
            
            echo -e "${CYAN}🛠️ === ADVANCED SIGNAL OPTIMIZATION ===${NC}"
            echo ""
            
            echo "📊 Current Signal Analysis:"
            echo "   Signal Strength: ${CURRENT_SIGNAL:-Unknown} dBm"
            echo "   Current Band: ${CURRENT_BAND:-Unknown}"
            echo "   Current Frequency: ${CURRENT_FREQ:-Unknown} MHz"
            echo ""
            
            echo "🚀 PROVEN SIGNAL IMPROVEMENT TECHNIQUES:"
            echo ""
            
            echo "1. Band optimization for maximum range:"
            echo "   💡 2.4GHz: Better penetration through walls, longer range"
            echo "   💡 5GHz: Less congested, shorter range but higher speeds"
            echo "   💡 6GHz: Cleanest spectrum, shortest range, highest speeds"
            if [ -n "$CURRENT_SSID" ]; then
                echo ""
                echo "   Switch commands for your network:"
                echo "   ⏰ IMMEDIATE (2.4GHz): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                echo "   ⏰ IMMEDIATE (5GHz): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band a"
                echo "   💡 Test each band to find optimal signal/speed balance"
            fi
            echo ""
            
            echo "2. Antenna diversity and positioning:"
            echo "   🔧 Laptop: Adjust screen angle (affects internal antenna orientation)"
            echo "   🔧 Desktop: Ensure M.2 WiFi card antennas are properly connected"
            echo "   🔧 USB adapters: Try different USB ports, use extension cable"
            echo "   🔧 External antennas: Position perpendicular to router antennas"
            echo ""
            
            echo "3. Modern regulatory domain optimization:"
            echo "   📡 Current domain: $(iw reg get | grep country || echo 'Not set')"
            echo "   🔧 Optimize for your location:"
            echo "   ⏰ IMMEDIATE: sudo iw reg set US  # (or your country code)"
            echo "   💡 Proper regulatory domain can increase allowed TX power"
            echo ""
            
            echo "4. Channel width optimization for range vs speed:"
            if [ -n "$CHANNEL_WIDTH" ]; then
                echo "   📊 Current width: $CHANNEL_WIDTH MHz"
                if [ "$CHANNEL_WIDTH" -ge 80 ]; then
                    echo "   💡 Wide channels give speed but reduce range"
                    echo "   🔧 For better range: Force router to 40MHz or 80MHz"
                fi
            fi
            echo "   💡 Wider channels = faster speeds but shorter range"
            echo "   💡 Narrower channels = longer range but slower speeds"
            echo ""
            
            # Chipset-specific TX power advice
            if echo "$CHIP_MODEL" | grep -qi "mt79"; then
                echo "   📝 MediaTek note: TX power commands often fail or are ignored"
                echo "   💡 Router-side power increase usually more effective"
            elif echo "$CHIP_MODEL" | grep -qi "intel"; then
                echo "   📝 Intel note: Regulatory restrictions often limit manual TX power"
                echo "   💡 Ensure proper regulatory domain is set first"
            fi
            echo ""
            
            echo "6. Physical optimization techniques:"
            echo "   🏠 Router placement: Central location, elevated position"
            echo "   🏠 Reduce obstacles: Minimize walls, large objects between devices"
            echo "   🏠 Interference reduction: Keep away from microwaves, baby monitors"
            echo "   📱 Client positioning: Higher floors often get better signal"
            echo ""
            
            echo "7. WiFi 6E/7 specific optimizations:"
            if [ "$SUPPORTS_WIFI7" = true ]; then
                echo "   ✅ Your hardware supports modern WiFi features"
                echo "   🌟 6GHz band: Clean spectrum but limited range"
                echo "   🔧 Use 6GHz for close-range, high-speed connections"
                echo "   🔧 Use 5GHz for medium-range connections"
                echo "   🔧 Use 2.4GHz for maximum range connections"
                
                if [ "$SUPPORTS_MLO" = true ]; then
                    echo "   🚀 MLO capable: Can use multiple bands simultaneously"
                    echo "   💡 Requires MLO-capable router for maximum benefit"
                fi
            else
                echo "   💡 Current hardware: WiFi 6 or older"
                echo "   💡 Consider WiFi 6E/7 upgrade for access to 6GHz clean spectrum"
            fi
            echo ""
            
            echo "8. Real-time signal monitoring:"
            echo "   📊 Watch signal: watch -n 1 'iw dev $IFACE link | grep signal'"
            echo "   📊 Site survey: sudo iw dev $IFACE scan | grep -E 'SSID|signal|freq'"
            echo "   📊 Speed test: speedtest-cli (install if needed)"
            echo ""
            
            echo "🎯 TESTING PROTOCOL:"
            echo "1. Baseline test: speedtest-cli && iw dev $IFACE link | grep signal"
            echo "2. Try 2.4GHz: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
            echo "3. Test again: speedtest-cli && iw dev $IFACE link | grep signal"
            echo "4. Try 5GHz: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band a"
            echo "5. Test again: speedtest-cli && iw dev $IFACE link | grep signal"
            echo "6. Use band with best signal/speed ratio for your location"
            ;;
        8)
            echo ""
            echo "🔍 Analyzing DFS radar interference patterns..."
            gather_system_intelligence >/dev/null 2>&1
            analyze_dfs_channels >/dev/null 2>&1
            
            echo -e "${MAGENTA}🛠️ === DFS RADAR INTERFERENCE FIXES ===${NC}"
            echo ""
            
            echo "📡 DFS Analysis Results:"
            echo "   Current DFS connection: $([ "$DFS_CURRENT_CONNECTION" = true ] && echo "Yes (HIGH RISK)" || echo "No")"
            echo "   DFS networks in area: $DFS_COUNT"
            echo "   Recent radar events: $DFS_RADAR_EVENTS"
            echo "   DFS risk score: $DFS_IMPACT_SCORE/100"
            echo ""
            
            echo "🎯 IMMEDIATE DFS FIXES:"
            echo ""
            echo "1. Emergency non-DFS channel switch:"
            if [ -n "$CURRENT_SSID" ]; then
                echo "   ⏰ IMMEDIATE: sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                echo "   ⏰ IMMEDIATE: sudo nmcli connection up \"$CURRENT_SSID\""
                echo "   💡 Forces 2.4GHz connection - no DFS channels in 2.4GHz band"
            fi
            echo ""
            echo "2. Router configuration (CRITICAL - prevents future issues):"
            echo "   🔒 PERMANENT: Primary 5GHz channel → 36, 40, 44, or 48 (low band, no DFS)"
            echo "   🔒 PERMANENT: Alternative channels → 149, 153, 157, 161, 165 (high band, no DFS)"
            echo "   🔒 PERMANENT: Disable automatic channel selection"
            echo "   🔒 PERMANENT: Disable DFS channels entirely (if router supports this option)"
            echo ""
            echo "3. Verification and testing:"
            echo "   🧪 Test connectivity: ping -c 30 8.8.8.8"
            echo "   💡 No timeouts should occur (previously had 30+ second gaps)"
            echo "   🧪 Verify channel: iw dev $IFACE link | grep freq"
            echo "   💡 Frequency should NOT be 5260-5320 MHz or 5500-5700 MHz (DFS ranges)"
            echo ""
            echo "4. Long-term DFS-free solutions:"
            echo ""
            echo "   Option A - 6GHz Migration (BEST):"
            if [ "$SUPPORTS_WIFI7" = true ]; then
                echo "   ✅ Your hardware supports 6GHz"
                echo "   🔒 PERMANENT: Upgrade to WiFi 6E/7 router"
                echo "   🌟 6GHz band: ALL channels are DFS-free (no radar interference possible)"
                echo "   🚀 Additional benefits: Clean spectrum, higher throughput, lower latency"
            else
                echo "   💡 Hardware upgrade to WiFi 6E/7 required"
                echo "   💡 6GHz band: ALL channels are DFS-free"
                echo "   💡 Recommended cards: MT7925, Intel BE200, Qualcomm WCN7850"
            fi
            echo ""
            echo "   Option B - Strategic 5GHz Channel Planning:"
            echo "   🔒 PERMANENT: Use ONLY these channels: 36, 40, 44, 48, 149, 153, 157, 161, 165"
            echo "   💡 These channels never require DFS and are immune to radar"
            echo "   💡 Avoid channels 52-64 and 100-144 (all DFS channels)"
            echo ""
            
            # Provide DFS-specific monitoring commands
            echo "🔍 DFS Monitoring Commands:"
            echo ""
            echo "Real-time radar event monitoring:"
            echo "   📋 journalctl -f | grep -iE 'radar|dfs|cac'"
            echo ""
            echo "Channel stability monitoring:"
            echo "   📋 watch -n 2 'iw dev $IFACE link | grep freq'"
            echo ""
            echo "Connection stability test:"
            echo "   📋 ping -i 1 8.8.8.8 | ts"
            echo "   💡 Look for gaps > 30 seconds (indicates radar detection)"
            echo ""
            ;;
        9)
            echo ""
            echo "🆘 Emergency fixes - Choose your emergency type:"
            echo ""
            echo "1) Complete WiFi failure (not connecting at all)"
            echo "2) Frequent disconnections (working but unstable)"
            echo "3) Very slow speeds (connected but poor performance)"
            echo "4) Overheating system (fans spinning, hot)"
            echo ""
            echo -n "Emergency type [1-4]: "
            read -r emergency_type
            
            case $emergency_type in
                1)
                    echo ""
                    echo "🚨 EMERGENCY: Complete WiFi failure fixes"
                    echo ""
                    echo "Try these in order, test after each:"
                    echo ""
                    echo "1. Restart network services:"
                    echo "   sudo systemctl restart NetworkManager"
                    echo "   sudo systemctl restart wpa_supplicant"
                    echo ""
                    echo "2. Reset WiFi driver:"
                    echo "   sudo modprobe -r $DRIVER && sleep 5 && sudo modprobe $DRIVER"
                    echo ""
                    echo "3. Turn WiFi off and on:"
                    echo "   sudo nmcli radio wifi off && sleep 5 && sudo nmcli radio wifi on"
                    echo ""
                    echo "4. Reset regulatory domain:"
                    echo "   sudo iw reg set US  # (or your country code)"
                    echo ""
                    echo "5. If nothing works - reboot:"
                    echo "   sudo reboot"
                    ;;
                2)
                    echo ""
                    echo "🚨 EMERGENCY: Disconnection fixes"
                    echo ""
                    if [ "$DFS_CURRENT_CONNECTION" = true ]; then
                        echo "🎯 DFS detected - likely cause of disconnections!"
                        echo ""
                        echo "Emergency DFS fix:"
                        if [ -n "$CURRENT_SSID" ]; then
                            echo "   sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                            echo "   sudo nmcli connection up \"$CURRENT_SSID\""
                        fi
                    else
                        echo "Emergency stability fixes:"
                        echo ""
                        echo "1. Disable power saving:"
                        echo "   sudo iw dev $IFACE set power_save off"
                        echo ""
                        echo "2. Force 2.4GHz (most stable):"
                        if [ -n "$CURRENT_SSID" ]; then
                            echo "   sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                        fi
                    fi
                    ;;
                3)
                    echo ""
                    echo "🚨 EMERGENCY: Speed improvement fixes"
                    echo ""
                    echo "1. Switch to 5GHz:"
                    if [ -n "$CURRENT_SSID" ]; then
                        echo "   sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band a"
                    fi
                    echo ""
                    echo "2. Disable power saving:"
                    echo "   sudo iw dev $IFACE set power_save off"
                    echo ""
                    ;;
                4)
                    echo ""
                    echo "🚨 EMERGENCY: Overheating fixes"
                    echo ""
                    echo "1. Enable power saving:"
                    echo "   sudo iw dev $IFACE set power_save on"
                    echo ""
                    echo "2. Set CPU governor to powersave:"
                    echo "   echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
                    echo ""
                    echo "3. Force 2.4GHz (lower power):"
                    if [ -n "$CURRENT_SSID" ]; then
                        echo "   sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
                    fi
                    ;;
            esac
            ;;
        10)
            echo ""
            echo "🔍 Running comprehensive diagnostic first..."
            complete_wifi_analysis
            echo ""
            echo "Based on diagnostic results, what specific issue do you see?"
            echo "Re-run this option (3) and select specific issue number."
            ;;
        *)
            echo ""
            echo "❌ Invalid option selected"
            echo "💡 Please select a number between 1-10"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}💡 TIP: Save these modern commands for future use!${NC}"
    echo "📋 All solutions are tailored for your $DISTRO_NAME system"
    if [ "$DFS_IMPACT_SCORE" -gt 25 ]; then
        echo "📡 DFS considerations included for radar-free operation"
    fi
    echo ""
}

# DFS-specific recommendations
provide_dfs_recommendations() {
    echo -e "${CYAN}💡 === DFS OPTIMIZATION RECOMMENDATIONS ===${NC}"
    echo ""
    
    # Sanitize variables at start of function
    DFS_COUNT=$(sanitize_number "$DFS_COUNT" "0")
    DFS_RADAR_EVENTS=$(sanitize_number "$DFS_RADAR_EVENTS" "0")
    
    if [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo "🎯 IMMEDIATE ACTIONS (Currently on DFS channel):"
        echo ""
        echo "1. Switch to non-DFS channel:"
        if [ -n "$CURRENT_SSID" ]; then
            echo "   🔧 Force 2.4GHz (no DFS): sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
            echo "   🔧 Force low 5GHz (36-48): Configure router to use channels 36, 40, 44, 48"
            echo "   🔧 Force high 5GHz (149+): Configure router to use channels 149, 153, 157, 161, 165"
        fi
        echo ""
        echo "2. Router configuration (PRIORITY FIX):"
        echo "   🔧 Set primary 5GHz channel to: 36, 40, 44, 48 (low band, no DFS)"
        echo "   🔧 Alternative channels: 149, 153, 157, 161, 165 (high band, no DFS)"
        echo "   🔧 Disable automatic channel selection if using DFS channels"
        echo "   🔧 Disable DFS channels entirely in router settings (if available)"
        echo ""
    fi
    
    if [ "$DFS_COUNT" -gt 5 ] || [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
        echo "🎯 ENVIRONMENT OPTIMIZATION (High DFS area):"
        echo ""
        echo "1. Preferred channel strategy:"
        echo "   📡 2.4GHz: Channels 1, 6, 11 (no DFS, good for basic connectivity)"
        echo "   📡 5GHz Low: Channels 36, 40, 44, 48 (no DFS, universally available)"
        echo "   📡 5GHz High: Channels 149, 153, 157, 161, 165 (no DFS, less congested)"
        echo ""
        echo "2. Modern WiFi 6E/7 optimization:"
        if [ "$SUPPORTS_WIFI7" = true ] || echo "$CHIP_MODEL" | grep -qi "6E\|mt7922\|ax210\|ax211"; then
            echo "   🌟 6GHz migration: NO DFS in 6GHz band!"
            echo "   🔧 Router upgrade: WiFi 6E/7 with 6GHz eliminates DFS issues"
            echo "   💡 6GHz channels 1-233 are all non-DFS"
        else
            echo "   💡 Consider WiFi 6E/7 hardware upgrade for DFS-free 6GHz"
        fi
        echo ""
    fi
    
    echo "🎯 MONITORING & PREVENTION:"
    echo ""
    echo "1. DFS event monitoring:"
    echo "   🔍 Monitor logs: journalctl -f | grep -i 'radar\\|dfs\\|cac'"
    echo "   🔍 Check current channel: watch -n 5 'iw dev $IFACE link | grep freq'"
    echo ""
    echo "2. Router firmware updates:"
    echo "   🔧 Update router firmware (better DFS handling)"
    echo "   🔧 Check for radar detection sensitivity settings"
    echo ""
    echo "3. Connection profile optimization:"
    if [ -n "$CURRENT_SSID" ]; then
        echo "   🔧 Create separate 2.4GHz profile: nmcli connection clone \"$CURRENT_SSID\" \"${CURRENT_SSID}_24G\""
        echo "   🔧 Configure 2.4GHz-only: nmcli connection modify \"${CURRENT_SSID}_24G\" 802-11-wireless.band bg"
    fi
    echo ""
    
    # Advanced DFS recommendations
    echo "🎯 ADVANCED DFS MITIGATION:"
    echo ""
    echo "1. Router-side DFS configuration:"
    echo "   🔧 Disable band steering (prevents automatic DFS channel selection)"
    echo "   🔧 Set static channels: Use channel planning tool to avoid DFS"
    echo "   🔧 Regional optimization: Verify router region matches your location"
    echo ""
    echo "2. Professional environments:"
    echo "   🔧 Site survey: Use WiFi analyzer to map DFS usage patterns"
    echo "   🔧 Channel planning: Coordinate with neighboring networks"
    echo "   🔧 Enterprise APs: Use DFS-aware management systems"
    echo ""
    
    if [ "$DFS_RADAR_EVENTS" -gt 0 ]; then
        echo "🚨 RADAR ENVIRONMENT SPECIFIC:"
        echo ""
        echo "1. Identify radar sources:"
        echo "   📡 Weather radar (permanent, predictable patterns)"
        echo "   📡 Military radar (temporary, high impact)"
        echo "   📡 Aviation radar (permanent near airports)"
        echo ""
        echo "2. Mitigation strategies:"
        echo "   🔧 Relocate equipment away from radar sources"
        echo "   🔧 Use directional antennas to reduce radar reception"
        echo "   🔧 Implement automatic channel switching (smart routers)"
        echo ""
    fi
}

# Dedicated DFS Channel Monitor - COMPLETE
dfs_channel_monitor() {
    echo -e "${BOLD}${MAGENTA}📡 === DFS CHANNEL MONITOR ===${NC}"
    echo "🔍 Dedicated Dynamic Frequency Selection and radar interference analysis"
    echo ""
    
    # Quick system check first
    gather_system_intelligence >/dev/null 2>&1
    
    # Run comprehensive DFS analysis
    analyze_dfs_channels
    
    echo ""
    provide_dfs_recommendations
    
    echo ""
    echo -e "${CYAN}🔍 === DFS MONITORING COMMANDS ===${NC}"
    echo ""
    echo "Real-time DFS monitoring commands you can run:"
    echo ""
    echo "1. Monitor for radar events:"
    echo "   📋 REALTIME: journalctl -f | grep -iE 'radar|dfs|cac'"
    echo ""
    echo "2. Watch channel changes:"
    echo "   📋 REALTIME: watch -n 2 'iw dev $IFACE link | grep freq'"
    echo ""
    echo "3. Scan for DFS channels in area:"
    echo "   📋 PERIODIC: iw dev $IFACE scan | grep -E 'freq: 5[2-6][0-9][0-9]|freq: 51[0-9][0-9]|SSID'"
    echo ""
    echo "4. Check regulatory domain:"
    echo "   📋 STATUS: iw reg get"
    echo ""
    echo "5. Monitor connection stability:"
    echo "   📋 CONTINUOUS: ping -i 1 8.8.8.8 | while read pong; do echo \"\$(date): \$pong\"; done"
    echo ""
    
    if [ "$DFS_CURRENT_CONNECTION" = true ]; then
        echo -e "${RED}🚨 IMMEDIATE ACTION ITEMS:${NC}"
        echo ""
        echo "Your current connection uses a DFS channel. To eliminate radar-related"
        echo "disconnections, implement these fixes immediately:"
        echo ""
        echo "Router-side fixes (RECOMMENDED):"
        echo "• Change router channel to: 36, 40, 44, 48 (low 5GHz, no DFS)"
        echo "• Alternative channels: 149, 153, 157, 161, 165 (high 5GHz, no DFS)"
        echo "• Disable automatic channel selection"
        echo "• Disable DFS channels entirely if router supports it"
        echo ""
        echo "Client-side temporary fix:"
        if [ -n "$CURRENT_SSID" ]; then
            echo "sudo nmcli connection modify \"$CURRENT_SSID\" 802-11-wireless.band bg"
            echo "sudo nmcli connection up \"$CURRENT_SSID\""
            echo "(Forces 2.4GHz connection - no DFS channels exist in 2.4GHz)"
        fi
        echo ""
    fi
    
    echo -e "${GREEN}💡 DFS-Free Future: WiFi 6E/7 with 6GHz${NC}"
    echo ""
    echo "The 6GHz band (WiFi 6E/7) contains NO DFS channels:"
    echo "• All 6GHz channels (1-233) are DFS-free"
    echo "• No radar interference possible"
    echo "• Clean spectrum with minimal congestion"
    echo "• Requires WiFi 6E/7 hardware and router"
    echo ""
    
    if [ "$SUPPORTS_WIFI7" = true ] || echo "$CHIP_MODEL" | grep -qi "6E"; then
        echo "✅ Your hardware supports 6GHz!"
        echo "💡 Upgrade to WiFi 6E/7 router for DFS-free operation"
    else
        echo "💡 Consider WiFi 6E/7 hardware upgrade for DFS-free future"
    fi

    echo ""
    echo -e "${CYAN}🔧 === SMART CHANNEL SWITCHING ===${NC}"
    echo ""
    echo "Would you like to run the Smart Channel Switcher to avoid DFS issues? [y/N]"
    read -r switcher_choice
    
    if [[ "$switcher_choice" =~ ^[Yy]$ ]]; then
        echo ""
        smart_channel_switcher
    else
        echo ""
        echo "💡 You can manually run channel switching commands:"
        echo "   • Emergency 2.4GHz: sudo nmcli connection modify \"NETWORK_NAME\" 802-11-wireless.band bg"
        echo "   • Safe 5GHz channels: 36, 40, 44, 48, 149, 153, 157, 161, 165"
        echo "   • Example: sudo nmcli connection modify \"NETWORK_NAME\" 802-11-wireless.channel 44"
    fi
}

# Smart DFS Channel Switcher - COMPLETE
smart_channel_switcher() {
    echo -e "${BOLD}${GREEN}🔧 === SMART DFS CHANNEL SWITCHER ===${NC}"
    echo "🎯 Intelligent channel switching to avoid DFS interference"
    echo ""
    
    # Get current active connection
    ACTIVE_CONNECTION=$(nmcli -t connection show --active | grep -E "wifi|802-11-wireless" | head -1 | cut -d: -f1)
    
    if [ -z "$ACTIVE_CONNECTION" ]; then
        echo -e "${RED}❌ No active WiFi connection detected${NC}"
        echo "💡 Connect to WiFi first, then run this tool"
        return 1
    fi
    
    echo "📡 Current active connection: $ACTIVE_CONNECTION"
    
    # Get current connection details
    CURRENT_CHANNEL=$(nmcli connection show "$ACTIVE_CONNECTION" | grep "802-11-wireless.channel:" | awk '{print $2}')
    CURRENT_BAND=$(nmcli connection show "$ACTIVE_CONNECTION" | grep "802-11-wireless.band:" | awk '{print $2}')
    CURRENT_FREQ_LINK=$(iw dev "$IFACE" link 2>/dev/null | grep "freq:" | awk '{print $2}')
    
    echo "📊 Current configuration:"
    echo "   Channel setting: ${CURRENT_CHANNEL:-auto}"
    echo "   Band setting: ${CURRENT_BAND:-auto}"
    echo "   Actual frequency: ${CURRENT_FREQ_LINK:-unknown} MHz"
    
    # Analyze current DFS status
    local current_dfs_risk="Unknown"
    if [ -n "$CURRENT_FREQ_LINK" ]; then
        FREQ_INT=$(printf "%.0f" "$CURRENT_FREQ_LINK" 2>/dev/null || echo "$CURRENT_FREQ_LINK" | cut -d'.' -f1)
        CHANNEL_NUM=$(freq_to_channel "$FREQ_INT")
        
        if is_dfs_channel "$CHANNEL_NUM"; then
            current_dfs_risk="HIGH - Currently on DFS channel $CHANNEL_NUM"
        else
            current_dfs_risk="LOW - Currently on non-DFS channel $CHANNEL_NUM"
        fi
    fi
    
    echo "   DFS Risk: $current_dfs_risk"
    echo ""
    
    # Safe channel recommendations based on scan results
    echo "🔍 Analyzing environment for optimal safe channels..."
    echo ""
    
    # Define safe channels with priorities
    declare -A SAFE_CHANNELS
    SAFE_CHANNELS[36]="5180"
    SAFE_CHANNELS[40]="5200" 
    SAFE_CHANNELS[44]="5220"
    SAFE_CHANNELS[48]="5240"
    SAFE_CHANNELS[149]="5745"
    SAFE_CHANNELS[153]="5765"
    SAFE_CHANNELS[157]="5785"
    SAFE_CHANNELS[161]="5805"
    SAFE_CHANNELS[165]="5825"
    
    # Analyze congestion on safe channels
    echo "📊 Safe channel analysis:"
    for channel in 36 40 44 48 149 153 157 161 165; do
        freq=${SAFE_CHANNELS[$channel]}
        # Count networks on this frequency
        count=$(echo "$SCAN_RESULTS" | grep "freq: $freq" | wc -l 2>/dev/null || echo "0")
        
        if [ "$count" -eq 0 ]; then
            echo -e "   ${GREEN}✅ Channel $channel ($freq MHz): CLEAR (0 networks)${NC}"
        elif [ "$count" -le 2 ]; then
            echo -e "   ${YELLOW}📊 Channel $channel ($freq MHz): Light usage ($count networks)${NC}"
        else
            echo -e "   ${RED}🚨 Channel $channel ($freq MHz): Congested ($count networks)${NC}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}🎯 === CHANNEL SWITCHING OPTIONS ===${NC}"
    echo ""
    
    # Option 1: Emergency 2.4GHz fallback
    echo "1) 🚨 EMERGENCY: Force 2.4GHz (guaranteed DFS-free)"
    echo "   Command: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band bg"
    echo "   Effect: Immediate stability, reduced speed"
    echo "   Use when: Frequent disconnections, need immediate fix"
    echo ""
    
    # Option 2: Best available safe 5GHz channel
    echo "2) 🎯 OPTIMAL: Switch to best available safe 5GHz channel"
    
    # Find least congested safe channel
    best_channel=""
    min_count=999
    for channel in 44 36 40 48 157 149 153 161 165; do  # Prioritize 44 and 157
        freq=${SAFE_CHANNELS[$channel]}
        count=$(echo "$SCAN_RESULTS" | grep "freq: $freq" | wc -l 2>/dev/null || echo "0")
        if [ "$count" -lt "$min_count" ]; then
            min_count=$count
            best_channel=$channel
        fi
    done
    
    if [ -n "$best_channel" ]; then
        echo "   Recommended: Channel $best_channel (${SAFE_CHANNELS[$best_channel]} MHz) - $min_count networks detected"
        echo "   Commands:"
        echo "     sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel $best_channel"
        echo "     sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band a"
        echo "     sudo nmcli connection up \"$ACTIVE_CONNECTION\""
    fi
    echo ""
    
    # Option 3: Manual channel selection
    echo "3) 🔧 MANUAL: Choose specific safe channel"
    echo "   Low 5GHz band (best for compatibility):"
    echo "     Channel 36: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 36"
    echo "     Channel 44: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 44"
    echo "     Channel 48: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 48"
    echo ""
    echo "   High 5GHz band (often less congested):"
    echo "     Channel 149: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 149"
    echo "     Channel 157: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 157"
    echo "     Channel 161: sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel 161"
    echo ""
    echo "   After setting channel: sudo nmcli connection up \"$ACTIVE_CONNECTION\""
    echo ""
    
    # Option 4: Reset to auto (remove manual settings)
    echo "4) 🔄 RESET: Return to automatic channel selection"
    echo "   Commands:"
    echo "     sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.channel ''"
    echo "     sudo nmcli connection modify \"$ACTIVE_CONNECTION\" 802-11-wireless.band ''"
    echo "     sudo nmcli connection up \"$ACTIVE_CONNECTION\""
    echo "   Warning: May select DFS channels again in congested areas"
    echo ""
    
    # Interactive execution option
    echo -e "${YELLOW}💡 Would you like to execute one of these options now? [y/N]${NC}"
    read -r execute_choice
    
    if [[ "$execute_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Select option to execute:"
        echo "1) Emergency 2.4GHz"
        echo "2) Optimal safe 5GHz (Channel $best_channel)"
        echo "3) Manual channel (specify)"
        echo "4) Reset to auto"
        echo "5) Cancel"
        echo ""
        echo -n "Choice [1-5]: "
        read -r exec_option
        
        case $exec_option in
            1)
                echo "🚨 Switching to 2.4GHz (DFS-free)..."
                sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band bg
                sudo nmcli connection up "$ACTIVE_CONNECTION"
                echo "✅ Switched to 2.4GHz band"
                ;;
            2)
                if [ -n "$best_channel" ]; then
                    echo "🎯 Switching to optimal channel $best_channel..."
                    sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.channel "$best_channel"
                    sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a
                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                    echo "✅ Switched to channel $best_channel (5GHz)"
                else
                    echo "❌ Could not determine best channel"
                fi
                ;;
            3)
                echo -n "Enter channel number (36,40,44,48,149,153,157,161,165): "
                read -r manual_channel
                if [[ "$manual_channel" =~ ^(36|40|44|48|149|153|157|161|165)$ ]]; then
                    echo "🔧 Switching to manual channel $manual_channel..."
                    sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.channel "$manual_channel"
                    sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band a
                    sudo nmcli connection up "$ACTIVE_CONNECTION"
                    echo "✅ Switched to channel $manual_channel"
                else
                    echo "❌ Invalid channel. Must be: 36,40,44,48,149,153,157,161,165"
                fi
                ;;
            4)
                echo "🔄 Resetting to automatic selection..."
                sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.channel ""
                sudo nmcli connection modify "$ACTIVE_CONNECTION" 802-11-wireless.band ""
                sudo nmcli connection up "$ACTIVE_CONNECTION"
                echo "✅ Reset to automatic channel selection"
                ;;
            5)
                echo "Cancelled - no changes made"
                ;;
            *)
                echo "❌ Invalid option"
                ;;
        esac
        
        if [[ "$exec_option" =~ ^[1-4]$ ]]; then
            echo ""
            echo "🔍 Waiting 10 seconds for connection to stabilize..."
            sleep 10
            echo "📊 New connection status:"
            iw dev "$IFACE" link 2>/dev/null | grep -E "Connected|freq|signal" || echo "Connection info not available"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}💡 TIP: Save these commands for future use!${NC}"
    echo "📋 You can run these commands anytime DFS issues occur"
}

# Main execution with modern error checking
main() {
    # Check for required modern tools
    if ! command -v iw >/dev/null 2>&1; then
        echo -e "${RED}Error: 'iw' command not found${NC}"
        echo "Install with your package manager:"
        
        detect_distribution
        case "$DISTRO_ID" in
            "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
                echo "sudo dnf install iw wireless-tools"
                ;;
            "ubuntu"|"debian"|"pop"|"mint")
                echo "sudo apt install iw wireless-tools"
                ;;
            "arch"|"manjaro"|"endeavouros")
                echo "sudo pacman -S iw wireless_tools"
                ;;
            *)
                echo "Use your distribution's package manager to install 'iw'"
                ;;
        esac
        exit 1
    fi
    
    # Check for modern kernel
    KERNEL_VERSION=$(uname -r)
    KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f1)
    KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f2)
    
    if [ "$KERNEL_MAJOR" -lt 6 ]; then
        echo -e "${YELLOW}⚠️ Warning: Kernel $KERNEL_VERSION detected${NC}"
        echo "For best WiFi 7/6E support, consider kernel 6.8+ or newer"
        echo ""
    fi
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                complete_wifi_analysis | tee "wifi_analysis_2025_$(date +%Y%m%d_%H%M%S).log"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            2)
                error_analysis_troubleshooting | tee "wifi_errors_2025_$(date +%Y%m%d_%H%M%S).log"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            3)
                interactive_workaround_generator
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            4)
                dfs_channel_monitor | tee "dfs_analysis_$(date +%Y%m%d_%H%M%S).log"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            5)
                tx_power_band_test | tee "tx_power_test_$(date +%Y%m%d_%H%M%S).log"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            6)
                manual_band_switching | tee "band_switching_$(date +%Y%m%d_%H%M%S).log"
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            7)
                echo -e "${GREEN}🎯 WiFi Analysis complete! Modern networking with DFS monitoring awaits.${NC}"
                echo "Thank you for using the Enhanced WiFi Analyzer with DFS support!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
