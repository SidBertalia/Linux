#!/bin/bash

# Função para modificar um aplicativo
modify_app() {
    local APP_NAME="$1"

    echo ""
    echo "🔍 Procurando por '$APP_NAME'..."

    # Verifica se é Flatpak
    FLATPAK_ID=$(flatpak list --columns=application | grep -i "$APP_NAME" | head -n1)
    
    if [ -n "$FLATPAK_ID" ]; then
        echo "📦 Aplicativo Flatpak encontrado: $FLATPAK_ID"
        DESKTOP_FILE="/var/lib/flatpak/exports/share/applications/${FLATPAK_ID}.desktop"
        
        if [ ! -f "$DESKTOP_FILE" ]; then
            DESKTOP_FILE="$HOME/.local/share/flatpak/exports/share/applications/${FLATPAK_ID}.desktop"
        fi
        
        DESKTOP_FILES="$DESKTOP_FILE"
    else
        # Locais onde arquivos .desktop podem estar
        DESKTOP_LOCATIONS=(
            "/usr/share/applications/"
            "$HOME/.local/share/applications/"
        )
        DESKTOP_FILES=$(find "${DESKTOP_LOCATIONS[@]}" -iname "*$APP_NAME*.desktop" 2>/dev/null)
    fi

    if [ -z "$DESKTOP_FILES" ]; then
        echo "⚠️  Nenhum arquivo .desktop encontrado para '$APP_NAME'."
        return
    fi

    echo "📂 Arquivos encontrados:"
    echo "$DESKTOP_FILES"

    # Pergunta se deseja modificar o nome
    read -p "🖊️  Quer alterar o nome? (Digite o novo nome ou Enter para pular): " NEW_NAME
    if [ -n "$NEW_NAME" ]; then
        read -p "🔤 O nome será alterado para '$NEW_NAME'. Confirmar? (s/N): " CONFIRM
        if [[ "$CONFIRM" =~ [sS] ]]; then
            for file in $DESKTOP_FILES; do
                if [[ "$file" == *flatpak* ]]; then
                    echo "📦 Usando flatpak override para alterar nome..."
                    flatpak override --user --env=NAME="$NEW_NAME" "$FLATPAK_ID"
                    # Cria um arquivo .desktop local para sobrescrever
                    LOCAL_DESKTOP="$HOME/.local/share/applications/${FLATPAK_ID}.desktop"
                    cp "$file" "$LOCAL_DESKTOP"
                    sed -i "s/Name=.*/Name=$NEW_NAME/" "$LOCAL_DESKTOP"
                else
                    if [[ "$file" == /usr/* ]]; then
                        sudo sed -i "s/Name=.*/Name=$NEW_NAME/" "$file"
                    else
                        sed -i "s/Name=.*/Name=$NEW_NAME/" "$file"
                    fi
                fi
                echo "✅ Nome alterado em: $file"
            done
        fi
    fi

    # Pergunta se deseja modificar o ícone
    read -p "🖼️  Quer alterar o ícone? (Digite o caminho completo ou Enter para pular): " ICON_PATH
    ICON_PATH=${ICON_PATH//\'/}  # Remove aspas simples se presentes
    if [ -n "$ICON_PATH" ]; then
        if [ ! -f "$ICON_PATH" ]; then
            echo "⚠️  Arquivo de ícone não encontrado: $ICON_PATH"
            echo "🔍 Procurando ícones em locais comuns..."
            
            # Tenta encontrar automaticamente
            POSSIBLE_ICONS=(
                "/usr/share/icons/"
                "$HOME/.local/share/icons/"
                "/opt/$APP_NAME/"
                "$HOME/.local/share/applications/"
            )
            
            FOUND_ICON=$(find "${POSSIBLE_ICONS[@]}" -iname "*${APP_NAME}*.png" -o -iname "*${APP_NAME}*.svg" 2>/dev/null | head -n1)
            
            if [ -n "$FOUND_ICON" ]; then
                read -p "🔍 Ícone encontrado: $FOUND_ICON. Usar este? (s/N): " USE_FOUND
                if [[ "$USE_FOUND" =~ [sS] ]]; then
                    ICON_PATH="$FOUND_ICON"
                fi
            else
                echo "Dica: Coloque o ícone em um desses locais antes de continuar:"
                echo "  - /usr/share/icons/hicolor/512x512/apps/"
                echo "  - ~/.local/share/icons/hicolor/512x512/apps/"
                return
            fi
        fi

        if [ -f "$ICON_PATH" ]; then
            read -p "🎨 O ícone será alterado para '$ICON_PATH'. Confirmar? (s/N): " CONFIRM
            if [[ "$CONFIRM" =~ [sS] ]]; then
                for file in $DESKTOP_FILES; do
                    if [[ "$file" == *flatpak* ]]; then
                        echo "📦 Configurando ícone para Flatpak..."
                        flatpak override --user --filesystem=xdg-data/icons:ro "$FLATPAK_ID"
                        flatpak override --user --env=ICON="$ICON_PATH" "$FLATPAK_ID"
                        
                        # Cria arquivo .desktop local
                        LOCAL_DESKTOP="$HOME/.local/share/applications/${FLATPAK_ID}.desktop"
                        cp "$file" "$LOCAL_DESKTOP"
                        sed -i "s|Icon=.*|Icon=$ICON_PATH|" "$LOCAL_DESKTOP"
                    else
                        if [[ "$file" == /usr/* ]]; then
                            sudo sed -i "s|Icon=.*|Icon=$ICON_PATH|" "$file"
                        else
                            sed -i "s|Icon=.*|Icon=$ICON_PATH|" "$file"
                        fi
                    fi
                    echo "✅ Ícone alterado em: $file"
                done
                
                # Atualiza cache de ícones
                echo "🔄 Atualizando cache de ícones..."
                sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null
                gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null
            fi
        fi
    fi

    # Atualiza o banco de dados
    echo "🔄 Atualizando banco de dados desktop..."
    sudo update-desktop-database
    update-desktop-database ~/.local/share/applications
    
    echo "✨ Modificações concluídas para '$APP_NAME'!"
}

# --- Menu principal ---
echo "🔄 RENOMEADOR DE APLICATIVOS (Nome/Ícone) 🔄"
echo "────────────────────────────────────────────"

# Pergunta qual app modificar
read -p "🔍 Qual aplicativo deseja modificar? (Ex: zapzap): " APP_NAME

# Chama a função de modificação
modify_app "$APP_NAME"

echo ""
echo "🎉 Concluído! Reinicie o sistema ou a sessão para ver as alterações."
