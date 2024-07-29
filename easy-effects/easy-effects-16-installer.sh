#!/bin/bash

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is already installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. We need to install it."
    
    # Search for Easy Effects
    echo "Searching for Easy Effects..."
    search_result=$(flatpak search easyeffects)
    
    if [ -z "$search_result" ]; then
        echo "No results found for Easy Effects. Please check your Flatpak remotes and try again."
        exit 1
    fi
    
    # Display search results and prompt for selection
    echo "Found the following options:"
    echo "$search_result"
    echo ""
    read -p "Please enter the Application ID you want to install: " app_id
    
    # Attempt to install the selected Application ID
    if flatpak install "$app_id"; then
        echo "Easy Effects has been successfully installed."
    else
        echo "Installation failed. Please try again manually."
        exit 1
    fi
fi

# Rest of the script for setting up the preset
mkdir -p ~/.config/easyeffects/output
curl -o ~/.config/easyeffects/output/fw16-easy-effects.json https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json

PRESET_NAME="fw16-easy-effects"
PRESET_FILE="$HOME/.config/easyeffects/output/$PRESET_NAME.json"
PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
mkdir -p "$PRESET_DIR"
cp "$PRESET_FILE" "$PRESET_DIR"

ln -sf "$PRESET_FILE" "$PRESET_DIR/$PRESET_NAME.json"

pkill easyeffects || true
sleep 2
nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &

echo "Easy Effects profile installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
