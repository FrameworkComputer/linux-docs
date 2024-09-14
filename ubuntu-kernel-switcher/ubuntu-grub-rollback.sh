#!/bin/bash

# ANSI color codes for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'  # Reset color

# Step 1: Extract kernel entries from GRUB's "Advanced options for Ubuntu"
KERNEL_LIST=$(sudo grep -A100 "Advanced options for Ubuntu" /boot/grub/grub.cfg | grep -oP "(?<=Ubuntu, with Linux )[^']*" | grep -v 'recovery mode')

# Step 2: Check if there are any kernels listed
if [ -z "$KERNEL_LIST" ]; then
  echo -e "${RED}Error: No kernels found in GRUB configuration. Exiting.${RESET}"
  exit 1
fi

# Step 3: Display the kernels and prompt user to choose one
echo -e "${CYAN}Available kernels in GRUB:${RESET}"
echo "$KERNEL_LIST" | nl  # Number the kernel list for easy selection

# Step 4: Ask the user to pick a kernel by number
read -p "Enter the number of the kernel you want to pin: " kernel_number

# Step 5: Validate user selection
SELECTED_KERNEL=$(echo "$KERNEL_LIST" | sed -n "${kernel_number}p")
if [ -z "$SELECTED_KERNEL" ]; then
  echo -e "${RED}Invalid selection. Exiting.${RESET}"
  exit 1
fi

# Step 6: Confirm user's choice
echo -e "${YELLOW}You have selected: ${GREEN}$SELECTED_KERNEL${RESET}"
read -p "Do you want to pin this kernel to GRUB? (yes/no): " response

if [ "$response" != "yes" ]; then
  echo -e "${CYAN}Exiting script without making changes.${RESET}"
  exit 0
fi

# Step 7: Backup GRUB configuration
GRUB_CONFIG="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.bak_$(date +%F_%T)"
sudo cp $GRUB_CONFIG $GRUB_BACKUP

echo -e "${CYAN}GRUB configuration backed up to: ${GREEN}$GRUB_BACKUP${RESET}"

# Step 8: Modify GRUB to pin the selected kernel
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux $SELECTED_KERNEL"

# Check if the string already exists
if grep -q "^GRUB_DEFAULT=" "$GRUB_CONFIG"; then
  sudo sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"$GRUB_DEFAULT\"|" $GRUB_CONFIG
else
  echo "GRUB_DEFAULT=\"$GRUB_DEFAULT\"" | sudo tee -a $GRUB_CONFIG > /dev/null
fi

# Step 9: Display changes made
echo -e "${CYAN}The following change has been made to GRUB:${RESET}"
echo -e "${GREEN}GRUB_DEFAULT=\"$GRUB_DEFAULT\"${RESET}"

# Step 10: Ask for final confirmation
echo -e "${YELLOW}Do you want to save these changes and update GRUB?${RESET}"
read -p "(yes/no): " final_response

if [ "$final_response" != "yes" ]; then
  echo -e "${RED}Reverting changes. Restoring GRUB backup.${RESET}"
  sudo cp $GRUB_BACKUP $GRUB_CONFIG
  exit 0
fi

# Step 11: Update GRUB
echo -e "${CYAN}Updating GRUB...${RESET}"
sudo update-grub

echo -e "${GREEN}GRUB has been updated. The system will now boot with the kernel: ${CYAN}$SELECTED_KERNEL${RESET}"

