#!/bin/bash

iso_base=$1
iso_out=out.iso
workdir=work

rm -rf $workdir squashfs-root rootfs rootfs.tar $iso_out
mkdir $workdir
bsdtar -x -C $workdir -f $iso_base

sed -i -e 's/nouveau.modeset=1 i915.modeset=1 radeon.modeset=1/nomodeset systemd.unit=multi-user.target/g' $workdir/boot/grub/kernels.cfg
sed -i -e 's/nouveau.modeset=0 i915.modeset=1 radeon.modeset=1/nomodeset systemd.unit=multi-user.target/g' $workdir/boot/grub/kernels.cfg
sed -i -e 's/quiet systemd.show_status=1 splash//g' $workdir/boot/grub/kernels.cfg

unsquashfs $workdir/manjaro/x86_64/rootfs.sfs
cp scripts/mod.sh scripts/startup.sh squashfs-root
cp scripts/startup.service squashfs-root/lib/systemd/system
mkdir -p squashfs-root/etc/ssh
ssh-keygen -f squashfs-root/etc/ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f squashfs-root/etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
ssh-keygen -f squashfs-root/etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
bsdtar -C squashfs-root -c . | docker import - mjro_temp:base
docker buildx build -o rootfs docker
mksquashfs rootfs rootfs.sfs
md5sum rootfs.sfs > $workdir/manjaro/x86_64/rootfs.md5
mv rootfs.sfs $workdir/manjaro/x86_64/rootfs.sfs

xorriso -as mkisofs \
    --modification-date=$(date -u +%Y-%m-%d-%H-%M-%S-00  | sed -e s/-//g) \
    --protective-msdos-label \
    -volid "Manjaro custom" \
    -appid "Manjaro custom" \
    -publisher "$USER" \
    -preparer "Repacked" \
    -r -graft-points -no-pad \
    --sort-weight 0 / \
    --sort-weight 1 /boot \
    --grub2-mbr $workdir/boot/grub/i386-pc/boot_hybrid.img \
    -iso_mbr_part_type 0x00 \
    -partition_offset 16 \
    -b boot/grub/i386-pc/eltorito.img \
    -c boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
    -eltorito-alt-boot \
    -append_partition 2 0xef $workdir/efi.img \
    -e --interval:appended_partition_2:all:: \
    -no-emul-boot \
    -full-iso9660-filenames \
    -iso-level 3 -rock -joliet \
    -o $iso_out \
    $workdir/
