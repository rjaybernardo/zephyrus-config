#!/usr/bin/env bash
# Undo apply.sh: stop the weekly cleanup and restore the default setting.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

systemctl disable --now paccache.timer
sed -i 's/^PACCACHE_ARGS=.*/PACCACHE_ARGS=/' /etc/conf.d/pacman-contrib
echo "Rolled back."
