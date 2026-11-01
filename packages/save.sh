#!/usr/bin/env bash
# Save the list of apps installed on purpose (not their dependencies), to reinstall after a reformat.
#
#   ./packages/save.sh       refresh pacman.txt and aur.txt
#
# Reinstall on a fresh CachyOS:
#   sudo pacman -S --needed - < packages/pacman.txt
#   paru -S --needed - < packages/aur.txt
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
pacman -Qqen > pacman.txt
pacman -Qqem > aur.txt
echo "saved $(wc -l < pacman.txt) pacman + $(wc -l < aur.txt) AUR packages"
