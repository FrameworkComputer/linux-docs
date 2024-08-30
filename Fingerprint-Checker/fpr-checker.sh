#!/bin/bash

# fpr-checker.sh - A script to manage fingerprint data using fprintd with a selectable menu.

# Colors for output
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Determine the actual user invoking the script, whether through sudo or not
if [ -n "$SUDO_USER" ]; then
    USER=$SUDO_USER
else
    USER=$(whoami)
fi

# Function to detect the desktop environment
detect_desktop_environment() {
    if [ "$XDG_CURRENT_DESKTOP" ]; then
        echo "${YELLOW}Desktop Environment: $XDG_CURRENT_DESKTOP${RESET}"
        if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
            echo "${RED}Note: Fingerprint login might not work with this desktop environment, but you can still configure sudo to work with fingerprints.${RESET}"
        fi
    else
        echo "${YELLOW}Desktop Environment: Unknown${RESET}"
    fi
}

# Function to enroll a specific finger for the actual user
enroll_finger() {
    local finger=$1
    echo "${YELLOW}Enrolling $finger for user $USER...${RESET}"
    sudo -u "$USER" fprintd-enroll -f "$finger"
    if [ $? -eq 0 ]; then
        echo "${GREEN}Fingerprint enrolled successfully for $finger.${RESET}"
    else
        echo "${RED}Failed to enroll fingerprint for $finger.${RESET}"
    fi
    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to get standard Linux users (UID between 1000 and 60000)
get_standard_users() {
    awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' /etc/passwd
}

# Function to delete all fingerprints for standard Linux users
delete_all_fingerprints() {
    echo "${RED}Deleting all fingerprints for standard Linux users...${RESET}"
    local deleted_any=0

    for user in $(get_standard_users); do
        sudo fprintd-delete "$user" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "${GREEN}All fingerprints deleted successfully for user: $user${RESET}"
            deleted_any=1
        else
            echo "${YELLOW}No fingerprints found for user: $user${RESET}"
        fi
    done

    if [ $deleted_any -eq 0 ]; then
        echo "${YELLOW}No fingerprints were found to delete for standard Linux users.${RESET}"
    fi

    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to list registered fingerprints for standard Linux users
list_fingerprints_for_all() {
    echo "${YELLOW}Listing registered fingerprints for standard Linux users...${RESET}"
    local registered=0

    for user in $(get_standard_users); do
        output=$(sudo fprintd-list "$user" 2>/dev/null)

        if [[ "$output" != *"no fingers enrolled"* && -n "$output" ]]; then
            echo "${GREEN}Fingerprints for user: $user${RESET}"
            echo "$output"
            echo
            registered=1
        fi
    done

    if [ $registered -eq 0 ]; then
        echo "${YELLOW}No fingerprints registered for any standard Linux users.${RESET}"
    fi

    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Main menu function
show_menu() {
    clear
    detect_desktop_environment
    echo "===================================="
    echo "  Fingerprint Management Script"
    echo "===================================="
    echo "1. Enroll Left Thumb"
    echo "2. Enroll Left Index Finger"
    echo "3. Enroll Left Middle Finger"
    echo "4. Enroll Left Ring Finger"
    echo "5. Enroll Left Little Finger"
    echo "6. Enroll Right Thumb"
    echo "7. Enroll Right Index Finger"
    echo "8. Enroll Right Middle Finger"
    echo "9. Enroll Right Ring Finger"
    echo "10. Enroll Right Little Finger"
    echo "11. Delete All Fingerprints for Standard Users"
    echo "12. List Registered Fingerprints for Standard Users"
    echo "13. Exit"
    echo "===================================="
    echo -n "Choose an option: "
}

# Function to handle user input
read_options() {
    local choice
    read -r choice
    case $choice in
        1) enroll_finger "left-thumb" ;;
        2) enroll_finger "left-index-finger" ;;
        3) enroll_finger "left-middle-finger" ;;
        4) enroll_finger "left-ring-finger" ;;
        5) enroll_finger "left-little-finger" ;;
        6) enroll_finger "right-thumb" ;;
        7) enroll_finger "right-index-finger" ;;
        8) enroll_finger "right-middle-finger" ;;
        9) enroll_finger "right-ring-finger" ;;
        10) enroll_finger "right-little-finger" ;;
        11) delete_all_fingerprints ;;
        12) list_fingerprints_for_all ;;
        13) exit 0 ;;
        *) echo "${RED}Invalid option!${RESET}" && sleep 2
    esac
}

# Main script loop
while true
do
    show_menu
    read_options
done
