#!/usr/bin/env bash
# Put the old login screen (elarun) back. Safe to run from a TTY (Ctrl+Alt+F3) if the login screen is broken.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

CONF=/etc/sddm.conf.d/theme.conf
backup=$(printf '%s\n' "$CONF".before-silent.* | sort | head -1)   # oldest stamp = original
[[ -f "$backup" ]] || backup=""
if [[ -n "$backup" ]]; then
  cp -a "$backup" "$CONF"
else
  printf '[Theme]\nCurrent=elarun\n' > "$CONF"
fi
echo "Restored $CONF:"; cat "$CONF"
echo "Takes effect at next logout/reboot (or now: sudo systemctl restart sddm — this ends your session)."
