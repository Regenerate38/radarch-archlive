#!/bin/bash

DRIVE='/dev/sda'

TIMEZONE='Asia/Kathmandu'

HOSTNAME='praharsha'
PASSWORD='praharsha'

main() {
	partitionDisks	
	formatPartitions
	mountFileSystems
	installEssentialPackages
	configureSystem
	unmountAndReboot
}

partitionDisks() {
	echo "Partitioning the disks"
	# Creating new GPT partition
	parted --script "$DRIVE" mklabel gpt
	# Creating EFI partition (1GB)
	parted --script "$DRIVE" mkpart ESP fat32 1MiB 1025MiB
	parted --script "$DRIVE" set 1 esp on
	# Creating swap partition (4GB)
	parted --script "$DRIVE" mkpart primary linux-swap 1025MiB 5121MiB
	# Creating Root partition (remaining space)
	parted --script "$DRIVE" mkpart primary ext4 5121MiB 100%
}

formatPartitions() {
	echo "Formatting the partitions"
	# Creating Ext4 FS on root partition
	mkfs.ext4 /dev/sda3
	# Initializing swap
	mkswap /dev/sda2
	# Formatting EFI partition to FAT32
	mkfs.fat -F 32 /dev/sda1
}

mountFileSystems() {
	echo "Mounting the file systems"
	# Mounting the root partition to /mnt
	mount /dev/sda3 /mnt
	# Creating /mnt/boot and mounting the EFI partition to it
	mount --mkdir /dev/sda1 /mnt/boot
	# Enabling the swap partition
	swapon /dev/sda2
}

installEssentialPackages() {
	echo "Installing essential packages"
	# Installing linux kernel and firmware with the base package and network manager
	pacstrap -K /mnt base linux linux-firmware networkmanager
}

configureSystem() {
	echo "Configuring the system"
	# Generating fstab file
	genfstab -U /mnt >> /mnt/etc/fstab
	# Copying resolv.conf for network access
	cp --dereference /etc/resolv.conf /mnt/etc/resolv.conf
	# Chrooting into new system
	arch-chroot /mnt /bin/bash <<EOF
		# Setting the timezone
		ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
		# Generating locale
		echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
		locale-gen
		# Setting the hostname
		echo "$HOSTNAME" > /etc/hostname
		# Setting root password
		echo -en "$PASSWORD\n$PASSWORD" | passwd
		# Installing grub and efibootmgr
		pacman -Sy --noconfirm grub efibootmgr
		# Initializing GRUB
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
		# Generating GRUB config
		grub-mkconfig -o /boot/grub/grub.cfg
		# Enabling network manager on boot
		systemctl enable NetworkManager.service
EOF
}

unmountAndReboot() {
	echo "Unmounting /mnt and rebooting"
	unmount -R /mnt
	reboot
}

main

