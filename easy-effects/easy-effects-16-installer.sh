#!/bin/bash

# Function to print and execute a command
run_command() {
  echo "Running: $*"
  eval "$@"
}

# Check if Easy Effects is installed
if command -v easyeffects &> /dev/null || flatpak list | grep -q com.github.wwmm.easyeffects; then
  echo "Easy Effects is already installed."
  exit 0
fi

echo "Easy Effects is not installed. Searching for available packages..."

# Function to find Easy Effects packages
find_easy_effects() {
  # Check system packages (adjust for your package manager)
  if command -v apt &> /dev/null; then
    apt search easyeffects | grep -i easyeffects | awk -F/ '{print "apt:" $1}'
  fi
  
  # Check Flatpak
  if command -v flatpak &> /dev/null; then
    flatpak search easyeffects | grep -i easyeffects | awk '{print "flatpak:" $1}'
  fi
}

# Find available Easy Effects options
mapfile -t easy_effects_options < <(find_easy_effects)

# Create a selection menu
if [ ${#easy_effects_options[@]} -eq 0 ]; then
  echo "No Easy Effects options found."
  exit 1
fi

echo "Available Easy Effects packages:"
PS3="Select an Easy Effects package to install (or 0 to exit): "
select option in "${easy_effects_options[@]}" "Exit"
do
  if [[ "$REPLY" == "0" || "$option" == "Exit" ]]; then
    echo "Installation cancelled."
    exit 0
  elif [[ $REPLY -gt 0 && $REPLY -le ${#easy_effects_options[@]} ]]; then
    break
  fi
  echo "Invalid selection. Please try again."
done

IFS=':' read -r install_method app_id <<< "$option"
echo "You selected: $app_id (via $install_method)"
read -p "Do you want to install this package? (y/n): " confirm

if [[ $confirm == [Yy]* ]]; then
  # Install the selected Easy Effects package
  case $install_method in
    apt)
      run_command "sudo apt install $app_id -y"
      ;;
    flatpak)
      run_command "flatpak install flathub $app_id -y"
      ;;
    *)
      echo "Unknown installation method: $install_method"
      exit 1
      ;;
  esac
  
  # Setup for system install
  if [ "$install_method" == "apt" ]; then
    PRESET_DIR="$HOME/.config/easyeffects/output"
  # Setup for Flatpak install
  elif [ "$install_method" == "flatpak" ]; then
    PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
  fi

  run_command "mkdir -p $PRESET_DIR"
  PRESET_NAME="fw16-easy-effects"
  PRESET_FILE="$PRESET_DIR/$PRESET_NAME.json"

  run_command "curl -o $PRESET_FILE https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json"
  
  run_command "pkill easyeffects || true"
  sleep 2
  if [ "$install_method" == "flatpak" ]; then
    run_command "nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &"
  else
    run_command "nohup easyeffects &>/dev/null &"
  fi
  
  echo "Easy Effects profile installation completed and preset preloaded. Please open Easy Effects and verify the 'fw16-easy-effects' profile is loaded."
else
  echo "Installation cancelled."
  exit 0
fi
