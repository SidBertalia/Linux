#!/bin/bash
##############################################################
# INSTALL GOOGLE CHROME
##############################################################

# Import functions and variables from main script if running standalone
if [ -z "$BOLD" ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    GRAY=$(tput setaf 7)
    RESET=$(tput sgr0)

    is_installed() {
        command -v "$1" &> /dev/null
    }

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

    PACKAGE_MANAGER=""
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    fi
fi

if is_installed google-chrome; then
    echo "${GREEN}Google Chrome is already installed.${RESET}"
    exit 0
fi

if ask_confirmation "Do you want to install Google Chrome?"; then
    echo "${YELLOW}${BOLD}Installing Google Chrome...${RESET}"
    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        wget -q --show-progress https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
        sudo dpkg -i /tmp/google-chrome.deb || sudo apt-get install -f -y
        rm -f /tmp/google-chrome.deb
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    fi
    echo "${GREEN}Google Chrome installed successfully.${RESET}"

    if command -v xdg-settings &> /dev/null; then
        if ask_confirmation "Do you want to set Google Chrome as the default browser?"; then
            xdg-settings set default-web-browser google-chrome.desktop
            echo "${GREEN}Google Chrome set as default browser.${RESET}"
        fi
    fi
else
    echo "${RED}${BOLD}Google Chrome installation skipped.${RESET}"
fi
