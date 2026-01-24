#!/bin/bash

set -e

SRC="$(pwd)/addons/contents"
DEST="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents"
MAIN="$DEST/ui/main.qml"

BACKUP="$DEST.BACKUP.$(date +%F-%H%M)"

echo "== Weather Widget Plus Addon Installer =="

echo "[+] Backing up existing contents to:"
echo "    $BACKUP"
cp -a "$DEST" "$BACKUP"

echo "[+] Installing addon files..."
cp -a "$SRC/code/"* "$DEST/code/"
cp -a "$SRC/ui/"*   "$DEST/ui/"
cp -a "$SRC/config/"* "$DEST/config/"

echo "[+] Patching imports..."

# only add imports if not already present
grep -q 'dailyState.js' "$MAIN" || sed -i '/import "..\/code\/unit-utils.js"/a \
import "../code/diary.js" as Diary\nimport "../code/dailyState.js" as DailyState' "$MAIN"

echo "[+] Patching function call..."

grep -q 'DailyState.handleWeather' "$MAIN" || sed -i '/refreshTooltipSubText()/a \
        DailyState.handleWeather(currentWeatherModel, currentPlace)' "$MAIN"

echo "[+] Restarting Plasma..."
plasmareset

echo "========================================"
echo "Addon installed."
echo "Backup stored at:"
echo "$BACKUP"
echo "========================================"
