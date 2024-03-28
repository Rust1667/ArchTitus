#!/bin/bash

# Define DISK variable
DEFAULT_DISK="/dev/vda"
echo "Please enter the value for DISK (default: $DEFAULT_DISK):"
read -r USER_DISK
if [ -z "$USER_DISK" ]; then
    DISK="$DEFAULT_DISK"
else
    DISK="$USER_DISK"
fi
echo "The chosen disk path is: ${DISK}"

# adjust cli
loadkeys es
setfont ter-v22b
pacman -Sy --noconfirm --needed gptfdisk btrfs-progs glibc

# wipe disk
umount -A --recursive /mnt
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# # create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-8G --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
sgdisk -n 4::+4G --typecode=4:8300 --change-name=4:'HOME' ${DISK} # partition 4
sgdisk -n 5::-0 --typecode=5:8300 --change-name=5:'STORAGE' ${DISK} # partition 5
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # reread partition table to ensure it is correct


# check if ${DISK}3 exists
if [ ! -b ${DISK}3 ]; then
    echo "Error: ${DISK}3 does not exist"
    exit 1
fi

# format partitions
mkfs.fat -F32 ${DISK}1
mkfs.fat -F32 ${DISK}2
mkfs.btrfs ${DISK}3 -f
mkfs.ext4 ${DISK}4
mkfs.ext4 ${DISK}5

# check if vda3 is correctly created and a btrfs system
if [ ! -b ${DISK}3 -o "$(blkid -s TYPE -o value ${DISK}3)" != "btrfs" ]; then
    echo "Error: ${DISK}3 is not a btrfs system"
    exit 1
fi

# make btrfs subvolumes
mkdir /mnt
mount ${DISK}3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# mount btrfs subvolumes
mount -o noatime,compress=zstd,subvol=@ ${DISK}3 /mnt
mkdir -p /mnt/{var,tmp,.snapshots}
mount -o noatime,compress=zstd,subvol=@var ${DISK}3 /mnt/var
mount -o noatime,compress=zstd,subvol=@tmp ${DISK}3 /mnt/tmp
mount -o noatime,compress=zstd,subvol=@.snapshots ${DISK}3 /mnt/.snapshots

# mount home
mkdir /mnt/home
mount ${DISK}4 /mnt/home

# mount boot for EFI case
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

# check partitions
fdisk -l ${DISK}
lsblk ${DISK}

# check mounted directory
ls -la /mnt

# suggest next step
echo -ne "
next step:
bash <(curl -L t.ly/Gsuns)
"
