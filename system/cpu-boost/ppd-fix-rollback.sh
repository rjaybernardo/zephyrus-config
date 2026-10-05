#!/usr/bin/env bash
# Undo ppd-fix.sh: ppd loads its amd_pstate driver again, asusd.ron restored.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
RON=/etc/asusd/asusd.ron
rm -f /etc/systemd/system/power-profiles-daemon.service.d/block-amd-pstate.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/power-profiles-daemon.service.d 2>/dev/null || true
if [[ -f $RON.before-ppd-fix ]]; then
  systemctl stop asusd
  cp $RON.before-ppd-fix $RON
  systemctl start asusd
fi
systemctl daemon-reload
systemctl restart power-profiles-daemon
echo "Rolled back. ppd: $(powerprofilesctl get)"
