#!/bin/bash

# Function to set power save for a given interface
set_power_save() {
    local interface=$1
    local state=$2
    echo "Setting power save to $state for $interface..."
    
    if sudo iw dev $interface set power_save $state; then
        echo "Power save set to $state for $interface using iw command."
    else
        echo "Failed to set power save using iw command. Please check your permissions or wireless interface status."
        return 1
    fi
}

# Function to get and display power save status
get_power_save_status() {
    local interface=$1
    local status=$(iw dev $interface get power_save | awk '{print $3}')
    echo -n "$interface: Power save: "
    if [ "$status" = "on" ]; then
        echo "on"
    elif [ "$status" = "off" ]; then
        echo "off"
    else
        echo "unknown (raw output: $status)"
    fi
}

# Function to make changes persistent
make_persistent() {
    local state=$1
    echo "Making power save settings persistent..."
    
    # Create a script to be executed by the service
    cat << EOF | sudo tee /usr/local/bin/set-wifi-power-save.sh > /dev/null
#!/bin/bash
sleep 10  # Wait for network interfaces to be fully up
for interface in \$(iw dev | awk '\$1=="Interface"{print \$2}'); do
    iw dev \$interface set power_save $state
    echo "Set power_save $state for \$interface"
done
EOF
    sudo chmod +x /usr/local/bin/set-wifi-power-save.sh

    # Create a systemd service file
    cat << EOF | sudo tee /etc/systemd/system/wifi-power-save.service > /dev/null
[Unit]
Description=Set WiFi Power Save
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-wifi-power-save.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable wifi-power-save.service
    sudo systemctl start wifi-power-save.service
    
    echo "Persistent service created and enabled."
}

# Function to install a package if not installed
install_if_needed() {
    local package=$1
    if ! command -v $package &> /dev/null; then
        echo "$package not found, installing..."
        if [ -f /etc/fedora-release ]; then
            sudo dnf install -y $package
        elif [ -f /etc/lsb-release ]; then
            sudo apt-get update
            sudo apt-get install -y $package
        else
            echo "Unsupported Linux distribution. Please install $package manually."
            exit 1
        fi
    else
        echo "$package is already installed."
    fi
}

# Install iw and lshw if necessary
install_if_needed iw
install_if_needed lshw
clear

# Get all wireless interfaces
wireless_interfaces=$(iw dev | awk '$1=="Interface"{print $2}')

if [ -z "$wireless_interfaces" ]; then
    echo "No wireless interfaces found."
    exit 1
fi

# Prompt user for power save state
echo "Choose power save state:"
echo "1) On"
echo "2) Off"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1) state="on" ;;
    2) state="off" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

# Set power save for each wireless interface
for interface in $wireless_interfaces; do
    set_power_save $interface $state
done

# Verify power save status
echo -e "\nVerifying power save status:"
for interface in $wireless_interfaces; do
    get_power_save_status $interface
done

# Make changes persistent
make_persistent $state

echo -e "\nPower save settings applied and made persistent."
echo "Changes should persist across reboots."
echo "You can check the status of the persistent service with: sudo systemctl status wifi-power-save.service"
echo "If issues persist, check the system logs with: sudo journalctl -u wifi-power-save.service"
