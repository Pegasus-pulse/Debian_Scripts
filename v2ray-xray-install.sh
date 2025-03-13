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

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    printf "${red}wget is not installed. Installing wget...${reset}\n"
    sudo apt update
    sudo apt install -y wget
fi

install_v2ray() {
    printf "${red}Installing Xray-Core...${reset}\n"
    if ! command -v xray --version &> /dev/null; then
	sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    else
        printf "${yellow}Xray-Core is already installed.${reset}\n"
    fi

    # Disable and stop xray service if it's running
    if systemctl is-active --quiet xray.service; then
        sudo systemctl disable xray.service
        sudo systemctl stop xray.service
    else
        printf "${yellow}Xray-Core service is not running,no need to stop.${reset}\n"
    fi

    if ! command -v v2raya --version&> /dev/null; then
        printf "${red}Installing v2rayA Web app...${reset}\n"

        wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc
        echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
        sudo apt update
        sudo apt install -y v2raya

        sudo systemctl start v2raya.service

        #Uncomment below line if you want to start v2rayA everytime you boot up the system
        #sudo systemctl enable v2raya.service

        # Check if v2raya service started successfully
        if systemctl is-active --quiet v2raya.service; then
            printf "${green}V2rayA service started successfully.${reset}\n"
        else
            printf "${red}Failed to start V2rayA service.${reset}\n"
        fi

        printf "${green}Launch V2rayA web GUI using the desktop shortcut${reset}\n"
    else
        printf "${yellow}V2rayA Web app is already installed.${reset}\n"
        printf "${green}Launch it using the desktop shortcut.${reset}\n"
    fi
}

update_xray_core() {
    printf "${red}Updating Xray-Core...${reset}\n"
    if ! command -v xray --version &> /dev/null; then
        printf "${yellow}Xray-Core is not installed.${reset}\n"
    else
        sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    fi
}

prompt_user() {
    clear
    while true; do
        echo "1) Install V2rayA(xray-core)"
        echo "2) Update Xray-core"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_v2ray
                break
                ;;
            2 )
                update_xray_core
                break
                ;;
            * )
                clear
                echo -e "${yellow}Invalid option. Please select a valid number.${reset}"
                ;;
        esac
    done
}

prompt_user
