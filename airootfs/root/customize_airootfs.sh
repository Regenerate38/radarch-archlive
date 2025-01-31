#!/bin/bash

set -e -u

# Enable UTF-8 locale
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Set timezone to UTC
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Change root shell to zsh and copy skeleton files
usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

# Configure SSH and systemd settings
sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

# Ignore suspend and hibernate keys
sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

# Enable necessary services and set default target
systemctl enable pacman-init.service choose-mirror.service
systemctl set-default multi-user.target
systemctl enable sddm.service

# Add user and configure sudo access without manual editing
useradd -m -G wheel user
echo "user ALL=(ALL) ALL" >> /etc/sudoers.d/user

# Ensure the new sudoers file has correct permissions
chmod 440 /etc/sudoers.d/user

# Set password for new user (this will prompt for input)
passwd user

echo "Before the keys thingy"
# Initialize pacman keyring and update packages
sudo bash -c "pacman -Sy --noconfirm && pacman-key --init && pacman-key --populate archlinux"

echo "Enabiling sddm as default display manager"
# Setting SDDM as the default display manager
sudo systemctl enable sddm.service

echo "Creating xinitrc file"
# Create a .xinitrc file for the user to start Plasma Wayland
sudo echo "exec startplasma-wayland" > /home/user/.xinitrc
echo "Chown"
sudo chown user:user /home/user/.xinitrc
