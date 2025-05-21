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
fi

# Function to display a progress bar
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

# Paths of the files to be modified
files=(
    "/usr/lib/x86_64-linux-gnu/gtk-3.0/3.0.0/immodules.cache"
    "/usr/lib/x86_64-linux-gnu/gtk-2.0/2.10.0/immodules.cache"
)
backup_suffix=".fix_cedilha.bak"

# Check if the system is 32-bit and adjust paths if necessary
if [ "$(uname -m)" != "x86_64" ]; then
    files=(
        "/usr/lib/i386-linux-gnu/gtk-3.0/3.0.0/immodules.cache"
        "/usr/lib/i386-linux-gnu/gtk-2.0/2.10.0/immodules.cache"
    )
fi

# Path to the Compose file
compose_file="/usr/share/X11/locale/en_US.UTF-8/Compose"
compose_backup="${compose_file}${backup_suffix}"

# Function to install the fix
install_fix_cedilha() {
    echo "${YELLOW}${BOLD}Applying cedilla fix...${RESET}"
    total_files=${#files[@]}
    for i in "${!files[@]}"; do
        file="${files[$i]}"
        backup="${file}${backup_suffix}"
        if [ -f "$file" ]; then
            # Backup if it doesn't exist yet
            if [ ! -f "$backup" ]; then
                sudo cp "$file" "$backup"
            fi
            sudo sed -i 's/"cedilla" "Cedilla" "gtk20" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa"/"cedilla" "Cedilla" "gtk20" "\/usr\/share\/locale" "az:ca:co:fr:gv:oc:pt:sq:tr:wa:en"/' "$file"
            echo "File $file successfully modified."
        else
            echo "File $file not found."
        fi
        show_progress $((i + 1)) $total_files
    done
    echo

    # Backup and modify the Compose file
    echo "Backing up and modifying the Compose file..."
    if [ -f "$compose_file" ]; then
        if [ ! -f "$compose_backup" ]; then
            sudo cp "$compose_file" "$compose_backup"
        fi
        tmp_compose=$(mktemp)
        sed 's/ć/ç/g' < "$compose_file" | sed 's/Ć/Ç/g' > "$tmp_compose"
        sudo mv "$tmp_compose" "$compose_file"
        echo "Compose file successfully modified."
    else
        echo "Compose file not found."
    fi

    # Add environment variables to /etc/environment if not already present
    echo "Adding environment variables to /etc/environment..."
    for var in GTK_IM_MODULE QT_IM_MODULE; do
        if ! grep -q "^${var}=cedilla" /etc/environment; then
            sudo bash -c "echo \"${var}=cedilla\" >> /etc/environment"
        fi
    done
    echo "Environment variables added successfully."

    echo "${GREEN}${BOLD}Cedilla fix applied. Please reboot your computer for the changes to take effect.${RESET}"
}

# Function to uninstall the fix
uninstall_fix_cedilha() {
    echo "${YELLOW}${BOLD}Restoring cedilla backups...${RESET}"
    total_files=${#files[@]}
    for i in "${!files[@]}"; do
        file="${files[$i]}"
        backup="${file}${backup_suffix}"
        if [ -f "$backup" ]; then
            sudo cp "$backup" "$file"
            echo "File $file restored from backup."
        else
            echo "Backup for $file not found, not restored."
        fi
        show_progress $((i + 1)) $total_files
    done
    echo

    # Restore Compose
    if [ -f "$compose_backup" ]; then
        sudo cp "$compose_backup" "$compose_file"
        echo "Compose file restored from backup."
    else
        echo "Backup for Compose file not found, not restored."
    fi

    # Remove environment variables
    echo "Removing environment variables from /etc/environment..."
    sudo sed -i '/^GTK_IM_MODULE=cedilla/d' /etc/environment
    sudo sed -i '/^QT_IM_MODULE=cedilla/d' /etc/environment
    echo "Environment variables removed successfully."

    echo "${GREEN}${BOLD}Cedilla fix uninstalled. Please reboot your computer for the changes to take effect.${RESET}"
}

# Main logic for install_linux.sh: always apply the fix (no menu)
install_fix_cedilha
