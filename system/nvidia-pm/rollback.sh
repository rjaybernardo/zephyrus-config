#!/usr/bin/env bash
# Undo apply.sh: back to the driver's default power management.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

rm -f /etc/modprobe.d/nvidia-pm.conf
limine-mkinitcpio
echo "Rolled back. Takes effect after reboot."
