#!/usr/bin/env bash
clear

# ANSI color codes
RED="\\e[31m"
GREEN="\\e[32m"
CYAN_BOLD="\\e[1;36m"
RESET="\\e[0m"

# Directory for Tuned profiles
TUNED_PROFILES_DIR="/etc/tuned/profiles"

# Configuration file for tuned-ppd
CONFIG_FILE="/etc/tuned/ppd.conf"

# Validate configuration file existence
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error:${RESET} $CONFIG_FILE does not exist!"
    exit 1
fi

# Function to ensure bsdtar is installed
ensure_bsdtar() {
    if ! command -v bsdtar &>/dev/null; then
        echo -e "${CYAN_BOLD}bsdtar is not installed. Attempting to install...${RESET}"
        
        if [ -f /etc/os-release ]; then
            . /etc/os-release  # Source OS details
            
            if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    echo -e "${CYAN_BOLD}Detected Ubuntu/Debian. Installing libarchive-tools (bsdtar)...${RESET}"
    sudo apt update &>/dev/null && sudo apt install -y libarchive-tools &>/dev/null || {
        echo -e "${RED}Failed to install bsdtar. Please install libarchive-tools manually.${RESET}"
        exit 1
    }
elif [[ "$ID" == "fedora" ]]; then
    echo -e "${CYAN_BOLD}Detected Fedora. Installing bsdtar...${RESET}"
    sudo dnf install -y bsdtar &>/dev/null || {
        echo -e "${RED}Failed to install bsdtar. Please install it manually.${RESET}"
        exit 1
    }
            else
                echo -e "${RED}Unsupported distribution. Please install bsdtar manually.${RESET}"
                exit 1
            fi
        else
            echo -e "${RED}Could not detect the operating system. Please install bsdtar manually.${RESET}"
            exit 1
        fi
    else
        echo -e "${GREEN}bsdtar is already installed.${RESET}"
    fi
    
}

# Describe the purpose of the script and explain tuned-ppd and GNOME's PPD menu
echo
echo -e "${CYAN_BOLD}This script helps you configure how your system manages power and performance.${RESET}"
echo
echo "Customize which tuned profiles correspond to menu options. Normally, this requires a third-party applet or similar, but with this script, you can configure it directly while continuing to use GNOME's power menu." | fmt -w 80
echo

# Function to back up the configuration file
backup_config() {
    clear
    BACKUP_FILE="/etc/tuned/ppd.conf.bak.$(date +%Y%m%d%H%M%S)"
    
    # Create a new backup
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE" && echo -e "${GREEN}Backup created: $BACKUP_FILE${RESET}" || {
        echo -e "${RED}Failed to create backup.${RESET}"
        exit 1
    }
    
    # Check for excess backups
    BACKUPS=($(ls -t /etc/tuned/ppd.conf.bak.* 2>/dev/null))
    BACKUP_COUNT=${#BACKUPS[@]}
    
    if [[ $BACKUP_COUNT -gt 3 ]]; then
        echo -e "${CYAN_BOLD}More than 3 backups detected. Removing oldest backups...${RESET}"
        
        # Remove oldest backups, keeping only the 3 newest
        for ((i=3; i<BACKUP_COUNT; i++)); do
            echo -e "${CYAN_BOLD}Deleting: ${BACKUPS[$i]}${RESET}"
            sudo rm -f "${BACKUPS[$i]}"
        done
    fi
}

