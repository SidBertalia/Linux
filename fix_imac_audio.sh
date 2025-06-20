#!/bin/bash

# Import functions and variables from main script if running standalone
if [ -z "$BOLD" ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    GRAY=$(tput setaf 7)
    RESET=$(tput sgr0)

    ask_confirmation() {
        local question="$1"
        echo -e "${YELLOW}${BOLD}${question} (y/n):${RESET}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "${RED}${BOLD}Action skipped by user.${RESET}"
            return 1
        fi
        return 0
    }
fi

DOWNLOADS_DIR="$HOME/Downloads"
DRIVER_DIR="$DOWNLOADS_DIR/snd-hda-codec-cs8409"

echo "${YELLOW}${BOLD}This script will install the snd-hda-codec-cs8409 driver on your Ubuntu system.${RESET}"
echo "Dependencies will be installed and the driver will be downloaded and compiled in the Downloads folder."
echo "After installation, the downloaded files will be removed."
echo "It is recommended to reboot your computer after installation."
echo

if ! ask_confirmation "Do you want to continue?"; then
    echo "${RED}${BOLD}Installation cancelled.${RESET}"
    exit 0
fi

echo "${YELLOW}${BOLD}Installing dependencies...${RESET}"
sudo apt update
sudo apt install -y linux-headers-generic build-essential git gcc-12

echo "${YELLOW}${BOLD}Downloading the driver to the Downloads folder...${RESET}"
rm -rf "$DRIVER_DIR"
git clone https://github.com/egorenar/snd-hda-codec-cs8409 "$DRIVER_DIR"

echo "${YELLOW}${BOLD}Compiling and installing the driver...${RESET}"
cd "$DRIVER_DIR" || { echo "${RED}${BOLD}Error accessing the driver directory.${RESET}"; exit 1; }
make
sudo make install
cd "$HOME"

echo "${YELLOW}${BOLD}Cleaning up downloaded files...${RESET}"
rm -rf "$DRIVER_DIR"

echo
echo "${GREEN}${BOLD}Installation completed!${RESET}"
if ask_confirmation "Do you want to reboot the computer now?"; then
    echo "${YELLOW}${BOLD}Rebooting the computer...${RESET}"
    sudo reboot
else
    echo "${YELLOW}Please reboot your computer manually to apply the changes.${RESET}"
fi

echo "${BLUE}To remove the driver, download the repository again and run: sudo make uninstall${RESET}"
