#!/usr/bin/env bash
# Switch the SDDM login screen to the Silent theme (AUR: sddm-silent-theme).
# Only the theme changes: SDDM, its X11 display server and the session list stay as they are.
# Usage: sudo bash apply.sh [preset]   e.g. default, nord, catppuccin-mocha (see /usr/share/sddm/themes/silent/configs)
set -euo pipefail

THEME_DIR=/usr/share/sddm/themes/silent
CONF=/etc/sddm.conf.d/theme.conf
META="$THEME_DIR/metadata.desktop"
PRESET="${1:-default}"
STAMP=$(date +%Y%m%d-%H%M%S)

[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
[[ -f "$THEME_DIR/Main.qml" ]] || { echo "Silent theme not installed"; exit 1; }
[[ -f "$THEME_DIR/configs/$PRESET.conf" ]] || { echo "No preset '$PRESET'"; ls "$THEME_DIR/configs"; exit 1; }

cp -a "$CONF" "$CONF.before-silent.$STAMP"
cp -a "$META" "$META.before-silent.$STAMP"
echo "Backups: $CONF.before-silent.$STAMP, $META.before-silent.$STAMP"

# Pick the preset (metadata.desktop is a pacman backup= file, so upgrades keep this)
sed -i "s|^ConfigFile=.*|ConfigFile=configs/$PRESET.conf|" "$META"

cat > "$CONF" <<CFG
[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=$THEME_DIR/components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=silent
CFG

# Verify: SDDM must now resolve to the silent theme with our settings
if grep -q '^Current=silent' "$CONF" && grep -q "^ConfigFile=configs/$PRESET.conf" "$META"; then
  echo "OK: login screen set to Silent ($PRESET). Takes effect at next logout/reboot."
  echo "Nothing was restarted. Undo: sudo bash $(dirname "$0")/rollback.sh"
else
  echo "Verification failed, restoring backups"
  cp -a "$CONF.before-silent.$STAMP" "$CONF"
  cp -a "$META.before-silent.$STAMP" "$META"
  exit 1
fi
