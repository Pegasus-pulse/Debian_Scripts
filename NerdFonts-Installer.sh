#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists unzip; then
  echo "Installing unzip..."
  sudo apt install unzip -y
fi

# Create directory for fonts if it doesn't exist
sudo mkdir -p /usr/share/fonts/NerdFonts

# Array of font names
fonts=(
  "CascadiaCode"
  "FiraCode"
  "Hermit"
  "Hack"
  "JetBrainsMono"
  "Meslo"
  "Mononoki"
  "NerdFontsSymbolsOnly"
  "RobotoMono"
  "UbuntuMono"
)

check_font_installed() {
  font_name=$1
  if [ -d /usr/share/fonts/NerdFonts/$font_name ]; then
    echo "Font $font_name is already installed. Skipping..."
    return 0 # Font already installed
  else
    return 1 # Font not installed
  fi
}

for font in "${fonts[@]}"; do
  if check_font_installed "$font"; then
    echo "Skipping installation of font: $font"
    continue
  fi

  echo "Installing font: $font"
  # Update the URL manually, when a new version is available
  wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/$font.zip" -P /tmp
  if [ $? -ne 0 ]; then
    echo "Failed to download font: $font"
    continue
  fi

  sudo unzip -q /tmp/$font.zip -d /usr/share/fonts/NerdFonts/$font/
  if [ $? -ne 0 ]; then
    echo "Failed to extract font: $font"
    continue
  fi

  rm /tmp/$font.zip
done

sudo fc-cache -f

echo "Fonts installation completed."
