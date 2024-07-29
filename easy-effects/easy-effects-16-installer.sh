#!/bin/bash

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is already installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. We need to install it."
    
    echo "Please choose from the following options:"
    echo "1) Install from Flathub (system)"
    echo "2) Install from Flathub (user)"
    echo "3) Cancel installation"
    
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            echo "You chose to install from Flathub (system)."
            echo "Run the following command to install:"
            echo "sudo flatpak install flathub com.github.wwmm.easyeffects"
            ;;
        2)
            echo "You chose to install from Flathub (user)."
            echo "Run the following command to install:"
            echo "flatpak install --user flathub com.github.wwmm.easyeffects"
            ;;
        3)
            echo "Installation cancelled."
            ;;
        *)
            echo "Invalid choice. Installation cancelled."
            ;;
    esac
    
    echo "After installation, please run this script again to set up the preset."
    exit 0
fi

# Create the necessary directory and download the JSON file
mkdir -p ~/.config/easyeffects/output
curl -o ~/.config/easyeffects/output/fw16-easy-effects.json https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json

# Ensure the preset is copied to the correct location
PRESET_NAME="fw16-easy-effects"
PRESET_FILE="$HOME/.config/easyeffects/output/$PRESET_NAME.json"
PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
mkdir -p "$PRESET_DIR"
cp "$PRESET_FILE" "$PRESET_DIR"

# Create a symlink for the preset if needed
ln -sf "$PRESET_FILE" "$PRESET_DIR/$PRESET_NAME.json"

# Restart Easy Effects (if it is running)
pkill easyeffects || true

# Wait for a moment to ensure the process is fully terminated
sleep 2

# Start Easy Effects
nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &

echo "Easy Effects profile installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
