#!/bin/bash

DEST="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents"
MAIN="$DEST/ui/main.qml"

echo "[+] Removing addon imports and calls..."

sed -i '/import "..\/code\/diary.js" as Diary/d' "$MAIN"
sed -i '/import "..\/code\/dailyState.js" as DailyState/d' "$MAIN"
sed -i '/DailyState.handleWeather/d' "$MAIN"

echo "[+] Removing addon files..."

rm -f "$DEST/code/dailyState.js"
rm -f "$DEST/code/diary.js"
rm -f "$DEST/code/diary_altvers.js"
rm -f "$DEST/code/diaryState.js"

rm -f "$DEST/ui/DiaryDialog.qml"

rm -f "$DEST/ui/config/ConfigDiary.qml"
rm -f "$DEST/ui/config/ConfigLogs.qml"
rm -f "$DEST/ui/config/ConfigEffects.qml"

rm -rf "$DEST/ui/addons"
rm -rf "$DEST/ui/effects"
rm -rf "$DEST/ui/images"

echo "[+] Restarting Plasma..."
plasmareset

echo "Uninstalled."
