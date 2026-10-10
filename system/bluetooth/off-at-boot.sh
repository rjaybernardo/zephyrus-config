#!/usr/bin/env bash
# Bluetooth starts powered OFF at every boot (battery). Still turn it on any time from Noctalia
# or `bluetoothctl power on`. BlueZ's own setting (AutoEnable=false), no packages, bluetooth.service untouched.
# main.conf is a pacman backup= file, so bluez upgrades keep this (new defaults land in main.conf.pacnew).
# Undo: sudo bash on-at-boot.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
CONF=/etc/bluetooth/main.conf

cp -n $CONF $CONF.before-off-at-boot
sed -i -E 's/^#?AutoEnable=.*/AutoEnable=false/' $CONF

if [[ $(grep -c '^AutoEnable=false' $CONF) -eq 1 ]] && ! grep -q '^AutoEnable=true' $CONF; then
  bluetoothctl power off >/dev/null 2>&1 || true
  echo "OK: Bluetooth starts off at boot (and is off now). Undo: sudo bash $(dirname "$0")/on-at-boot.sh"
else
  echo "Verification failed, restoring backup"
  cp $CONF.before-off-at-boot $CONF
  exit 1
fi
