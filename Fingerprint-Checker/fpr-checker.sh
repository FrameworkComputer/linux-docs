#!/bin/bash

# fpr-clear.sh - A script to manage fingerprint data using fprintd with a selectable menu.

# Colors for output
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

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

# Function to list fingerprints for the current or specified user
list_fingerprints() {
    local user=$1
    if [ -z "$user" ]; then
        user="$USER"
    fi
    echo "${YELLOW}Listing fingerprints for user: $user${RESET}"
    fprintd-list "$user" | while read -r line; do
        if [[ "$line" == *"-"* ]]; then
            # Highlight fingerprints
            echo "${YELLOW}$line${RESET}"
        else
            echo "$line"
        fi
    done
    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to enroll a new fingerprint for the current or specified user
enroll_fingerprint() {
    local user=$1
    if [ -z "$user" ]; then
        user="$USER"
    fi
    echo "${YELLOW}Enrolling a new fingerprint for user: $user${RESET}"
    fprintd-enroll "$user"
    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to delete fingerprints for the current or specified user
delete_fingerprints() {
    local user=$1
    if [ -z "$user" ]; then
        user="$USER"
    fi
    echo "${RED}Deleting fingerprints for user: $user${RESET}"
    sudo fprintd-delete "$user"
    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to verify a fingerprint for the current or specified user
verify_fingerprint() {
    local user=$1
    if [ -z "$user" ]; then
        user="$USER"
    fi
    echo "${YELLOW}Verifying fingerprint for user: $user${RESET}"
    fprintd-verify "$user" | while read -r line; do
        if [[ "$line" == *"Verifying:"* ]]; then
            echo "${YELLOW}$line${RESET}"
        else
            echo "$line"
        fi
    done
    read -p "Press [Enter] key to continue..."  # Pause to let the user see the output
}

# Function to restart the fprintd service
restart_fprintd_service() {
    echo "${YELLOW}Restarting the fprintd service...${RESET}"
    sudo systemctl restart fprintd
    if [ $? -eq 0 ]; then
        echo "${GREEN}fprintd service restarted successfully.${RESET}"
    else
        echo "${RED}Failed to restart fprintd service.${RESET}"
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
    echo "1. List fingerprints for the current user"
    echo "2. List fingerprints for a specific user"
    echo "3. Enroll a new fingerprint for the current user"
    echo "4. Enroll a new fingerprint for a specific user"
    echo "5. Delete fingerprints for the current user"
    echo "6. Delete fingerprints for a specific user"
    echo "7. Verify a fingerprint for the current user"
    echo "8. Restart the fprintd service"
    echo "9. Exit"
    echo "===================================="
    echo -n "Choose an option: "
}

# Function to handle user input
read_options() {
    local choice
    read -r choice
    case $choice in
        1) list_fingerprints "$USER" ;;
        2) 
            echo -n "Enter the username: "
            read -r username
            list_fingerprints "$username"
            ;;
        3) enroll_fingerprint "$USER" ;;
        4) 
            echo -n "Enter the username: "
            read -r username
            enroll_fingerprint "$username"
            ;;
        5) delete_fingerprints "$USER" ;;
        6) 
            echo -n "Enter the username: "
            read -r username
            delete_fingerprints "$username"
            ;;
        7) verify_fingerprint "$USER" ;;
        8) restart_fprintd_service ;;
        9) exit 0 ;;
        *) echo "${RED}Invalid option!${RESET}" && sleep 2
    esac
}

# Loop until the user chooses to exit
while true
do
    show_menu
    read_options
done

