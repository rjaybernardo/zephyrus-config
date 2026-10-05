#!/usr/bin/env bash
# Format a USB stick as FAT32 (e.g. for ASUS EZ Flash BIOS updates).
# Called from Dolphin's right-click menu (format-fat32.desktop) with the
# folder you clicked in; also works by hand: format-fat32.sh /run/media/$USER/STICK
# Uses udisks2 (no sudo, no extra packages). Refuses anything that isn't a USB drive.
set -uo pipefail
die() { echo -e "\n✗ $*"; read -rp "Press Enter to close…"; exit 1; }

DIR=${1:-}
[[ -d $DIR ]] || die "No folder given."
DEV=$(findmnt -nvo SOURCE --target "$DIR") || die "Can't find the drive for $DIR"
[[ $(findmnt -no TARGET --target "$DIR") == "$(realpath "$DIR")" ]] ||
  die "Right-click inside the USB stick's top folder (you clicked a subfolder or a non-USB folder)."
DISK=/dev/$(lsblk -no PKNAME "$DEV")
[[ $DISK == /dev/ ]] && DISK=$DEV   # filesystem directly on the stick, no partition table
[[ $(lsblk -dno TRAN "$DISK") == usb ]] || die "$DEV is not a USB drive — refusing."

echo "This will ERASE everything on:"
echo
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL,MOUNTPOINTS "$DISK"
echo
echo "Partition to format: $DEV  →  FAT32"
read -rp "New label (max 11 chars, Enter = USB): " LABEL
LABEL=${LABEL:-USB}; LABEL=${LABEL^^}; LABEL=${LABEL:0:11}
read -rp "Type 'yes' to erase $DEV: " OK
[[ $OK == yes ]] || die "Cancelled, nothing changed."

udisksctl unmount -b "$DEV" || die "Couldn't unmount $DEV (close files/windows using it)."
gdbus call --system --timeout 600 --dest org.freedesktop.UDisks2 \
  --object-path "/org/freedesktop/UDisks2/block_devices/${DEV#/dev/}" \
  --method org.freedesktop.UDisks2.Block.Format vfat \
  "{'label': <'$LABEL'>, 'update-partition-type': <true>}" >/dev/null || die "Format failed."
udisksctl mount -b "$DEV" >/dev/null
echo
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DEV"
echo -e "\n✓ Done: $DEV is FAT32 ($LABEL)."
read -rp "Press Enter to close…"