# Function to download and check for missing profiles
download_and_check_profiles() {
    clear
    echo -e "${CYAN_BOLD}Checking for missing profiles...${RESET}"
    REPO_URL="https://github.com/redhat-performance/tuned/archive/refs/heads/master.zip"
    TEMP_DIR=$(mktemp -d)

    wget -q "$REPO_URL" -O "$TEMP_DIR/tuned.zip" || {
        echo -e "${RED}Failed to download profiles. Please check your internet connection.${RESET}"
        return 1
    }
    echo -e "${CYAN_BOLD}Extracting profiles...${RESET}"
    mkdir -p "$TEMP_DIR/tuned-master" || {
        echo -e "${RED}Failed to create extraction directory.${RESET}"
        rm -rf "$TEMP_DIR"
        return 1
    }
    bsdtar -xf "$TEMP_DIR/tuned.zip" -C "$TEMP_DIR" || {
        echo -e "${RED}Failed to extract profiles. Please check the archive.${RESET}"
        rm -rf "$TEMP_DIR"
        return 1
    }

    if [ ! -d "$TUNED_PROFILES_DIR" ]; then
        echo -e "${CYAN_BOLD}Creating profiles directory: $TUNED_PROFILES_DIR${RESET}"
        sudo mkdir -p "$TUNED_PROFILES_DIR"
    fi

    MISSING_PROFILES=0
    for PROFILE in "$TEMP_DIR/tuned-master/profiles/"*; do
        PROFILE_NAME=$(basename "$PROFILE")
        LOCAL_PROFILE_PATH="$TUNED_PROFILES_DIR/$PROFILE_NAME"
        if [ ! -d "$LOCAL_PROFILE_PATH" ]; then
            echo -e "${CYAN_BOLD}Installing missing profile: $PROFILE_NAME${RESET}"
            sudo cp -r "$PROFILE" "$LOCAL_PROFILE_PATH"
            MISSING_PROFILES=$((MISSING_PROFILES + 1))
        fi
    done

    rm -rf "$TEMP_DIR"

    if [ "$MISSING_PROFILES" -gt 0 ]; then
        echo -e "${GREEN}Installed $MISSING_PROFILES new profiles.${RESET}"
    else
        echo -e "${CYAN_BOLD}No missing profiles. All profiles are up to date.${RESET}"
    fi
}

# Function to restore defaults
restore_defaults() {
    clear
    echo -e "${CYAN_BOLD}Restoring default configuration...${RESET}"
    
    # Find the most recent backup file
    LATEST_BACKUP=$(ls -t /etc/tuned/ppd.conf.bak.* 2>/dev/null | head -n 1)
    
    if [[ -z "$LATEST_BACKUP" ]]; then
        echo -e "${RED}No backup file found to restore from.${RESET}"
        return
    fi
    
    # Restore the latest backup
    sudo cp "$LATEST_BACKUP" "$CONFIG_FILE" && echo -e "${GREEN}Defaults restored from backup: $LATEST_BACKUP${RESET}" || {
        echo -e "${RED}Failed to restore defaults.${RESET}"
    }
    echo -e "${CYAN_BOLD}Restarting tuned-ppd service...${RESET}"
    sudo systemctl restart tuned-ppd
}

