#!/bin/bash

output_file="$(pwd)/combined_log.txt"  # Using current directory for input file
filtered_output_file="$(pwd)/filtered_log.txt"  # Using current directory for output file
summary_file="/tmp/summary_temp_$$_$(date +%s).txt"
focused_summary_file="/tmp/focused_summary_temp_$$_$(date +%s).txt"
recommendations_file="/tmp/recommendations_temp_$$_$(date +%s).txt"
error_context_file="/tmp/error_context_temp_$$_$(date +%s).txt"
error_codes_file="/tmp/error_codes_temp_$$_$(date +%s).txt"
state_changes_file="/tmp/state_changes_temp_$$_$(date +%s).txt"

# Cleanup function
cleanup_temp_files() {
    [ -f "$summary_file" ] && rm -f "$summary_file"
    [ -f "$focused_summary_file" ] && rm -f "$focused_summary_file"
    [ -f "$recommendations_file" ] && rm -f "$recommendations_file"
    [ -f "$error_context_file" ] && rm -f "$error_context_file"
    [ -f "$error_codes_file" ] && rm -f "$error_codes_file"
    [ -f "$state_changes_file" ] && rm -f "$state_changes_file"
}

# Set trap to cleanup on exit or interrupt
trap cleanup_temp_files EXIT INT TERM

# Initialize analysis files
> "$recommendations_file"
> "$error_context_file"
> "$error_codes_file" 
> "$state_changes_file"
> "$summary_file"
> "$focused_summary_file"

# Variables for context-aware analysis
previous_line=""
error_burst_window=30  # seconds
declare -A error_timestamps
declare -A device_states

# ANSI escape codes for text formatting
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Enhanced noise filter - filters out normal system operations that aren't actual problems
is_harmless_system_noise() {
    local line="$1"
    
    # === SECURITY/AUDIT NOISE (Normal system operations) ===
    [[ $line == *"audit"* && $line == *"CRED_ACQ"* ]] ||  # Normal credential acquisition
    [[ $line == *"audit"* && $line == *"CRED_DISP"* ]] ||  # Normal credential disposal
    [[ $line == *"audit"* && $line == *"USER_AUTH"* ]] ||  # Normal user authentication
    [[ $line == *"audit"* && $line == *"USER_ACCT"* ]] ||  # Normal user account access
    [[ $line == *"audit"* && $line == *"SESSION_OPEN"* ]] ||  # Normal session opening
    [[ $line == *"audit"* && $line == *"SESSION_CLOSE"* ]] ||  # Normal session closing
    
    # === DEVICE MANAGEMENT NOISE (Normal udev operations) ===
    [[ $line == *"udev-worker"* && $line == *"BAT"* && $line == *"chmod"* ]] ||  # Battery permission setup
    [[ $line == *"udev-worker"* && $line == *"ADP"* && $line == *"chmod"* ]] ||  # Power adapter permission setup
    [[ $line == *"udev-worker"* && $line == *"/sys/"* && $line == *"chmod"* ]] ||  # General device permissions
    [[ $line == *"udev-worker"* && $line == *"Process"* && $line == *"'/bin/chmod"* ]] ||  # Any chmod operations
    
    # === SYSTEMD SERVICE NOISE (Normal service management) ===
    [[ $line == *"systemd"* && $line == *"Starting"* ]] ||  # Service starting (normal)
    [[ $line == *"systemd"* && $line == *"Started"* ]] ||   # Service started (normal)
    [[ $line == *"systemd"* && $line == *"Stopping"* ]] ||  # Service stopping (normal)
    [[ $line == *"systemd"* && $line == *"Stopped"* ]] ||   # Service stopped (normal)
    [[ $line == *"systemd"* && $line == *"Reloading"* ]] ||  # Service reloading (normal)
    [[ $line == *"systemd"* && $line == *"Reloaded"* ]] ||   # Service reloaded (normal)
    [[ $line == *"systemd"* && $line == *"Deactivated successfully"* ]] ||  # Normal deactivation
    
    # === GNOME/DESKTOP NOISE ===
    [[ $line == *"gnome-shell"* ]] ||  # All gnome-shell messages (usually UI glitches)
    [[ $line == *"org.gnome"* ]] ||    # GNOME application messages
    [[ $line == *"gvfsd"* ]] ||        # GNOME virtual filesystem
    
    # === FRAMEWORK-SPECIFIC HARMLESS NOISE ===
    [[ $line == *"platform regulatory.0: Direct firmware load for regulatory.db failed"* ]] ||
    [[ $line == *"cros_ec_lpcs"* && $line == *"EC communication failed"* ]] ||
    [[ $line == *"ACPI BIOS Error"* && $line == *"AE_NOT_FOUND"* ]] ||
    [[ $line == *"intel_pstate"* && $line == *"Unknown P-state control mode"* ]] ||
    [[ $line == *"bluetooth hci0: Direct firmware load"* && $line == *"failed"* ]] ||
    [[ $line == *"rtw89"* && $line == *"firmware"* && $line == *"not found"* ]] ||
    [[ $line == *"iwlwifi"* && $line == *"api flags index"* && $line == *"larger than supported"* ]] ||
    [[ $line == *"ACPI"* && $line == *"_OSC failed"* && $line == *"not supported"* ]] ||
    [[ $line == *"platform efi-framebuffer.0: Cannot reserve"* && $line == *"resource"* ]] ||
    [[ $line == *"ucsi_ccg"* && $line == *"failed to reset PPM"* ]] ||
    [[ $line == *"ucsi_ccg"* && $line == *"PPM init failed"* ]] ||
    [[ $line == *"thunderbolt"* && $line == *"device disappeared"* ]] ||
    [[ $line == *"pcieport"* && $line == *"AER: Corrected error"* ]] ||
    [[ $line == *"pcieport"* && $line == *"PCIe Bus Error"* && $line == *"Corrected"* ]] ||
    [[ $line == *"ACPI Warning"* && $line == *"SystemIO range"* ]] ||
    [[ $line == *"ACPI Warning"* && $line == *"0x0000000000000400-0x000000000000041f"* ]] ||
    [[ $line == *"pci"* && $line == *"BAR"* && $line == *"bogus alignment"* ]] ||
    [[ $line == *"amd_pmc"* && $line == *"SMU debugging info"* ]] ||
    [[ $line == *"amdgpu"* && $line == *"WARN"* && $line == *"SMU feature is not enabled"* ]] ||
    [[ $line == *"mt7925e"* && $line == *"Message 00000010 (seq 1) timeout"* ]] ||
    [[ $line == *"rfkill"* && $line == *"input handler disabled"* ]] ||
    
    # === NETWORK MANAGER NOISE (Normal network operations) ===
    [[ $line == *"NetworkManager"* && $line == *"policy"* ]] ||  # Normal network policy
    [[ $line == *"wpa_supplicant"* && $line == *"Authentication"* ]] ||  # Normal WiFi auth
    
    # === POWER MANAGEMENT NOISE ===
    [[ $line == *"power_supply"* && $line == *"BAT"* ]] ||  # Normal battery events
    [[ $line == *"power_supply"* && $line == *"ADP"* ]] ||  # Normal adapter events
    
    # === TEMPORARY FILE SYSTEM NOISE ===
    [[ $line == *"tmpfiles"* ]] ||  # Temporary file management
    
    # === NORMAL KERNEL INFORMATIONAL MESSAGES ===
    [[ $line == *"kernel:"* && $line == *"Bluetooth:"* && $line == *"hci"* ]] ||  # Bluetooth info
    [[ $line == *"kernel:"* && $line == *"usb"* && $line == *"new"* ]] ||  # New USB device (normal)
    [[ $line == *"kernel:"* && $line == *"usb"* && $line == *"disconnect"* ]] &&  # USB disconnect (normal)
    return 0
    return 1
}

