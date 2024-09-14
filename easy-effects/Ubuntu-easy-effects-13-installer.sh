#!/bin/bash

log_file="/tmp/easy_effects_install.log"

# Function to install Easy Effects via apt
install_easy_effects() {
    echo "Installing Easy Effects via apt..." | tee -a "$log_file"

    # Update package list
    echo "Updating package list..." | tee -a "$log_file"
    sudo apt update | tee -a "$log_file"

    # Install Easy Effects
    echo "Running apt install command for Easy Effects..." | tee -a "$log_file"
    sudo apt install -y easyeffects | tee -a "$log_file"
    if [ $? -ne 0 ]; then
        echo "apt installation failed. Please check the log for details." | tee -a "$log_file"
        exit 1
    fi

    echo "Easy Effects installation completed." | tee -a "$log_file"
}

# Install Easy Effects
install_easy_effects

echo -e "Creating configuration directory...\n" | tee -a "$log_file"

# Define config directory and file
config_dir=~/.config/easyeffects/output
config_file="$config_dir/fw13-easy-effects.json"
irs_dir=~/.config/easyeffects/irs
irs_file="$irs_dir/IR_22ms_27dB_5t_15s_0c.irs"

# Create config directory if it doesn't exist
mkdir -p "$config_dir"
mkdir -p "$irs_dir"

echo -e "Downloading the configuration file...\n" | tee -a "$log_file"

# Download the configuration file
curl -fo "$config_file" https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw13-easy-effects.json | tee -a "$log_file"

# Check if the downloaded file is empty
if [ ! -s "$config_file" ]; then
    echo -e "Error: The downloaded configuration file is empty. Please check the source URL.\n" | tee -a "$log_file"
    exit 1
fi
echo -e "Configuration file downloaded to $config_file\n" | tee -a "$log_file"

echo -e "Downloading the convolver impact file...\n" | tee -a "$log_file"

curl -fo "$irs_file" https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/irs/IR_22ms_27dB_5t_15s_0c.irs | tee -a "$log_file"
# Check if the downloaded file is empty
if [ ! -s "$irs_file" ]; then
    echo -e "Error: The downloaded convolver file is empty. Please check the source URL.\n" | tee -a "$log_file"
    exit 1
fi

echo -e "Convolver impact file downloaded to $irs_file\n" | tee -a "$log_file"

echo -e "Stopping any running Easy Effects processes...\n" | tee -a "$log_file"

# Kill existing Easy Effects process if running
pkill easyeffects || true

echo -e "Starting Easy Effects...\n" | tee -a "$log_file"

# Start Easy Effects
nohup easyeffects &>/dev/null &

echo -e "Easy Effects has been started.\n" | tee -a "$log_file"
echo -e "Please open Easy Effects and load the 'fw13-easy-effects' profile manually.\n" | tee -a "$log_file"
