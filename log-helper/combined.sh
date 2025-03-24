#!/bin/bash

output_file="$(pwd)/combined_log.txt"  # Using current directory for input file
filtered_output_file="$(pwd)/filtered_log.txt"  # Using current directory for output file
summary_file="summary_temp.txt"
focused_summary_file="focused_summary_temp.txt"

# ANSI escape codes for text formatting
BOLD='\033[1m'
RESET='\033[0m'

# Ensure necessary packages are installed based on the operating system
if [ -f /etc/os-release ]; then
    OS_ID=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')
    OS_VERSION_ID=$(grep ^VERSION_ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')

    # Check and install required packages based on the distribution
    case "$OS_ID" in
        ubuntu)
            sudo apt-get update -qq
            sudo apt-get install -y -qq pciutils iw inxi || { echo "${BOLD}Package installation failed on Ubuntu.${RESET}"; exit 1; }
            ;;
        fedora)
            sudo dnf install -y -q pciutils iw inxi || { echo "${BOLD}Package installation failed on Fedora.${RESET}"; exit 1; }
            ;;
        bluefin|bazzite)
            # Do not install any packages on these distributions
            # Just skip installation.
            ;;
        *)
            echo "${BOLD}Unsupported distribution: $OS_ID${RESET}"
            exit 1
            ;;
    esac
else
    echo "${BOLD}Could not detect the OS distribution.${RESET}"
    exit 1
fi

# Function to display progress bar
show_progress() {
    local width=50
    local percentage=$1
    local filled=$(printf "%.0f" $(echo "$percentage * $width / 100" | bc -l))
    local empty=$((width - filled))
    printf "\rProgress: [%-${width}s] %d%%" $(printf "#%.0s" $(seq 1 $filled)) $percentage
}

# Function to add to summary, ignoring gnome-shell errors
add_to_summary() {
    if ! [[ $1 =~ gnome-shell ]]; then
        echo "$1" >> "$summary_file"
        if [[ $1 =~ i915|amdgpu|wayland|wifi|network|failed ]]; then
            echo "$1" >> "$focused_summary_file"
        fi
    fi
}

# Function to get system information
get_system_info() {
    echo "===== System Information =====" > "$output_file"
    echo "" >> "$output_file"
    echo "Kernel version: $(uname -r)" >> "$output_file"
    echo "Desktop Environment: $XDG_CURRENT_DESKTOP" >> "$output_file"

    # For distribution, read from /etc/os-release
    if [ -f /etc/os-release ]; then
        OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
        echo "Distribution: $OS_NAME" >> "$output_file"
    else
        echo "Distribution: Unknown (no /etc/os-release)" >> "$output_file"
    fi

    echo "BIOS Version: $(sudo dmidecode -s bios-version)" >> "$output_file"
    echo "" >> "$output_file"
}

