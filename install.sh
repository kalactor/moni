#!/bin/bash

PACKAGE_LIST="packages.txt"
LOG_FILE="install.log"

# Installing Yay...

./yay.sh

if [[ ! -f "$PACKAGE_LIST" ]]; then
	echo "Error: Package list file '$PACKAGE_LIST' not found!"
	exit 1
fi

echo "Updating system..."
sudo yay -Syu --noconfirm >> "$LOG_FILE" 2>&1

while IFS= read -r package; do
	[[ -z "$package" || "$package" =~ ^#.* ]] && continue

	if yay -Qi "$package" &>/dev/null; then
		echo -e "\033[0;33m[skipping]\033[0m $package is already installed."
	else
		echo "Installing $package..."
		if sudo yay -S --noconfirm --needed "$package" >> "$LOG_FILE" 2>&1; then
			echo "Successfully installed $package"
		else
			echo "Failed to install $package. Check $LOG_FILE for details."
		fi
	fi
done < "$PACKAGE_LIST"

echo "Installation process completed :)"
