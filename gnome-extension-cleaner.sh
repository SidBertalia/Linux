#!/bin/bash
set -e

# Import functions and variables if running standalone
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
# GNOME EXTENSION CLEANUP TOOL
##########################################################

# Create automatic backup
echo -e "${YELLOW}${BOLD}==> Creating settings backup...${RESET}"
BACKUP_DIR="$HOME/gnome-backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/gnome-shell-settings-$(date +%Y%m%d%H%M%S).conf"
dconf dump /org/gnome/shell/ > "$BACKUP_FILE"
echo -e "${GREEN}Backup created at: ${BLUE}$BACKUP_FILE${RESET}"

# Verify GNOME Shell is running
if ! pgrep -x "gnome-shell" > /dev/null; then
    echo -e "${RED}${BOLD}Error: GNOME Shell is not running!${RESET}"
    exit 1
fi

# Identify currently installed extensions
echo -e "${YELLOW}${BOLD}==> Identifying installed extensions...${RESET}"
INSTALLED_EXTS=$(gnome-extensions list --enabled)
echo -e "Installed extensions:\n${BLUE}$INSTALLED_EXTS${RESET}"

# Clean residual configurations
echo -e "${YELLOW}${BOLD}==> Cleaning residual configurations...${RESET}"
REMOVED_CONFIGS=0

# Check dconf settings
for UUID in $(dconf list /org/gnome/shell/extensions/); do
    UUID=${UUID%/}
    if ! echo "$INSTALLED_EXTS" | grep -q "$UUID"; then
        echo -e "${RED}Removing settings for uninstalled extension: ${BOLD}$UUID${RESET}"
        dconf reset -f "/org/gnome/shell/extensions/$UUID/"
        ((REMOVED_CONFIGS++))
    fi
done

# Clean residual files
echo -e "${YELLOW}${BOLD}==> Checking residual files...${RESET}"
REMOVED_FILES=0

# Check both local and system extension directories
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

# Update active extensions list
echo -e "${YELLOW}${BOLD}==> Updating active extensions list...${RESET}"
ENABLED_EXTS=$(gnome-extensions list --enabled | tr '\n' ',' | sed 's/,$//')
dconf write /org/gnome/shell/enabled-extensions "[$ENABLED_EXTS]"

# Operation summary
echo -e "\n${GREEN}${BOLD}Cleanup completed successfully!${RESET}"
echo -e "Configurations removed from dconf: ${BLUE}$REMOVED_CONFIGS${RESET}"
echo -e "Residual files removed: ${BLUE}$REMOVED_FILES${RESET}"

# Restart GNOME Shell to apply changes
echo -e "\n${YELLOW}${BOLD}==> Restarting GNOME Shell...${RESET}"
sleep 2
if command -v busctl &> /dev/null; then
    busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting...")'
else
    echo -e "${YELLOW}Using fallback method to restart GNOME Shell${RESET}"
    gnome-shell --replace & disown
fi

echo -e "\n${GREEN}Process completed!${RESET}"
