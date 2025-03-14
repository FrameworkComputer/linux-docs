# Fedora Only 

## Copy and paste this into the terminal using your touchpad or mouse, then press enter.

``
sudo dnf install lshw dmidecode -y && clear && echo "===== BIOS & SYSTEM INFORMATION =====" && \
sudo dmidecode -t bios -t system | awk '/Vendor:/ || /Version:/ || /Manufacturer:/ || /Product Name:/' && \
echo -e "\n===== CPU INFORMATION =====" && \
sudo lshw -C cpu | grep -e product: -e vendor: -A1
``
