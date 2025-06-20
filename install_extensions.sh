#!/bin/bash

set -e

# Color variables and helpers
if [ -z "$BOLD" ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
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

REQUIRED_TOOLS=(wget unzip gnome-extensions)
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
# EXTENSIONS TO INSTALL (UUIDs)
##########################################################

EXTENSIONS_UUIDS=(
    rectangle@acristoffers.me
    caffeine@patapon.info
    mediacontrols@cliffniff.github.com
    easy_docker_containers@red.software.systems
    dim-completed-calendar-events@marcinjahn.com
    fq@megh
    weatheroclock@CleoMenezesJr.github.io
    fullscreen-avoider@noobsai.github.com
    tweaks-system-menu@extensions.gnome-shell.fifi.org
    blur-my-shell@aunetx
    user-theme@gnome-shell-extensions.gcampax.github.com
    gnome-ui-tune@itstime.tech
    quick-settings-tweaks@qwreey
    compiz-alike-magic-lamp-effect@hermes83.github.com
    search-light@icedman.github.com
    top-bar-organizer@julian.gse.jsts.xyz
    notification-position@drugo.dev
    drive-menu@gnome-shell-extensions.gcampax.github.com
    Bluetooth-Battery-Meter@maniacx.github.com
    notifications-alert-on-user-menu@hackedbellini.gmail.com
    ding@rastersoft.com
    ubuntu-appindicators@ubuntu.com
    ubuntu-dock@ubuntu.com
)

##########################################################
# INSTALL EXTENSIONS FROM GNOME EXTENSIONS WEBSITE
##########################################################

# Function to install extension by UUID using gnome-extensions CLI or fallback to gnome-shell-extension-installer
install_gnome_extension() {
    local uuid="$1"
    echo "${YELLOW}${BOLD}Installing $uuid...${RESET}"
    # Try with gnome-shell-extension-installer if available
    if is_installed gnome-shell-extension-installer; then
        gnome-shell-extension-installer --yes "$uuid"
    else
        # Try with gnome-extensions CLI (requires extension to be available in repo)
        echo "${RED}gnome-shell-extension-installer not found. Please install it for automatic installation.${RESET}"
        echo "${YELLOW}You can install it with:${RESET} sudo wget -O /usr/local/bin/gnome-shell-extension-installer https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer && sudo chmod +x /usr/local/bin/gnome-shell-extension-installer"
    fi
}

for uuid in "${EXTENSIONS_UUIDS[@]}"; do
    install_gnome_extension "$uuid"
done

echo "${GREEN}GNOME extensions installed successfully.${RESET}"

# Enable all installed extensions
echo "${YELLOW}Enabling extensions...${RESET}"
for uuid in "${EXTENSIONS_UUIDS[@]}"; do
    if gnome-extensions list | grep -q "$uuid"; then
        gnome-extensions enable "$uuid"
        echo "${BLUE}Enabled extension: $uuid${RESET}"
    fi
done

echo "${GREEN}GNOME extensions enabled successfully.${RESET}"
