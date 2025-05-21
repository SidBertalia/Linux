# Linux Installation, Maintenance, and Drivers Repository

This repository was created to store and manage everything related to installation, maintenance, drivers, and other useful configurations for Linux systems, making it easier to use on different machines and scenarios.

## Available Scripts

- **install_linux.sh**
  Main script to automate the installation and configuration of drivers, applications, and essential tools on Linux.

- **install_chrome.sh**
  Installs Google Chrome.

- **install_docker.sh**
  Installs Docker and Docker Compose, adds the user to the docker group, and sets up useful aliases.

- **install_drivers.sh**
  Detects hardware (such as iMac or MacBook Pro) and offers to install specific drivers (audio, Wi-Fi, etc.).

- **install_flatpack_apps.sh**
  Installs Flatpak, adds the Flathub repository, and offers to install several useful Flatpak applications.

- **install_fonts.sh**
  Downloads and installs popular programming fonts (Cascadia Code, Fira Code, JetBrains Mono, Monaspace, Operator Mono).

- **install_git.sh**
  Installs and configures Git, generates an SSH key, and guides you to add it to GitHub.

- **install_java.sh**
  Installs Java and sets up the JAVA_HOME environment variable.

- **install_vscode.sh**
  Installs Visual Studio Code, Zsh, and Oh My Zsh, and optionally sets Zsh as the default shell.

- **fix-imac-audio-ubuntu.sh**
  Installs the `snd-hda-codec-cs8409` audio driver on Ubuntu/Debian systems, useful for fixing audio issues on iMacs.

- **fix_cedilha.sh**
  Applies a fix for the cedilla (ç) key issue on some keyboard layouts.

## How to Use

1. Clone this repository:

   ```sh
   git clone https://github.com/your-username/your-repository.git
   cd your-repository
   ```

2. Make the main script executable and run it:

   ```sh
   chmod +x install_linux.sh
   ./install_linux.sh
   ```

> **Note:**
> Do not run the script as root. It will request sudo permissions when needed.

## Contributing

Feel free to contribute with improvements, new scripts, or fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
