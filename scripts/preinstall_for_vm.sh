#!/bin/bash

# adjust cli
loadkeys es
setfont ter-v22b
pacman -Sy --noconfirm --needed gptfdisk btrfs-progs glibc

# wipe disk
umount -A --recursive /mnt
sgdisk -Z /dev/vda # zap all on disk
#sgdisk -a 2048 -o /dev/vda # new gpt disk 2048 alignment

# make partitions
# sgdisk -n 1::+300M --typecode=1:ef02 /dev/vda
# sgdisk -n 2::+8G --typecode=2:8300 /dev/vda
# sgdisk -n 3::+4G --typecode=3:8300 /dev/vda
# sgdisk -n 4::-0 --typecode=4:8300 /dev/vda

# # create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' /dev/vda # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' /dev/vda # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-8G --typecode=3:8300 --change-name=3:'ROOT' /dev/vda # partition 3 (Root), default start, remaining
sgdisk -n 3::+4G --typecode=3:8300 --change-name=4:'HOME' /dev/vda # partition 4
sgdisk -n 4::-0 --typecode=4:8300 --change-name=5:'STORAGE' /dev/vda # partition 5
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 /dev/vda
fi
partprobe /dev/vda # reread partition table to ensure it is correct



# check if /dev/vda3 exists
if [ ! -b /dev/vda3 ]; then
    echo "Error: /dev/vda3 does not exist"
    exit 1
fi

# format partitions
mkfs.fat -F32 /dev/vda1
mkfs.fat -F32 /dev/vda2
mkfs.btrfs /dev/vda3 -f
mkfs.ext4 /dev/vda4
mkfs.ext4 /dev/vda5

# check if vda3 is correctly created and a btrfs system
if [ ! -b /dev/vda3 -o "$(blkid -s TYPE -o value /dev/vda3)" != "btrfs" ]; then
    echo "Error: /dev/vda3 is not a btrfs system"
    exit 1
fi

# make btrfs subvolumes
mkdir /mnt
mount /dev/vda3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
umount /mnt

# mount btrfs subvolumes
mount -o noatime,compress=zstd,subvol=@ /dev/vda3 /mnt
mkdir -p /mnt/{var,tmp,.snapshots}
mount -o noatime,compress=zstd,subvol=@var /dev/vda3 /mnt/var
mount -o noatime,compress=zstd,subvol=@tmp /dev/vda3 /mnt/tmp
mount -o noatime,compress=zstd,subvol=@.snapshots /dev/vda3 /mnt/.snapshots

# mount home
mkdir /mnt/home
mount /dev/vda3 /mnt/home

# mount boot
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

# check partitions
fdisk -l /dev/vda
lsblk /dev/vda

# check mounted directory
ls -la /mnt

# suggest next step
echo -ne "
next step:
bash <(curl -L t.ly/Gsuns)
"
