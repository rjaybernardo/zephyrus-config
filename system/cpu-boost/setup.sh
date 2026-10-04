#!/usr/bin/env bash
# Keep CPU boost OFF (max ~4.0 GHz) for a cooler, longer-lasting G14.
# Measured 2026-10-04: AI answers peak 69°C instead of 92°C at -3% speed,
# all-core work same speed at 37 W instead of 43 W, idle 4 W instead of 5 W.
# Uses systemd-tmpfiles (part of systemd) — no extra packages.
# Toggle any time: boost-on / boost-off (zsh); undo: rollback.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
BOOST=/sys/devices/system/cpu/cpufreq/boost
[[ -w $BOOST ]] || { echo "No writable $BOOST — nothing to do"; exit 1; }

cat > /etc/tmpfiles.d/cpu-boost-off.conf <<'CFG'
# CPU boost off at every boot (G14 cool setup, see ~/.config/nvim/system/cpu-boost)
w /sys/devices/system/cpu/cpufreq/boost - - - - 0
CFG
systemd-tmpfiles --create /etc/tmpfiles.d/cpu-boost-off.conf
[[ $(cat $BOOST) == 0 ]] && echo "OK: boost is OFF now and at every boot." || { echo "Failed: boost=$(cat $BOOST)"; exit 1; }
