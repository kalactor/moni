#!/bin/bash

# List available disks with sizes
echo "Available disks:"
declare -a disks
declare -a sizes
i=1
while read -r disk size; do
    echo "$i) /dev/$disk ($size)"
    disks[$i]="$disk"
    sizes[$i]="$size"
    ((i++))
done < <(lsblk -d -n -o NAME,SIZE | grep -E '^(sd|nvme)')

# Define default disk as /dev/sdb
default_disk="/dev/sdb"
default_index=""

# Look for the default disk in the list
for index in "${!disks[@]}"; do
    if [ "/dev/${disks[$index]}" == "$default_disk" ]; then
        default_index=$index
        break
    fi
done

# Prompt for disk selection with a 60-second timeout
if [ -n "$default_index" ]; then
    prompt="Enter the disk number you wish to partition [default: $default_disk] (waiting 60 seconds): "
else
    prompt="Enter the disk number you wish to partition (waiting 60 seconds): "
fi

read -t 60 -p "$prompt" disk_num

# If no input provided or timeout occurs, use default disk if available
if [ -z "$disk_num" ] && [ -n "$default_index" ]; then
    disk_num=$default_index
fi

# Validate disk selection
if [ -z "${disks[$disk_num]}" ]; then
    echo "Invalid disk selection. Exiting."
    exit 1
fi

selected_disk="/dev/${disks[$disk_num]}"
echo "You have selected $selected_disk of size ${sizes[$disk_num]}."

# Warning before proceeding
echo "WARNING: ALL DATA on $selected_disk will be erased."
read -p "Are you sure you want to proceed? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Determine partition naming scheme (for NVMe devices)
if [[ "$selected_disk" =~ nvme ]]; then
    part1="${selected_disk}p1"
    part2="${selected_disk}p2"
    part3="${selected_disk}p3"
else
    part1="${selected_disk}1"
    part2="${selected_disk}2"
    part3="${selected_disk}3"
fi

# Create a new GPT partition table to remove existing partitions
sudo parted -s "$selected_disk" mklabel gpt

# Create partitions using parted
# Partition 1: 1GB EFI System Partition (from 1MiB to 1025MiB)
parted -s "$selected_disk" mkpart primary fat32 1MiB 1025MiB
parted -s "$selected_disk" set 1 esp on

# Partition 2: 4GB Linux swap partition (from 1025MiB to 5121MiB)
parted -s "$selected_disk" mkpart primary linux-swap 1025MiB 5121MiB

# Partition 3: Linux filesystem partition (from 5121MiB to the end of the disk)
parted -s "$selected_disk" mkpart primary ext4 5121MiB 100%

# Pause briefly to allow the kernel to recognize the changes
sleep 2

# Format the partitions
mkfs.fat -F32 "$part1"      # Format EFI partition as FAT32
mkswap "$part2"             # Prepare swap partition
mkfs.ext4 "$part3"          # Format Linux filesystem partition as ext4

echo "Partitioning and formatting complete on $selected_disk."

# Mount partitions
mount /dev/$part3 /mnt
mkdir -p /mnt/boot
mount /dev/$part1 /mnt/boot

# Enable swap
swapon /dev/$part2