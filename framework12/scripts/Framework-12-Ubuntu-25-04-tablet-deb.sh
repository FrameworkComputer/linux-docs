#!/usr/bin/env bash
set -euo pipefail

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

DEB_URL="https://launchpad.net/ubuntu/+source/iio-sensor-proxy/3.5-1build2/+build/27983927/+files/iio-sensor-proxy_3.5-1build2_amd64.deb"
PKG_FILE="iio-sensor-proxy_3.5-1build2_amd64.deb"

# Ensure we have a downloader
if ! command -v wget &>/dev/null; then
  echo -e "${RED}Error:${RESET} wget is required but not installed." >&2
  exit 1
fi

echo -e "${BLUE}Downloading iio-sensor-proxy...${RESET}"
wget --progress=bar:force -O "$PKG_FILE" "$DEB_URL"

echo
echo -e "${BLUE}Installing iio-sensor-proxy (requires sudo)...${RESET}"
sudo dpkg -i "$PKG_FILE"

echo
echo -e "${BLUE}Fixing and installing any missing dependencies...${RESET}"
sudo apt-get update
sudo apt-get install -f -y

echo
echo -e "${BLUE}Cleaning up...${RESET}"
rm -f "$PKG_FILE"

echo -e "${GREEN}✅ iio-sensor-proxy has been installed.${RESET}"
echo

# Explain why holding matters
echo -e "${YELLOW}iio-sensor-proxy was installed manually at version 3.5-1build2."
echo -e "Ubuntu’s normal 'apt upgrade' cycle may later pull in a newer version"
echo -e "from the official repositories (e.g. 3.7-1) and overwrite this one.${RESET}"
echo

# Prompt to hold or not
while true; do
  echo -en "${YELLOW}Do you want to hold iio-sensor-proxy at this version? [y/N] ${RESET}"
  read -r yn
  case "$yn" in
    [Yy]* )
      sudo apt-mark hold iio-sensor-proxy
      echo -e "${GREEN}→ Package is now held. It will not be upgraded automatically.${RESET}"
      break
      ;;
    [Nn]*|'' )
      echo -e "${BLUE}→ Package will remain unheld and may be upgraded by apt in the future.${RESET}"
      break
      ;;
    * )
      echo -e "${RED}Please answer y or n.${RESET}"
      ;;
  esac
done
