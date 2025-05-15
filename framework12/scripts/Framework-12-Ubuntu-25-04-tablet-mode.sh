#!/bin/bash

echo "=== Framework Laptop 12 Auto-Rotation and On-Screen Keyboard Setup Script for Ubuntu ==="
echo "This script will set up auto-rotation and on-screen keyboard for Framework Laptop 12"
echo

# Function to check if we're running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Check if we're root
check_root

# Find the current user (at the beginning so we can use it throughout the script)
ACTUAL_USER=$(who | grep -E '\([[:alnum:]]+\)' | head -n1 | awk '{print $1}')
if [ -z "$ACTUAL_USER" ] && [ -n "$SUDO_USER" ]; then
    ACTUAL_USER=$SUDO_USER
fi

if [ -n "$ACTUAL_USER" ]; then
    USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
    echo "Setting up for user $ACTUAL_USER (home: $USER_HOME)"
fi

echo "1. Setting up iio-sensor-proxy service..."

# Stop and remove services - if this was installed once before
systemctl stop auto-rotate 2>/dev/null || true
systemctl stop Framework-sensor-proxy 2>/dev/null || true
systemctl disable auto-rotate 2>/dev/null || true
systemctl disable Framework-sensor-proxy 2>/dev/null || true
rm -f /etc/systemd/system/auto-rotate.service
rm -f /etc/systemd/system/Framework-sensor-proxy.service
systemctl daemon-reload

# Remove udev rules - if this was installed once before
rm -f /etc/udev/rules.d/61-sensor-local.rules
udevadm control --reload-rules

# Remove iio-sensor-proxy package
apt remove --purge iio-sensor-proxy -y

# Clean up package files - from any previous installs
if [ -n "$ACTUAL_USER" ] && [ -d "$USER_HOME" ]; then
    echo "Cleaning up package files from home directory..."
    # Remove any files with iio-sensor-proxy in the name from the home directory
    rm -f "$USER_HOME"/iio-sensor-proxy*
    rm -f "$USER_HOME"/*iio-sensor-proxy*
fi

# Clean up any temporary files from previous runs
rm -rf /tmp/main.zip /tmp/gnome-shell-extension-screen-autorotate-main
cd /tmp && rm -f iio-sensor-proxy*.rpm iio-sensor-proxy*.deb

echo "2. Installing required packages..."
apt install -y alien rpm libgudev-1.0-0 libsystemd0 dbus wget unzip curl gnome-shell-extension-prefs gnome-tweaks

# Install on-screen keyboard packages
echo "3. Installing on-screen keyboard packages..."
apt install -y caribou onboard

# Grabbing from https://packages.fedoraproject.org/pkgs/iio-sensor-proxy/iio-sensor-proxy/fedora-42.html
echo "4. Downloading Fedora's iio-sensor-proxy package..."
wget -q https://kojipkgs.fedoraproject.org//packages/iio-sensor-proxy/3.5/6.fc42/x86_64/iio-sensor-proxy-3.5-6.fc42.x86_64.rpm

echo "5. Converting and installing the package..."
alien --scripts -d iio-sensor-proxy-3.5-6.fc42.x86_64.rpm
dpkg -i iio-sensor-proxy_3.5-*.deb

echo "6. Creating device nodes and fixing permissions..."
for DEVICE in /sys/devices/platform/cros_ec_lpcs.0/cros-ec-dev.*/cros-ec-sensorhub.*/cros-ec-accel.*/iio:device*; do
    if [ -d "$DEVICE" ]; then
        echo "Found device: $DEVICE"
        
        # Fix permissions - using 0660 instead of 0666
        chmod -R 660 $DEVICE/scan_elements 2>/dev/null || echo "Could not set permissions on scan_elements"
        
        # Create character device if missing
        if [ -f "$DEVICE/dev" ]; then
            MAJOR=$(cat $DEVICE/dev | cut -d: -f1)
            MINOR=$(cat $DEVICE/dev | cut -d: -f2)
            DEV_NUM=$(basename $DEVICE | sed 's/iio:device//')
            
            echo "Creating character device /dev/iio:device$DEV_NUM with major:minor $MAJOR:$MINOR"
            rm -f /dev/iio:device$DEV_NUM
            mknod /dev/iio:device$DEV_NUM c $MAJOR $MINOR 2>/dev/null || echo "- Failed to create device"
            chmod 660 /dev/iio:device$DEV_NUM
            chgrp plugdev /dev/iio:device$DEV_NUM 2>/dev/null || echo "- Failed to set group"
        fi
    fi
done

echo "7. Creating udev rules for sensor permissions..."
cat > /etc/udev/rules.d/61-sensor-local.rules << 'EOF'
# Framework sensor permissions
SUBSYSTEM=="iio", KERNEL=="iio:device*", ATTRS{name}=="cros-ec-*", TAG+="systemd", MODE="0660", GROUP="plugdev"
EOF

echo "8. Setting up systemd service for iio-sensor-proxy..."
cat > /etc/systemd/system/Framework-sensor-proxy.service << 'EOF'
[Unit]
Description=Framework IIO Sensor Proxy Service
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/libexec/iio-sensor-proxy
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

