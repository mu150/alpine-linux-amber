#!/usr/bin/env bash
set -euxo pipefail

# 1. variables
IMG=alpine-rg353vs-${GITHUB_SHA}.img
UBOOT=uboot.img
MINIROOT=http://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-minirootfs-3.19.0-aarch64.tar.gz
WORKDIR=$(mktemp -d)
BOOT_SIZE=64      # MiB
TOTAL_SIZE=1024   # MiB

# 2. fetch rootfs and u‑boot
wget -O "$WORKDIR/rootfs.tar.gz" "$MINIROOT"
cp "$UBOOT" "$WORKDIR/uboot.img"

# 3. create empty image
truncate -s ${TOTAL_SIZE}M "$IMG"

# 4. partition: 1=FAT32 @ [1MiB–${BOOT_SIZE}MiB],  2=ext4 @ [${BOOT_SIZE}MiB–end]
parted --script "$IMG" \
  mklabel msdos \
  mkpart primary fat32 1MiB ${BOOT_SIZE}MiB \
  mkpart primary ext4  ${BOOT_SIZE}MiB 100%

# 5. map to loop devices
LOOP=$(losetup --show -fP "$IMG")
BOOT_DEV=${LOOP}p1
ROOT_DEV=${LOOP}p2

# 6. format
mkfs.vfat -n BOOT "$BOOT_DEV"
mkfs.ext4 -L ROOTFS "$ROOT_DEV"

# 7. install u-boot (at 8KiB)
dd if="$WORKDIR/uboot.img" of="$IMG" bs=1K seek=8 conv=fsync

# 8. mount & populate
mkdir -p "$WORKDIR"/{mnt/boot,mnt/root}
mount "$BOOT_DEV" "$WORKDIR/mnt/boot"
mount "$ROOT_DEV" "$WORKDIR/mnt/root"

# 8a. extract rootfs
tar xzf "$WORKDIR/rootfs.tar.gz" -C "$WORKDIR/mnt/root"

# 8b. copy kernel, dtb, boot script
cp linux-firmware/*.dtb "$WORKDIR/mnt/boot"/
cp zImage "$WORKDIR/mnt/boot"/
cp boot.scr "$WORKDIR/mnt/boot"/

# 9. cleanup
sync
umount "$WORKDIR"/mnt/{boot,root}
losetup -d "$LOOP"
rm -rf "$WORKDIR"

echo "Created $IMG"