# Extract actual hardware details for context
get_device_details() {
    echo "Hardware Context:" >> "$output_file"
    
    # Get actual GPU info
    local gpu_info=$(lspci | grep -E "VGA|3D|Display")
    if [ -n "$gpu_info" ]; then
        echo "  GPU: $gpu_info" >> "$output_file"
    fi
    
    # Get NVMe/Storage info
    local nvme_info=$(lspci | grep -i "non-volatile\|nvme")
    if [ -n "$nvme_info" ]; then
        echo "  Storage: $nvme_info" >> "$output_file"
        # Get NVMe model names
        for nvme in /dev/nvme*n1; do
            if [ -e "$nvme" ]; then
                local model=$(sudo nvme id-ctrl "$nvme" 2>/dev/null | grep "mn " | awk '{print $2}' | xargs)
                if [ -n "$model" ]; then
                    echo "    $(basename $nvme): $model" >> "$output_file"
                fi
            fi
        done
    fi
    
    # Get WiFi card info
    local wifi_info=$(lspci | grep -iE "wireless|wifi|802\.11|network controller.*wi-fi|network controller.*MT79|network controller.*intel|network controller.*realtek|network controller.*broadcom|network controller.*mediatek")
    if [ -n "$wifi_info" ]; then
        echo "  WiFi: $wifi_info" >> "$output_file"
    fi
    
    # Get RAM info
    if command -v dmidecode >/dev/null 2>&1; then
        # Get total RAM size - dmidecode shows size in MB for each module
        local total_ram_mb=$(sudo dmidecode -t memory 2>/dev/null | grep "Size:" | grep -v "No Module Installed" | grep -v "Not Specified" | grep -E "[0-9]+ MB|[0-9]+ GB" | awk '
        BEGIN { sum = 0 }
        /MB/ { sum += $2 }
        /GB/ { sum += ($2 * 1024) }
        END { if (sum > 0) print sum }')
        
        local ram_speed=$(sudo dmidecode -t memory 2>/dev/null | grep "Configured Memory Speed:" | head -1 | awk '{print $4 " " $5}')
        local ram_type=$(sudo dmidecode -t memory 2>/dev/null | grep "Type:" | grep -v "Unknown" | grep -v "Error Correction Type" | head -1 | awk '{print $2}')
        
        if [ -n "$total_ram_mb" ] && [ "$total_ram_mb" -gt 0 ]; then
            local ram_gb=$((total_ram_mb / 1024))
            local ram_output="  RAM: ${ram_gb} GB"
            if [ -n "$ram_type" ] && [ "$ram_type" != "" ]; then
                ram_output="$ram_output $ram_type"
            fi
            if [ -n "$ram_speed" ] && [ "$ram_speed" != " " ]; then
                ram_output="$ram_output @ $ram_speed"
            fi
            echo "$ram_output" >> "$output_file"
        fi
    else
        # Fallback to /proc/meminfo
        local total_ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
        if [ -n "$total_ram_kb" ]; then
            local total_ram_gb=$((total_ram_kb / 1024 / 1024))
            echo "  RAM: ${total_ram_gb} GB (from /proc/meminfo)" >> "$output_file"
        fi
    fi
    
    echo "" >> "$output_file"
}

# Detect AMD CPU generation for appropriate thermal thresholds
detect_amd_generation() {
    # Use the already detected product/model information instead of parsing lscpu again
    if [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 13" ]]; then
        # Framework Laptop 13 uses modern AMD (7040+ series or AI 300)
        echo "modern"
    elif [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 16" ]]; then
        # Framework Laptop 16 uses modern AMD (7040 series)
        echo "modern"
    elif [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 12" ]]; then
        # Framework Laptop 12 uses Intel, but check if AMD variant exists
        echo "modern"
    elif [[ $PRODUCT_NAME =~ "Desktop" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Desktop" ]]; then
        # Framework Desktop uses modern AMD (AI Max 300 series)
        echo "modern"
    else
        # Fallback to lscpu parsing for non-Framework devices
        local cpu_model=$(lscpu | grep "Model name" | awk '{print substr($0, index($0,$3))}')
        if [[ $cpu_model =~ 7[4-9][0-9][0-9] ]] || [[ $cpu_model =~ 8[0-9][0-9][0-9] ]] || [[ $cpu_model =~ "AI " ]]; then
            echo "modern"
        else
            echo "legacy"
        fi
    fi
}

# Function to check real-time network connectivity
check_network_connectivity() {
    echo "  Network Connectivity:" >> "$output_file"
    
    # Check if any network interfaces are up
    local interfaces_up=$(ip link show | grep "state UP" | wc -l)
    
    # Test actual internet connectivity
    local internet_working=false
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        internet_working=true
        echo "    Internet: ✅ Connected" >> "$output_file"
    elif ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        internet_working=true
        echo "    Internet: ✅ Connected" >> "$output_file"
    else
        echo "    Internet: ❌ Not connected" >> "$output_file"
        echo "IMPORTANT|NETWORK_CONNECTIVITY|Your internet is not working right now → Check your WiFi connection, network cable, or contact your internet provider" >> "$recommendations_file"
    fi
    
    # Check WiFi status if available
    local wifi_connected=false
    if command -v iwconfig >/dev/null 2>&1; then
        local wifi_count=$(iwconfig 2>/dev/null | grep "ESSID" | grep -v "off/any" | wc -l)
        if [ "$wifi_count" -gt 0 ]; then
            wifi_connected=true
            local wifi_name=$(iwconfig 2>/dev/null | grep "ESSID" | grep -v "off/any" | head -1 | awk -F'"' '{print $2}')
            echo "    WiFi: ✅ Connected to \"$wifi_name\"" >> "$output_file"
        else
            echo "    WiFi: ❌ Not connected" >> "$output_file"
            if [ "$internet_working" = false ]; then
                echo "IMPORTANT|WIFI_CONNECTIVITY|Your WiFi is not connected → Check that WiFi is enabled and you're connected to your network" >> "$recommendations_file"
            fi
        fi
    fi
    
    # Check if ethernet is connected
    local ethernet_connected=$(ip link show | grep -E "eth|enp|eno" | grep "state UP" | wc -l)
    if [ "$ethernet_connected" -gt 0 ]; then
        echo "    Ethernet: ✅ Connected" >> "$output_file"
    else
        echo "    Ethernet: ❌ Not connected" >> "$output_file"
    fi
    
    # Set global variables for use in log analysis
    NETWORK_CURRENTLY_WORKING="$internet_working"
    WIFI_CURRENTLY_CONNECTED="$wifi_connected"
    
    echo "" >> "$output_file"
}
# Check current temperatures with Framework-specific thresholds
check_current_temperatures() {
    if command -v sensors >/dev/null 2>&1; then
        echo "  Thermal Status:" >> "$output_file"
        
        # Get CPU temperature from multiple sources (priority order)
        local cpu_temp=""
        local cpu_source=""
        
        # 1. Try k10temp Tctl (AMD primary)
        local tctl_temp=$(sensors 2>/dev/null | grep "Tctl:" | awk '{print $2}' | head -1 | sed 's/[+-]//g' | sed 's/°C//')
        if [ -n "$tctl_temp" ]; then
            cpu_temp="$tctl_temp"
            cpu_source="Tctl"
        else
            # 2. Try Package temp (Intel primary)
            local package_temp=$(sensors 2>/dev/null | grep "Package" | awk '{print $3}' | head -1 | sed 's/[+-]//g' | sed 's/°C//')
            if [ -n "$package_temp" ]; then
                cpu_temp="$package_temp"
                cpu_source="Package"
            else
                # 3. Try Core 0 or cpu@4c (alternatives)
                local core_temp=$(sensors 2>/dev/null | grep -E "Core.*0:|cpu@4c:" | awk '{print $3}' | head -1 | sed 's/[+-]//g' | sed 's/°C//')
                if [ -n "$core_temp" ]; then
                    cpu_temp="$core_temp"
                    cpu_source="Core"
                fi
            fi
        fi
        
        # Display all sensor output (condensed)
        sensors 2>/dev/null | grep -E "Tctl|Package|edge|Composite|cpu@4c" >> "$output_file"
        
        # Apply temperature thresholds if we got a reading
        if [ -n "$cpu_temp" ] && [[ $cpu_temp =~ ^[0-9]+\.?[0-9]*$ ]]; then
            local temp_int=$(printf "%.0f" "$cpu_temp")
            
            # Detect CPU architecture for appropriate thresholds
            local cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')
            local is_framework_detected=false
            
            # Check if this is a Framework device
            if [[ $PRODUCT_NAME =~ Framework ]] || [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $PRODUCT_NAME =~ "Desktop" ]]; then
                is_framework_detected=true
            fi
            
            # Apply Framework-specific AMD thresholds with generation detection
            if [[ $cpu_vendor == "AuthenticAMD" ]] || [[ $cpu_vendor == "AMD" ]]; then
                local amd_generation=$(detect_amd_generation)
                
                if [[ $amd_generation == "modern" ]]; then
                    # AMD 7040+ series - designed to run hotter safely
                    if [ "$temp_int" -ge 105 ]; then
                        echo "IMMEDIATE|THERMAL_EMERGENCY|Your processor is dangerously hot (${cpu_temp}°C) → Your laptop will shut down to protect itself. Stop using immediately, check that air vents aren't blocked, and let it cool down completely before using again" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 100 ]; then
                        echo "URGENT|THERMAL_CRITICAL|Your processor is running very hot (${cpu_temp}°C) → This sustained high temperature could damage your laptop. Close demanding programs, ensure air vents are clear, and consider using a laptop cooling pad" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 95 ]; then
                        echo "INFORMATIONAL|THERMAL_THROTTLING|Your processor is hot but this is normal (${cpu_temp}°C) → Modern AMD processors are designed to run at these temperatures under heavy load. Your laptop is automatically slowing down to stay cool" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 90 ] && [ "$is_framework_detected" = true ]; then
                        echo "PREVENTIVE|THERMAL_ELEVATED|Your processor temperature is elevated (${cpu_temp}°C) → Consider reducing your workload or closing some programs if the laptop feels warm" >> "$recommendations_file"
                    fi
                    
                    # Temperature display for modern AMD
                    if [ "$is_framework_detected" = true ]; then
                        echo "    Current CPU: ${cpu_temp}°C via ${cpu_source} (Modern AMD: runs hot by design - watch at 90°C, throttles at 95°C, critical at 100°C, emergency at 105°C)" >> "$output_file"
                    else
                        echo "    Current CPU: ${cpu_temp}°C via ${cpu_source}" >> "$output_file"
                    fi
                else
                    # Legacy AMD processors - more conservative thresholds
                    if [ "$temp_int" -ge 105 ]; then
                        echo "IMMEDIATE|THERMAL_EMERGENCY|Your processor is dangerously hot (${cpu_temp}°C) → Your laptop will shut down to protect itself. Stop using immediately, check that air vents aren't blocked, and let it cool down completely" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 95 ]; then
                        echo "URGENT|THERMAL_CRITICAL|Your processor is too hot (${cpu_temp}°C) → This could damage your laptop. Close demanding programs immediately, check that air vents are clear, and reduce your workload" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 90 ]; then
                        echo "IMPORTANT|THERMAL_WARNING|Your processor is running hot (${cpu_temp}°C) → This is too hot for older AMD processors. Close some programs and make sure air vents aren't blocked" >> "$recommendations_file"
                    elif [ "$temp_int" -ge 85 ] && [ "$is_framework_detected" = true ]; then
                        echo "PREVENTIVE|THERMAL_ELEVATED|Your processor temperature is elevated (${cpu_temp}°C) → Consider reducing your workload to keep temperatures lower" >> "$recommendations_file"
                    fi
                    
                    # Temperature display for legacy AMD
                    if [ "$is_framework_detected" = true ]; then
                        echo "    Current CPU: ${cpu_temp}°C via ${cpu_source} (Older AMD: watch at 85°C, warning at 90°C, critical at 95°C, emergency at 105°C)" >> "$output_file"
                    else
                        echo "    Current CPU: ${cpu_temp}°C via ${cpu_source}" >> "$output_file"
                    fi
                fi
            else
                # Intel Framework thresholds - lower due to cooler operation
                if [ "$temp_int" -ge 100 ]; then
                    echo "IMMEDIATE|THERMAL_EMERGENCY|Your processor is dangerously hot (${cpu_temp}°C) → Your laptop will shut down to protect itself. Stop using immediately, check that air vents aren't blocked, and let it cool down completely" >> "$recommendations_file"
                elif [ "$temp_int" -ge 90 ]; then
                    echo "URGENT|THERMAL_CRITICAL|Your Intel processor is too hot (${cpu_temp}°C) → This could damage your laptop. Close demanding programs immediately, check that air vents are clear, and reduce your workload" >> "$recommendations_file"
                elif [ "$temp_int" -ge 85 ]; then
                    echo "IMPORTANT|THERMAL_WARNING|Your Intel processor is running hot (${cpu_temp}°C) → Close some programs and make sure air vents aren't blocked. Intel processors should run cooler than this" >> "$recommendations_file"
                elif [ "$temp_int" -ge 80 ] && [ "$is_framework_detected" = true ]; then
                    echo "PREVENTIVE|THERMAL_ELEVATED|Your Intel processor temperature is elevated (${cpu_temp}°C) → Consider reducing your workload to keep temperatures lower" >> "$recommendations_file"
                fi
                
                if [ "$is_framework_detected" = true ]; then
                    echo "    Current CPU: ${cpu_temp}°C via ${cpu_source} (Intel: watch at 80°C, warning at 85°C, critical at 90°C, emergency at 100°C)" >> "$output_file"
                else
                    echo "    Current CPU: ${cpu_temp}°C via ${cpu_source}" >> "$output_file"
                fi
            fi
            
            # Check GPU temperature if available
            local gpu_temp=$(sensors 2>/dev/null | grep "edge:" | awk '{print $2}' | head -1 | sed 's/[+-]//g' | sed 's/°C//')
            if [ -n "$gpu_temp" ] && [[ $gpu_temp =~ ^[0-9]+\.?[0-9]*$ ]]; then
                local gpu_temp_int=$(printf "%.0f" "$gpu_temp")
                if [ "$gpu_temp_int" -ge 95 ]; then
                    echo "URGENT|GPU_THERMAL|Your graphics card is dangerously hot (${gpu_temp}°C) → Close games, video editing software, or other graphics-intensive programs immediately to prevent damage" >> "$recommendations_file"
                elif [ "$gpu_temp_int" -ge 85 ]; then
                    echo "IMPORTANT|GPU_THERMAL|Your graphics card is running hot (${gpu_temp}°C) → Consider reducing graphics settings in games or closing graphics-intensive programs" >> "$recommendations_file"
                fi
                echo "    Current GPU: ${gpu_temp}°C (starts getting warm at 85°C, critical at 95°C)" >> "$output_file"
            fi
            
        else
            echo "    Thermal sensors not accessible or no temperature reading available" >> "$output_file"
        fi
    fi
}

