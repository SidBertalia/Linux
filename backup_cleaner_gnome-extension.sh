#!/bin/bash
set -e

# --- Color variables and helpers ---
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
            echo "${RED}${BOLD}Action cancelled by user.${RESET}"
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
# GNOME EXTENSIONS BACKUP FUNCTIONALITY
##########################################################
backup_gnome_extensions() {
    echo -e "${YELLOW}${BOLD}==> Starting GNOME Shell extensions backup...${RESET}"
    BACKUP_DIR="$HOME/gnome_extensions_backup"
    BACKUP_FILE="$HOME/gnome_extensions_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    EXTENSIONS_LIST=(
        "rectangle@acristoffers.me"
        "caffeine@patapon.info"
        "mediacontrols@cliffniff.github.com"
        "easy_docker_containers@red.software.systems"
        "dim-completed-calendar-events@marcinjahn.com"
        "fq@megh"
        "weatheroclock@CleoMenezesJr.github.io"
        "fullscreen-avoider@noobsai.github.com"
        "tweaks-system-menu@extensions.gnome-shell.fifi.org"
        "blur-my-shell@aunetx"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "gnome-ui-tune@itstime.tech"
        "quick-settings-tweaks@qwreey"
        "compiz-alike-magic-lamp-effect@hermes83.github.com"
        "search-light@icedman.github.com"
        "top-bar-organizer@julian.gse.jsts.xyz"
        "notification-position@drugo.dev"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "Bluetooth-Battery-Meter@maniacx.github.com"
        "notifications-alert-on-user-menu@hackedbellini.gmail.com"
        "ding@rastersoft.com"
        "ubuntu-appindicators@ubuntu.com"
        "ubuntu-dock@ubuntu.com"
    )

    if [ ! -d "$HOME/.local/share/gnome-shell/extensions" ]; then
        echo -e "${RED}Error: GNOME extensions directory not found!${RESET}"
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    echo "Collecting system information..."
    gnome-shell --version > "$BACKUP_DIR/gnome_version.txt"
    dconf dump /org/gnome/shell/enabled-extensions/ > "$BACKUP_DIR/enabled_extensions.txt"

    echo "Copying extension settings..."
    for EXTENSION in "${EXTENSIONS_LIST[@]}"; do
        EXTENSION_PATH="/org/gnome/shell/extensions/${EXTENSION%%@*}/"
        if dconf list "$EXTENSION_PATH" >/dev/null 2>&1; then
            echo "Backing up extension: $EXTENSION"
            dconf dump "$EXTENSION_PATH" > "$BACKUP_DIR/${EXTENSION}.dconf"
        fi
        if [ -d "$HOME/.local/share/gnome-shell/extensions/$EXTENSION" ]; then
            cp -r "$HOME/.local/share/gnome-shell/extensions/$EXTENSION" "$BACKUP_DIR/${EXTENSION}_files"
        fi
    done

    echo "Creating backup archive..."
    tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" .

    rm -rf "$BACKUP_DIR"

    echo -e "${GREEN}Backup completed successfully!${RESET}"
    echo "Backup file created: $BACKUP_FILE"
    echo ""
    echo "To restore your settings:"
    echo "1. Extract the archive: tar -xzf $BACKUP_FILE"
    echo "2. For each extension, run:"
    echo "   dconf load /org/gnome/shell/extensions/EXTENSION_NAME/ < EXTENSION_NAME.dconf"
    echo "3. Copy the extension directories back to ~/.local/share/gnome-shell/extensions/"
}

##########################################################
# GNOME EXTENSION CLEANUP FUNCTIONALITY
##########################################################
gnome_extension_cleaner() {
    echo -e "${YELLOW}${BOLD}==> Creating GNOME Shell settings backup...${RESET}"
    BACKUP_DIR="$HOME/gnome-backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/gnome-shell-settings-$(date +%Y%m%d%H%M%S).conf"
    dconf dump /org/gnome/shell/ > "$BACKUP_FILE"
    echo -e "${GREEN}Backup created at: ${BLUE}$BACKUP_FILE${RESET}"

    if ! pgrep -x "gnome-shell" > /dev/null; then
        echo -e "${RED}${BOLD}Error: GNOME Shell is not running!${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}${BOLD}==> Identifying installed extensions...${RESET}"
    INSTALLED_EXTS=$(gnome-extensions list --enabled)
    echo -e "Installed extensions:\n${BLUE}$INSTALLED_EXTS${RESET}"

    echo -e "${YELLOW}${BOLD}==> Cleaning up residual settings...${RESET}"
    REMOVED_CONFIGS=0
    for UUID in $(dconf list /org/gnome/shell/extensions/); do
        UUID=${UUID%/}
        if ! echo "$INSTALLED_EXTS" | grep -q "$UUID"; then
            echo -e "${RED}Removing settings for uninstalled extension: ${BOLD}$UUID${RESET}"
            dconf reset -f "/org/gnome/shell/extensions/$UUID/"
            ((REMOVED_CONFIGS++))
        fi
    done

    echo -e "${YELLOW}${BOLD}==> Checking for residual files...${RESET}"
    REMOVED_FILES=0
    EXT_DIRS=(
        "$HOME/.local/share/gnome-shell/extensions"
        "/usr/share/gnome-shell/extensions"
    )
    for DIR in "${EXT_DIRS[@]}"; do
        if [ -d "$DIR" ]; then
            for EXT_DIR in "$DIR"/*; do
                if [ -d "$EXT_DIR" ]; then
                    UUID=$(basename "$EXT_DIR")
                    if ! echo "$INSTALLED_EXTS" | grep -q "$UUID"; then
                        echo -e "${RED}Removing residual directory: ${BOLD}$EXT_DIR${RESET}"
                        rm -rf "$EXT_DIR"
                        ((REMOVED_FILES++))
                    fi
                fi
            done
        fi
    done

    echo -e "${YELLOW}${BOLD}==> Updating active extensions list...${RESET}"
    ENABLED_EXTS=$(gnome-extensions list --enabled | tr '\n' ',' | sed 's/,$//')
    dconf write /org/gnome/shell/enabled-extensions "[$ENABLED_EXTS]"

    echo -e "\n${GREEN}${BOLD}Cleanup completed successfully!${RESET}"
    echo -e "Configurations removed from dconf: ${BLUE}$REMOVED_CONFIGS${RESET}"
    echo -e "Residual files removed: ${BLUE}$REMOVED_FILES${RESET}"

    echo -e "\n${YELLOW}${BOLD}==> Restarting GNOME Shell...${RESET}"
    sleep 2
    if command -v busctl &> /dev/null; then
        busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting...")'
    else
        echo -e "${YELLOW}Using fallback method to restart GNOME Shell${RESET}"
        gnome-shell --replace & disown
    fi

    echo -e "\n${GREEN}Process completed!${RESET}"
}

##########################################################
# MAIN MENU
##########################################################
main_menu() {
    while true; do
        echo
        echo "${BLUE}${BOLD}GNOME Extensions Utility${RESET}"
        echo "  1 - Backup GNOME Shell extensions settings"
        echo "  2 - Clean up residual extension settings and files"
        echo "  3 - Exit"
        echo
        read -p "Choose an option: " opt
        case $opt in
            1) backup_gnome_extensions ;;
            2) gnome_extension_cleaner ;;
            3) echo "Exiting..."; break ;;
            *) echo "${RED}Invalid option${RESET}" ;;
        esac
    done
}

main_menu
