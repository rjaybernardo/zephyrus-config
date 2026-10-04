#!/usr/bin/env bash
# Zephyrus G14: closing the lid sleeps, then hibernates.
#
# - lid closed on battery: suspend, hibernate after 2 h (or earlier when the
#   battery runs low); lid closed on AC: plain suspend. No idle timers.
# - 32 GiB swapfile on its own btrfs subvolume (@swap), outside snapper's @
# - zram stays the normal swap (priority 100); the swapfile (priority -2)
#   is only used for hibernation
# - resume uses systemd's HibernateLocation EFI variable, so no kernel
#   parameter, bootloader or initramfs change is needed
# - NVIDIA uses kernel suspend notifiers; nvidia-hibernate services stay off
#
# Undo with rollback.sh in this folder.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }

ROOT_UUID="6b245cc7-a06c-4d14-9e60-dc3aabf6a434"
SWAPFILE=/swap/swapfile
SWAP_SIZE=32g
FSTAB=/etc/fstab
BACKUP="/etc/fstab.before-hibernate.$(date +%Y%m%d-%H%M%S)"

echo "==> Preflight"
[[ "$(findmnt -no UUID /)" == "$ROOT_UUID" ]] || { echo "Root UUID changed; aborting."; exit 1; }
grep -q '\[none\]' /sys/kernel/security/lockdown || { echo "Kernel lockdown is on; hibernation is blocked."; exit 1; }
grep -qw disk /sys/power/state || { echo "Kernel has no hibernation support."; exit 1; }
[[ -d /sys/firmware/efi/efivars ]] || { echo "Not booted via EFI."; exit 1; }
findmnt --verify --tab-file "$FSTAB" >/dev/null || { echo "Current fstab already has errors; fix those first."; exit 1; }
if grep -q '/swap/swapfile' "$FSTAB"; then
	echo "fstab already has the swapfile; nothing to do."
	exit 0
fi

echo "==> 1/5 Create @swap subvolume and the swapfile"
TOP=$(mktemp -d)
mount -o subvolid=5 "UUID=$ROOT_UUID" "$TOP"
[[ -d "$TOP/@swap" ]] || btrfs subvolume create "$TOP/@swap"
umount "$TOP"
rmdir "$TOP"

mkdir -p /swap
mountpoint -q /swap || mount -o subvol=/@swap,noatime "UUID=$ROOT_UUID" /swap
[[ -f "$SWAPFILE" ]] || btrfs filesystem mkswapfile --size "$SWAP_SIZE" --uuid clear "$SWAPFILE"

echo "==> 2/5 Add fstab entries (backup: $BACKUP)"
cp -a "$FSTAB" "$BACKUP"
cat >> "$FSTAB" <<EOF

# Hibernation swapfile (system/hibernate/setup.sh). nofail: never blocks boot.
UUID=$ROOT_UUID /swap btrfs subvol=/@swap,defaults,noatime,nofail 0 0
$SWAPFILE none swap defaults,pri=-2,nofail 0 0
EOF

# Exit code is non-zero only for errors; warnings are fine.
if ! findmnt --verify --tab-file "$FSTAB"; then
	echo "fstab check failed; restoring backup."
	cp -a "$BACKUP" "$FSTAB"
	exit 1
fi
systemctl daemon-reload

echo "==> 3/5 Prove the fstab entries work, then enable the swapfile"
umount /swap
mount /swap
swapon "$SWAPFILE"
swapon --show

echo "==> 4/5 Lid and sleep settings"
mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
cat > /etc/systemd/sleep.conf.d/10-hibernate.conf <<'EOF'
# system/hibernate/setup.sh
[Sleep]
HibernateDelaySec=2h
HibernateOnACPower=no
EOF
cat > /etc/systemd/logind.conf.d/10-lid.conf <<'EOF'
# system/hibernate/setup.sh — applies after the next reboot
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
EOF

echo "==> 5/5 Check"
busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate
busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspendThenHibernate

echo
echo "Done. Both lines above should say \"yes\"."
echo "Next: reboot, save your work, then test with: systemctl hibernate"
