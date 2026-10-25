#!/usr/bin/env bash
# Force NVIDIA runtime D3 (dGPU sleeps when idle). Seen 2026-10-25 (kernel 7.3, driver 615.78): the driver's
# default (DynamicPowerManagement=3) reports "Runtime D3 status: Disabled by default"
# and the RTX 4060 stays awake (~14 W idle on battery instead of ~7 W).
# Undo: rollback.sh. Takes effect after reboot.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

echo 'options nvidia NVreg_DynamicPowerManagement=0x02' > /etc/modprobe.d/nvidia-pm.conf
limine-mkinitcpio
echo "Done. Reboot, then check: grep 'Runtime D3' /proc/driver/nvidia/gpus/*/power"
