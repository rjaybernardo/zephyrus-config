#!/usr/bin/env bash
# Nautilus right-click → Scripts → "Format USB as FAT32".
# Works on the clicked folder/file's drive, or the open folder if nothing is selected.
TARGET=${1:-}
if [[ -z $TARGET ]]; then
  TARGET=$(python3 -c 'import sys,urllib.parse as u;print(u.unquote(u.urlparse(sys.argv[1]).path))' "${NAUTILUS_SCRIPT_CURRENT_URI:-}")
fi
[[ -f $TARGET ]] && TARGET=$(dirname "$TARGET")
MNT=$(findmnt -no TARGET --target "$TARGET")
exec ghostty -e "$HOME/.config/nvim/system/usb-format/format-fat32.sh" "$MNT"
