#!/usr/bin/env bash
# Undo igpu-apply.sh: SDDM's Xorg goes back to stock GPU autodetection.
# Safe to run from a TTY (Ctrl+Alt+F3) if the login screen is broken.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

rm -f /etc/systemd/system/sddm.service.d/igpu-only.conf \
      /etc/X11/xorg.conf.d/20-sddm-igpu-only.conf \
      /usr/local/lib/sddm-igpu-guard
rmdir --ignore-fail-on-non-empty /etc/systemd/system/sddm.service.d 2>/dev/null || true
systemctl daemon-reload
echo "Rolled back. Takes effect at next reboot (or now: sudo systemctl restart sddm, which ends your session)."
