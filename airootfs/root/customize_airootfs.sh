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

# Set default target to graphical
systemctl set-default graphical.target

# Enable SDDM service
systemctl enable sddm.service

# # Add user and configure sudo access without manual editing
# useradd -m -G wheel user || echo "User already exists, skipping creation."
# echo "user ALL=(ALL) ALL" > /etc/sudoers.d/user
#
# # Ensure the new sudoers file has correct permissions
# chmod 440 /etc/sudoers.d/user
#
# # Set password for the user (optional)
# echo "user:password" | chpasswd
#
# # Copying themes to .local/share/themes in user's home directory
# source_folder="/theme-to-copy/"
# destination_folder="/home/user/.local/share/"
# mkdir -p "$destination_folder"
# cp -r "$source_folder." "$destination_folder"
#
# # Set ownership of the copied files to the user
# chown -R user:user "/home/user/.local"
#
# # Initialize pacman keyring and update packages
# pacman-key --init && pacman-key --populate archlinux
# pacman -Sy --noconfirm
#
# echo "Enabling SDDM as default display manager"
# systemctl enable sddm.service
#
# echo "Creating xinitrc file"
# # Create a .xinitrc file for the user to start Plasma Wayland
# echo "exec startplasma-wayland" > /home/user/.xinitrc
# chown user:user /home/user/.xinitrc
#
# echo "Applying KDE Plasma settings"
#
# plasmarc_path="/home/user/.config/plasmarc"
# kdeglobals_path="/home/user/.config/kdeglobals"
#
# mkdir -p "/home/user/.config"
# update_plasmarc() {
#     if [ ! -f "$plasmarc_path" ]; then
#         echo "[Theme]" > "$plasmarc_path"
#         echo "name=Ant-Dark" >> "$plasmarc_path"
#     else
#         if ! grep -q "^\[Theme\]" "$plasmarc_path"; then
#             echo "[Theme]" >> "$plasmarc_path"
#         fi
#
#         if grep -q "^name=" "$plasmarc_path"; then
#             sed -i 's/^name=.*/name=Ant-Dark/' "$plasmarc_path"
#         else
#             sed -i '/^\[Theme\]/a name=Ant-Dark' "$plasmarc_path"
#         fi
#     fi
# }
#
# update_kdeglobals() {
#     if [ ! -f "$kdeglobals_path" ]; then
#         echo "[Icons]" > "$kdeglobals_path"
#         echo "Theme=Ant-Dark" >> "$kdeglobals_path"
#     else
#         if ! grep -q "^\[Icons\]" "$kdeglobals_path"; then
#             echo "[Icons]" >> "$kdeglobals_path"
#         fi
#
#         if grep -q "^Theme=" "$kdeglobals_path"; then
#             sed -i 's/^Theme=.*/Theme=Ant-Dark/' "$kdeglobals_path"
#         else
#             sed -i '/^\[Icons\]/a Theme=Ant-Dark' "$kdeglobals_path"
#         fi
#     fi
# }
# echo "Updating plasmarc"
# update_plasmarc
# echo "Updating KDE Globals"
# update_kdeglobals
#
# # chown user:user "$plasmarc_path" "$kdeglobals_path"
#
# echo "Script execution completed successfully!"
