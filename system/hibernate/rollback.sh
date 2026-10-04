#!/usr/bin/env bash
# Undo system/hibernate/setup.sh.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }

ROOT_UUID="6b245cc7-a06c-4d14-9e60-dc3aabf6a434"

swapoff /swap/swapfile 2>/dev/null || true
umount /swap 2>/dev/null || true

cp -a /etc/fstab "/etc/fstab.before-rollback.$(date +%Y%m%d-%H%M%S)"
sed -i -e '/system\/hibernate\/setup.sh/d' -e '\|/swap btrfs subvol=/@swap|d' -e '\|^/swap/swapfile |d' /etc/fstab
findmnt --verify --tab-file /etc/fstab
systemctl daemon-reload

rm -f /etc/systemd/sleep.conf.d/10-hibernate.conf /etc/systemd/logind.conf.d/10-lid.conf

TOP=$(mktemp -d)
mount -o subvolid=5 "UUID=$ROOT_UUID" "$TOP"
[[ -d "$TOP/@swap" ]] && btrfs subvolume delete "$TOP/@swap"
umount "$TOP"
rmdir "$TOP" /swap 2>/dev/null || true

echo "Hibernate setup removed. Lid goes back to plain suspend after the next reboot."