if [ -n "$ACTUAL_USER" ]; then
    # Add user to plugdev group
    usermod -a -G plugdev "$ACTUAL_USER"
    
    if [ -d "$USER_HOME" ]; then
        echo "9. Installing screen-rotate extension with CORRECT name..."
        
        # Remove any existing extension installations
        rm -rf "$USER_HOME/.local/share/gnome-shell/extensions/screen-autorotate@klinnex"
        rm -rf "$USER_HOME/.local/share/gnome-shell/extensions/screen-rotate@shyzus.github.io"
        
        # Create extensions directory if it doesn't exist
        mkdir -p "$USER_HOME/.local/share/gnome-shell/extensions"
        
        # Download extension directly using curl
        echo "Downloading extension..."
        cd /tmp
        rm -rf main.zip gnome-shell-extension-screen-autorotate-main
        curl -L -o main.zip https://github.com/shyzus/gnome-shell-extension-screen-autorotate/archive/refs/heads/main.zip
        
        # Check if download was successful
        if [ -f main.zip ]; then
            echo "Extension downloaded successfully."
            
            # Unzip the extension
            unzip -q main.zip
            
            if [ -d gnome-shell-extension-screen-autorotate-main ]; then
                # Create extension directory with CORRECT name
                EXTENSION_DIR="$USER_HOME/.local/share/gnome-shell/extensions/screen-rotate@shyzus.github.io"
                rm -rf "$EXTENSION_DIR"
                mkdir -p "$EXTENSION_DIR"
                
                # Copy ONLY the files from the correct subdirectory
                echo "Installing extension files with correct structure..."
                cp -r /tmp/gnome-shell-extension-screen-autorotate-main/screen-rotate@shyzus.github.io/* "$EXTENSION_DIR/"
                
                # Fix permissions
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$EXTENSION_DIR"
                chmod -R 755 "$EXTENSION_DIR"
                
                echo "Extension installed at $EXTENSION_DIR"
                
                # Check if GNOME version is in metadata.json
                GNOME_VERSION=$(su - "$ACTUAL_USER" -c "gnome-shell --version | cut -d' ' -f3 | cut -d'.' -f1,2")
                echo "Detected GNOME version: $GNOME_VERSION"
                
                # Update metadata.json to ensure compatibility with current GNOME version
                if [ -n "$GNOME_VERSION" ]; then
                    METADATA="$EXTENSION_DIR/metadata.json"
                    if [ -f "$METADATA" ]; then
                        # Backup the original
                        cp "$METADATA" "$METADATA.bak"
                        
                        # Add current GNOME version to shell-version array if not already there
                        if ! grep -q "\"$GNOME_VERSION\"" "$METADATA"; then
                            echo "Adding GNOME version $GNOME_VERSION to metadata.json"
                            sed -i "s/\"shell-version\":\s*\[\([^]]*\)\]/\"shell-version\": [\1, \"$GNOME_VERSION\"]/" "$METADATA"
                            # Fix JSON syntax if needed (remove extra comma after empty array)
                            sed -i 's/\[\s*,/[/' "$METADATA"
                        fi
                        
                        chown "$ACTUAL_USER:$ACTUAL_USER" "$METADATA"
                    fi
                fi
                
                # Create autostart script for enabling the extension
                mkdir -p "$USER_HOME/.config/autostart"
                cat > "$USER_HOME/.config/autostart/enable-rotate-extension.desktop" << EOL
[Desktop Entry]
Type=Application
Name=Enable Screen Rotation Extension
Exec=bash -c "sleep 10 && gnome-extensions enable screen-rotate@shyzus.github.io"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOL
                chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/autostart/enable-rotate-extension.desktop"
                chmod 755 "$USER_HOME/.config/autostart/enable-rotate-extension.desktop"
                
                # Compile schemas if needed
                if [ -d "$EXTENSION_DIR/schemas" ]; then
                    echo "Compiling extension schemas..."
                    cd "$EXTENSION_DIR/schemas"
                    glib-compile-schemas .
                fi
            else
                echo "Failed to extract extension files."
            fi
        else
            echo "Failed to download extension."
        fi
    else
        echo "User home directory not found: $USER_HOME"
    fi
else
    echo "Could not determine current user."
fi

echo "10. Reload systemd and enable services..."
systemctl daemon-reload
systemctl enable Framework-sensor-proxy
systemctl restart Framework-sensor-proxy

echo "11. Reload udev rules..."
udevadm control --reload-rules
udevadm trigger

# Clean up package files from /tmp and home directory
cd /tmp && rm -f iio-sensor-proxy*.rpm iio-sensor-proxy*.deb main.zip
rm -rf /tmp/gnome-shell-extension-screen-autorotate-main

# Clean up package files from home directory - any files with iio-sensor-proxy in the name
if [ -n "$ACTUAL_USER" ] && [ -d "$USER_HOME" ]; then
    echo "Cleaning up package files from home directory..."
    # Remove any files with iio-sensor-proxy in the name from the home directory
    rm -f "$USER_HOME"/iio-sensor-proxy*
    rm -f "$USER_HOME"/*iio-sensor-proxy*
fi

echo
echo "=== Installation Complete ==="
echo "The script has:"
echo "1. Installed the Fedora version of iio-sensor-proxy"
echo "2. Set up device nodes and permissions with secure 0660 permissions"
echo "3. Added your user to the plugdev group for sensor access"
echo "4. Created necessary udev rules with MODE=\"0660\""
echo "5. Installed the screen-rotate extension"
echo "6. Preserved the built-in on-screen keyboard functionality"
echo
echo "IMPORTANT: You MUST reboot your device for all changes to take effect."
echo "           This is especially important for the group permissions to apply."
echo
echo "After reboot:"
echo "1. Auto-rotation should work automatically"
echo "2. The built-in on-screen keyboard should appear when you rotate to tablet mode"
echo
echo "Your Framework's auto-rotation and on-screen keyboard should now work with proper"
echo "touch screen support in Wayland after reboot."
