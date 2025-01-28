#!/bin/bash

# Update and install Flatpak
sudo apt update
sudo apt install -y flatpak

# Add the Flathub repository (if not already added)
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Flatseal Flathub
flatpak install flathub com.github.tchx84.Flatseal -y

# Verify the installation
flatpak list | grep Flatseal

echo "Flatseal been installed successfully."
