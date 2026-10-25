#!/usr/bin/env bash
# Weekly cleanup of old pacman downloads: keep the installed version + one older
# (for downgrades). Uses pacman-contrib's stock paccache.timer.
# Undo: rollback.sh.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

sed -i 's/^PACCACHE_ARGS=.*/PACCACHE_ARGS=-k2/' /etc/conf.d/pacman-contrib
systemctl enable --now paccache.timer
paccache -rk2
echo "Done. Next run: $(systemctl show paccache.timer -p NextElapseUSecRealtime --value)"
