#!/bin/bash
set -e

##########################################################
# FUNCTIONS
##########################################################

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
GRAY=$(tput setaf 7)
RESET=$(tput sgr0)

detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "unsupported"
    fi
}

is_installed() {
    command -v "$1" &> /dev/null
}

update_progress() {
    local progress=$1
    local total=$2
    local percent=$((progress * 100 / total))
    local bar_length=$((percent / 2))
    local bar=$(printf "%-${bar_length}s" "=")
    echo -ne "${GREEN}${BOLD}Progress:${RESET} ${GRAY}${bar}${RESET} ${GREEN}${BOLD}${percent}%${RESET}\r"
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

# Adjust the number of steps as needed
TOTAL_STEPS=9
CURRENT_STEP=0

##########################################################
# DETECT PACKAGE MANAGER
##########################################################

PACKAGE_MANAGER=$(detect_package_manager)
if [ "$PACKAGE_MANAGER" == "unsupported" ]; then
    echo "${RED}${BOLD}Unsupported package manager.${RESET}"
    exit 1
fi
echo "${BLUE}${BOLD}Package Manager: $PACKAGE_MANAGER${RESET}"
CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS

##########################################################
# DETECT OPERATING SYSTEM
##########################################################

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
else
    echo "${RED}${BOLD}Unsupported operating system.${RESET}"
    exit 1
fi
echo "${BLUE}${BOLD}Operating System: $OS_NAME${RESET}"
CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS

##########################################################
# CONFIRMATION
##########################################################

if ! ask_confirmation "Start installation on $OS_NAME?"; then
    echo "${RED}${BOLD}Installation aborted.${RESET}"
    exit 1
fi
CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS

##########################################################
# INSTALLATION: SYSTEM UPDATE
##########################################################

if [ "$PACKAGE_MANAGER" == "apt" ]; then
    echo "${YELLOW}${BOLD}Updating repositories and packages...${RESET}"
    sudo apt update && sudo apt upgrade -y
elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
    echo "${YELLOW}${BOLD}Updating repositories and packages...${RESET}"
    sudo dnf check-update && sudo dnf upgrade -y
fi
echo "${GREEN}Repositories and packages updated successfully.${RESET}"
CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS

##########################################################
# CALL SUBSCRIPTS
##########################################################

# 1. Install drivers (hardware, network, audio, etc.)
if [ -f ./install_drivers.sh ]; then
    if ! ./install_drivers.sh; then
        echo "${RED}${BOLD}Error installing drivers.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 2. Install Google Chrome
if [ -f ./install_chrome.sh ]; then
    if ! ./install_chrome.sh; then
        echo "${RED}${BOLD}Error installing Google Chrome.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 3. Install Docker
if [ -f ./install_docker.sh ]; then
    if ! ./install_docker.sh; then
        echo "${RED}${BOLD}Error installing Docker.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 4. Install and configure Git (and SSH key)
if [ -f ./install_git.sh ]; then
	if ! ./install_git.sh; then
        echo "${RED}${BOLD}Error installing/configuring Git.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 5. Install VSCode, Zsh/Oh My Zsh and vsce extension manager
if [ -f ./install_vscode.sh ]; then
    if ! ./install_vscode.sh; then
        echo "${RED}${BOLD}Error installing VSCode/Zsh.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 6. Install Java
if [ -f ./install_java.sh ]; then
	if ! ./install_java.sh; then
		echo "${RED}${BOLD}Error installing Java.${RESET}"; exit 1
	fi
	CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 7. Install fonts
if [ -f ./install_fonts.sh ]; then
    if ! ./install_fonts.sh; then
        echo "${RED}${BOLD}Error installing fonts.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 8. Install Flatpak applications
if [ -f ./install_flatpack_apps.sh ]; then
    if ! ./install_flatpack_apps.sh; then
        echo "${RED}${BOLD}Error installing Flatpak Apps.${RESET}"; exit 1
    fi
    CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

# 9. Install Pop OS Tilting
if [ -f ./install_tiling.sh ]; then
	if ! ./install_tiling.sh; then
		echo "${RED}${BOLD}Error installing Pop Shell Tilting.${RESET}"; exit 1
	fi
	CURRENT_STEP=$((CURRENT_STEP + 1)); update_progress $CURRENT_STEP $TOTAL_STEPS
fi

################################################################
# FINISHING INSTALLATION
################################################################

echo "${GREEN}${BOLD}Installation finished.${RESET}"

# Offer reboot
if ask_confirmation "Do you want to reboot now to apply all changes?"; then
    echo -e "${YELLOW}${BOLD}\nThe system will reboot in 5 seconds...\nSee you soon. Goodbye!${RESET}"
    sleep 5
    sudo reboot
else
    echo "${YELLOW}${BOLD}\nReboot skipped.\nPlease reboot manually later to apply all changes.\n${RESET}"
fi
