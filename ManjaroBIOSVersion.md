## Simply copy and paste this entire code into the terminal
The output will give you BIOS, CPU and kernel information.

Go to the Manjaro Launcher or press the super key. Search for Terminal, launch the application.

``
sudo pacman -S dmidecode lshw  --noconfirm && sudo dmidecode | grep -A3 'Vendor:' && sudo lshw -C cpu | grep -A3 'product:' && sudo echo -e "\033[1;33mKernel: $(uname -r)\033[0m"
``
