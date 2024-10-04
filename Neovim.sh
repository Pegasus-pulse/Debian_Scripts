#!/usr/bin/env bash

set -e # Exit on any error

# Check if the terminal supports colors
supports_colors() {
    [ -t 1 ] && [ "$(tput colors)" -ge 8 ]
}

# Set color codes if supported
set_colors() {
    if supports_colors; then
        red='\e[1;31m'
        green='\e[1;32m'
        yellow='\e[1;33m'
        reset='\e[0m'
    else
        red=''
        green=''
        yellow=''
        reset=''
    fi
}

# Initialize color codes
set_colors

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${red}This script requires sudo. Please run it with 'sudo ./script.sh'${reset}"
    exit 1
fi

packages=("git" "ninja-build" "gettext" "cmake" "unzip" "curl" "build-essential")

install_if_missing() {
    package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        printf "${yellow}$package is not installed. Installing $package...${reset}\n"
        sudo apt install -y "$package"
    else
        printf "${green}$package is already installed.${reset}\n"
    fi
}

install_neovim() {
    for package in "${packages[@]}"; do
        install_if_missing "$package"
    done

    printf "${red}Installing Neovim...${reset}\n"
    local user_home
    user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    git clone https://github.com/neovim/neovim # Neovim gitrepo is close to 300 MB
    cd neovim || exit
    git checkout stable # To install the stable release
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    cd build || exit
    cpack -G DEB
    sudo dpkg -i nvim-linux64.deb
    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    sudo rm -rf neovim

    echo ''
    if dpkg -s picom &> /dev/null; then
        printf "${green}Neovim installation complete.${reset}\n"
    else
        printf "${red}Neovim installation failed.${reset}\n"
    fi
}

remove_neovim() {
    printf "${red}Removing Neovim...${reset}\n"
    sudo apt purge -y neovim

    echo ''
    if dpkg -s neovim &> /dev/null; then
        printf "${red}Removing Neovim failed.${reset}\n"
    else
        printf "${green}Neovim removed successfully.${reset}\n"
    fi
}

prompt_user() {
    while true; do
        echo "1) Install Neovim"
        echo "2) Remove Neovim"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_neovim
                break
                ;;
            2 )
                remove_neovim
                break
                ;;
            * )
                clear
                echo "Invalid option. Please select a valid number."
                ;;
        esac
    done
}

prompt_user