# Parse error codes and frequencies
parse_error_codes() {
    local line="$1"
    # Extract structured error information
    local error_code=""
    
    if [[ $line =~ error\ -([0-9]+) ]]; then
        error_code="errno_${BASH_REMATCH[1]}"
    elif [[ $line =~ errno=([0-9]+) ]]; then
        error_code="errno_${BASH_REMATCH[1]}"
    elif [[ $line =~ fault\ (0x[0-9a-f]+) ]]; then
        error_code="fault_${BASH_REMATCH[1]}"
    elif [[ $line =~ "I/O error" ]]; then
        error_code="io_error"
    elif [[ $line =~ "timeout" ]]; then
        error_code="timeout"
    elif [[ $line =~ "hang" ]]; then
        error_code="hang"
    fi
    
    if [ -n "$error_code" ]; then
        echo "$error_code|$line" >> "$error_codes_file"
    fi
}

# Track device state changes
track_state_changes() {
    local line="$1"
    local timestamp="$2"
    
    # USB device state changes
    if [[ $line =~ "USB disconnect, address ([0-9]+)" ]]; then
        device_states["usb_${BASH_REMATCH[1]}"]="disconnected:$timestamp"
        echo "USB_DISCONNECT|$timestamp|$line" >> "$state_changes_file"
    elif [[ $line =~ "new.*USB device.*address ([0-9]+)" ]]; then
        local addr="${BASH_REMATCH[1]}"
        if [[ -n "${device_states["usb_$addr"]}" ]]; then
            echo "USB_RECONNECT|$timestamp|$line" >> "$state_changes_file"
        else
            echo "USB_CONNECT|$timestamp|$line" >> "$state_changes_file"
        fi
        device_states["usb_$addr"]="connected:$timestamp"
    fi
    
    # Thermal state changes
    if [[ $line =~ "thermal.*throttling" ]]; then
        device_states["thermal"]="throttling:$timestamp"
        echo "THERMAL_THROTTLE|$timestamp|$line" >> "$state_changes_file"
    elif [[ $line =~ "thermal.*normal" ]]; then
        if [[ "${device_states["thermal"]}" =~ throttling ]]; then
            echo "THERMAL_RECOVERY|$timestamp|$line" >> "$state_changes_file"
        fi
        device_states["thermal"]="normal:$timestamp"
    fi
    
    # GPU state changes
    if [[ $line =~ "amdgpu.*ring.*timeout" ]]; then
        device_states["gpu"]="hang:$timestamp"
        echo "GPU_HANG|$timestamp|$line" >> "$state_changes_file"
    elif [[ $line =~ "amdgpu.*ring.*recovered" ]]; then
        if [[ "${device_states["gpu"]}" =~ hang ]]; then
            echo "GPU_RECOVERY|$timestamp|$line" >> "$state_changes_file"
        fi
        device_states["gpu"]="recovered:$timestamp"
    fi
}

# Context-aware error analysis
analyze_error_context() {
    local current_line="$1"
    local timestamp="$2"
    
    # GPU hang sequences
    if [[ $current_line =~ "amdgpu.*timeout" ]] && [[ $previous_line =~ "amdgpu.*ring" ]]; then
        echo "GPU_HANG_SEQUENCE|$timestamp|Ring timeout followed by GPU timeout" >> "$error_context_file"
        return 0
    fi
    
    # NVMe controller reset sequences
    if [[ $current_line =~ "nvme.*reset controller" ]] && [[ $previous_line =~ "nvme.*I/O.*timeout" ]]; then
        echo "NVME_RESET_SEQUENCE|$timestamp|I/O timeout triggered controller reset" >> "$error_context_file"
        return 0
    fi
    
    # USB enumeration failure patterns
    if [[ $current_line =~ "device not accepting address" ]] && [[ $previous_line =~ "USB disconnect" ]]; then
        echo "USB_ENUM_FAILURE|$timestamp|Disconnect followed by enumeration failure" >> "$error_context_file"
        return 0
    fi
    
    # EC timeout patterns
    if [[ $current_line =~ "cros_ec.*timeout" ]] && [[ $previous_line =~ "cros_ec.*command" ]]; then
        echo "EC_COMMAND_TIMEOUT|$timestamp|EC command timeout sequence" >> "$error_context_file"
        return 0
    fi
    
    return 1
}

