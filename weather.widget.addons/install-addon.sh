#!/usr/bin/env bash
set -e

ADDON_ROOT="$(cd "$(dirname "$0")" && pwd)/addons"

echo "== Weather Widget Plus Addon Installer =="

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

# -----------------------------
# Sanity checks
# -----------------------------
if [[ -z "$PLASMOID" ]]; then
  echo "✗ Base widget not found in any known location."
  echo ""
  echo "Searched:"
  for c in "${CANDIDATES[@]}"; do echo "   $c"; done
  echo ""
  echo "Install Weather Widget Plus first:"
  echo "  yay -S plasma6-applets-weather-widget-3-git"
  echo "  or: KDE Store https://store.kde.org/p/2281196"
  exit 1
fi

MAINQML="$PLASMOID/contents/ui/main.qml"
BACKUP="$MAINQML.bak.$(date +%s)"

if [[ ! -f "$MAINQML" ]]; then
  echo "✗ main.qml not found:"
  echo "   $MAINQML"
  exit 1
fi

# -----------------------------
# Backup
# -----------------------------
echo "[+] Backing up main.qml to:"
echo "    $BACKUP"
cp "$MAINQML" "$BACKUP"

# -----------------------------
# Install addon files
# -----------------------------
echo "[+] Installing addon files"
mkdir -p "$PLASMOID/contents/ui/gui"
mkdir -p "$PLASMOID/contents/code"
mkdir -p "$PLASMOID/contents/ui/config"

cp -r "$ADDON_ROOT/contents/ui/gui/"* "$PLASMOID/contents/ui/gui/"
cp -r "$ADDON_ROOT/contents/code/"* "$PLASMOID/contents/code/"
cp -r "$ADDON_ROOT/contents/ui/config/"* "$PLASMOID/contents/ui/config/"

# -----------------------------
# Patch main.qml
# -----------------------------
echo "[+] Patching main.qml"

# 0) Remove backtick template literal comments - QML parser rejects them even commented out
sed -i '/`.*\${.*}`/d' "$MAINQML"
echo "    ✓ Removed backtick template literal comments"

# 1) Ensure DiaryUI import
grep -q 'import "gui" as DiaryUI' "$MAINQML" || \
sed -i '/^import /a import "gui" as DiaryUI' "$MAINQML"

# 2) Ensure diary js imports
grep -q 'import "../code/diary.js"' "$MAINQML" || \
sed -i '/^import /a import "../code/diary.js" as Diary' "$MAINQML"

grep -q 'import "../code/dailyState.js"' "$MAINQML" || \
sed -i '/^import /a import "../code/dailyState.js" as State' "$MAINQML"

grep -q 'import "../code/weatherMapping.js"' "$MAINQML" || \
sed -i '/^import /a import "../code/weatherMapping.js" as WeatherMap' "$MAINQML"

# 3a) Insert diary properties (only once)
if ! grep -q 'diaryLoggingEnabled' "$MAINQML"; then
  sed -i '/^PlasmoidItem {/a\
    property bool diaryLoggingEnabled: plasmoid.configuration.diaryLoggingEnabled !== undefined ? plasmoid.configuration.diaryLoggingEnabled : true\
    property bool diaryAutoPopupEnabled: plasmoid.configuration.diaryAutoPopupEnabled !== undefined ? plasmoid.configuration.diaryAutoPopupEnabled : false\
    property int  diaryAutoPopupHour: plasmoid.configuration.diaryAutoPopupHour !== undefined ? plasmoid.configuration.diaryAutoPopupHour : 20\
' "$MAINQML"
fi

# 3b) Insert DiaryDialog object (before first Timer)
if ! grep -q 'DiaryUI.DiaryDialog' "$MAINQML"; then
  sed -i '/^ *Timer {/i\
    // Import DiaryDialog\
    DiaryUI.DiaryDialog {\
        id: diaryDialog\
    }\
' "$MAINQML"
fi

# 4) Insert diary logging hook (only once)
if ! grep -q '=== DIARY LOGGING ===' "$MAINQML"; then
  sed -i '/updateLastReloadedText()/a\
        // === DIARY LOGGING ===\
        if (!currentWeatherModel || currentWeatherModel.temperature === -9999) {\
            dbgprint("Diary: weather model not ready yet")\
            saveToCache()\
            return\
        }\
        var _today = new Date().toISOString().slice(0, 10)\
        if (diaryLoggingEnabled) {\
            var _shouldShow = false\
            if (diaryAutoPopupEnabled) {\
                _shouldShow = State.shouldPrompt(\
                    { lastPromptDate: plasmoid.configuration.lastPromptDate || "" },\
                    diaryAutoPopupHour\
                )\
            } else {\
                _shouldShow = (plasmoid.configuration.lastLoggedDate || "") !== _today\
            }\
            if (_shouldShow) {\
                var _cond = WeatherMap.getWeatherDescription(currentWeatherModel.iconName, currentPlace.providerId)\
                diaryDialog.showDiaryEntryDialog({\
                    temperature: currentWeatherModel.temperature,\
                    humidity: currentWeatherModel.humidity,\
                    pressureHpa: currentWeatherModel.pressureHpa,\
                    condition: _cond\
                })\
                plasmoid.configuration.lastLoggedDate = _today\
                plasmoid.configuration.lastPromptDate = _today\
            }\
        }\
' "$MAINQML"
fi

# -----------------------------
# Verify
# -----------------------------
grep -q 'import "../code/diary.js"' "$MAINQML" || { echo "✗ diary import missing"; exit 1; }
grep -q 'import "../code/dailyState.js"' "$MAINQML" || { echo "✗ dailyState import missing"; exit 1; }
grep -q 'import "../code/weatherMapping.js"' "$MAINQML" || { echo "✗ weatherMapping import missing"; exit 1; }
grep -q 'DiaryUI.DiaryDialog' "$MAINQML" || { echo "✗ DiaryDialog block missing"; exit 1; }
grep -q '=== DIARY LOGGING ===' "$MAINQML" || { echo "✗ hook missing"; exit 1; }

echo "✓ Imports OK"
echo "✓ Hook OK"

# -----------------------------
# Restart Plasma
# -----------------------------
echo "[+] Restarting Plasma"
kquitapp6 plasmashell && plasmashell &

echo "== Install complete =="
