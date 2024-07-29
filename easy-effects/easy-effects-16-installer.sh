#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if curl is installed
if ! command_exists curl; then
    echo "curl is not installed. Installing curl..."
    sudo dnf install -y curl
else
    echo "curl is already installed."
fi

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "Easy Effects is installed via Flatpak."
else
    echo "Easy Effects is not installed via Flatpak. Please install it first."
    exit 1
fi

# Create the necessary directory and download the JSON file
mkdir -p ~/.config/easyeffects/output
curl -o ~/.config/easyeffects/output/fw16-easy-effects.json https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json

# Restart Easy Effects (if it is running)
pkill easyeffects || true

# Wait for a moment to ensure the process is fully terminated
sleep 2

# Start Easy Effects (if you want to start it automatically)
nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &

echo "Easy Effects profile installation completed. Please open Easy Effects and load the 'fw16-easy-effects' profile from the 'Presets' tab."
