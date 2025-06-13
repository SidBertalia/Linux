#!/bin/bash

set -e

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

##########################################################
# DEPENDENCY INSTALLATION
##########################################################

# Verify and install basic dependencies
REQUIRED_TOOLS=(wget unzip)
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! is_installed "$tool"; then
        echo "${YELLOW}${BOLD}Installing $tool...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt-get install -y "$tool"
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y "$tool"
        fi
    fi
done

##########################################################
# GNOME SHELL EXTENSIONS INSTALLATION
##########################################################

# Install gnome-shell-extensions package if not already installed
if ! is_installed gnome-shell-extensions; then
    if ask_confirmation "Do you want to install gnome-shell-extensions?"; then
        echo "${YELLOW}${BOLD}Installing gnome-shell-extensions...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt-get install -y gnome-shell-extensions
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y gnome-shell-extensions
        fi
        echo "${GREEN}gnome-shell-extensions installed successfully.${RESET}"
    else
        echo "${RED}${BOLD}Skipping gnome-shell-extensions installation.${RESET}"
        exit 1
    fi
else
    echo "${GREEN}gnome-shell-extensions is already installed.${RESET}"
fi

##########################################################
# GNOME EXTENSIONS FROM GITHUB
##########################################################

EXTENSIONS=(
    "https://github.com/acristoffers/gnome-rectangle/archive/master.zip"
    "https://github.com/eonpatapon/gnome-shell-extension-caffeine/archive/master.zip"
    "https://github.com/cliffniff/media-controls/archive/master.zip"
    "https://github.com/RedSoftwareSystems/easy_docker_containers/archive/master.zip"
    "https://github.com/GSConnect/gnome-shell-extension-gsconnect/archive/master.zip"
    "https://github.com/marcinjahn/gnome-dim-completed-calendar-events-extension/archive/master.zip"
    "https://github.com/jiggak/notification-icons/archive/master.zip"
    "https://github.com/meghprkh/force-quit/archive/master.zip"
    "https://github.com/CleoMenezesJr/weather-oclock/archive/master.zip"
    "https://github.com/Noobsai/fullscreen-avoider/archive/master.zip"
    "https://github.com/F-i-f/tweaks-system-menu/archive/master.zip"
    "https://github.com/aunetx/blur-my-shell/archive/master.zip"
    "https://gitlab.gnome.org/GNOME/gnome-shell-extensions/-/archive/master/gnome-shell-extensions-master.zip"
    "https://github.com/axxapy/gnome-ui-tune/archive/master.zip"
    "https://github.com/qwreey/quick-settings-tweaks/archive/master.zip"
    "https://github.com/hermes83/compiz-alike-magic-lamp-effect/archive/master.zip"
)

# Create extensions directory if it doesn't exist
mkdir -p ~/.local/share/gnome-shell/extensions

TEMP_DIR=$(mktemp -d)
for EXTENSION in "${EXTENSIONS[@]}"; do
    echo "${YELLOW}${BOLD}Installing $EXTENSION...${RESET}"
    wget "$EXTENSION" -O "$TEMP_DIR/extension.zip"
    unzip "$TEMP_DIR/extension.zip" -d "$TEMP_DIR"

    # Try to find and properly install the extension
    EXTENSION_DIR=$(find "$TEMP_DIR" -maxdepth 2 -type f -name "metadata.json" -exec dirname {} \; | head -n 1)
    if [ -n "$EXTENSION_DIR" ]; then
        UUID=$(grep -Po '(?<="uuid": ")[^"]*' "$EXTENSION_DIR/metadata.json")
        if [ -n "$UUID" ]; then
            mv "$EXTENSION_DIR" "$HOME/.local/share/gnome-shell/extensions/$UUID"
            echo "${BLUE}Extension installed with UUID: $UUID${RESET}"
        else
            echo "${RED}Failed to find UUID in metadata.json${RESET}"
        fi
    else
        echo "${RED}Failed to find extension directory in downloaded files${RESET}"
    fi

    rm -rf "$TEMP_DIR"/*
done
rm -rf "$TEMP_DIR"

echo "${GREEN}GNOME extensions installed successfully.${RESET}"

# Restart GNOME Shell to detect new extensions
echo "${YELLOW}Restarting GNOME Shell...${RESET}"
busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting...")'

# Enable all installed extensions
echo "${YELLOW}Enabling extensions...${RESET}"
for EXTENSION_DIR in ~/.local/share/gnome-shell/extensions/*; do
    if [ -f "$EXTENSION_DIR/metadata.json" ]; then
        UUID=$(basename "$EXTENSION_DIR")
        if gnome-extensions list | grep -q "$UUID"; then
            gnome-extensions enable "$UUID"
            echo "${BLUE}Enabled extension: $UUID${RESET}"
        fi
    fi
done

echo "${GREEN}GNOME extensions enabled successfully.${RESET}"