# Function to process logs
process_logs() {
    local start_time=$1
    local end_time=$2

    local start_seconds=$(date -d "$start_time" +%s)
    local end_seconds=$(date -d "$end_time" +%s)

    # Create a header for dmesg section with spacing
    echo "===== dmesg output starts =====" >> "$output_file"
    echo "" >> "$output_file"

    # Collect and filter dmesg output with progress bar
    local total_lines=$(sudo dmesg | wc -l)
    local current_line=0

    sudo dmesg -T | while IFS= read -r line; do
        ((current_line++))
        local percentage=$((current_line * 100 / total_lines))
        show_progress $percentage

        if [[ $line =~ \[(.*?)\] ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            if date -d "$timestamp" &>/dev/null; then
                local line_seconds=$(date -d "$timestamp" +%s)
                if (( line_seconds >= start_seconds && line_seconds <= end_seconds )); then
                    echo "$line" >> "$output_file"
                    if [[ $line =~ error|warning|fail|critical|failed ]]; then
                        add_to_summary "$line"
                    fi
                fi
            fi
        fi
    done

    echo -e "\nDmesg processing complete."
    echo "" >> "$output_file"

    # Create a header for journalctl section with spacing
    echo "===== journalctl output starts =====" >> "$output_file"
    echo "" >> "$output_file"

    # Append journalctl output to the file with progress bar
    total_lines=$(sudo journalctl --since="$start_time" --until="$end_time" | wc -l)
    current_line=0

    sudo journalctl --since="$start_time" --until="$end_time" | while IFS= read -r line; do
        ((current_line++))
        percentage=$((current_line * 100 / total_lines))
        show_progress $percentage
        echo "$line" >> "$output_file"
        if [[ $line =~ error|warning|fail|critical|failed ]]; then
            add_to_summary "$line"
        fi
    done

    echo -e "\nJournalctl processing complete."
}

# Function to add summaries to the file
add_summaries() {
    local file=$1

    # Add focused summary section to the end of the output file
    echo "" >> "$file"
    echo "===== Focused Summary of Potential Issues =====" >> "$file"
    echo "Issues related to i915, amdgpu, wayland, wifi, network, and failed items:" >> "$file"
    echo "" >> "$file"

    if [ -s "$focused_summary_file" ]; then
        sort "$focused_summary_file" | uniq -c | sort -rn >> "$file"
    else
        echo "No critical issues found related to graphics, display, networking, or failed items." >> "$file"
    fi

    echo "" >> "$file"

    # Add general summary section to the end of the output file
    echo "===== General Summary of Potential Issues (excluding gnome-shell errors) =====" >> "$file"
    echo "" >> "$file"

    if [ -s "$summary_file" ]; then
        sort "$summary_file" | uniq -c | sort -rn >> "$file"
    else
        echo "No other critical issues found in the logs (excluding gnome-shell errors)." >> "$file"
    fi

    echo "" >> "$file"
}

########################################
# Main script starts here
########################################

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
    get_system_info
    process_logs "$start_time" "$end_time"
    add_summaries "$output_file"
    ;;
  2)
    start_time=$(date -d "24 hours ago" '+%Y-%m-%d %H:%M')
    end_time=$(date '+%Y-%m-%d %H:%M')
    get_system_info
    process_logs "$start_time" "$end_time"
    add_summaries "$output_file"
    ;;
  3)
    echo "Enter the start time (YYYY-MM-DD HH:MM):"
    read start_time
    echo "Enter the end time (YYYY-MM-DD HH:MM):"
    read end_time
    get_system_info
    process_logs "$start_time" "$end_time"
    add_summaries "$output_file"
    ;;
  4)
    echo "Looking for file called combined_log.txt in current directory..."
    if [ ! -f "$output_file" ]; then
        echo "File not found: $output_file"
        exit 1
    fi
    echo "File found. Proceeding with filtering options."

    echo "Choose filtering option:"
    echo "1. Grep for a key phrase"
    echo "2. Grep for a keyword"
    read grep_choice

    case $grep_choice in
      1)
        echo "Enter the key phrase to grep for:"
        read key_phrase
        key_phrase=$(echo "$key_phrase" | xargs)  # Trim whitespace
        grep -F -i -B 3 -A 5 "$key_phrase" "$output_file" > "$filtered_output_file"
        ;;
      2)
        echo "Enter the keyword to grep for:"
        read keyword
        keyword=$(echo "$keyword" | xargs)  # Trim whitespace
        grep -w -i -B 3 -A 5 "$keyword" "$output_file" > "$filtered_output_file"
        ;;
      *)
        echo "Invalid choice. No filtering applied."
        exit 1
        ;;
    esac

    if [ ! -s "$filtered_output_file" ]; then
        echo "No matches found. Filtered log file is empty."
        exit 1
    fi

    echo -e "\n${BOLD}Filtered log saved in $filtered_output_file${RESET}"
    line_count=$(wc -l < "$filtered_output_file")
    echo -e "${BOLD}Total lines in filtered output: $line_count${RESET}"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

# Clean up temporary files
[ -f "$summary_file" ] && rm "$summary_file"
[ -f "$focused_summary_file" ] && rm "$focused_summary_file"
