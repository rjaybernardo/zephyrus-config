#!/usr/bin/env bash
# Let the RTX 4060 sleep after login: pin SDDM's Xorg (login screen) to the AMD iGPU.
# Installs igpu-guard.sh as an sddm.service ExecStartPre (prefixed "-": if the guard ever
# fails, SDDM still starts normally). Theme, display manager and sessions are untouched.
# Usage: sudo bash igpu-apply.sh     then reboot.   Undo: sudo bash igpu-rollback.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
GUARD=/usr/local/lib/sddm-igpu-guard
DROPIN=/etc/systemd/system/sddm.service.d/igpu-only.conf

install -Dm755 "$HERE/igpu-guard.sh" "$GUARD"
install -d "${DROPIN%/*}"
cat > "$DROPIN" <<UNIT
# Pin SDDM's Xorg to the iGPU when the panel is on it (see $GUARD)
[Service]
ExecStartPre=-$GUARD
UNIT
systemctl daemon-reload

"$GUARD"   # write the Xorg config now so it can be inspected before rebooting
if systemctl cat sddm.service | grep -q "ExecStartPre=-$GUARD"; then
  echo "OK: installed. Takes effect at next reboot (nothing was restarted)."
  [[ -f /etc/X11/xorg.conf.d/20-sddm-igpu-only.conf ]] && cat /etc/X11/xorg.conf.d/20-sddm-igpu-only.conf
  echo "If the login screen is ever black: Ctrl+Alt+F3, log in, sudo bash $HERE/igpu-rollback.sh, reboot."
else
  echo "Verification failed, rolling back"; bash "$HERE/igpu-rollback.sh"; exit 1
fi
