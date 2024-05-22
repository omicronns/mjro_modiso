#!/bin/bash

pacman-key --init
pacman-key --populate

yes | pacman -Sy yay base-devel linux69-headers

sed -i -e 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
useradd -m -G wheel -s /bin/bash aur

yes | sudo -u aur yay -S ncurses5-compat-libs

systemctl enable startup

rm -rf /var/cache/pacman/pkg/*
rm -rf /home/aur/.cache/*
