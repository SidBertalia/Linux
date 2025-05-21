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
# VSCODE INSTALLATION
##########################################################

if ! is_installed code; then
    if ask_confirmation "Do you want to install VSCode?"; then
        echo "${YELLOW}${BOLD}Installing VSCode...${RESET}"
        sudo snap install --classic code
        echo "${GREEN}VSCode installed successfully.${RESET}"
    fi
else
    echo "${GREEN}VSCode is already installed.${RESET}"
fi

# Test VSCode installation
if is_installed code; then
    code --version
    echo "${GREEN}VSCode tested successfully.${RESET}"
fi

##########################################################
# ZSH INSTALLATION
##########################################################

if ! is_installed zsh; then
    if ask_confirmation "Do you want to install Zsh?"; then
        echo "${YELLOW}${BOLD}Installing Zsh...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt install -y zsh
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf install -y zsh
        fi
        echo "${GREEN}Zsh installed successfully.${RESET}"
    else
        echo "${RED}${BOLD}Zsh installation skipped.${RESET}"
    fi
else
    echo "${GREEN}Zsh is already installed.${RESET}"
fi

# Change default shell to Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    if ask_confirmation "Do you want to change the default shell to Zsh?"; then
        echo "${YELLOW}${BOLD}Changing default shell to Zsh...${RESET}"
        chsh -s "$(which zsh)"
        echo "${GREEN}Default shell changed to Zsh.${RESET}"
    else
        echo "${RED}${BOLD}Default shell change skipped.${RESET}"
    fi
else
    echo "${GREEN}Default shell is already Zsh.${RESET}"
fi

##############################################################
# OH MY ZSH INSTALLATION
##############################################################
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if ask_confirmation "Do you want to install Oh My Zsh?"; then
        echo "${YELLOW}${BOLD}Installing Oh My Zsh...${RESET}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        echo "${GREEN}Oh My Zsh installed successfully.${RESET}"
    else
        echo "${RED}${BOLD}Oh My Zsh installation skipped.${RESET}"
    fi
else
    echo "${GREEN}Oh My Zsh is already installed.${RESET}"
fi

################################################################
# VSCE INSTALLATION (VSCode Extension Manager)
################################################################
if ! is_installed vsce; then
    if ask_confirmation "Do you want to install VSCE?"; then
        echo "${YELLOW}${BOLD}Installing VSCE...${RESET}"
        sudo npm install -g vsce
        echo "${GREEN}VSCE installed successfully.${RESET}"
    else
        echo "${RED}${BOLD}VSCE installation skipped.${RESET}"
    fi
else
    echo "${GREEN}VSCE is already installed.${RESET}"
fi

##############################################################
# ZSHRC CONFIGURATION
##############################################################

if [ ! -f ~/.zshrc ]; then
    echo "${RED}${BOLD}Zsh configuration file not found. Creating a new one...${RESET}"
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    echo "${GREEN}Zsh configuration file created successfully.${RESET}"
else
    echo "${GREEN}Zsh configuration file already exists.${RESET}"
fi

ZSHRC="$HOME/.zshrc"
CONFIG_BLOCK_START="# >>> Custom Oh My Zsh Configuration <<<"
CONFIG_BLOCK_END="# <<< Custom Oh My Zsh Configuration >>>"

# Backup BEFORE modifying
BACKUP_DIR="$HOME/Documents"
mkdir -p "$BACKUP_DIR"
cp "$ZSHRC" "$BACKUP_DIR/.zshrc.backup.$(date +%s)"
echo "${YELLOW}Backup of .zshrc created in $BACKUP_DIR${RESET}"

# Add custom configuration to .zshrc if not already present
if ! grep -q "$CONFIG_BLOCK_START" "$ZSHRC"; then
cat <<EOF >> "$ZSHRC"

$CONFIG_BLOCK_START
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source \$ZSH/oh-my-zsh.sh

# Aliases
alias zshconfig="mate ~/.zshrc"
alias ohmyzsh="mate ~/.oh-my-zsh"
alias dkr_clr='docker compose down --rmi all -v'
alias dkr_up='docker compose up -d'
alias dkr_clr_up='docker compose down --rmi all -v && docker compose up -d'
alias dkr_log='docker compose logs -f'
alias brewup='brew update && brew upgrade'
alias brewcln='brew cleanup'
alias brewclnup='brew cleanup && brew doctor'
alias vscodesettings='code ~/.config/Code/User/settings.json'
$CONFIG_BLOCK_END

EOF
    echo "${GREEN}Custom Oh My Zsh configuration added to .zshrc.${RESET}"
else
    echo "${YELLOW}Custom Oh My Zsh configuration already present in .zshrc.${RESET}"
fi

echo "${YELLOW}To apply the new configuration, run: source ~/.zshrc${RESET}"
