#adjust cli
loadkeys es
setfont ter-v22b

#wipe disk
umount -A --recursive /mnt
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

#make partitions
sgdisk -n 1::+600M --typecode=1:ef02 --change-name=1:'BIOSBOOT' /dev/vda
sgdisk -n 2::+8G --typecode=3:8300 --change-name=2:'ROOT' /dev/vda
sgdisk -n 3::+4G --typecode=3:8300 --change-name=3:'HOME' /dev/vda
sgdisk -n 4::-0 --typecode=3:8300 --change-name=4:'STORAGE' /dev/vda

#check partitions
fdisk -l /dev/vda
lsblk /dev/vda

#format partitions
mkfs.fat -F32 /dev/vda1
mkfs.btrfs /dev/vda2
mkfs.ext4 /dev/vda3
mkfs.ext4 /dev/vda4

#check partitions
fdisk -l /dev/vda
lsblk /dev/vda

#make btrfs subvolumes
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots
umount /mnt

#mount btrfs subvolumes
mount -o noatime,compress=zstd,subvol=@ /dev/vda2 /mnt
mkdir -p /mnt/{var,tmp,.snapshots}
mount -o noatime,compress=zstd,subvol=@var /dev/vda2 /mnt/var
mount -o noatime,compress=zstd,subvol=@tmp /dev/vda2 /mnt/tmp
mount -o noatime,compress=zstd,subvol=@.snapshots /dev/vda2 /mnt/.snapshots

#mount home
mkdir -p /mnt/{home}
mount /dev/vda3 /mnt/home

#mount boot
mkdir -p /mnt/{boot}
mount /dev/vda1 /mnt/boot

#check partitions
fdisk -l /dev/vda
lsblk /dev/vda

#check mounted directory
ls -l /mnt

# suggest next step
echo -ne "
next step:
bash <(curl -L t.ly/Gsuns)
"