# Enhanced function to translate technical errors into plain English
analyze_and_recommend() {
    local log_line="$1"
    
    # Critical GPU hangs - model-specific charger recommendations with plain English
    if [[ $log_line =~ amdgpu.*ring.*timeout|amdgpu.*job.*timeout|amdgpu.*GPU.*hang ]]; then
        local charger_spec=""
        local plain_english="Your computer's graphics stopped working and might have crashed. This usually happens when your charger isn't powerful enough, your graphics need updating, or your computer is too hot."
        
        if [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 13" ]] ||
           [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 12" ]]; then
            charger_spec="verify you're using the official 60W charger"
            plain_english="$plain_english Make sure you're using the official Framework 60W charger that came with your laptop (not a phone charger)."
        elif [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 16" ]]; then
            charger_spec="verify you're using the official 180W charger"
            plain_english="$plain_english Make sure you're using the official Framework 180W charger (the big one that came with your Laptop 16)."
        elif [[ $PRODUCT_NAME =~ "Desktop" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Desktop" ]]; then
            charger_spec="check power supply connections"
            plain_english="$plain_english Check that all power cables are plugged in properly to your desktop."
        else
            charger_spec="verify adequate power supply"
            plain_english="$plain_english Check that your charger is working and plugged in properly."
        fi
        
        echo "URGENT|GPU_HANG|Your computer's graphics crashed → $plain_english Also check for graphics updates and contact support if this keeps happening" >> "$recommendations_file"
        return
    fi
    
    # Additional serious hardware issues that cause crashes/freezes
if [[ $log_line =~ "i915.*GPU.*hang"|"i915.*reset"|"drm.*GPU.*hang"|"Machine check"|"mce:"|"MCE:"|"DMAR.*fault"|"IOMMU.*fault"|"DMA.*fault"|"CPU.*failed"|"processor.*failed"|"SMP.*failed" ]]; then
    local issue_type="hardware problem"
    if [[ $log_line =~ "i915"|"drm.*GPU" ]]; then
        issue_type="Intel graphics crashed"
        echo "URGENT|INTEL_GPU_HANG|$issue_type → Close graphics programs, restart, and check for driver updates" >> "$recommendations_file"
    elif [[ $log_line =~ "Machine check"|"mce:" ]]; then
        issue_type="serious hardware fault detected"
        echo "IMMEDIATE|HARDWARE_ERROR|$issue_type → Your computer detected a hardware problem that could cause crashes. Contact support immediately" >> "$recommendations_file"
    elif [[ $log_line =~ "DMAR"|"IOMMU"|"DMA.*fault" ]]; then
        issue_type="hardware communication error"
        echo "URGENT|DMA_FAULT|$issue_type → This can cause sudden freezes. Try disabling IOMMU/VT-d in BIOS settings or contact support" >> "$recommendations_file"
    else
        issue_type="processor core failure"
        echo "IMMEDIATE|CPU_FAILURE|$issue_type → Hardware problem detected that can cause crashes. Contact support" >> "$recommendations_file"
    fi
    return
fi
    
        # Thermal emergencies with plain English
    if [[ $log_line =~ critical.*temperature|thermal.*emergency|over.*temperature ]]; then
        local thermal_explanation="Your computer got dangerously hot and will shut down to protect itself from damage. This means the cooling fans might be blocked with dust, you're running very demanding programs, or the computer needs cleaning."
        echo "IMMEDIATE|THERMAL_CRITICAL|Computer dangerously hot → $thermal_explanation Stop using it immediately, let it cool down, and clean the air holes" >> "$recommendations_file"
        return
    fi
    
    # System freeze/lockup detection with plain English
    if [[ $log_line =~ "hard LOCKUP"|"Kernel panic"|"kernel BUG"|"BUG: kernel NULL pointer dereference" ]]; then
        local freeze_explanation="Your computer completely froze and stopped working. This usually means something serious went wrong with the software, a part is failing, or there's a problem with your memory. You'll need to force restart by holding the power button for 10 seconds."
        echo "IMMEDIATE|SYSTEM_FREEZE|Computer completely frozen → $freeze_explanation If this keeps happening, contact support because a part might be broken" >> "$recommendations_file"
        return
    fi
    
    # Soft lockups and hung tasks with plain English
    if [[ $log_line =~ "soft lockup"|"hung_task"|"blocked for more than.*seconds"|"task.*blocked for more than" ]]; then
        local hang_explanation="Your computer is running very slowly or getting stuck. This means a program got stuck and won't respond, your hard drive is having trouble, or too many programs are running at once."
        echo "URGENT|SOFT_LOCKUP|Computer running very slowly → $hang_explanation Try closing programs or restart if everything feels frozen" >> "$recommendations_file"
        return
    fi
    
    # RCU stalls (kernel responsiveness issues) with plain English
    if [[ $log_line =~ "rcu_sched stall"|"rcu_preempt stall"|"RCU.*stall" ]]; then
        local rcu_explanation="The main parts of your computer got stuck, which can make everything freeze or become extremely slow. This is serious and usually needs a restart to fix."
        echo "URGENT|RCU_STALL|Main computer functions stuck → $rcu_explanation Restart your computer if it becomes unresponsive" >> "$recommendations_file"
        return
    fi
    
    # CPU stalls and scheduler issues with plain English
    if [[ $log_line =~ "CPU.*stall"|"NMI watchdog"|"watchdog.*BUG"|"scheduling while atomic" ]]; then
        local cpu_explanation="Your computer's main processor ran into a serious problem and might cause everything to freeze or become unstable. This could be from parts overheating, hardware problems, or software bugs."
        echo "URGENT|CPU_STALL|Main processor problem → $cpu_explanation Watch for stability problems and contact support if issues continue" >> "$recommendations_file"
        return
    fi
    
    # Memory-related freezes with plain English
    if [[ $log_line =~ "Out of memory"|"oom-killer"|"Killed process"|"page allocation failure"|"Memory allocation failed" ]]; then
        local memory_explanation="Your computer ran out of memory and had to shut down programs to free up space. This can cause freezing if important programs get shut down. Close some programs or restart to free up memory."
        echo "URGENT|MEMORY_CRITICAL|Computer out of memory → $memory_explanation Consider closing browser tabs, big programs, or getting more memory" >> "$recommendations_file"
        return
    fi
    
    # I/O freezes and storage issues with plain English
    if [[ $log_line =~ "task.*in.*state.*for.*seconds"|"INFO: task.*blocked for more than.*seconds"|"blk_update_request.*I/O error" ]]; then
        local io_explanation="Your computer's storage (where files are saved) is having trouble, which can make programs freeze when they try to open or save files. This could mean your hard drive is having problems or getting too hot."
        echo "IMPORTANT|IO_FREEZE|File storage having problems → $io_explanation Check that your computer isn't too hot and consider backing up important files" >> "$recommendations_file"
        return
    fi
    
    # USB enumeration failures with plain English
    if [[ $log_line =~ device.*not.*accepting.*address|device.*descriptor.*read.*error.*-110 ]]; then
        local usb_explanation="A USB device (like an expansion card or accessory) couldn't connect properly. This often happens when connections are loose or USB ports have problems."
        echo "IMPORTANT|USB_ENUM_FAIL|USB device couldn't connect → $usb_explanation Try unplugging and reconnecting the device, or try a different USB port" >> "$recommendations_file"
        return
    fi
    
    # NVMe issues with plain English
    if [[ $log_line =~ nvme.*I/O.*timeout|nvme.*reset.*controller|nvme.*resetting.*controller ]]; then
        local nvme_explanation="Your main storage drive is having trouble responding and might be failing or getting too hot. This can cause slow performance or you could lose files."
        echo "URGENT|NVME_TIMEOUT|Main storage drive having problems → $nvme_explanation Back up important files immediately and check that the drive is properly connected" >> "$recommendations_file"
        return
    fi
    
    # WiFi firmware crashes with plain English
    if [[ $log_line =~ iwlwifi.*firmware.*error|iwlwifi.*microcode.*SW.*error|mt7925.*firmware.*error|mt7925.*microcode.*error|mt7925.*firmware.*assert ]]; then
        local wifi_explanation="Your WiFi card's software crashed, which will cause WiFi to disconnect and have connection problems. This is usually fixable with driver updates or diagnostic tools."
        echo "IMPORTANT|WIFI_FIRMWARE|WiFi software crashed → $wifi_explanation Run the Enhanced WiFi Analyzer tool: https://github.com/FrameworkComputer/linux-docs/tree/main/Enhanced-WiFi-Analyzer" >> "$recommendations_file"
        return
    fi
    
    # WiFi connection drops (tracked for pattern analysis)
    if [[ $log_line =~ wl[a-z0-9]*.*disconnected|wifi.*connection.*lost|deauthenticated|disassociated|CTRL-EVENT-DISCONNECTED ]]; then
        echo "WIFI_DROP|$(date)|$log_line" >> "$state_changes_file"
        return
    fi
    
    # Battery and power issues with plain English
    if [[ $log_line =~ "battery.*critical"|"battery.*low"|"power.*critical"|"AC.*disconnect" ]]; then
        local power_explanation="Your computer's power system is having problems. This could be low battery, charger problems, or power management issues."
        echo "IMPORTANT|POWER_ISSUE|Power system problems → $power_explanation Check that your charger is connected and working properly" >> "$recommendations_file"
        return
    fi
    
    # Network/Ethernet issues with plain English - but only if network is actually down
    if [[ $log_line =~ "Network is unreachable"|"No route to host"|"Connection timed out"|"ethernet.*link.*down"|"network.*unreachable"|"soft blocked"|"hard blocked"|"rfkill.*block"|"No network connectivity"|"connection failed"|"link is not ready"|"disconnected"|"no carrier"|"network interface.*down" ]]; then
        # Only report network issues if network is actually down right now
        if [[ "$NETWORK_CURRENTLY_WORKING" != "true" ]]; then
            local network_explanation="Your network connection (WiFi or cable) is having problems connecting or staying connected."
            echo "IMPORTANT|NETWORK_ISSUE|Network connection problems → $network_explanation Check your network cables, WiFi signal strength, or router. If WiFi is blocked, check airplane mode or hardware WiFi switch" >> "$recommendations_file"
        fi
        return
    fi
    
    # Audio/Sound issues with plain English
    if [[ $log_line =~ "audio.*error"|"sound.*fail"|"alsa.*error"|"pulseaudio.*error" ]]; then
        local audio_explanation="Your sound system is having problems, which might cause no sound, crackling, or audio errors."
        echo "IMPORTANT|AUDIO_ISSUE|Sound system problems → $audio_explanation Try restarting sound services or check sound settings" >> "$recommendations_file"
        return
    fi
    
    # Filesystem errors with plain English
    if [[ $log_line =~ "filesystem.*error"|"ext4.*error"|"btrfs.*error"|"corruption" ]]; then
        local fs_explanation="Your file system found errors or corruption, which could cause you to lose files or make your computer unstable."
        echo "URGENT|FILESYSTEM_ERROR|File system errors found → $fs_explanation Back up important files immediately and run file system checks" >> "$recommendations_file"
        return
    fi
    
    # CATCH-ALL: Only flag ACTUAL problems, not routine system operations
    if [[ $log_line =~ error|Error|ERROR|warning|Warning|WARNING|fail|Fail|FAIL|critical|Critical|CRITICAL|fatal|Fatal|FATAL|panic|Panic|PANIC ]]; then
        
        # FIRST: Check if this is just normal system noise that contains error keywords
        if is_harmless_system_noise "$log_line"; then
            return  # Ignore it completely
        fi
        
        # SECOND: Check for specific patterns that are actually problems
        local is_real_problem=false
        local simple_explanation=""
        
        # Hardware failures that users should know about
        if [[ $log_line =~ "Input/output error"|"I/O error"|"read error"|"write error" ]]; then
            is_real_problem=true
            simple_explanation="Your computer can't read or write files properly. Your hard drive might be breaking. Save your important files somewhere else right away."
        elif [[ $log_line =~ "No space left on device"|"disk full" ]]; then
            is_real_problem=true
            simple_explanation="Your computer is completely full and can't save anything new. Delete some files or photos to free up space."
        elif [[ $log_line =~ "Temperature above threshold"|"critical temperature" ]]; then
            is_real_problem=true
            simple_explanation="Your computer is getting too hot and might shut down to protect itself. Clean the air holes and close heavy programs."
        elif [[ $log_line =~ "segmentation fault"|"segfault" ]]; then
            is_real_problem=true
            simple_explanation="A program just crashed. This happens sometimes, but if it keeps happening, something might be wrong."
        elif [[ $log_line =~ "unable to mount"|"mount failed" ]]; then
            is_real_problem=true
            simple_explanation="Your computer can't see a connected drive or USB stick. Check that everything is plugged in properly."
        elif [[ $log_line =~ "Network is unreachable"|"No route to host"|"Connection timed out"|"network is down"|"soft blocked"|"hard blocked"|"rfkill.*block"|"No network connectivity"|"connection failed"|"link is not ready"|"disconnected"|"no carrier"|"network interface.*down" ]]; then
            is_real_problem=true
            simple_explanation="Your internet isn't working. Check your WiFi connection or network cable."
        elif [[ $log_line =~ "authentication failed"|"login failed"|"permission denied" ]] && [[ ! $log_line =~ "audit"|"systemd" ]]; then
            is_real_problem=true
            simple_explanation="Something couldn't log in or get permission to do what it needs. Some features might not work properly."
        fi
        
        # Only report if it's actually a problem users should care about
        if [[ $is_real_problem == true ]]; then
            echo "IMPORTANT|ACTUAL_PROBLEM|$simple_explanation" >> "$recommendations_file"
        fi
        
        # If we can't determine what it is, just ignore it rather than create noise
        return
    fi
}

# Ensure necessary packages are installed based on the operating system
if [ -f /etc/os-release ]; then
    OS_ID=$(grep ^ID= /etc/os-release | awk -F= '{print $2}' | tr -d '"')
    OS_VERSION_ID=$(grep ^VERSION_ID= /etc/os-release | awk -F= '{print $2}' | tr -d '"')

    # Check and install required packages based on the distribution
    case "$OS_ID" in
        ubuntu)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi lm-sensors bc || { echo "${BOLD}Package installation failed on Ubuntu.${RESET}"; exit 1; }
            ;;
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi lm-sensors bc || { echo "${BOLD}Package installation failed on Debian.${RESET}"; exit 1; }
            ;;
        linuxmint)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi lm-sensors bc || { echo "${BOLD}Package installation failed on Linux Mint.${RESET}"; exit 1; }
            ;;
        pop)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi lm-sensors || { echo "${BOLD}Package installation failed on Pop!_OS.${RESET}"; exit 1; }
            ;;
        fedora)
            sudo dnf install -y -q pciutils iw inxi lm_sensors || { echo "${BOLD}Package installation failed on Fedora.${RESET}"; exit 1; }
            ;;
        arch)
            sudo pacman -Sy --needed --noconfirm pciutils iw inxi lm_sensors || { echo "${BOLD}Package installation failed on Arch Linux.${RESET}"; exit 1; }
            ;;
        manjaro)
            sudo pacman -Sy --needed --noconfirm pciutils iw inxi lm_sensors || { echo "${BOLD}Package installation failed on Manjaro.${RESET}"; exit 1; }
            ;;
        endeavouros)
            sudo pacman -Sy --needed --noconfirm pciutils iw inxi lm_sensors || { echo "${BOLD}Package installation failed on EndeavourOS.${RESET}"; exit 1; }
            ;;
        opensuse-tumbleweed|opensuse-leap|opensuse)
            sudo zypper install -y pciutils iw inxi sensors || { echo "${BOLD}Package installation failed on openSUSE.${RESET}"; exit 1; }
            ;;
        nixos)
    # NixOS uses declarative package management - check if tools are available
    missing_tools=()
    command -v lspci >/dev/null || missing_tools+=("pciutils")
    command -v lsusb >/dev/null || missing_tools+=("usbutils")
    command -v dmidecode >/dev/null || missing_tools+=("dmidecode")
    command -v iw >/dev/null || missing_tools+=("iw")
    command -v inxi >/dev/null || missing_tools+=("inxi") 
    command -v sensors >/dev/null || missing_tools+=("lm_sensors")
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "${BOLD}${YELLOW}Missing tools on NixOS: ${missing_tools[*]}${RESET}"
        echo "Add these packages to your configuration.nix:"
        echo "environment.systemPackages = with pkgs; ["
        for tool in "${missing_tools[@]}"; do
            echo "  $tool"
        done
        echo "];"
        echo "Then run: sudo nixos-rebuild switch"
        echo ""
        echo "Continuing with available tools..."
    fi
    ;;
        bluefin|bazzite)
            # Do not install any packages on these distributions
            # Just skip installation.
            ;;
        *)
            echo "${BOLD}Unsupported distribution: $OS_ID${RESET}"
            echo "Supported distributions: Ubuntu, Debian, Linux Mint, Pop!_OS, Fedora, Arch Linux, Manjaro, EndeavourOS, openSUSE, NixOS"
            exit 1
            ;;
    esac
