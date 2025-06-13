#!/bin/bash

# Função para modificar um aplicativo
modify_app() {
    local APP_NAME="$1"

    echo ""
    echo "🔍 Procurando por '$APP_NAME'..."

    # Locais onde arquivos .desktop podem estar (incluindo Flatpak)
    DESKTOP_LOCATIONS=(
        "/usr/share/applications/"
        "$HOME/.local/share/applications/"
        "/var/lib/flatpak/exports/share/applications/"
        "$HOME/.local/share/flatpak/exports/share/applications/"
    )

    # Encontra arquivos .desktop do app
    DESKTOP_FILES=$(find "${DESKTOP_LOCATIONS[@]}" -iname "*$APP_NAME*.desktop" 2>/dev/null)

    if [ -z "$DESKTOP_FILES" ]; then
        echo "⚠️  Nenhum arquivo .desktop encontrado para '$APP_NAME'."
        echo "    Se for um Flatpak, tente buscar o ID exato com: flatpak list | grep -i '$APP_NAME'"
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
                sudo sed -i "s/Name=.*/Name=$NEW_NAME/" "$file"
                echo "✅ Nome alterado em: $file"
            done
        fi
    fi

    # Pergunta se deseja modificar o ícone
    read -p "🖼️  Quer alterar o ícone? (Digite o caminho completo ou Enter para pular): " ICON_PATH
    if [ -n "$ICON_PATH" ]; then
        if [ -f "$ICON_PATH" ]; then
            read -p "🎨 O ícone será alterado para '$ICON_PATH'. Confirmar? (s/N): " CONFIRM
            if [[ "$CONFIRM" =~ [sS] ]]; then
                for file in $DESKTOP_FILES; do
                    sudo sed -i "s|Icon=.*|Icon=$ICON_PATH|" "$file"
                    echo "✅ Ícone alterado em: $file"
                done
            fi
        else
            echo "⚠️  Arquivo de ícone não encontrado: $ICON_PATH"
        fi
    fi

    # Atualiza o banco de dados
    sudo update-desktop-database
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
echo "🎉 Concluído! Reinicie o sistema para ver as alterações."