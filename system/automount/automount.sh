#!/usr/bin/env bash
# Auto-mount external drives (USB disks, sticks, SD cards) when plugged in,
# at /run/media/$USER/<label>. Run by systemd/user/automount.service.
# Uses udisks2 only (no udiskie). Internal disks are never touched.
# A "dirty" NTFS drive (unplugged without ejecting / Windows Fast Startup) is
# mounted read-only with a notification; fix it with: sudo ntfsfix -d /dev/sdX1
set -uo pipefail

notify() { notify-send -a "Automount" -i drive-removable-media "$@" 2>/dev/null || true; }

try_mount() {
  local dev=/dev/$1 hotplug fstype mnt out
  [[ -b $dev ]] || return
  read -r hotplug fstype < <(lsblk -dno HOTPLUG,FSTYPE "$dev")
  [[ $hotplug == 1 && -n ${fstype:-} ]] || return
  case $fstype in swap|crypto_LUKS|LVM2_member|linux_raid_member) return ;; esac
  [[ -z $(lsblk -dno MOUNTPOINTS "$dev") ]] || return

  if out=$(udisksctl mount -b "$dev" --no-user-interaction 2>&1); then
    mnt=$(lsblk -dno MOUNTPOINTS "$dev")
    notify "Mounted $(lsblk -dno LABEL "$dev" || echo "$dev")" "$mnt"
  elif out=$(udisksctl mount -b "$dev" -o ro --no-user-interaction 2>&1); then
    mnt=$(lsblk -dno MOUNTPOINTS "$dev")
    notify -u critical "Mounted READ-ONLY: $mnt" \
      "$dev needs repair before writing. In a terminal: sudo ntfsfix -d $dev"
  else
    notify -u critical "Couldn't mount $dev" "$out"
  fi
}

# Drives already plugged in at login.
for d in $(lsblk -lno NAME); do try_mount "$d"; done

# Newly plugged drives. udisks reports either a new device object
#   "Added /org/freedesktop/UDisks2/block_devices/sda1"
# or a filesystem appearing on an existing one
#   "/org/freedesktop/UDisks2/block_devices/sda1: Added interface org.freedesktop.UDisks2.Filesystem"
re='(Added |^)/org/freedesktop/UDisks2/block_devices/([^:[:space:]]+)(: Added interface org\.freedesktop\.UDisks2\.Filesystem)?$'
stdbuf -oL udisksctl monitor 2>/dev/null | while read -r _ line; do
  [[ $line =~ $re && ( -n ${BASH_REMATCH[1]} || -n ${BASH_REMATCH[3]} ) ]] || continue
  sleep 1   # let udev finish probing the filesystem
  try_mount "${BASH_REMATCH[2]}"
done
