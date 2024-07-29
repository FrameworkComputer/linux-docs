#!/bin/bash

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is already installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. We need to install it."

    # Run flatpak install command and allow user interaction
    flatpak install com.github.wwmm.easyeffects

    # Check if installation was successful
    if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
        echo "Easy Effects has been successfully installed."
    else
        echo "Failed to install Easy Effects. Please try again manually."
        exit 1
    fi
fi

# Rest of the script remains the same
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
