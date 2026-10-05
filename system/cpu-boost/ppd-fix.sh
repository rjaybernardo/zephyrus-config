#!/usr/bin/env bash
# Make power-profiles-daemon work again with boost off (needed since BIOS 311 enabled amd_pstate).
# Problem: ppd's amd_pstate driver writes policy*/boost on every profile switch; with global
# boost=0 the kernel rejects it (EINVAL) and ppd aborts the whole switch → stuck on Balanced.
# Fix: block ppd's amd_pstate driver (ppd keeps the platform_profile driver = firmware power
# limits) and let asusd set EPP per platform profile instead. No packages. Undo: ppd-fix-rollback.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
RON=/etc/asusd/asusd.ron
DROPIN=/etc/systemd/system/power-profiles-daemon.service.d/block-amd-pstate.conf
EPP=/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
BOOST=/sys/devices/system/cpu/cpufreq/boost

# 1. ppd: skip its amd_pstate CPU driver
mkdir -p "$(dirname $DROPIN)"
cat > $DROPIN <<'CFG'
# G14: ppd's amd_pstate driver fights the boost-off rule (see ~/.config/nvim/system/cpu-boost)
[Service]
ExecStart=
ExecStart=/usr/lib/power-profiles-daemon --block-driver=amd_pstate
CFG

# 2. asusd: set EPP from the platform profile (Quiet → power, Balanced → balance_performance)
cp -n $RON $RON.before-ppd-fix
systemctl stop asusd
sed -i -e 's/platform_profile_linked_epp: false/platform_profile_linked_epp: true/' \
       -e 's/profile_quiet_epp: [A-Za-z]*/profile_quiet_epp: Power/' \
       -e 's/profile_balanced_epp: [A-Za-z]*/profile_balanced_epp: BalancePerformance/' $RON
systemctl daemon-reload
systemctl restart power-profiles-daemon
systemctl start asusd
sleep 3

# 3. Verify: each switch must succeed, EPP must follow, boost must stay off
fail=0
powerprofilesctl | grep -q 'CpuDriver' && { echo "Failed: ppd still loads a CPU driver"; fail=1; }
for p in power-saver balanced; do
  powerprofilesctl set $p || { echo "Failed: powerprofilesctl set $p"; fail=1; }
  sleep 2
  echo "$p → platform $(cat /sys/firmware/acpi/platform_profile), EPP $(cat $EPP), boost $(cat $BOOST)"
done
[[ $(cat $BOOST) == 0 ]] || { echo "Failed: boost turned on"; fail=1; }
journalctl -u power-profiles-daemon --since '-30s' --no-pager | grep -i 'failed' && fail=1
# leave the right profile for the current power source
[[ $(cat /sys/class/power_supply/AC*/online) == 1 ]] && powerprofilesctl set balanced || powerprofilesctl set power-saver
(( fail )) && { echo "Something failed — undo: sudo bash $(dirname "$0")/ppd-fix-rollback.sh"; exit 1; }
echo "OK. If EPP above did not change between power-saver and balanced, tell Claude (asusd link not working)."
