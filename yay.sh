#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

# Function to check if yay is installed
check_yay_installed() {
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}yay is already installed!${NC}"
    else
        echo -e "${RED}yay is not installed.${NC}"
    fi
}

# Install yay
install_yay() {
    echo -e "${YELLOW}Updating system...${NC}"
    sudo pacman -Syu --noconfirm

    echo -e "${YELLOW}Installing yay...${NC}"
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd ..
}

# Check if yay is installed before installing
check_yay_installed

# If yay is not installed, install it
if ! command -v yay &> /dev/null; then
    install_yay
    echo -e "${GREEN}yay has been installed successfully!${NC}"
else
    echo -e "${YELLOW}Skipping installation as yay is already installed.${NC}"
fi

