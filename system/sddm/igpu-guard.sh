#!/usr/bin/env bash
# Keep SDDM's Xorg on the AMD iGPU so the RTX 4060 can runtime-suspend after login.
# (SDDM leaves its Xorg + greeter running on VT2 during the niri session; on stock
# autodetection both hold /dev/nvidia* open and the dGPU never sleeps.)
# Runs before every SDDM start (sddm.service ExecStartPre, installed by igpu-apply.sh).
# Fail-safe: the Xorg config is written only when the internal panel is lit by an amdgpu
# card (Hybrid/Integrated). In MUX dGPU mode, or if anything is unclear, it is removed
# and SDDM falls back to stock autodetection.
# Dry run (prints what it would do, touches nothing): DRYRUN=1 bash igpu-guard.sh
CONF=/etc/X11/xorg.conf.d/20-sddm-igpu-only.conf

busid=""
for _ in {1..10}; do   # amdgpu may still be binding this early in boot: wait up to 5 s
  for s in /sys/class/drm/card*-eDP-*/status; do
    [[ "$(cat "$s" 2>/dev/null)" == connected ]] || continue
    card=${s#/sys/class/drm/}; card=${card%%-*}                  # card2-eDP-2 -> card2
    [[ "$(basename "$(readlink -f /sys/class/drm/$card/device/driver)")" == amdgpu ]] || continue
    pci=$(basename "$(readlink -f /sys/class/drm/$card/device)")  # 0000:65:00.0
    IFS=':.' read -r _dom bus dev fn <<<"$pci"
    busid=$(printf 'PCI:%d:%d:%d' "0x$bus" "0x$dev" "0x$fn")      # Xorg wants decimal
    break 2
  done
  sleep 0.5
done

if [[ -z "$busid" ]]; then
  echo "sddm-igpu-guard: panel not on amdgpu (MUX dGPU mode?) -> stock Xorg autodetection"
  [[ -n "$DRYRUN" ]] || rm -f "$CONF"
  exit 0
fi

cfg='# Written by sddm-igpu-guard (~/.config/nvim/system/sddm). Do not edit; undo: igpu-rollback.sh
Section "ServerFlags"
    Option "AutoAddGPU" "false"
    Option "AutoBindGPU" "false"
EndSection

Section "Device"
    Identifier "iGPU"
    Driver "amdgpu"
    BusID "'$busid'"
EndSection'

echo "sddm-igpu-guard: panel on amdgpu $busid -> SDDM Xorg pinned to iGPU"
if [[ -n "$DRYRUN" ]]; then echo "$cfg"; else
  mkdir -p "${CONF%/*}"; printf '%s\n' "$cfg" > "$CONF"
fi
