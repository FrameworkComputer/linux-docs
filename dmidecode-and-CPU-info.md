# Fedora 37/38 only 

## Copy and paste this into the terminal using your touchpad or mouse, then press enter.

``
sudo dnf install lshw dmidecode -y && sudo dmidecode | grep -A3 'Vendor:\|Product:' && sudo lshw -C cpu | grep -A3 'product:\|vendor:'
``
