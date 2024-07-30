#!/bin/bash

# Update and install Flatpak
sudo apt update
sudo apt install -y flatpak

# Add the Flathub repository (if not already added)
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Mission Center from Flathub
flatpak install flathub io.missioncenter.MissionCenter -y

# Verify the installation
flatpak list | grep MissionCenter

echo "Mission Center has been installed successfully."
