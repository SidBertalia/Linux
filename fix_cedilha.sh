#!/bin/bash

# Cedilla Fix Script for Ubuntu (Xorg and Wayland/GTK4)
# This script must be run as root (sudo).
#
# Options:
#   - Xorg: modifies system files and sets environment variables via /etc/profile.d
#   - Wayland/GTK4: sets variables in /etc/environment, creates ~/.XCompose, and sets GTK4 input method
#
# Use the Xorg method for Xorg sessions, and the Wayland/GTK4 method for modern GNOME/GTK4/Wayland sessions.
#
# WARNING: This script makes system-wide changes. Always run as root and make backups if necessary.

# --- Color variables ---
if [ -z "$BOLD" ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
fi

# --- Require root ---
if [[ $EUID -ne 0 ]]; then
    echo "${RED}${BOLD}This script must be run as root (sudo).${RESET}"
    exit 1
fi

# --- Check dependencies ---
command -v gsettings >/dev/null 2>&1 || { echo >&2 "${YELLOW}Warning: gsettings not found. GTK4 features may not work.${RESET}"; }

# --- Progress bar ---
show_progress() {
    local progress=$1
    local total=$2
    local percent=$((progress * 100 / total))
    local bar_length=50
    local filled_length=$((percent * bar_length / 100))
    local bar=$(printf "%-${bar_length}s" "#" | tr ' ' '#')
    local empty=$(printf "%-${bar_length}s" "-" | tr ' ' '-')
    printf "\r[%s%s] %d%%" "${bar:0:filled_length}" "${empty:filled_length}" "$percent"
}

# --- Paths ---
files=(
    "/usr/lib/x86_64-linux-gnu/gtk-3.0/3.0.0/immodules.cache"
    "/usr/lib/x86_64-linux-gnu/gtk-2.0/2.10.0/immodules.cache"
)
backup_suffix=".fix_cedilha.bak"

if [ "$(uname -m)" != "x86_64" ]; then
    files=(
        "/usr/lib/i386-linux-gnu/gtk-3.0/3.0.0/immodules.cache"
        "/usr/lib/i386-linux-gnu/gtk-2.0/2.10.0/immodules.cache"
    )
fi

compose_file="/usr/share/X11/locale/en_US.UTF-8/Compose"
compose_backup="${compose_file}${backup_suffix}"

environment_file="/etc/environment"
environment_backup="${environment_file}${backup_suffix}"
user_compose_file="$HOME/.XCompose"
user_compose_backup="${user_compose_file}${backup_suffix}"

# --- Xorg fix ---
install_fix_cedilha() {
    echo "${YELLOW}${BOLD}Applying Cedilla Fix for Xorg...${RESET}"
    total_files=${#files[@]}
    for i in "${!files[@]}"; do
        file="${files[$i]}"
        backup="${file}${backup_suffix}"
        if [ -f "$file" ]; then
            if [ ! -f "$backup" ]; then
                cp "$file" "$backup"
            fi
            # If you want to force cedilla for en, add the sed line here.
            echo "File $file successfully checked and backed up."
        else
            echo "File $file not found."
        fi
        show_progress $((i + 1)) $total_files
    done
    echo

    echo "Backing up and modifying Compose file..."
    if [ -f "$compose_file" ]; then
        if [ ! -f "$compose_backup" ]; then
            cp "$compose_file" "$compose_backup"
        fi
        tmp_compose=$(mktemp)
        sed 's/ć/ç/g' < "$compose_file" | sed 's/Ć/Ç/g' > "$tmp_compose"
        mv "$tmp_compose" "$compose_file"
        echo "Compose file successfully modified."
    else
        echo "Compose file not found."
    fi

    echo "Creating environment variable script in /etc/profile.d/..."
    cat <<'EOF' > /etc/profile.d/99-cedilla-fix.sh
#!/bin/sh
export GTK_IM_MODULE=cedilla
export QT_IM_MODULE=cedilla
EOF
    chmod +x /etc/profile.d/99-cedilla-fix.sh
    echo "Environment variable script created successfully."

    echo "${GREEN}${BOLD}Cedilla Fix for Xorg applied. Please reboot for changes to take effect.${RESET}"
}

uninstall_fix_cedilha() {
    echo "${YELLOW}${BOLD}Restoring Cedilla Fix for Xorg...${RESET}"
    total_files=${#files[@]}
    for i in "${!files[@]}"; do
        file="${files[$i]}"
        backup="${file}${backup_suffix}"
        if [ -f "$backup" ]; then
            cp "$backup" "$file"
            echo "File $file restored from backup."
        else
            echo "Backup for $file not found, not restored."
        fi
        show_progress $((i + 1)) $total_files
    done
    echo

    if [ -f "$compose_backup" ]; then
        cp "$compose_backup" "$compose_file"
        echo "Compose file restored from backup."
    else
        echo "Backup for Compose not found, not restored."
    fi

    echo "Removing environment variable script from /etc/profile.d/..."
    if [ -f "/etc/profile.d/99-cedilla-fix.sh" ]; then
        rm "/etc/profile.d/99-cedilla-fix.sh"
    fi
    echo "Environment variable script removed successfully."

    echo "${GREEN}${BOLD}Cedilla Fix for Xorg uninstalled. Please reboot for changes to take effect.${RESET}"
}

# --- Wayland/GTK4 fix ---
apply_alternative_fix() {
    echo "${YELLOW}${BOLD}Applying Cedilla Fix for Wayland/GTK4...${RESET}"

    if [ -f "$environment_file" ] && [ ! -f "$environment_backup" ]; then
        cp "$environment_file" "$environment_backup"
    fi

    if ! grep -q "GTK_IM_MODULE=cedilla" "$environment_file"; then
        echo "GTK_IM_MODULE=cedilla" >> "$environment_file"
    fi
    if ! grep -q "QT_IM_MODULE=cedilla" "$environment_file"; then
        echo "QT_IM_MODULE=cedilla" >> "$environment_file"
    fi
    echo "/etc/environment updated."

    if [ -f "$user_compose_file" ] && [ ! -f "$user_compose_backup" ]; then
        cp "$user_compose_file" "$user_compose_backup"
    fi

    cat > "$user_compose_file" <<EOF
# UTF-8 (Unicode) compose sequences

# Overrides C acute with Ccedilla:
<dead_acute> <C> : "Ç" "Ccedilla"
<dead_acute> <c> : "ç" "ccedilla"
EOF
    echo ".XCompose created/updated at $user_compose_file."

    # Use the original user for gsettings if available
    user=${SUDO_USER:-$USER}
    if command -v gsettings >/dev/null 2>&1; then
        sudo -u "$user" gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule': <'ibus'>}"
        echo "GTK4 configuration applied via gsettings."
    fi

    echo "${GREEN}${BOLD}Cedilla Fix for Wayland/GTK4 applied. Log out or reboot for changes to take effect.${RESET}"
}

restore_alternative_fix() {
    echo "${YELLOW}${BOLD}Restoring Cedilla Fix for Wayland/GTK4...${RESET}"

    if [ -f "$environment_backup" ]; then
        cp "$environment_backup" "$environment_file"
        echo "/etc/environment restored."
    fi

    if [ -f "$user_compose_backup" ]; then
        cp "$user_compose_backup" "$user_compose_file"
        echo ".XCompose restored."
    else
        rm -f "$user_compose_file"
        echo ".XCompose removed."
    fi

    user=${SUDO_USER:-$USER}
    if command -v gsettings >/dev/null 2>&1; then
        sudo -u "$user" gsettings reset org.gnome.settings-daemon.plugins.xsettings overrides
        echo "GTK4 configuration restored."
    fi

    echo "${GREEN}${BOLD}Cedilla Fix for Wayland/GTK4 uninstalled. Log out or reboot for changes to take effect.${RESET}"
}

# --- Menu ---
show_menu() {
    while true; do
        echo
        echo "${BLUE}${BOLD}Cedilla Fix for Xorg${RESET}"
        echo "  1 - Install"
        echo "  2 - Uninstall"
        echo "${BLUE}${BOLD}Cedilla Fix for Wayland/GTK4${RESET}"
        echo "  3 - Install"
        echo "  4 - Uninstall"
        echo "  5 - Exit"
        echo
        read -p "Choose an option: " opt
        case $opt in
            1) install_fix_cedilha ;;
            2) uninstall_fix_cedilha ;;
            3) apply_alternative_fix ;;
            4) restore_alternative_fix ;;
            5) echo "Exiting script."; break ;;
            *) echo "${RED}Invalid option${RESET}" ;;
        esac
    done
}

# ---
