#!/bin/bash

# Function to install Easy Effects via Flatpak
# Installs Easy Effects via Flatpak for Fedora or distros using flatpak.
install_easy_effects() {
    echo "Easy Effects is not installed. Installing Flatpak package..."
    if ! flatpak install --user flathub com.github.wwmm.easyeffects -y; then
        echo "User installation failed. Trying system installation..."
        sudo flatpak install --system flathub com.github.wwmm.easyeffects -y
    fi
    
    if [ $? -ne 0 ]; then
        echo "Installation failed. Please install Easy Effects manually."
        exit 1
    fi
    echo "Easy Effects installation completed."
}

# Check if Easy Effects is installed
if ! flatpak list | grep -q com.github.wwmm.easyeffects; then
    install_easy_effects
fi

clear
echo -e "Creating configuration directory...\n"

# Define config directory and file
config_dir=~/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output
config_file="$config_dir/fw16-easy-effects.json"

# Create config directory if it doesn't exist
mkdir -p "$config_dir"

clear
echo -e "Downloading the configuration file...\n"

# Download the configuration file
curl -o "$config_file" https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json

# Check if the downloaded file is empty
if [ ! -s "$config_file" ]; then
    echo -e "Error: The downloaded configuration file is empty. Please check the source URL.\n"
    exit 1
fi

clear
echo -e "Configuration file downloaded to $config_file\n"

clear
echo -e "Stopping any running Easy Effects processes...\n"

# Kill existing Easy Effects process if running
pkill easyeffects || true

clear
echo -e "Starting Easy Effects...\n"

# Start Easy Effects
nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &

clear
echo -e "Easy Effects has been started.\n"
echo -e "Please open Easy Effects and load the 'fw16-easy-effects' profile manually.\n"
