#!/bin/bash

# --- Color variables ---
if [ -z "$BOLD" ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
fi

# Function to remove a specific app
remove_app() {
    local APP_NAME="$1"
    echo ""
    echo "${BLUE}${BOLD}🔍 Searching and removing '$APP_NAME'...${RESET}"

    # --- 1. APT removal ---
    if apt list --installed 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "${YELLOW}📦 Found via APT. Remove?${RESET}"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    sudo apt purge "$APP_NAME" -y
                    sudo apt autoremove -y
                    break;;
                No ) break;;
            esac
        done
    fi

    # --- 2. Snap removal ---
    if snap list 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "${YELLOW}🦊 Found via Snap. Remove?${RESET}"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    sudo snap remove --purge "$APP_NAME"
                    break;;
                No ) break;;
            esac
        done
    fi

    # --- 3. Flatpak removal ---
    if flatpak list 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "${YELLOW}📦 Found via Flatpak. Remove?${RESET}"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    flatpak uninstall --delete-data "$APP_NAME" -y
                    break;;
                No ) break;;
            esac
        done
    fi

    # --- 4. Residual files cleanup ---
    echo "${YELLOW}🧹 Search for residual files of '$APP_NAME'? (Icons, configs, etc.)${RESET}"
    select yn in "Yes" "No"; do
        case $yn in
            Yes )
                echo "${BLUE}Cleaning...${RESET}"
                sudo find /usr/share/applications/ ~/.local/share/applications/ -iname "*$APP_NAME*.desktop" -delete
                sudo find /usr/share/icons/ ~/.local/share/icons/ -iname "*$APP_NAME*" -delete
                sudo find ~/.config/ ~/.cache/ -iname "*$APP_NAME*" -exec rm -rf {} +
                sudo find /opt/ ~/.local/bin/ -iname "*$APP_NAME*" -exec rm -rf {} +
                sudo update-desktop-database
                sudo update-mime-database /usr/share/mime
                break;;
            No ) break;;
        esac
    done

    echo "${GREEN}✅ Completed for '$APP_NAME'!${RESET}"
    echo "${GRAY}─────────────────────────────────────${RESET}"
}

# --- Main menu ---
echo "${BLUE}${BOLD}🛠️  APP UNINSTALLER (APT/Snap/Flatpak) 🛠️${RESET}"
echo "${GRAY}─────────────────────────────────────${RESET}"

# Ask how many apps to remove
read -p "How many apps do you want to remove? " NUM_APPS

# Loop for each app
for (( i=1; i<=$NUM_APPS; i++ )); do
    read -p "Enter name of app #$i: " APP_NAME
    remove_app "$APP_NAME"
done

echo ""
echo "${GREEN}🎉 All apps have been processed!${RESET}"
echo "${YELLOW}Tip: Reboot the system to ensure all changes take effect.${RESET}"
