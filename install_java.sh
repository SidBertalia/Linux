#!/bin/bash

##############################################################
# JAVA INSTALLATION
##############################################################

BOLD=$(tput bold)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

is_installed() {
    command -v java &> /dev/null
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

if is_installed; then
    echo "${GREEN}Java is already installed.${RESET}"
    java -version
    exit 0
fi

if ask_confirmation "Do you want to install the latest available OpenJDK?"; then
    echo "${YELLOW}${BOLD}Installing the latest available OpenJDK...${RESET}"
    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        sudo apt update
        sudo apt install -y default-jdk
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        sudo dnf install -y java-latest-openjdk
    fi
    echo "${GREEN}Java installed successfully.${RESET}"
    java -version
else
    echo "${RED}${BOLD}Java installation skipped.${RESET}"
fi

# Set JAVA_HOME for bash
JAVA_PATH=$(readlink -f "$(command -v java)" | sed "s:bin/java::")
if ! grep -q "JAVA_HOME" ~/.bashrc; then
    echo "export JAVA_HOME=${JAVA_PATH}" >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    echo "${GREEN}JAVA_HOME set in ~/.bashrc:${RESET} ${JAVA_PATH}"
else
    echo "${YELLOW}JAVA_HOME is already set in ~/.bashrc.${RESET}"
fi

# Set JAVA_HOME for zsh
if [ -f ~/.zshrc ]; then
    if ! grep -q "JAVA_HOME" ~/.zshrc; then
        echo "export JAVA_HOME=${JAVA_PATH}" >> ~/.zshrc
        echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc
        echo "${GREEN}JAVA_HOME set in ~/.zshrc:${RESET} ${JAVA_PATH}"
    else
        echo "${YELLOW}JAVA_HOME is already set in ~/.zshrc.${RESET}"
    fi
fi
