#!/bin/bash

# Script de instalação do driver snd-hda-codec-cs8409 para Ubuntu
# Autor: [Seu Nome]
# Versão: 1.2

# Função para verificar comandos essenciais
check_commands() {
    for cmd in git make gcc; do
        if ! command -v $cmd &>/dev/null; then
            echo "Erro: O comando '$cmd' não está disponível. Tente instalar as dependências manualmente."
            exit 1
        fi
    done
}

# Função para checar permissão de sudo
check_sudo() {
    if ! sudo -v &>/dev/null; then
        echo "Erro: Você não tem permissão para usar sudo."
        exit 1
    fi
}

# Função para checar conexão com a internet
check_internet() {
    if ! ping -c 1 github.com &>/dev/null; then
        echo "Erro: Sem conexão com a internet. Verifique sua rede."
        exit 1
    fi
}

# Função para verificar e instalar dependências
install_dependencies() {
    echo "Instalando dependências necessárias..."
    sudo apt update
    sudo apt install -y linux-headers-generic build-essential git gcc-12
    if [ $? -eq 0 ]; then
        echo "Dependências instaladas com sucesso!"
    else
        echo "Erro ao instalar dependências. Verifique sua conexão com a internet."
        exit 1
    fi
}

# Função para baixar o driver
download_driver() {
    echo "Baixando o driver snd-hda-codec-cs8409..."
    if [ -d "snd-hda-codec-cs8409" ]; then
        echo "Diretório snd-hda-codec-cs8409 já existe. Removendo..."
        rm -rf snd-hda-codec-cs8409
    fi
    git clone https://github.com/egorenar/snd-hda-codec-cs8409
    if [ -d "snd-hda-codec-cs8409" ]; then
        echo "Driver baixado com sucesso!"
    else
        echo "Erro ao baixar o driver. Verifique a URL ou sua conexão com a internet."
        exit 1
    fi
}

compile_install() {
    echo "Compilando e instalando o driver..."
    cd snd-hda-codec-cs8409 || { echo "Erro ao acessar o diretório do driver."; exit 1; }
    make
    if [ $? -eq 0 ]; then
        sudo make install
        if [ $? -eq 0 ]; then
            echo "Driver instalado com sucesso!"
        else
            echo "Erro durante a instalação."
            exit 1
        fi
    else
        echo "Erro durante a compilação. Verifique as dependências."
        exit 1
    fi
    cd ..
    # rm -rf snd-hda-codec-cs8409 # Descomente se quiser remover após instalar
}

# Função principal
main() {
    echo "Iniciando instalação do driver de áudio snd-hda-codec-cs8409..."

    # Verificar se é Ubuntu/Debian
    if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
        echo "Aviso: Este script foi projetado para Ubuntu/Debian. Continue por sua conta e risco."
    fi

    # Verificar se é root
    if [ "$EUID" -eq 0 ]; then
        echo "Erro: Não execute este script como root. Execute como usuário normal."
        exit 1
    fi

    check_sudo
    check_commands
    check_internet
    install_dependencies
    download_driver
    compile_install

    echo ""
    echo "Instalação concluída com sucesso!"
    echo "Reinicie seu computador para aplicar as alterações:"
    echo "sudo reboot"
    echo ""
    echo "Após reiniciar, o som deve funcionar normalmente."
    echo "Se precisar remover o driver, acesse o diretório do driver e execute:"
    echo "sudo make uninstall"
}

# Executar função principal
main
