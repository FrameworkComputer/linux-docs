#!/bin/bash

# Function to print and execute a command
run_command() {
  echo "Running: $*"
  eval "$@"
}

# Check if Easy Effects is installed via Flatpak
if flatpak list | grep -q com.github.wwmm.easyeffects; then
  echo "Easy Effects is already installed via Flatpak."
  exit 0
fi

echo "Easy Effects is not installed. Searching for Flatpak package..."

# Function to find Easy Effects Flatpak package
find_easy_effects() {
  flatpak search "EasyEffects" | grep "Easy Effects" | awk '{print $(NF-3)}'
}

# Find available Easy Effects option
easy_effects_option=$(find_easy_effects)

if [ -z "$easy_effects_option" ]; then
  echo "No Easy Effects Flatpak package found."
  exit 1
fi

echo "Found Easy Effects Flatpak package: $easy_effects_option"

# Install Easy Effects Flatpak package without prompting
run_command "flatpak install flathub $easy_effects_option -y"

# Setup for Flatpak install
PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
run_command "mkdir -p $PRESET_DIR"
PRESET_NAME="fw16-easy-effects"
PRESET_FILE="$PRESET_DIR/$PRESET_NAME.json"
run_command "curl -o $PRESET_FILE https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json"

run_command "pkill easyeffects || true"
sleep 2
run_command "nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &"

echo "Easy Effects Flatpak installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
