#!/bin/bash

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. Installing Easy Effects..."
    flatpak install -y flathub com.github.wwmm.easyeffects
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
