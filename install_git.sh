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
# GIT INSTALLATION AND CONFIGURATION
##########################################################

if ! is_installed git; then
    if ask_confirmation "Do you want to install Git?"; then
        echo "${YELLOW}${BOLD}Installing Git...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt install -y git
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y git
        fi
        echo "${GREEN}Git installed successfully.${RESET}"
    fi
else
    echo "${GREEN}Git is already installed.${RESET}"
fi

# Interactive Git configuration
echo "${YELLOW}${BOLD}Git configuration:${RESET}"
read -p "Enter your name: " git_name
git config --global user.name "$git_name"
read -p "Enter your email: " git_email
git config --global user.email "$git_email"
echo "${GREEN}Git configured successfully.${RESET}"

# Generate SSH key if it does not exist
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "${YELLOW}${BOLD}Generating SSH key...${RESET}"
    ssh-keygen -t ed25519 -C "$git_email"
    echo "${GREEN}SSH key generated successfully.${RESET}"
else
    echo "${GREEN}SSH key already exists.${RESET}"
fi

# Add SSH key to agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo "${GREEN}SSH key added to agent.${RESET}"

# Show public key
echo "${YELLOW}${BOLD}SSH public key:${RESET}"
cat ~/.ssh/id_ed25519.pub

echo "${YELLOW}${BOLD}Add the above public key to Github: https://github.com/settings/keys${RESET}"
read -p "${YELLOW}${BOLD}Press Enter to continue...${RESET}"
