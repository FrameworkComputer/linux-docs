#!/bin/bash

# Function to print and execute a command
run_command() {
  echo "Running: $*"
  eval "$@"
}

# Check if Easy Effects is installed (adjust for your system)
if command -v easyeffects &> /dev/null; then
  echo "Easy Effects is already installed."
  exit 0
fi

echo "Easy Effects is not installed."

# Function to find Easy Effects packages (adjust for your system)
find_easy_effects() {
  # Replace with appropriate package manager commands for your system
  # Example for Debian-based systems:
  dpkg -l | grep -i easyeffects | awk '{print $2}'
}

# Find available Easy Effects options
easy_effects_options=$(find_easy_effects)

# Create a selection menu
if [ -z "$easy_effects_options" ]; then
  echo "No Easy Effects options found."
  exit 1
fi

PS3="Select an Easy Effects package: "
select app_id in $easy_effects_options
do
  if [[ $REPLY -gt 0 && $REPLY -le ${#easy_effects_options[@]} ]]; then
    break
  fi
  echo "Invalid selection. Please try again."
done

# Attempt to install the selected Easy Effects package (adjust for your system)
# Example for Debian-based systems:
run_command "sudo apt install $app_id -y"

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
run_command "nohup easyeffects &>/dev/null &"  # Assuming `easyeffects` is the command to run
echo "Easy Effects profile installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