else
    echo "${BOLD}Could not detect the OS distribution.${RESET}"
    exit 1
fi

# Function to display a clean, terminal-friendly progress bar
show_progress_with_context() {
    local percentage=$1
    local context="$2"
    local width=40
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    local bar=""
    
    # Check if terminal supports Unicode (UTF-8)
    if [[ "$LANG" =~ UTF-8 ]] || [[ "$LC_ALL" =~ UTF-8 ]] || [[ "$LC_CTYPE" =~ UTF-8 ]]; then
        # Use Unicode blocks for modern terminals
        local fill_char="█"
        local empty_char="░"
        local arrow="▶"
    else
        # Fallback to ASCII for older/basic terminals
        local fill_char="="
        local empty_char="-"
        local arrow=">"
    fi
    
    # Build the progress bar
    for ((i=0; i<filled; i++)); do
        bar+="$fill_char"
    done
    for ((i=0; i<empty; i++)); do
        bar+="$empty_char"
    done
    
    # Clear the line and print progress
    printf "\r\033[K${CYAN}${arrow} ${context}${RESET} [${GREEN}${bar}${RESET}] ${BOLD}${percentage}%%${RESET}"
    
    # Add newline when complete
    if [ "$percentage" -eq 100 ]; then
        printf "\n"
    fi
}

# Enhanced function to add to summary with intelligent analysis
add_to_summary() {
    local line="$1"
    local timestamp="$2"
    
    # Skip ALL noise - gnome-shell errors, systemd operations, and harmless system events
    if [[ $line =~ gnome-shell ]] || is_harmless_system_noise "$line"; then
        return
    fi
    
    echo "$line" >> "$summary_file"
    
    # Analyze line for recommendations
    analyze_and_recommend "$line"
    
    # Parse error codes for frequency analysis
    parse_error_codes "$line"
    
    # Track device state changes
    track_state_changes "$line" "$timestamp"
    
    # Analyze error context patterns
    analyze_error_context "$line" "$timestamp"
    previous_line="$line"
    
    # Only add to focused summary if it contains actual critical error patterns
    if [[ $line =~ "timeout"|"fault"|"failed"|"error.*critical"|"hang"|"crash"|"corruption"|"hard LOCKUP"|"Kernel panic"|"soft lockup"|"hung_task"|"rcu.*stall"|"CPU.*stall"|"NMI watchdog"|"Out of memory"|"oom-killer"|"blocked for more than.*seconds" ]]; then
        echo "$line" >> "$focused_summary_file"
    fi
}

