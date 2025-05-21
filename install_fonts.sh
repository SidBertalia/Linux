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

################################################################
# FONTS INSTALLATION
################################################################

FONTS_DIR="$HOME/Downloads/FONTS"
FONT_DEST="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR" "$FONT_DEST"

declare -A FONT_URLS=(
    ["CascadiaCode"]="https://github.com/microsoft/cascadia-code/releases/download/v2404.23/CascadiaCode-2404.23.zip"
    ["OperatorMono"]="https://github.com/beichensky/Font/raw/master/Operator%20Mono/OperatorMono.zip"
    ["FiraCode"]="https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"
    ["JetBrainsMono"]="https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
    ["Monaspace"]="https://github.com/githubnext/monaspace/releases/download/v1.200/Monaspace-v1.200.zip"
)

echo "${YELLOW}${BOLD}Installing fonts...${RESET}"

for font in "${!FONT_URLS[@]}"; do
    url="${FONT_URLS[$font]}"
    zip_file="$FONTS_DIR/${font}.zip"
    echo "${YELLOW}Downloading $font...${RESET}"
    wget -q --show-progress -O "$zip_file" "$url"
    unzip -oq "$zip_file" -d "$FONTS_DIR/$font"
    find "$FONTS_DIR/$font" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp -v {} "$FONT_DEST/" \;
done

fc-cache -fv

echo "${GREEN}${BOLD}Fonts installed successfully!${RESET}"

rm -rf "$FONTS_DIR"
echo "${GREEN}Downloaded files removed from $FONTS_DIR.${RESET}"
