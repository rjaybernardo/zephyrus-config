#!/usr/bin/env bash
# Undo setup.sh: boost back ON now and at every boot.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
rm -f /etc/tmpfiles.d/cpu-boost-off.conf
echo 1 > /sys/devices/system/cpu/cpufreq/boost
echo "Boost ON (boot default restored): $(cat /sys/devices/system/cpu/cpufreq/boost)"
