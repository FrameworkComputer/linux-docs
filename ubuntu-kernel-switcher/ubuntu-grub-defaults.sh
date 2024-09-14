#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Step 1: Backup the current GRUB configuration
GRUB_CONFIG="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.bak_$(date +%F_%T)"
sudo cp $GRUB_CONFIG $GRUB_BACKUP

echo "Current GRUB configuration backed up to: $GRUB_BACKUP"

# Step 2: Display the proposed changes for review
echo -e "\nThe following changes will be applied to GRUB:"
echo -e "${GREEN}GRUB_DEFAULT=0${NC}"
echo -e "${GREEN}GRUB_TIMEOUT_STYLE=hidden${NC}"
echo -e "${GREEN}GRUB_TIMEOUT=0${NC}"
echo -e "${GREEN}GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"${NC}"

# Step 3: Perform diff manually and colorize
echo -e "\nDifferences between current and proposed configuration:"
while IFS= read -r line; do
    if [[ "$line" == -* ]]; then
        echo -e "${RED}$line${NC}"
    elif [[ "$line" == +* ]]; then
        echo -e "${GREEN}$line${NC}"
    fi
done < <(diff --unchanged-line-format="" \
     --old-line-format="-%L" \
     --new-line-format="+%L" \
     <(grep -E "^GRUB_DEFAULT|^GRUB_TIMEOUT_STYLE|^GRUB_TIMEOUT|^GRUB_CMDLINE_LINUX_DEFAULT" $GRUB_CONFIG) <(cat <<EOL
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=0
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
EOL
))

# Step 4: Ask for confirmation
read -p "Do you want to apply these changes to the GRUB configuration? (yes/no): " response

if [ "$response" != "yes" ]; then
  echo "No changes were made. Exiting."
  exit 0
fi

# Step 5: Apply only the specific changes to GRUB configuration
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' $GRUB_CONFIG
sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' $GRUB_CONFIG
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' $GRUB_CONFIG
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' $GRUB_CONFIG

echo "GRUB configuration has been updated with the requested changes."

# Step 6: Ask for confirmation before updating GRUB
read -p "Do you want to update GRUB with these changes? (yes/no): " final_response

if [ "$final_response" != "yes" ]; then
  echo "Changes not applied. You can manually update GRUB later if needed."
  exit 0
fi

# Step 7: Update GRUB to apply changes
echo "Updating GRUB..."
sudo update-grub

echo "GRUB has been updated with the restored configuration."

