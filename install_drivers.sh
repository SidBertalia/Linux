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

    PACKAGE_MANAGER=""
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    fi
fi

##########################################################
# DETECT IMAC AND OFFER AUDIO DRIVER
##########################################################

PRODUCT_NAME=$(sudo dmidecode -s system-product-name 2>/dev/null | tr -d '\n')
if [[ "$PRODUCT_NAME" =~ iMac ]]; then
    echo "${YELLOW}${BOLD}iMac detected.${RESET}"
    if ask_confirmation "Do you want to install the audio drivers for iMac?"; then
        if [ -f ./fix-imac-audio-ubuntu.sh ]; then
            chmod +x ./fix-imac-audio-ubuntu.sh
            ./fix-imac-audio-ubuntu.sh
        else
            echo "${RED}${BOLD}Script fix-imac-audio-ubuntu.sh not found!${RESET}"
        fi
    else
        echo "${YELLOW}iMac audio driver installation skipped.${RESET}"
    fi
fi

##########################################################
# DETECT MACBOOK PRO 9,1 AND OFFER BROADCOM DRIVER
##########################################################

if [[ "$PRODUCT_NAME" =~ "MacBookPro9,1" ]]; then
    echo "${YELLOW}${BOLD}MacBook Pro 9,1 detected.${RESET}"
    if ask_confirmation "Do you want to install Broadcom BCM43xx Wi-Fi drivers?"; then
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt update
            sudo apt install -y bcmwl-kernel-source
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y broadcom-wl
        fi
        echo "${GREEN}Broadcom BCM43xx drivers installed successfully.${RESET}"
    else
        echo "${YELLOW}Broadcom BCM43xx driver installation skipped.${RESET}"
    fi
fi

##########################################################
# DETECT CEDILLA ISSUE AND OFFER FIX
##########################################################

echo -n "Testing cedilla key (ç)... Please type ç and press Enter: "
read -r cedilla_test
if [[ "$cedilla_test" == "ć" ]]; then
    echo "${YELLOW}${BOLD}Cedilla issue detected (ç returns ć).${RESET}"
    if ask_confirmation "Do you want to apply the cedilla fix (fix_cedilha.sh)?"; then
        if [ -f ./fix_cedilha.sh ]; then
            chmod +x ./fix_cedilha.sh
            ./fix_cedilha.sh
        else
            echo "${RED}${BOLD}Script fix_cedilha.sh not found!${RESET}"
        fi
    else
        echo "${YELLOW}Cedilla fix skipped.${RESET}"
    fi
fi
