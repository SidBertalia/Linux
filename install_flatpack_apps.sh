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
# FLATHUB INSTALLATION (before Flatpak apps)
##########################################################

if ! is_installed flatpak; then
    if ask_confirmation "Do you want to install Flatpak and enable Flathub?"; then
        echo "${YELLOW}${BOLD}Installing Flatpak and Flathub...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt install -y flatpak
            sudo apt install -y gnome-software-plugin-flatpak
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y flatpak
        fi
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        echo "${GREEN}Flatpak and Flathub installed successfully.${RESET}"
    fi
else
    echo "${GREEN}Flatpak is already installed.${RESET}"
fi

flatpak --version
echo "${GREEN}Flatpak tested successfully.${RESET}"

##########################################################
# FLATPAK APPLICATIONS INSTALLATION (optimized)
##########################################################

declare -A FLATPAK_APPS=(
    ["GNOME Tweaks (Extensions)"]="org.gnome.Extensions"
    ["Cheese"]="org.gnome.Cheese"
    ["DeepSeek Desktop"]="ai.deepseek.DeepSeekDesktop"
    ["Draw.io"]="com.jgraph.drawio.desktop"
    ["Atom"]="io.atom.Atom"
    ["Whaler"]="com.gustavosbarreto.Whaler"
    ["MarkText"]="com.github.marktext.marktext"
    ["Minder"]="com.github.phase1geo.minder"
)

for app_name in "${!FLATPAK_APPS[@]}"; do
    app_id="${FLATPAK_APPS[$app_name]}"
    if ! flatpak list --app | grep -q "$app_id"; then
        if ask_confirmation "Do you want to install $app_name?"; then
            echo "${YELLOW}${BOLD}Installing $app_name...${RESET}"
            flatpak install -y flathub "$app_id"
            echo "${GREEN}$app_name installed successfully.${RESET}"
        fi
    else
        echo "${GREEN}$app_name is already installed.${RESET}"
    fi
done

echo "${GREEN}${BOLD}Flatpak applications installation finished.${RESET}"
