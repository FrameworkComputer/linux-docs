#!/bin/bash

# Ensure curl is installed on Fedora
sudo dnf install -y curl

# Create the necessary directory and download the JSON file for Easy Effects on Fedora
mkdir -p ~/.config/easyeffects/output
curl -o ~/.config/easyeffects/output/fw16-easy-effects.json https://raw.githubusercontent.com/FrameworkComputer/linux-docs/main/easy-effects/fw16-easy-effects.json
