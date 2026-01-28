#!/usr/bin/env bash
set -e

PLASMOID="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
MAINQML="$PLASMOID/contents/ui/main.qml"

echo "== Weather Widget Plus Addon Uninstaller =="

if [[ ! -f "$MAINQML" ]]; then
  echo "❌ main.qml not found"
  exit 1
fi

# -----------------------------
# Remove injected patch block
# -----------------------------
sed -i '/=== DIARY LOGGING First Patch ===/,/plasmoid.configuration.lastLoggedDate = today/d' "$MAINQML"

# -----------------------------
# Remove DiaryDialog block
# -----------------------------
sed -i '/\/\/ Import DiaryDialog/,/}/d' "$MAINQML"

# -----------------------------
# Remove imports
# -----------------------------
sed -i '/import "..\/code\/diary.js"/d' "$MAINQML"
sed -i '/import "..\/code\/dailyState.js"/d' "$MAINQML"
sed -i '/import "gui" as DiaryUI/d' "$MAINQML"

# -----------------------------
# Remove addon files
# -----------------------------
rm -f "$PLASMOID/contents/code/diary.js"
rm -f "$PLASMOID/contents/code/dailyState.js"
rm -f "$PLASMOID/contents/ui/gui/DiaryDialog.qml"
rm -f "$PLASMOID/contents/ui/config/ConfigDiary.qml"
rm -f "$PLASMOID/contents/ui/config/ConfigLogs.qml"

echo "[+] Addon files removed"

# -----------------------------
# Restart Plasma
# -----------------------------
echo "[+] Restarting Plasma"
kquitapp6 plasmashell && plasmashell &

echo "== Uninstall complete =="
