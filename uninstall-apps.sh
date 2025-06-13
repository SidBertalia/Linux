#!/bin/bash

# Função para remover um aplicativo específico
remove_app() {
    local APP_NAME="$1"
    echo ""
    echo "🔍 Procurando e removendo '$APP_NAME'..."

    # --- 1. Remoção via APT ---
    if apt list --installed 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "📦 Encontrado via APT. Remover?"
        select yn in "Sim" "Não"; do
            case $yn in
                Sim )
                    sudo apt purge "$APP_NAME" -y
                    sudo apt autoremove -y
                    break;;
                Não ) break;;
            esac
        done
    fi

    # --- 2. Remoção via Snap ---
    if snap list 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "🦊 Encontrado via Snap. Remover?"
        select yn in "Sim" "Não"; do
            case $yn in
                Sim )
                    sudo snap remove --purge "$APP_NAME"
                    break;;
                Não ) break;;
            esac
        done
    fi

    # --- 3. Remoção via Flatpak ---
    if flatpak list 2>/dev/null | grep -qi "$APP_NAME"; then
        echo "📦 Encontrado via Flatpak. Remover?"
        select yn in "Sim" "Não"; do
            case $yn in
                Sim )
                    flatpak uninstall --delete-data "$APP_NAME" -y
                    break;;
                Não ) break;;
            esac
        done
    fi

    # --- 4. Limpeza de arquivos residuais ---
    echo "🧹 Buscar arquivos residuais de '$APP_NAME'? (Ícones, configurações, etc.)"
    select yn in "Sim" "Não"; do
        case $yn in
            Sim )
                echo "Limpando..."
                sudo find /usr/share/applications/ ~/.local/share/applications/ -iname "*$APP_NAME*.desktop" -delete
                sudo find /usr/share/icons/ ~/.local/share/icons/ -iname "*$APP_NAME*" -delete
                sudo find ~/.config/ ~/.cache/ -iname "*$APP_NAME*" -exec rm -rf {} +
                sudo find /opt/ ~/.local/bin/ -iname "*$APP_NAME*" -exec rm -rf {} +
                sudo update-desktop-database
                sudo update-mime-database /usr/share/mime
                break;;
            Não ) break;;
        esac
    done

    echo "✅ Concluído para '$APP_NAME'!"
    echo "─────────────────────────────────────"
}

# --- Menu principal ---
echo "🛠️  DESINSTALADOR DE APPS (APT/Snap/Flatpak) 🛠️"
echo "─────────────────────────────────────"

# Pergunta quantos apps serão removidos
read -p "Quantos aplicativos deseja remover? " NUM_APPS

# Loop para cada app
for (( i=1; i<=$NUM_APPS; i++ )); do
    read -p "Digite o nome do aplicativo #$i: " APP_NAME
    remove_app "$APP_NAME"
done

echo ""
echo "🎉 Todos os aplicativos foram processados!"
echo "Dica: Reinicie o sistema para garantir que todas as alterações tenham efeito."