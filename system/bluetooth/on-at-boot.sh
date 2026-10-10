#!/usr/bin/env bash
# Undo off-at-boot.sh: Bluetooth powers on at boot again (BlueZ default).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
CONF=/etc/bluetooth/main.conf
sed -i -E 's/^AutoEnable=false/#AutoEnable=true/' $CONF
rm -f $CONF.before-off-at-boot
bluetoothctl power on >/dev/null 2>&1 || true
echo "Rolled back: Bluetooth on at boot (and on now)."