# Function to get enhanced system information
get_system_info() {
    echo "===== System Information =====" > "$output_file"
    echo "" >> "$output_file"
    echo "Kernel version: $(uname -r)" >> "$output_file"
    
    # Get desktop environment from the actual running session
    local user_desktop=""
    local user_session=""
    
    # Try multiple methods to get desktop environment
    if [ -n "$SUDO_USER" ]; then
        # Get desktop environment from systemctl
        user_desktop=$(systemctl --user show-environment 2>/dev/null | grep "XDG_CURRENT_DESKTOP=" | awk -F= '{print $2}' 2>/dev/null)
        user_session=$(systemctl --user show-environment 2>/dev/null | grep "XDG_SESSION_TYPE=" | awk -F= '{print $2}' 2>/dev/null)
        
        # Method 2: If that fails, try loginctl
        if [ -z "$user_desktop" ]; then
            local session_id=$(loginctl list-sessions --no-legend | grep "$SUDO_USER" | awk '{print $1}' | head -1)
            if [ -n "$session_id" ]; then
                user_desktop=$(loginctl show-session "$session_id" -p Desktop --value 2>/dev/null)
                user_session=$(loginctl show-session "$session_id" -p Type --value 2>/dev/null)
            fi
        fi
        
        # Method 3: Check running processes as fallback
        if [ -z "$user_desktop" ]; then
            if pgrep -u "$SUDO_USER" gnome-shell >/dev/null 2>&1; then
                user_desktop="GNOME"
            elif pgrep -u "$SUDO_USER" kwin >/dev/null 2>&1; then
                user_desktop="KDE"
            elif pgrep -u "$SUDO_USER" xfce4-panel >/dev/null 2>&1; then
                user_desktop="XFCE"
            fi
            
            # Detect session type from processes
            if pgrep -u "$SUDO_USER" "Xorg" >/dev/null 2>&1; then
                user_session="x11"
            elif pgrep -u "$SUDO_USER" "gnome-shell" >/dev/null 2>&1 && [ -z "$user_session" ]; then
                user_session="wayland"
            fi
        fi
    else
        user_desktop="$XDG_CURRENT_DESKTOP"
        user_session="$XDG_SESSION_TYPE"
    fi
    
    # Display desktop environment info
    if [ -n "$user_desktop" ]; then
        if [ -n "$user_session" ]; then
            echo "Desktop Environment: $user_desktop ($user_session)" >> "$output_file"
        else
            echo "Desktop Environment: $user_desktop" >> "$output_file"
        fi
    else
        echo "Desktop Environment: Unknown" >> "$output_file"
    fi

    # For distribution, read from /etc/os-release
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep PRETTY_NAME /etc/os-release | awk -F= '{print $2}' | tr -d '"')
        echo "Distribution: $OS_NAME" >> "$output_file"
    else
        echo "Distribution: Unknown (no /etc/os-release)" >> "$output_file"
    fi

    echo "BIOS Version: $(sudo dmidecode -s bios-version 2>/dev/null || echo 'Unknown')" >> "$output_file"
    
    # Enhanced Framework-specific information with model detection
    echo "Hardware Information:" >> "$output_file"
    PRODUCT_NAME=$(sudo dmidecode -s system-product-name 2>/dev/null || echo 'Unknown')
    FRAMEWORK_MODEL=$(sudo dmidecode -s system-version 2>/dev/null || echo 'Unknown')
    echo "  Product: $PRODUCT_NAME" >> "$output_file"
    

    
    # Check if this is a Framework laptop with model-specific detection
    # Framework products can have names like "Laptop 13 (AMD Ryzen AI 300 Series)", "Framework Laptop 13", "Framework Desktop", etc.
    if [[ $PRODUCT_NAME =~ Framework ]] || [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $PRODUCT_NAME =~ "Desktop" ]]; then
        echo "  Framework device detected - applying Framework-specific diagnostics" >> "$output_file"
        
        # Model-specific information
        if [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 13" ]]; then
            echo "  Detected: Framework Laptop 13 - checking USB-C power delivery and thermal management" >> "$output_file"
        elif [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 16" ]]; then
            echo "  Detected: Framework Laptop 16 - checking GPU module and enhanced thermal envelope" >> "$output_file"
        elif [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Laptop 12" ]]; then
            echo "  Detected: Framework Laptop 12 - checking 2-in-1 convertible features and thermal management" >> "$output_file"
        elif [[ $PRODUCT_NAME =~ "Desktop" ]] || [[ $FRAMEWORK_MODEL =~ "Framework Desktop" ]]; then
            echo "  Detected: Framework Desktop - checking Mini-ITX system and modular components" >> "$output_file"
        fi
        
        # Expansion Cards Detection
        echo "  Expansion Cards:" >> "$output_file"
        
        # Check for HDMI and DisplayPort expansion cards when active
        local hdmi_dp_cards=$(lsusb | grep -iE "HDMI|DisplayPort")
        if [ -n "$hdmi_dp_cards" ]; then
            echo "$hdmi_dp_cards" | while read -r line; do
                echo "    $line" >> "$output_file"
            done
        else
            echo "    No active HDMI/DisplayPort expansion cards detected" >> "$output_file"
        fi
        
        # Power and Battery Status
        echo "  Power Status:" >> "$output_file"
        
        # Check if AC adapter is connected
        local ac_connected="Unknown"
        if [ -f /sys/class/power_supply/ADP*/online ]; then
            local ac_status=$(cat /sys/class/power_supply/ADP*/online 2>/dev/null)
            if [ "$ac_status" = "1" ]; then
                ac_connected="Connected"
            else
                ac_connected="Disconnected"
            fi
        elif [ -f /sys/class/power_supply/AC*/online ]; then
            local ac_status=$(cat /sys/class/power_supply/AC*/online 2>/dev/null)
            if [ "$ac_status" = "1" ]; then
                ac_connected="Connected"
            else
                ac_connected="Disconnected"
            fi
        fi
        echo "    AC Power: $ac_connected" >> "$output_file"
        
        # Battery status
        if [ -f /sys/class/power_supply/BAT*/capacity ]; then
            local battery_level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
            local battery_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
            echo "    Battery: ${battery_level}% (${battery_status})" >> "$output_file"
            
            # Battery health check using upower
            if command -v upower >/dev/null 2>&1; then
                local battery_health=$(upower -i $(upower -e | grep battery) 2>/dev/null | awk '/energy-full:/ {f=$2} /energy-full-design:/ {d=$2} END {h=(f/d)*100; print (h<85) ? "❌ Battery is NOT healthy" : "✅ Battery is healthy"}')
                if [ -n "$battery_health" ]; then
                    echo "    Health: $battery_health" >> "$output_file"
                fi
            fi
        else
            echo "    Battery: Status unavailable" >> "$output_file"
        fi
        
        # Get thermal information with intelligent thresholds
        check_current_temperatures
        
        # Check real-time network connectivity
        check_network_connectivity
    fi
    
    # ALWAYS check Framework distro compatibility if any Framework detected
    if [[ $PRODUCT_NAME =~ Framework ]] || [[ $PRODUCT_NAME =~ "Laptop 13" ]] || [[ $PRODUCT_NAME =~ "Laptop 16" ]] || [[ $PRODUCT_NAME =~ "Laptop 12" ]] || [[ $PRODUCT_NAME =~ "Desktop" ]]; then
        check_framework_distro_compatibility
    fi
    
    echo "" >> "$output_file"
    
    # Add detailed hardware context
    get_device_details
}

# Check if current distro/version is recommended for detected Framework hardware
check_framework_distro_compatibility() {
    local current_distro=$(grep ^ID= /etc/os-release | awk -F= '{print $2}' | tr -d '"')
    local current_version=$(grep ^VERSION_ID= /etc/os-release | awk -F= '{print $2}' | tr -d '"')
    local framework_model="$FRAMEWORK_MODEL"
    local product_name="$PRODUCT_NAME"
    
    # Framework support levels based on EXACT frame.work/linux page content
    local support_level=""
    local recommendation_msg=""
    local model_name=""
    
    # Framework Laptop 12 (13th Gen Intel® Core™)
    if [[ $framework_model =~ "Framework Laptop 12" ]] || [[ $product_name =~ "Laptop 12" ]]; then
        model_name="Framework Laptop 12"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 12 only supports Fedora 42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            ubuntu)
                if [[ $current_version == "25.04" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 12 only supports Ubuntu 25.04. Current: Ubuntu $current_version is not listed as supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            bluefin|arch|linuxmint)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "25.05" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 12 only supports NixOS 25.05. Current: NixOS $current_version is not listed as supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Laptop 12 officially supports: Fedora 42, Ubuntu 25.04, Bazzite. Community supported: Project Bluefin, Arch Linux, Linux Mint, NixOS 25.05. Your current distribution may not be fully compatible"
                ;;
        esac
    
    # Framework Desktop (AMD Ryzen™ AI Max 300 Series)
    elif [[ $framework_model =~ "Framework Desktop" ]] || [[ $product_name =~ "Desktop" ]]; then
        model_name="Framework Desktop"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Desktop only supports Fedora 42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            arch|bluefin)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "25.05" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Desktop only supports NixOS 25.05. Current: NixOS $current_version is not listed as supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Desktop officially supports: Fedora 42, Bazzite. Community supported: Arch Linux, NixOS 25.05, Project Bluefin. Your current distribution may not be fully compatible"
                ;;
        esac
    
    # Framework Laptop 13 (AMD Ryzen™ AI 300 Series)
    elif [[ $framework_model =~ "Framework Laptop 13" ]] && [[ $framework_model =~ "AMD Ryzen.*AI.*300" ]] ||
         [[ $product_name =~ "Laptop 13" ]] && [[ $product_name =~ "AMD Ryzen.*AI.*300" ]]; then
        model_name="Framework Laptop 13 (AMD Ryzen AI 300)"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 (AMD Ryzen AI 300) only supports Fedora 42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            arch|bluefin)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "25.05" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 (AMD Ryzen AI 300) only supports NixOS 25.05. Current: NixOS $current_version is not listed as supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Laptop 13 (AMD Ryzen AI 300) officially supports: Fedora 42, Bazzite. Community supported: Arch Linux, NixOS 25.05, Project Bluefin. Your current distribution may not be fully compatible"
                ;;
        esac
    
    # Framework Laptop 13 (Intel® Core™ Ultra Series 1)
    elif [[ $framework_model =~ "Framework Laptop 13" ]] && [[ $framework_model =~ "Intel.*Core.*Ultra" ]] ||
         [[ $product_name =~ "Laptop 13" ]] && [[ $product_name =~ "Intel.*Core.*Ultra" ]]; then
        model_name="Framework Laptop 13 (Intel Core Ultra)"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "41" || $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 (Intel Core Ultra) only supports Fedora 41/42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            ubuntu)
                # Ubuntu 24.04+ means 24.04 and later
                if [[ $current_version == "24.04" || $current_version > "24.04" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 (Intel Core Ultra) requires Ubuntu 24.04 or newer. Current: Ubuntu $current_version is not supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            bluefin|arch|linuxmint)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "25.05" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 (Intel Core Ultra) only supports NixOS 25.05. Current: NixOS $current_version is not listed as supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Laptop 13 (Intel Core Ultra) officially supports: Fedora 41/42, Ubuntu 24.04+, Bazzite. Community supported: Project Bluefin, Arch Linux, Linux Mint, NixOS 25.05. Your current distribution may not be fully compatible"
                ;;
        esac
    
    # Framework Laptop 16 (AMD Ryzen™ 7040 Series)
    elif [[ $framework_model =~ "Framework Laptop 16" ]] || [[ $product_name =~ "Laptop 16" ]]; then
        model_name="Framework Laptop 16"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 16 only supports Fedora 42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            ubuntu)
                if [[ $current_version == "24.04" || $current_version > "24.04" || $current_version == "22.04" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 16 supports Ubuntu 24.04+, 22.04 LTS. Current: Ubuntu $current_version is not listed as supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            bluefin|arch|linuxmint)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "24.11" || $current_version > "24.11" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 16 requires NixOS 24.11 or newer. Current: NixOS $current_version is not supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Laptop 16 officially supports: Fedora 42, Ubuntu 24.04+/22.04 LTS, Bazzite. Community supported: Project Bluefin, Arch Linux, NixOS 24.11+, Linux Mint. Your current distribution may not be fully compatible"
                ;;
        esac
    
    # Framework Laptop 13 (older generations) - fallback for other Intel/AMD variants
    elif [[ $framework_model =~ "Framework Laptop 13" ]] || [[ $product_name =~ "Laptop 13" ]]; then
        model_name="Framework Laptop 13"
        case "$current_distro" in
            fedora)
                if [[ $current_version == "42" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 only supports Fedora 42. Current: Fedora $current_version is not listed as supported"
                fi
                ;;
            ubuntu)
                if [[ $current_version == "24.04" || $current_version > "24.04" || $current_version == "22.04" ]]; then
                    support_level="OFFICIALLY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 supports Ubuntu 24.04+, 22.04 LTS. Current: Ubuntu $current_version is not listed as supported"
                fi
                ;;
            bazzite)
                support_level="OFFICIALLY_SUPPORTED"
                ;;
            manjaro|linuxmint|arch)
                support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                ;;
            nixos)
                if [[ $current_version == "24.11" || $current_version > "24.11" ]]; then
                    support_level="COMPATIBLE_COMMUNITY_SUPPORTED"
                else
                    support_level="UNTESTED"
                    recommendation_msg="Framework Laptop 13 requires NixOS 24.11 or newer. Current: NixOS $current_version is not supported"
                fi
                ;;
            *)
                support_level="UNTESTED"
                recommendation_msg="Framework Laptop 13 officially supports: Fedora 42, Ubuntu 24.04+/22.04 LTS, Bazzite. Community supported: Manjaro XFCE, Linux Mint, Arch Linux, NixOS 24.11+. Your current distribution may not be fully compatible"
                ;;
        esac
    fi
    
    # Generate appropriate recommendations based on support level with plain English
    if [[ -n $model_name ]]; then
        case "$support_level" in
            "OFFICIALLY_SUPPORTED")
                echo "INFORMATIONAL|DISTRO_COMPATIBILITY|✅ Your Linux distribution ($current_distro $current_version) is officially supported and tested by Framework for your $model_name → You should have the best experience and full hardware support" >> "$recommendations_file"
                ;;
            "COMPATIBLE_COMMUNITY_SUPPORTED")
                echo "INFORMATIONAL|DISTRO_COMPATIBILITY|🔵 Your Linux distribution ($current_distro $current_version) is community supported for your $model_name → Most features should work well, but you may need to install additional drivers or make minor tweaks" >> "$recommendations_file"
                ;;
            "UNTESTED")
                echo "INFORMATIONAL|DISTRO_COMPATIBILITY|⚠️ Your Linux distribution may not be fully compatible with your $model_name → $recommendation_msg For the best experience, consider switching to a supported distribution from frame.work/linux" >> "$recommendations_file"
                ;;
        esac
    fi
}

