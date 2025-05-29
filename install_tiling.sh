#!/bin/bash

set -e

if [ $? -ne 0 ]; then
	echo "An error occurred during script execution. Please check the logs for more information."
	exit 1
fi

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
# POP OS TILING
##########################################################

echo "${YELLOW}${BOLD}Installing dependencies...${RESET}"
if ! is_installed git; then
	if ask_confirmation "Do you want to install Git?"; then
		echo "${YELLOW}${BOLD}Installing Git...${RESET}"
		sudo $PACKAGE_MANAGER install -y git
		echo "${GREEN}Git installed successfully.${RESET}"
	fi
else
	echo "${GREEN}Git is already installed.${RESET}"
fi

if ! is_installed nodejs; then
	if ask_confirmation "Do you want to install Node.js?"; then
		echo "${YELLOW}${BOLD}Installing Node.js...${RESET}"
		sudo $PACKAGE_MANAGER install -y nodejs
		echo "${GREEN}Node.js installed successfully.${RESET}"
	fi
else
	echo "${GREEN}Node.js is already installed.${RESET}"
fi

if ! is_installed npm; then
	if ask_confirmation "Do you want to install npm?"; then
		echo "${YELLOW}${BOLD}Installing npm...${RESET}"
		sudo $PACKAGE_MANAGER install -y npm
		echo "${GREEN}npm installed successfully.${RESET}"
	fi
else
	echo "${GREEN}npm is already installed.${RESET}"
fi

if ! is_installed make; then
	if ask_confirmation "Do you want to install make?"; then
		echo "${YELLOW}${BOLD}Installing make...${RESET}"
		sudo $PACKAGE_MANAGER install -y make
		echo "${GREEN}make installed successfully.${RESET}"
	fi
else
	echo "${GREEN}make is already installed.${RESET}"
fi

if ! is_installed gnome-shell-extension-prefs; then
	if ask_confirmation "Do you want to install gnome-shell-extension-prefs?"; then
		echo "${YELLOW}${BOLD}Installing gnome-shell-extension-prefs...${RESET}"
		sudo $PACKAGE_MANAGER install -y gnome-shell-extension-prefs
		echo "${GREEN}gnome-shell-extension-prefs installed successfully.${RESET}"
	fi
else
	echo "${GREEN}gnome-shell-extension-prefs is already installed.${RESET}"
fi

echo "${YELLOW}${BOLD}Installing Pop Shell...${RESET}"
sudo $PACKAGE_MANAGER update
sudo $PACKAGE_MANAGER install -y git nodejs npm make gnome-shell-extension-prefs

if command -v npm &> /dev/null; then
	sudo npm install -g typescript
else
	echo "${RED}${BOLD}npm não encontrado. Por favor, verifique a instalação do Node.js e npm.${RESET}"
	exit 1
fi

if [ -d "shell" ]; then
	rm -rf shell
fi
git clone https://github.com/pop-os/shell.git
cd shell
git checkout master_noble
make local-install

echo "${GREEN}Pop Shell installed successfully.${RESET}"
echo "${YELLOW}${BOLD}You may need to restart your GNOME session (logout/login) or the GNOME Shell (Alt+F2 r Enter) for the extension to appear.${RESET}"
echo "${YELLOW}${BOLD}To manage extensions, you can use the 'Extensions' application (GNOME Extensions).${RESET}"
