#!/bin/bash

# Sync and install necessary packages
pacman -Sy --noconfirm
pacman -S --noconfirm archlinux-keyring

# lsblk

# echo "/dev/sdb is the currently selected disk"
# echo "Press Ctrl + C to exit the script, if wrong disk is selected :)"
# sleep 10

# # Format partitions
# mkfs.fat -F32 /dev/sdb1
# mkfs.ext4 /dev/sdb2
# mkswap /dev/sdb3

./new.sh

# Install base system and necessary packages
pacstrap /mnt base base-devel linux linux-headers linux-firmware intel-ucode sudo git vim cmake make networkmanager cargo gcc

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Change root to the new system
arch-chroot /mnt << EOF
# Set root password
echo "root:moni" | chpasswd

# Add user amit and set password
useradd -m -g users -G wheel,storage,video,audio -s /bin/bash amit
echo "amit:root" | chpasswd

# Grant sudo permissions to amit
echo 'amit ALL=(ALL) ALL' >> /etc/sudoers

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Configure locale
echo "en_IN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_IN.UTF-8" > /etc/locale.conf

# Set hostname
echo "kali" >> /etc/hostname
echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1	   localhost" >> /etc/hosts
echo "127.0.1.1    kali.localdomain   kali" >> /etc/hosts

# Install and configure GRUB
pacman -S --noconfirm grub efibootmgr dosfstools mtools
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

EOF

# Unmount all partitions
umount -lR /mnt
