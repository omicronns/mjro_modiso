#!/bin/bash

pacman-key --init
pacman-key --populate

yes | pacman -Sy yay base-devel

sed -i -e 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
useradd -m -G wheel -s /bin/bash god

yes | sudo -u god yay -S ncurses5-compat-libs

rm -rf /var/cache/pacman/pkg/*
rm -rf /home/god/.cache/*
