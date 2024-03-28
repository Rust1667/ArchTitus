#!/bin/bash

# adjust cli
setfont ter-v22b
pacman -Sy --noconfirm --needed gptfdisk btrfs-progs glibc

# Warning message
echo "WARNING: This script is going to wipe the partition that you choose as ROOT"
echo "Make sure you've selected the correct partition or you'll lose all data on it!"
read -rp "Press enter to continue"

# check partitions
fdisk -l
#lsblk

# Define DISK variable
DEFAULT_DISK="/dev/sda"
echo "Please enter the value for DISK (default: $DEFAULT_DISK):"
read -r USER_DISK
if [ -z "$USER_DISK" ]; then
    DISK="$DEFAULT_DISK"
else
    DISK="$USER_DISK"
fi
echo "The chosen disk path is: ${DISK}"

# check partitions
partprobe ${DISK} # reread partition table to ensure it is correct

# promp the user to choose the ROOT partition
echo -ne "Please enter the partition number for the ROOT partition (e.g. 3):\n"
read -r USER_ROOT
echo "The chosen ROOT partition is: ${DISK}${USER_ROOT}"

# prompt the user to choose the HOME partition
echo -ne "Please enter the partition number for the HOME partition (e.g. 4):\n"
read -r USER_HOME
echo "The chosen HOME partition is: ${DISK}${USER_HOME}"

# prompt the user to choose the EFIBOOT partition
echo -ne "Please enter the partition number for the EFIBOOT partition (e.g. 2):\n"
read -r USER_EFIBOOT
echo "The chosen EFIBOOT partition is: ${DISK}${USER_EFIBOOT}"

# prompt for confirmation, warning that the root partition is going to be wiped
read -rp "Are you sure you want to wipe ${DISK}${USER_ROOT}? (y/N) " -n 1 -r

# format the root partition
mkfs.btrfs -f ${DISK}${USER_ROOT}

# check if the root partition is correctly created
if [ ! -b ${DISK}${USER_ROOT} ]; then
    echo "Error: ${DISK}${USER_ROOT} does not exist"
    exit 1
fi


# make btrfs subvolumes
mkdir /mnt
mount ${DISK}${USER_ROOT} /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# mount btrfs subvolumes
mount -o noatime,compress=zstd,subvol=@ ${DISK}${USER_ROOT} /mnt
mkdir -p /mnt/{var,tmp,.snapshots}
mount -o noatime,compress=zstd,subvol=@var ${DISK}${USER_ROOT} /mnt/var
mount -o noatime,compress=zstd,subvol=@tmp ${DISK}${USER_ROOT} /mnt/tmp
mount -o noatime,compress=zstd,subvol=@.snapshots ${DISK}${USER_ROOT} /mnt/.snapshots

# mount home
mkdir /mnt/home
mount ${DISK}${USER_HOME} /mnt/home

# mount boot for EFI case
mkdir -p /mnt/boot/efi
mount -t vfat ${DISK}${USER_EFIBOOT} /mnt/boot/

# check partitions
#fdisk -l ${DISK}
lsblk ${DISK}

# check mounted directory
ls -la /mnt

# suggest next step
echo -ne "
next step:
bash <(curl -L t.ly/Gsuns)
"