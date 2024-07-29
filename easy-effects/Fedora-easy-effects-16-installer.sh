#!/bin/bash

# Fedora installer. Installs Easy Effects, installs the FW16 profile. 

install_easy_effects() {
    echo "Easy Effects is not installed. Installing Flatpak package..."
    
    echo "Installing Easy Effects..."
    if ! flatpak install flathub com.github.wwmm.easyeffects -y; then
        echo "Installation failed. Please install Easy Effects manually."
        exit 1
    fi
    
    echo "Easy Effects installation completed."
}

echo "Checking if Easy Effects is already installed..."
if ! flatpak list | grep -q com.github.wwmm.easyeffects; then
    echo "Easy Effects is not installed. Proceeding with installation..."
    install_easy_effects
else
    echo "Easy Effects is already installed."
fi

clear
echo -e "Creating configuration directory...\n"
config_dir=~/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output
config_file="$config_dir/fw16-easy-effects.json"
mkdir -p "$config_dir"

clear
echo -e "Downloading the configuration file...\n"
curl -o "$config_file" https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json

if [ ! -s "$config_file" ]; then
    echo -e "Error: The downloaded configuration file is empty. Please check the source URL.\n"
    exit 1
fi

clear
echo -e "Configuration file downloaded to $config_file\n"

clear
echo -e "Stopping any running Easy Effects processes...\n"
pkill easyeffects || true

clear
echo -e "Starting Easy Effects...\n"
nohup flatpak run com.github.wwmm.easyeffects &>/dev/null &

clear
echo -e "Easy Effects has been started.\n"
echo -e "Please open Easy Effects and load the 'fw16-easy-effects' profile manually.\n"
