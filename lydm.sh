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

check_zig_installation() {
    while true; do
        read -p "Zig needs to be installed to build Ly. Is Zig installed? (Y/N): " answer
        case $answer in
            [Yy]* )
                printf "${green}Proceeding with the installation${reset}\n"
                echo ''
                break
                ;;
            [Nn]* )
                echo ''
                printf "${red}Please install Zig before proceeding${reset}\n"
                exit 1
                ;;
            * )
                echo "Wrong answer. Please enter Y or N."
                ;;
        esac
    done
}

packages=("git" "build-essential" "libpam0g-dev" "libxcb-xkb-dev")

install_if_missing() {
    package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        printf "${yellow}$package is not installed. Installing $package...${reset}\n"
        sudo apt install -y "$package"
    else
        printf "${green}$package is already installed.${reset}\n"
    fi
}

for package in "${packages[@]}"; do
    install_if_missing "$package"
done


install_ly() {
    printf "${red}Installing Ly Display Manager...${reset}\n"
    local user_home
    user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    git clone https://github.com/fairyglade/ly
    cd ly || exit
    zig build
    sudo zig build installsystemd
    sudo systemctl enable ly.service
    sudo systemctl disable getty@tty2.service
    cd ..
    sudo rm -rf ly

    if ly --version &> /dev/null; then
        printf "${green}Ly Display Manager installed and enabled.${reset}\n"
    else
        printf "${red}Ly Display Manager installation failed.${reset}\n"
    fi
}

update_ly() {
    printf "${red}Updating Ly Display Manager...${reset}\n"
    local user_home
    user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    git clone https://github.com/fairyglade/ly
    cd ly || exit
    sudo zig build installnoconf
    cd ..
    rm -rf ly

    if ly --version &> /dev/null; then
        printf "${green}Ly Display Manager updated successfully.${reset}\n"
    else
        printf "${red}Ly Display Manager update failed.${reset}\n"
    fi
}

remove_ly () {
    printf "${red}Removing Ly Display Manager...${reset}\n"
    sudo rm /usr/bin/ly
    sudo rm /etc/pam.d/ly
    sudo rm -r /etc/ly
    sudo rm /lib/systemd/system/ly.service
    #sudo rm /usr/lib/systemd/system/ly.service

    if [ $? -ne 0 ]; then
        printf "${red}Failed to remove Ly Display Manager files.${reset}\n"
        return 1
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable getty@tty2.service

    if ly --version &> /dev/null; then
        printf "${red}Removing Ly Display Manager failed${reset}\n"
    else
         printf "${green}Ly Display Manager removed successfully.${reset}\n"
    fi
}

prompt_user() {
    while true; do
        echo "1) Install Ly"
        echo "2) Update Ly"
        echo "3) Remove Ly"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_ly
                break
                ;;
            2 )
                update_ly
                break
                ;;
            3 )
                remove_ly
                break
                ;;
            * )
                clear
                echo "Invalid option. Please select a valid number."
                ;;
        esac
    done
}

check_zig_installation
prompt_user
