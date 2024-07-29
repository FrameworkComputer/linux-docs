#!/bin/bash

# Function to print and execute a command
run_command() {
    echo "Running: $*"
    eval "$@"
}

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q ".easyeffects"; then
    echo "Easy Effects is already installed via Flatpak."
    exit 0
fi

echo "Easy Effects is not installed via Flatpak. We need to install it."

# Ensure Flathub remote is added
if ! flatpak remotes | grep -q "flathub"; then
    echo "Adding Flathub remote..."
    run_command "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
fi

# Search for Easy Effects
echo "Searching for Easy Effects..."
search_result=$(flatpak search easyeffects)
if [ -z "$search_result" ]; then
    echo "No results found for Easy Effects. Please check your Flatpak remotes and try again."
    exit 1
fi

# Display search results
echo "Found the following options:"
echo "$search_result"
echo ""

# Stop and wait for user confirmation
read -p "Press Enter to continue with the installation, or Ctrl+C to exit..."

# Attempt to install Easy Effects
app_id="com.github.wwmm.easyeffects"
if run_command "flatpak install --user -y flathub $app_id"; then
    echo "Easy Effects has been successfully installed."
else
    echo "Installation failed. Please try again manually."
    exit 1
fi

# Rest of the script for setting up the preset
run_command "mkdir -p ~/.config/easyeffects/output"
run_command "curl -o ~/.config/easyeffects/output/fw16-easy-effects.json https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json"
PRESET_NAME="fw16-easy-effects"
PRESET_FILE="$HOME/.config/easyeffects/output/$PRESET_NAME.json"
PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
run_command "mkdir -p $PRESET_DIR"
run_command "cp $PRESET_FILE $PRESET_DIR"
run_command "ln -sf $PRESET_FILE $PRESET_DIR/$PRESET_NAME.json"
run_command "pkill easyeffects || true"
sleep 2
run_command "nohup flatpak run $app_id &>/dev/null &"
echo "Easy Effects profile installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
