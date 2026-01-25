#!/bin/bash
set -e

DEST="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents"
MAIN="$DEST/ui/main.qml"

echo "== Uninstalling Weather Widget Plus Addon =="

echo "[+] Removing hook from main.qml..."
sed -i '/DailyState.handleWeather(currentWeatherModel, currentPlace)/d' "$MAIN"

echo "[+] Removing imports from main.qml..."
sed -i '/import "..\/code\/diary.js" as Diary/d' "$MAIN"
sed -i '/import "..\/code\/dailyState.js" as DailyState/d' "$MAIN"

echo "[+] Removing addon JS files..."
rm -f "$DEST/code/dailyState.js"
rm -f "$DEST/code/diary.js"
rm -f "$DEST/code/diary_altvers.js"
rm -f "$DEST/code/diaryState.js"

echo "[+] Removing addon UI files..."
rm -f "$DEST/ui/DiaryDialog.qml"
rm -f "$DEST/ui/config/ConfigDiary.qml"
rm -f "$DEST/ui/config/ConfigLogs.qml"
rm -f "$DEST/ui/config/ConfigEffects.qml"

echo "[+] Removing addon config..."
rm -f "$DEST/config/config.qml"
rm -f "$DEST/config/main.xml"

echo "[+] Restarting Plasma..."
plasmareset

echo "== Uninstall complete =="