# Function to process logs - FIXED to avoid subshell issues
process_logs() {
    local start_time=$1
    local end_time=$2

    local start_seconds=$(date -d "$start_time" +%s)
    local end_seconds=$(date -d "$end_time" +%s)

    # Create a header for dmesg section with spacing
    echo "===== dmesg output starts =====" >> "$output_file"
    echo "" >> "$output_file"

    # Process dmesg - FIXED: Use process substitution instead of pipe to avoid subshell
    local total_lines=$(sudo dmesg | wc -l)
    local current_line=0
    
    while IFS= read -r line; do
        ((current_line++))
        local percentage=$((current_line * 100 / total_lines))
        show_progress_with_context $percentage "dmesg logs" 2>/dev/null

        if [[ $line =~ \[(.*?)\] ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            if date -d "$timestamp" &>/dev/null; then
                local line_seconds=$(date -d "$timestamp" +%s)
                if (( line_seconds >= start_seconds && line_seconds <= end_seconds )); then
                    echo "$line" >> "$output_file"
                    if [[ $line =~ error|warning|fail|critical|failed|timeout|crash|disconnected|deauth ]]; then
                        add_to_summary "$line" "$timestamp"
                    fi
                fi
            fi
        fi
    done < <(sudo dmesg -T) 2>/dev/null

    echo -e "\n${GREEN}✅ Dmesg analysis complete${RESET}"
    echo "" >> "$output_file"

    # Create a header for journalctl section with spacing
    echo "===== journalctl output starts =====" >> "$output_file"
    echo "" >> "$output_file"

    # Process journalctl - FIXED: Use process substitution instead of pipe to avoid subshell
    total_lines=$(sudo journalctl --since="$start_time" --until="$end_time" 2>/dev/null | wc -l)
    current_line=0

    while IFS= read -r line; do
        ((current_line++))
        percentage=$((current_line * 100 / total_lines))
        show_progress_with_context $percentage "journal logs"
        echo "$line" >> "$output_file"
        
        # Extract timestamp from journalctl line
        local journal_timestamp=""
        if [[ $line =~ ^([A-Z][a-z]{2}\ [0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
            journal_timestamp="${BASH_REMATCH[1]}"
        fi
        
        if [[ $line =~ error|warning|fail|critical|failed|timeout|crash|disconnected|deauth ]]; then
            add_to_summary "$line" "$journal_timestamp"
        fi
    done < <(sudo journalctl --since="$start_time" --until="$end_time" 2>/dev/null)

    echo -e "${GREEN}✅ Journal analysis complete${RESET}"
}

# Function to generate intelligent recommendations with plain English
generate_recommendations() {
    local file=$1
    
    # Add intelligent recommendations section
    echo "" >> "$file"
    echo "===== INTELLIGENT RECOMMENDATIONS =====" >> "$file"
    echo "" >> "$file"
    
    # Check if recommendations file exists and has content
    if [ -f "$recommendations_file" ] && [ -s "$recommendations_file" ]; then
        # Sort and process recommendations by severity
        declare -A severity_colors
        severity_colors[IMMEDIATE]="🔴 IMMEDIATE"
        severity_colors[URGENT]="🟠 URGENT" 
        severity_colors[IMPORTANT]="🟡 IMPORTANT"
        severity_colors[INFORMATIONAL]="🔵 INFORMATIONAL"
        severity_colors[PREVENTIVE]="🟢 PREVENTIVE"
        
        # Process recommendations by severity order
        for severity in IMMEDIATE URGENT IMPORTANT INFORMATIONAL PREVENTIVE; do
            local recommendations=$(grep "^$severity|" "$recommendations_file" 2>/dev/null | sort | uniq)
            if [ -n "$recommendations" ]; then
                # Check if INFORMATIONAL contains positive confirmations vs warnings
                if [[ $severity == "INFORMATIONAL" ]]; then
                    local has_warnings=$(echo "$recommendations" | grep -v "✅" | wc -l)
                    if [[ $has_warnings -gt 0 ]]; then
                        echo "${severity_colors[$severity]} Actions Required:" >> "$file"
                    else
                        echo "${severity_colors[$severity]} Status:" >> "$file"
                    fi
                else
                    echo "${severity_colors[$severity]} Actions Required:" >> "$file"
                fi
                echo "" >> "$file"
                
                echo "$recommendations" | while IFS='|' read -r sev category rec; do
                    echo "• [$category] $rec" >> "$file"
                done
                echo "" >> "$file"
            fi
        done
        
        # Pattern analysis for multiple event types with plain English explanations
        pattern_analysis_added=false
        
        # WiFi drops
        wifi_drops=$(grep -c "WIFI_DROP" "$state_changes_file" 2>/dev/null | head -1)
        wifi_drops=${wifi_drops:-0}
        if [ "$wifi_drops" -gt 3 ]; then
            if [ "$pattern_analysis_added" = false ]; then
                echo "🟡 IMPORTANT Actions Required (Pattern Analysis):" >> "$file"
                echo "" >> "$file"
                pattern_analysis_added=true
            fi
            echo "• [WIFI_INSTABILITY] Your WiFi has disconnected $wifi_drops times → This means your WiFi connection is unstable. Run the Enhanced WiFi Analyzer tool to diagnose: https://github.com/FrameworkComputer/linux-docs/tree/main/Enhanced-WiFi-Analyzer" >> "$file"
        fi
        
        # USB reconnection patterns
        usb_reconnects=$(grep -c "USB_RECONNECT" "$state_changes_file" 2>/dev/null | head -1)
        usb_reconnects=${usb_reconnects:-0}
        if [ "$usb_reconnects" -gt 2 ]; then
            if [ "$pattern_analysis_added" = false ]; then
                echo "🟡 IMPORTANT Actions Required (Pattern Analysis):" >> "$file"
                echo "" >> "$file"
                pattern_analysis_added=true
            fi
            echo "• [USB_INSTABILITY] Your USB devices have reconnected $usb_reconnects times → This means USB ports or expansion cards may be loose. Unplug and firmly reconnect all USB devices and expansion cards" >> "$file"
        fi
        
        # GPU hang/recovery patterns
        gpu_hangs=$(grep -c "GPU_HANG" "$state_changes_file" 2>/dev/null | head -1)
        gpu_hangs=${gpu_hangs:-0}
        if [ "$gpu_hangs" -gt 1 ]; then
            if [ "$pattern_analysis_added" = false ]; then
                echo "🟡 IMPORTANT Actions Required (Pattern Analysis):" >> "$file"
                echo "" >> "$file"
                pattern_analysis_added=true
            fi
            echo "• [GPU_INSTABILITY] Your graphics card has crashed $gpu_hangs times → This suggests serious graphics problems. Check that you're using the correct charger, update graphics drivers, and contact Framework support if this continues" >> "$file"
        fi
        
        # Thermal throttling patterns
        thermal_events=$(grep -c "THERMAL_THROTTLE" "$state_changes_file" 2>/dev/null | head -1)
        thermal_events=${thermal_events:-0}
        if [ "$thermal_events" -gt 2 ]; then
            if [ "$pattern_analysis_added" = false ]; then
                echo "🟡 IMPORTANT Actions Required (Pattern Analysis):" >> "$file"
                echo "" >> "$file"
                pattern_analysis_added=true
            fi
            echo "• [THERMAL_CYCLING] Your laptop has overheated $thermal_events times → This means the cooling system is struggling. Clean the air vents, close demanding programs, and consider using your laptop on a hard surface for better airflow" >> "$file"
        fi
        
        if [ "$pattern_analysis_added" = true ]; then
            echo "" >> "$file"
        fi
        
    else
        echo "✅ No issues detected requiring immediate action." >> "$file"
    fi
    
    echo "" >> "$file"
}

# Function to add summaries to the file
add_summaries() {
    local file=$1

    # Add critical error summary section first
    echo "===== Critical Error Summary =====" >> "$file"
    echo "Actual system errors requiring attention:" >> "$file"
    echo "" >> "$file"

    if [ -s "$focused_summary_file" ]; then
        sort "$focused_summary_file" | uniq -c | sort -rn >> "$file"
    else
        echo "✅ No critical system errors detected in the logs." >> "$file"
    fi

    echo "" >> "$file"

    # Add general summary section
    echo "===== All Error/Warning Messages (excluding noise) =====" >> "$file"
    echo "" >> "$file"

    if [ -s "$summary_file" ]; then
        sort "$summary_file" | uniq -c | sort -rn >> "$file"
    else
        echo "No error or warning messages found in the logs (excluding gnome-shell and benign Framework messages)." >> "$file"
    fi

    echo "" >> "$file"
    
    # Add diagnostic completion summary
    echo "===== DIAGNOSTIC COMPLETION SUMMARY =====" >> "$file"
    echo "Scan completed: $(date)" >> "$file"
    local total_issues=$(wc -l < "$summary_file" 2>/dev/null || echo "0")
    local critical_issues=$(wc -l < "$focused_summary_file" 2>/dev/null || echo "0")
    local recommendations_count=$(wc -l < "$recommendations_file" 2>/dev/null || echo "0")
    echo "Total issues found: $total_issues" >> "$file"
    echo "Potentially important issues: $critical_issues" >> "$file"
    echo "Recommendations generated: $recommendations_count" >> "$file"
}

########################################
# Main script starts here
########################################

echo -e "${BOLD}${CYAN}Framework Laptop Enhanced Diagnostic Tool${RESET}"
echo -e "${BOLD}==========================================${RESET}"
echo ""
echo "Choose an option:"
echo "1. Last x minutes"
echo "2. Last 24 hours"
echo "3. Specific time range"
echo "4. Filter previously created log file"
read choice

case $choice in
  1)
    echo "Enter the number of minutes:"
    read minutes
    start_time=$(date -d "$minutes minutes ago" '+%Y-%m-%d %H:%M')
    end_time=$(date '+%Y-%m-%d %H:%M')
    get_system_info 2>/dev/null
    process_logs "$start_time" "$end_time"
    
    # Insert recommendations RIGHT AFTER system info by rebuilding the file
    temp_file="/tmp/temp_rebuild_temp_$$_$(date +%s).txt"
    
    # Extract everything up to and including the entire Hardware Context section
    sed -n '1,/^Hardware Context:/p' "$output_file" > "$temp_file"
    sed -n '/^  GPU:/,/^$/p' "$output_file" >> "$temp_file"
    
    # Add recommendations immediately after hardware context
    generate_recommendations "$temp_file"
    
    # Add the rest (dmesg and journalctl)
    sed -n '/^===== dmesg output starts =====/,$p' "$output_file" >> "$temp_file"
    
    # Replace original with rebuilt version
    mv "$temp_file" "$output_file"
    
    add_summaries "$output_file"
    ;;
  2)
    start_time=$(date -d "24 hours ago" '+%Y-%m-%d %H:%M')
    end_time=$(date '+%Y-%m-%d %H:%M')
    get_system_info
    process_logs "$start_time" "$end_time"
    
    # Insert recommendations RIGHT AFTER system info by rebuilding the file
    temp_file="/tmp/temp_rebuild_temp_$$_$(date +%s).txt"
    
    # Extract everything up to and including the entire Hardware Context section
    sed -n '1,/^Hardware Context:/p' "$output_file" > "$temp_file"
    sed -n '/^  GPU:/,/^$/p' "$output_file" >> "$temp_file"
    
    # Add recommendations immediately after hardware context
    generate_recommendations "$temp_file"
    
    # Add the rest (dmesg and journalctl)
    sed -n '/^===== dmesg output starts =====/,$p' "$output_file" >> "$temp_file"
    
    # Replace original with rebuilt version
    mv "$temp_file" "$output_file"
    
    add_summaries "$output_file"
    ;;
  3)
    echo "Enter the start time (YYYY-MM-DD HH:MM):"
    read start_time
    echo "Enter the end time (YYYY-MM-DD HH:MM):"
    read end_time
    get_system_info
    process_logs "$start_time" "$end_time"
    
    # Insert recommendations RIGHT AFTER system info by rebuilding the file
    temp_file="/tmp/temp_rebuild_temp_$$_$(date +%s).txt"
    
    # Extract everything up to and including the entire Hardware Context section
    sed -n '1,/^Hardware Context:/p' "$output_file" > "$temp_file"
    sed -n '/^  GPU:/,/^$/p' "$output_file" >> "$temp_file"
    
    # Add recommendations immediately after hardware context
    generate_recommendations "$temp_file"
    
    # Add the rest (dmesg and journalctl)
    sed -n '/^===== dmesg output starts =====/,$p' "$output_file" >> "$temp_file"
    
    # Replace original with rebuilt version
    mv "$temp_file" "$output_file"
    
    add_summaries "$output_file"
    ;;
  4)
    echo "Looking for file called combined_log.txt in current directory..."
    if [ ! -f "$output_file" ]; then
        echo -e "${RED}File not found: $output_file${RESET}"
        exit 1
    fi
    echo -e "${GREEN}File found. Proceeding with filtering options.${RESET}"

    echo "Choose filtering option:"
    echo "1. Grep for a key phrase"
    echo "2. Grep for a keyword"
    read grep_choice

    case $grep_choice in
      1)
        echo "Enter the key phrase to grep for:"
        read key_phrase
        key_phrase=$(echo "$key_phrase" | xargs)  # Trim whitespace
        echo "Searching for: '$key_phrase'"
        grep -i "$key_phrase" "$output_file" > "$filtered_output_file"
        ;;
      2)
        echo "Enter the keyword to grep for:"
        read keyword
        keyword=$(echo "$keyword" | xargs)  # Trim whitespace
        echo "Searching for: '$keyword'"
        grep -i "$keyword" "$output_file" > "$filtered_output_file"
        ;;
      *)
        echo -e "${RED}Invalid choice. No filtering applied.${RESET}"
        exit 1
        ;;
    esac

    if [ ! -s "$filtered_output_file" ]; then
        echo -e "${YELLOW}No matches found. Filtered log file is empty.${RESET}"
        exit 1
    fi

    echo -e "\n${BOLD}${GREEN}Filtered log saved in $filtered_output_file${RESET}"
    line_count=$(wc -l < "$filtered_output_file")
    echo -e "${BOLD}Total lines in filtered output: $line_count${RESET}"
    ;;
  *)
    echo -e "${RED}Invalid choice${RESET}"
    exit 1
    ;;
