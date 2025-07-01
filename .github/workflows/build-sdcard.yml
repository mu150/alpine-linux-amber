#!/usr/bin/env bash
set -euo pipefail

WORKDIR=/work
OUTDIR=${WORKDIR}/out
ROOTFS=${WORKDIR}/rootfs
IMG=${OUTDIR}/rg353vs-alpine.img
KERNEL_VER=v6.6.y
A55_DTB_URL="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git/plain/arch/arm64/boot/dts/allwinner/sun55iw2p1.dtb"

# 1. prepare workspace
rm -rf ${OUTDIR} ${ROOTFS}
mkdir -p ${OUTDIR} ${ROOTFS}

# 2. bootstrap an Alpine ARM64 rootfs
#    note: uses QEMU emulation via qemu-user-static
apk --root ${ROOTFS} --arch aarch64 --update-cache \
    add alpine-base openrc busybox

# 3. pull kernel + dtb
mkdir -p ${ROOTFS}/boot
curl -L https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VER}.tar.xz \
     | tar -xJ -C /tmp
make -C /tmp/linux-${KERNEL_VER} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
     sun55iw2p1_defconfig
make -C /tmp/linux-${KERNEL_VER} ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
     -j"$(nproc)" Image
cp /tmp/linux-${KERNEL_VER}/arch/arm64/boot/Image ${ROOTFS}/boot/vmlinuz-${KERNEL_VER}
curl -L ${A55_DTB_URL} -o ${ROOTFS}/boot/sun55iw2p1.dtb

# 4. system setup
cat <<EOF > ${ROOTFS}/etc/fstab
/dev/mmcblk0p1  /boot   vfat    defaults    0  2
/dev/mmcblk0p2  /       ext4    defaults    0  1
EOF

# 5. build raw image: 64 MB boot, rest rootfs (~1.5 GB total)
IMG_SIZE=1600M
BOOT_SIZE=64M
dd if=/dev/zero of=${IMG} bs=1 count=0 seek=${IMG_SIZE}

parted --script ${IMG} \
  mklabel msdos \
  mkpart primary fat32 1MiB ${BOOT_SIZE} \
  mkpart primary ext4 ${BOOT_SIZE} 100%

# 6. map partitions & format
LOOP=$(losetup --show -fP ${IMG})
mkfs.vfat "${LOOP}p1"
mkfs.ext4 "${LOOP}p2"

# 7. mount & copy
mkdir -p /mnt/boot /mnt/root
mount "${LOOP}p1" /mnt/boot
mount "${LOOP}p2" /mnt/root

cp -a ${ROOTFS}/boot/* /mnt/boot/
( cd ${ROOTFS} && tar cf - . ) | tar xf - -C /mnt/root/

# 8. clean up
umount /mnt/boot /mnt/root
losetup -d ${LOOP}

echo "Image built: ${IMG}"
