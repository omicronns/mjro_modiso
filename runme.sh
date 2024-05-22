#!/bin/bash

iso_base=manjaro-kde-24.0-minimal-240513-linux69.iso
workdir=work

rm -rf $workdir squashfs-root rootfs
mkdir $workdir
bsdtar -x -C $workdir -f $iso_base

sed -i -e 's/nouveau.modeset=1 i915.modeset=1 radeon.modeset=1/nomodeset systemd.unit=multi-user.target/g' $workdir/boot/grub/kernels.cfg
sed -i -e 's/nouveau.modeset=0 i915.modeset=1 radeon.modeset=1/nomodeset systemd.unit=multi-user.target/g' $workdir/boot/grub/kernels.cfg
sed -i -e 's/quiet systemd.show_status=1 splash/systemd.show_status=1/g' $workdir/boot/grub/kernels.cfg

unsquashfs $workdir/manjaro/x86_64/rootfs.sfs
cp mod.sh squashfs-root
tar -C squashfs-root -c . | docker import - mjro_temp:base
docker build --ulimit nofile=1024:524288 -t mjro_temp:mod docker
id=$(docker create mjro_temp:mod /bin/true)
mkdir rootfs && bsdtar -x -C rootfs -f rootfs.tar
mksquashfs rootfs rootfs.sfs
md5sum rootfs.sfs > $workdir/manjaro/x86_64/rootfs.md5
mv rootfs.sfs $workdir/manjaro/x86_64/rootfs.sfs

xorriso -as mkisofs \
    --modification-date=$(date -u +%Y-%m-%d-%H-%M-%S-00  | sed -e s/-//g) \
    --protective-msdos-label \
    -volid "Manjaro custom KDE" \
    -appid "Manjaro custom iso" \
    -publisher "kad" \
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
    -o out.iso \
    $workdir/
