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

install_if_missing() {
    package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        printf "${yellow}$package is not installed. Installing $package...${reset}\n"
        sudo apt install -y "$package"
    else
        printf "${green}$package is already installed.${reset}\n"
    fi
}

check_i3lock-color_installation() {
    while true; do
        read -p "i3lock-color is a dependencie for Betterlockscreen. Is i3lock-color installed? (Y/N): " answer
        case $answer in
            [Yy]* )
                printf "${green}Proceeding with the installation${reset}\n"
                break
                ;;
            [Nn]* )
                printf "${red}Proceeding with the i3lock-color installation${reset}\n"
                install_i3lock_color
                break
                ;;
            * )
                echo "Wrong answer. Please enter Y or N."
                ;;
        esac
    done
}

# Retrieve the home directory of the sudo user
user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

if [ -z "$user_home" ]; then
    echo -e "${red}Failed to determine the home directory for user $SUDO_USER${reset}"
    exit 1
fi

# i3lock-color installation------
install_i3lock_color() {
    printf "${red}Installing i3lock-color...${reset}\n"

    packages=("git" "autoconf" "gcc" "make" "pkg-config" "libpam0g-dev" "libcairo2-dev" "libfontconfig1-dev" "libxcb-composite0-dev" "libev-dev" "libx11-xcb-dev" "libxcb-xkb-dev" "libxcb-xinerama0-dev" "libxcb-randr0-dev" "libxcb-image0-dev" "libxcb-util0-dev" "libxcb-xrm-dev" "libxkbcommon-dev" "libxkbcommon-x11-dev" "libjpeg-dev")

    for package in "${packages[@]}"; do
        install_if_missing "$package"
    done

    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    git clone https://github.com/Raymo111/i3lock-color.git
    cd i3lock-color || exit
    chmod +x build.sh
    chmod +x install-i3lock-color.sh
    ./install-i3lock-color.sh
    cd ..
    sudo rm -rf i3lock-color
}

cd "$user_home"

packages=("imagemagick" "bc")
#Betterlockscreen dependencies

for package in "${packages[@]}"; do
    install_if_missing "$package"
done

# Uncomment for optional packages
#sudo apt install -y dunst feh

install_systemwide() {
    clear
    printf "${red}Installing Betterlockscreen(systemwide)...${reset}\n"
    wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | sudo bash -s system

    echo ''
    if betterlockscreen --version &> /dev/null; then
        printf "${green}Betterlockscreen installation complete.${reset}\n"
    else
        printf "${red}Betterlockscreen installation failed.${reset}\n"
    fi
}

install_currentuser() {
    clear
    printf "${red}Installing Betterlockscreen(current user)...${reset}\n"
    wget https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh -O - -q | bash -s user

    echo ''
    if betterlockscreen --version &> /dev/null; then
        printf "${green}Betterlockscreen installation complete.${reset}\n"
    else
        printf "${red}Betterlockscreen installation failed.${reset}\n"
    fi
}

prompt_user() {
    while true; do
        echo "1) Install Betterlockscreen Systemwide"
        echo "2) Install Betterlockscreen for the Current-user"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_systemwide
                break
                ;;
            2 )
                install_currentuser
                break
                ;;
            * )
                clear
                echo "Invalid option. Please select a valid number."
                ;;
        esac
    done
}

check_i3lock-color_installation
prompt_user