esac

# Cleanup happens automatically via trap
# Final output message - only show for diagnostic runs, not filtering
if [ "$choice" != "4" ]; then
    echo ""
    echo -e "${BOLD}${GREEN}✅ Diagnostic complete!${RESET}"
    echo -e "${BOLD}📋 Full report saved to: $output_file${RESET}"
    echo -e "${BOLD}🔍 Check the 'INTELLIGENT RECOMMENDATIONS' section for actionable solutions${RESET}"
    
    # Display summary of findings
    if [ -f "$output_file" ]; then
        echo ""
        echo -e "${BOLD}${CYAN}Quick Summary:${RESET}"
        
        # Check if we detected a Framework device
        if grep -q "Framework device detected" "$output_file" 2>/dev/null; then
            detected_model=$(grep "Detected:" "$output_file" 2>/dev/null | head -1 | awk '{print substr($0, index($0,$2))}' | xargs)
            if [ -n "$detected_model" ]; then
                echo -e "${GREEN}🖥️  $detected_model${RESET}"
            fi
        fi
        
        # Show current temperature if available
        temp_reading=$(grep "Current CPU:" "$output_file" 2>/dev/null | head -1)
        if [ -n "$temp_reading" ]; then
            echo -e "${BLUE}🌡️  $temp_reading${RESET}"
        fi
        
        # Show critical issues count - count everything EXCEPT INFORMATIONAL
        # Handle case where no recommendations section exists
        if grep -q "INTELLIGENT RECOMMENDATIONS" "$output_file" 2>/dev/null; then
            total_bullets=$(grep -A 1000 "INTELLIGENT RECOMMENDATIONS" "$output_file" 2>/dev/null | grep -c "^• \[")
            informational_bullets=$(grep -A 20 "🔵 INFORMATIONAL" "$output_file" 2>/dev/null | grep -c "^• \[")
        else
            total_bullets=0
            informational_bullets=0
        fi
        
        # Ensure we have valid numbers
        total_bullets=${total_bullets:-0}
        informational_bullets=${informational_bullets:-0}
        
        # Total issues = all bullets minus informational bullets
        critical_count=$((total_bullets - informational_bullets))
        
        # Ensure variables are numeric
        critical_count=${critical_count:-0}
        
        if [ "$critical_count" -gt 0 ]; then
            echo -e "${RED}⚠️  $critical_count issues found${RESET}"
        else
            echo -e "${GREEN}✅ No issues detected${RESET}"
        fi
        
        # Show if running supported distro
        if grep -q "officially supported and tested" "$output_file" 2>/dev/null; then
            echo -e "${GREEN}✅ Running officially supported Linux distribution${RESET}"
        elif grep -q "community supported" "$output_file" 2>/dev/null; then
            echo -e "${BLUE}🔵 Running community supported Linux distribution${RESET}"
        fi
        
        echo ""
        echo -e "${BOLD}For detailed analysis, open: $output_file${RESET}"
        
        # Provide quick access commands
        echo ""
        echo -e "${BOLD}${CYAN}Quick Commands:${RESET}"
        echo -e "${YELLOW}View full report:${RESET} cat \"$output_file\""
        echo -e "${YELLOW}View recommendations only:${RESET} grep -A 20 \"INTELLIGENT RECOMMENDATIONS\" \"$output_file\""
        echo -e "${YELLOW}View current temps:${RESET} sensors"
        echo -e "${YELLOW}Monitor temps:${RESET} watch -n 2 sensors"
        
        # Framework-specific quick links
        if grep -q "Framework device detected" "$output_file" 2>/dev/null; then
            echo ""
            echo -e "${BOLD}${CYAN}Framework Resources:${RESET}"
            echo -e "${GREEN}Support:${RESET} https://frame.work/support"
            echo -e "${GREEN}Linux Guides:${RESET} https://frame.work/linux"
            echo -e "${GREEN}Community forum:${RESET} https://community.frame.work/"
            echo -e "${GREEN}Linux docs:${RESET} https://github.com/FrameworkComputer/linux-docs"
            echo -e "${GREEN}Linux KnowledgeBase Articles:${RESET} https://knowledgebase.frame.work/categories/linux-S1IUEcFbkx"
            echo -e "${GREEN}Linux Tools and Scripts:${RESET} https://knowledgebase.frame.work/linux-on-framework-tools-and-scripts-rymax1Jdyg"
            
            # Show WiFi analyzer if WiFi issues detected
            if grep -q "WiFi has disconnected\|WiFi firmware crashed" "$output_file" 2>/dev/null; then
                echo -e "${YELLOW}WiFi issues detected - Enhanced WiFi Analyzer:${RESET}"
                echo "https://github.com/FrameworkComputer/linux-docs/tree/main/Enhanced-WiFi-Analyzer"
            fi
        fi
    fi
fi

# Exit with appropriate code based on findings
if [ "$choice" != "4" ] && [ -f "$output_file" ]; then
    # Check for critical issues - count everything EXCEPT INFORMATIONAL
    if grep -q "INTELLIGENT RECOMMENDATIONS" "$output_file" 2>/dev/null; then
        total_bullets=$(grep -A 1000 "INTELLIGENT RECOMMENDATIONS" "$output_file" 2>/dev/null | grep -c "^• \[")
        informational_bullets=$(grep -A 20 "🔵 INFORMATIONAL" "$output_file" 2>/dev/null | grep -c "^• \[")
    else
        total_bullets=0
        informational_bullets=0
    fi
    
    # Ensure we have valid numbers
    total_bullets=${total_bullets:-0}
    informational_bullets=${informational_bullets:-0}
    
    critical_issues=$((total_bullets - informational_bullets))
    critical_issues=${critical_issues:-0}
    if [ "$critical_issues" -gt 0 ]; then
        exit 1  # Exit with error code if critical issues found
    fi
fi

exit 0