# Function to apply a profile
apply_profile() {
    clear
    echo -e "${CYAN_BOLD}Which line do you want to update in [profiles]?${RESET}"
    echo ""
    echo "1) power-saver:"
    echo "   Selects a profile focused on reducing energy usage. Ideal for extending"
    echo "   battery life and keeping the system quieter and cooler. Typical tweaks"
    echo "   might lower CPU frequencies, reduce screen brightness, and apply other"
    echo "   measures that minimize power draw."
    echo ""
    echo "2) performance:"
    echo "   Selects a profile aimed at achieving maximum system speed and responsiveness."
    echo "   Perfect for demanding tasks like gaming, heavy computation, or large builds."
    echo "   This often means raising CPU frequencies, optimizing I/O operations, and"
    echo "   adjusting kernel parameters for improved throughput and lower latency."
    echo ""
    echo "q) Quit without making changes"
    echo ""

    read -p "Enter choice [1-2 or q]: " CHOICE
    case $CHOICE in
        1)
            echo -e "${CYAN_BOLD}Available Profiles:${RESET}"
            PROFILES=$(tuned-adm list | grep -E "powersave|battery" | grep -v -E "Current|active|profile:" | awk -F' - ' '{print $1}' | sed 's/^- //g' | sed '/^$/d')
            if [ -z "$PROFILES" ]; then
                echo -e "${RED}No profiles found for power-saver.${RESET}"
                return
            fi
            select PROFILE_NAME in $PROFILES; do
                if [[ -n "$PROFILE_NAME" ]]; then
                    sudo sed -i "s/^power-saver=.*/power-saver=$PROFILE_NAME/" "$CONFIG_FILE"
                    echo -e "${GREEN}Updated power-saver to use profile: $PROFILE_NAME${RESET}"
                    break
                else
                    echo -e "${RED}Invalid selection. Please try again.${RESET}"
                fi
            done
            ;;
        2)
            echo -e "${CYAN_BOLD}Available Profiles:${RESET}"
            PROFILES=$(tuned-adm list | grep -E "performance|throughput" | grep -v -E "Current|active|profile:" | awk -F' - ' '{print $1}' | sed 's/^- //g' | sed '/^$/d')
            if [ -z "$PROFILES" ]; then
                echo -e "${RED}No profiles found for performance.${RESET}"
                return
            fi
            select PROFILE_NAME in $PROFILES; do
                if [[ -n "$PROFILE_NAME" ]]; then
                    sudo sed -i "s/^performance=.*/performance=$PROFILE_NAME/" "$CONFIG_FILE"
                    echo -e "${GREEN}Updated performance to use profile: $PROFILE_NAME${RESET}"
                    break
                else
                    echo -e "${RED}Invalid selection. Please try again.${RESET}"
                fi
            done
            ;;
        q)
            echo -e "${CYAN_BOLD}No changes made.${RESET}"
            return
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${RESET}"
            apply_profile
            return
            ;;
    esac

    echo -e "${CYAN_BOLD}Restarting tuned-ppd service...${RESET}"
    sudo systemctl restart tuned-ppd
}

# Function to view specific section of /etc/tuned/ppd.conf
view_tuned_section() {
    clear
    local section=$1
    if [[ -f /etc/tuned/ppd.conf ]]; then
        echo -e "\n### Displaying $section ###\n"
        grep "^$section" /etc/tuned/ppd.conf | awk -F= '{print $2}' || echo "$section not found in /etc/tuned/ppd.conf"
        echo -e "\n#########################################\n"
    else
        echo "Error: /etc/tuned/ppd.conf not found!"
    fi
}

# Function to view tuned configurations
view_tuned_configurations() {
    clear
    if [[ -f /etc/tuned/ppd.conf ]]; then
        echo -e "${CYAN_BOLD}### Tuned Configurations ###${RESET}"
        awk '/\[profiles\]/ {flag=1; next} /^\[/ {flag=0} flag {if($0 ~ /^(power-saver|performance)=/) print "  " $0}' "$CONFIG_FILE" || echo "No relevant configurations found."
        echo -e "${CYAN_BOLD}#########################################${RESET}"
    else
        echo -e "${CYAN_BOLD}Error: /etc/tuned/ppd.conf not found!${RESET}"
    fi
}

# Main menu function
main_menu() {
    ensure_bsdtar
    while true; do
        echo -e "${CYAN_BOLD}Tuned-PPD Profile Manager${RESET}"
        echo "1. Back Up Configuration"
        echo "2. Download and Check for Missing Profiles"
        echo "3. Restore from Backup"
        echo "4. Apply a Profile"
        echo "5. View Tuned Configurations"
        echo "6. Exit"
        
        read -p "Choose an option: " OPTION
        case $OPTION in
            1) backup_config ;;
            2) download_and_check_profiles ;;
            3) restore_defaults ;;
            4) apply_profile ;;
            5) view_tuned_configurations ;;
            6) clear && echo -e "${GREEN}Exiting.${RESET}" ; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${RESET}" ;;
        esac
    done
}

# Start the main menu
main_menu
