set -euxo pipefail

# Vars
SHA=${{ github.sha }}
IMG="alpine-rg353vs-${SHA}.img"
UBOOT="uboot.img"
MINIROOT="http://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-minirootfs-3.19.0-aarch64.tar.gz"

# Download Alpine rootfs
wget -O rootfs.tar.gz "$MINIROOT"

# Create blank 1 GiB image
truncate -s 1G "$IMG"

# Attach image file as loop device
LOOP=$(sudo losetup --show -f "$IMG")

# Partition the loop device directly
sudo parted --script "$LOOP" \
  mklabel msdos \
  mkpart primary fat32 1MiB 64MiB \
  mkpart primary ext4 64MiB 100%

# Detach and reattach to trigger /dev/loopXpY devices
sudo losetup -d "$LOOP"
LOOP=$(sudo losetup --show -fP "$IMG")

# Wait for /dev/loopNp1 and loopNp2 to appear
sleep 2
BOOT_DEV="${LOOP}p1"
ROOT_DEV="${LOOP}p2"

# Format partitions
sudo mkfs.vfat -F 32 -n BOOT "$BOOT_DEV"
sudo mkfs.ext4 -L ROOTFS "$ROOT_DEV"

# Write u-boot at 8 KiB offset
sudo dd if="$UBOOT" of="$LOOP" bs=1K seek=8 conv=fsync

# Mount and populate partitions
mkdir -p mnt/boot mnt/root
sudo mount "$BOOT_DEV" mnt/boot
sudo mount "$ROOT_DEV" mnt/root

# Extract Alpine rootfs
sudo tar -xzf rootfs.tar.gz -C mnt/root

# Copy kernel and boot files
sudo cp zImage mnt/boot/
sudo cp *.dtb mnt/boot/
sudo cp boot.scr mnt/boot/

# Cleanup
sync
sudo umount mnt/boot mnt/root
sudo losetup -d "$LOOP"
