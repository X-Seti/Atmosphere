#!/bin/bash
set -e

SRC="$(pwd)/addons/contents"
DEST="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents"
MAIN="$DEST/ui/main.qml"

BACKUP="$DEST.BACKUP.$(date +%F-%H%M)"

echo "== Installing Weather Widget Plus Addon =="

echo "[+] Backup:"
echo "    $BACKUP"
cp -a "$DEST" "$BACKUP"

echo "[+] Copying addon contents..."
cp -a "$SRC/code/."   "$DEST/code/"
cp -a "$SRC/ui/."     "$DEST/ui/"
cp -a "$SRC/config/." "$DEST/config/"

echo "[+] Patching imports..."

# add imports only if missing
grep -q 'dailyState.js' "$MAIN" || sed -i '/import "..\/code\/unit-utils.js"/a \
import "../code/diary.js" as Diary\nimport "../code/dailyState.js" as DailyState' "$MAIN"

echo "[+] Patching hook..."

grep -q 'DailyState.handleWeather(currentWeatherModel, currentPlace)' "$MAIN" || sed -i '/refreshTooltipSubText()/a \
        DailyState.handleWeather(currentWeatherModel, currentPlace)' "$MAIN"

echo "[+] Restarting Plasma..."
plasmareset

echo "== Install complete =="
