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

# Retrieve the home directory of the sudo user
user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

if [ -z "$user_home" ]; then
    echo -e "${red}Failed to determine the home directory for user $SUDO_USER${reset}"
    exit 1
fi

install_discord() {
    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }

    if ! dpkg -s unzip >/dev/null 2>&1; then
        printf "${yellow}unzip is not installed. Installing...${reset}"
        sudo apt install -y unzip
    fi

    wget "https://discord.com/api/download?platform=linux&format=tar.gz" -O discord.tar.gz
    sudo tar -xvf discord.tar.gz -C /opt/;rm discord.tar.gz

    # Create symbolic link
    sudo ln -sf /opt/Discord/Discord /usr/bin/Discord

    # Desktop file
    cat > ./temp << "EOF"
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice messenger
GenericName=Internet Messenger
Exec=/usr/bin/Discord
Icon=/opt/Discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
Path=/usr/bin
EOF

    sudo cp ./temp /usr/share/applications/discord.desktop && rm ./temp || { echo "Failed to create desktop entry"; return 1; }

    echo ''
    if [ -d "/opt/Discord" ]; then
        printf "${green}Discord successfully installed.${reset}\n"
    else
        printf "${red}Discord installation failed.${reset}\n"
    fi
}

update_discord() {
    cd "$user_home/Downloads" || { echo "Failed to change directory to $user_home/Downloads"; exit 1; }
    wget "https://discord.com/api/download?platform=linux&format=tar.gz" -O discord.tar.gz
    sudo rm -rf /opt/Discord
    sudo tar -xvf discord.tar.gz -C /opt/;rm discord.tar.gz

    echo ''
    if [ -d "/opt/Discord" ]; then
        printf "${green}Discord updated successfully.${reset}\n"
    else
        printf "${red}Discord update failed.${reset}\n"
    fi
}

remove_discord() {
    # Remove Discord directory from /opt
    if [ -d "/opt/Discord" ]; then
        sudo rm -rf /opt/Discord
    fi

    # Remove symbolic link from /usr/bin
    if [ -L "/usr/bin/Discord" ]; then
        sudo rm /usr/bin/Discord
    fi

    # Remove desktop entry
    if [ -f "/usr/share/applications/discord.desktop" ]; then
        sudo rm /usr/share/applications/discord.desktop
    fi
    printf "${green}Discord removed successfully.${reset}\n"
}

prompt_user() {
    while true; do
        echo "1) Install Discord"
        echo "2) Update Discord"
        echo "3) Remove Discord"

        echo ''
        printf "${green}Pick an option by typing its number: ${reset}"
        read choice

        case $choice in
            1 )
                install_discord
                break
                ;;
            2 )
                update_discord
                break
                ;;
            3 )
                remove_discord
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
