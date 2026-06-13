#!/usr/bin/env bash
set -e

echo "== Weather Widget Plus Addon Uninstaller =="

# Auto-detect plasmoid location
PLASMOID=""
CANDIDATES=(
    "$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
    "$HOME/.local/share/plasma/plasmoids/org.kde.weatherWidget-3"
    "/usr/share/plasma/plasmoids/weather.widget.plus"
    "/usr/share/plasma/plasmoids/org.kde.weatherWidget-3"
)
for candidate in "${CANDIDATES[@]}"; do
    if [[ -d "$candidate" ]]; then
        PLASMOID="$candidate"
        echo "[+] Found widget at: $PLASMOID"
        break
    fi
done

if [[ -z "$PLASMOID" ]]; then
    echo "✗ Widget not found - nothing to uninstall"
    exit 1
fi

MAINQML="$PLASMOID/contents/ui/main.qml"

# Restore from backup if available
LATEST_BAK=$(ls -t "${MAINQML}".bak.* 2>/dev/null | head -1)
if [[ -n "$LATEST_BAK" ]]; then
    echo "[+] Restoring from backup: $LATEST_BAK"
    cp "$LATEST_BAK" "$MAINQML"
else
    echo "[!] No backup found - removing injected blocks manually"

    # Remove diary logging block
    sed -i '/=== DIARY LOGGING ===/,/plasmoid.configuration.lastPromptDate = _today/d' "$MAINQML"
    # Also catch old sentinel
    sed -i '/=== DIARY LOGGING First Patch ===/,/plasmoid.configuration.lastLoggedDate = today/d' "$MAINQML"
    # Remove DiaryDialog block
    sed -i '/\/\/ Import DiaryDialog/,/^    }$/d' "$MAINQML"
    # Remove diary properties
    sed -i '/property bool diaryLoggingEnabled/d' "$MAINQML"
    sed -i '/property bool diaryAutoPopupEnabled/d' "$MAINQML"
    sed -i '/property int  diaryAutoPopupHour/d' "$MAINQML"
    # Remove imports
    sed -i '/import "..\/code\/diary.js"/d' "$MAINQML"
    sed -i '/import "..\/code\/dailyState.js"/d' "$MAINQML"
    sed -i '/import "..\/code\/weatherMapping.js"/d' "$MAINQML"
    sed -i '/import "gui" as DiaryUI/d' "$MAINQML"
fi

# Remove addon files
rm -f "$PLASMOID/contents/code/diary.js"
rm -f "$PLASMOID/contents/code/dailyState.js"
rm -f "$PLASMOID/contents/code/weatherMapping.js"
rm -f "$PLASMOID/contents/ui/gui/DiaryDialog.qml"
rm -f "$PLASMOID/contents/ui/config/ConfigDiary.qml"
rm -f "$PLASMOID/contents/ui/config/ConfigLogs.qml"

echo "[+] Addon removed"

echo "[+] Restarting Plasma"
kquitapp6 plasmashell 2>/dev/null && plasmashell &

echo "== Uninstall complete =="
