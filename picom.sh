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

packages=("git" "libconfig-dev" "libdbus-1-dev" "libegl-dev" "libev-dev" "libgl-dev" "libepoxy-dev" "libpcre2-dev" "libpixman-1-dev" "libx11-xcb-dev" "libxcb1-dev" "libxcb-composite0-dev" "libxcb-damage0-dev" "libxcb-glx0-dev" "libxcb-image0-dev" "libxcb-present-dev" "libxcb-randr0-dev" "libxcb-render0-dev" "libxcb-render-util0-dev" "libxcb-shape0-dev" "libxcb-util-dev" "libxcb-xfixes0-dev" "meson" "ninja-build" "uthash-dev")

install_if_missing() {
    package=$1
    if ! dpkg -s "$package" &> /dev/null; then
        printf "${yellow}$package is not installed. Installing $package...${reset}\n"
        sudo apt install -y "$package"
    else
        printf "${green}$package is already installed.${reset}\n"
    fi
}

install_picom_git() {
    for package in "${packages[@]}"; do
        install_if_missing "$package"
    done

    printf "${red}Installing Picom-git...${reset}\n"
    cd /opt || { echo "Failed to change directory to /opt"; exit 1; }

    # If the repository already exists, pull the latest changes
    if [ -d "picom" ]; then
        if [ -d "picom/.git" ]; then
            cd picom || exit
            output=$(git pull origin next)
            if echo "$output" | grep -q 'Already up to date.'; then
                printf "${green}Picom-git is already up to date.'${reset}\n"
                exit 0
            fi
        else
            printf "${yellow}The 'picom' directory exists but is not a git repository. Moving it to /tmp to start fresh.${reset}\n"
            sudo mv "picom" /tmp/
            sudo rm -rf picom
            git clone https://github.com/yshui/picom
            sudo chown -R "$SUDO_USER":"$SUDO_USER" /opt/picom
            cd picom || exit
        fi
    else
        git clone https://github.com/yshui/picom
        sudo chown -R "$SUDO_USER":"$SUDO_USER" /opt/picom
        cd picom || exit
    fi

    meson setup --buildtype=release build
    ninja -C build
    sudo ninja -C build install

    echo ''
    if picom --version &> /dev/null; then
        printf "${green}Picom-git installation complete.${reset}\n"
    else
        printf "${red}Picom-git installation failed.${reset}\n"
    fi
}

install_picom() {
    printf "${red}Installing picom(apt)...${reset}\n"
    sudo apt update
    sudo apt install -y picom

    echo ''
    if dpkg -s picom &> /dev/null; then
        printf "${green}Picom(apt) installation complete.${reset}\n"
    else
        printf "${red}Picom(apt) installation failed.${reset}\n"
    fi
}

remove_picom() {
    if dpkg -s picom &> /dev/null; then
        printf "${red}Removing Picom installed via apt...${reset}\n"
	    pkill picom
        sudo apt purge -y picom

        echo ''
        if dpkg -s picom &> /dev/null; then
            printf "${red}Removing Picom(apt) failed.${reset}\n"
        else
            printf "${green}Picom(apt) removed successfully.${reset}\n"
        fi
    else
        printf "${yellow}Picom is not installed via apt${reset}\n"
        echo ''
        printf "${red}Removing Picom-git...${reset}\n"

        cd /opt || { echo "Failed to change directory to /opt"; exit 1; }

        if [ -d "picom" ]; then
            #pkill picom
	    cd picom || exit
            sudo ninja -C build uninstall
        else
            printf "${red}No previous installation of Picom-git found. Please install it first.${reset}\n"
        fi

        echo ''
        if picom --version &> /dev/null; then
            printf "${red}Removing Picom-git failed.${reset}\n"
        else
            printf "${green}Picom-git removed successfully.${reset}\n"
        fi
    fi
}

prompt_user() {
    while true; do
        echo "1) Install/Update Picom-git"
        echo "2) Install/Update Picom(apt)"
        echo "3) Remove Picom-git or Picom(apt)"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_picom_git
                break
                ;;
            2 )
                install_picom
                break
                ;;
            3 )
                remove_picom
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
