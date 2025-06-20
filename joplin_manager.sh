#!/bin/bash

# Função para instalar dependências necessárias
install_dependencies() {
    echo "🔧 Verificando/Instalando dependências..."
    sudo apt update
    sudo apt install -y libfuse2 wget
    echo "✔ Dependências instaladas."
}

# Função para instalar o Joplin
install_joplin() {
    install_dependencies  # Garante que as dependências estão instaladas
    echo "✅ Instalando/Atualizando Joplin..."
    wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
    echo "✔ Concluído! Execute 'joplin' para iniciar."
}

# Função para remover o Joplin
remove_joplin() {
    echo "🗑️ Removendo Joplin..."
    rm -rf ~/.joplin-bin 2>/dev/null
    rm -rf ~/.config/joplin 2>/dev/null
    sudo rm -f /usr/share/applications/joplin.desktop 2>/dev/null
    sudo rm -f /usr/bin/joplin 2>/dev/null
    echo "✔ Joplin removido. Observação: ~/.config/joplin foi apagado (faça backup se necessário)."
}

# Menu principal
case "$1" in
    install)
        install_joplin
        ;;
    remove)
        remove_joplin
        ;;
    *)
        echo "📌 Uso: $0 [install|remove]"
        echo "Exemplos:"
        echo "  $0 install   # Instala/atualiza o Joplin (resolve dependências automaticamente)"
        echo "  $0 remove    # Remove o Joplin completamente"
        exit 1
        ;;
esac