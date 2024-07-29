#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is already installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. Let's install it."

    # List available remotes
    echo "Available remotes:"
    flatpak remotes --columns=name,title

    # Prompt user to choose a remote
    read -p "Enter the name of the remote to use for installation (e.g., flathub): " remote_name

    # Search for Easy Effects in the chosen remote
    echo "Searching for Easy Effects in $remote_name..."
    search_results=$(flatpak search --remote="$remote_name" easyeffects)

    if [ -z "$search_results" ]; then
        echo "No Easy Effects package found in $remote_name. Please choose another remote."
        exit 1
    fi

    echo "Found the following package(s):"
    echo "$search_results"

    # Prompt user to confirm installation
    read -p "Do you want to install Easy Effects from $remote_name? (y/n): " confirm

    if [[ $confirm == [Yy]* ]]; then
        # Install Easy Effects from the chosen remote
        flatpak install --user -y "$remote_name" com.github.wwmm.easyeffects
    else
        echo "Installation cancelled."
        exit 0
    fi
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
