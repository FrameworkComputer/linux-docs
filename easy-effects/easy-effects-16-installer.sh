#!/bin/bash

# Function to print and execute a command
run_command() {
  echo "Running: $*"
  eval "$@"
}

# Check if Easy Effects is installed
if command -v easyeffects &> /dev/null; then
  echo "Easy Effects is already installed."
  exit 0
fi

echo "Easy Effects is not installed. Searching for available packages..."

# Function to find Easy Effects packages (adjust for your system)
find_easy_effects() {
  # Replace with appropriate package manager commands for your system
  # Example for Debian-based systems:
  apt search easyeffects | grep -i easyeffects | awk -F/ '{print $1}'
}

# Find available Easy Effects options
easy_effects_options=($(find_easy_effects))

# Create a selection menu
if [ ${#easy_effects_options[@]} -eq 0 ]; then
  echo "No Easy Effects options found."
  exit 1
fi

echo "Available Easy Effects packages:"
PS3="Select an Easy Effects package to install (or 0 to exit): "
select app_id in "${easy_effects_options[@]}" "Exit"
do
  if [[ "$REPLY" == "0" || "$app_id" == "Exit" ]]; then
    echo "Installation cancelled."
    exit 0
  elif [[ $REPLY -gt 0 && $REPLY -le ${#easy_effects_options[@]} ]]; then
    break
  fi
  echo "Invalid selection. Please try again."
done

echo "You selected: $app_id"
read -p "Do you want to install this package? (y/n): " confirm

if [[ $confirm == [Yy]* ]]; then
  # Attempt to install the selected Easy Effects package
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
else
  echo "Installation cancelled."
  exit 0
fi
