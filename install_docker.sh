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
# DOCKER INSTALLATION
##########################################################

if ! is_installed docker; then
    if ask_confirmation "Do you want to install Docker?"; then
        echo "${YELLOW}${BOLD}Installing Docker...${RESET}"
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
        fi
        echo "${GREEN}Docker installed successfully.${RESET}"
    fi
else
    echo "${GREEN}Docker is already installed.${RESET}"
fi

# Test Docker installation
if is_installed docker; then
    sudo docker run hello-world
    echo "${GREEN}Docker tested successfully.${RESET}"
fi

# Add user to docker group
sudo usermod -aG docker $USER
echo "${GREEN}User added to Docker group.${RESET}"

echo "${YELLOW}${BOLD}Log out and log in again to apply group changes.${RESET}"

# Ensure Docker service is running
sudo systemctl status docker || sudo systemctl start docker
echo "${GREEN}Docker service is running.${RESET}"

# Add alias to .bashrc
if ! grep -q "alias docker-compose='docker compose'" ~/.bashrc; then
    echo "alias docker-compose='docker compose'" >> ~/.bashrc
    echo "${GREEN}Alias for docker-compose added to .bashrc.${RESET}"
fi
