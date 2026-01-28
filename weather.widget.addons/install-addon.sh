#!/usr/bin/env bash
set -e

PLASMOID="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
MAINQML="$PLASMOID/contents/ui/main.qml"
BACKUP="$MAINQML.bak.$(date +%s)"

ADDON_ROOT="$(cd "$(dirname "$0")" && pwd)/addons"

echo "== Weather Widget Plus Addon Installer =="

# -----------------------------
# Sanity checks
# -----------------------------
if [[ ! -d "$PLASMOID" ]]; then
  echo "❌ Plasmoid not found:"
  echo "   $PLASMOID"
  exit 1
fi

if [[ ! -f "$MAINQML" ]]; then
  echo "❌ main.qml not found:"
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

cp -r "$ADDON_ROOT/ui/gui/"* "$PLASMOID/contents/ui/gui/"
cp -r "$ADDON_ROOT/code/"* "$PLASMOID/contents/code/"
cp -r "$ADDON_ROOT/ui/config/"* "$PLASMOID/contents/ui/config/"

# -----------------------------
# Patch main.qml
# -----------------------------
echo "[+] Patching main.qml"

# 1) Ensure DiaryUI import
grep -q 'import "gui" as DiaryUI' "$MAINQML" || \
sed -i '/^import /a import "gui" as DiaryUI' "$MAINQML"

# 2) Ensure diary js imports
grep -q 'import "../code/diary.js"' "$MAINQML" || \
sed -i '/^import /a import "../code/diary.js" as Diary' "$MAINQML"

grep -q 'import "../code/dailyState.js"' "$MAINQML" || \
sed -i '/^import /a import "../code/dailyState.js" as State' "$MAINQML"

# 3) Insert DiaryDialog object (before first Timer)
if ! grep -q 'DiaryUI.DiaryDialog' "$MAINQML"; then
  sed -i '/^ *Timer {/i\
    // Import DiaryDialog\
    DiaryUI.DiaryDialog {\
        id: diaryDialog\
    }\
' "$MAINQML"
fi

# 4) Insert diary logging hook (only once)
if ! grep -q '=== DIARY LOGGING First Patch ===' "$MAINQML"; then
  sed -i '/updateLastReloadedText()/a\
        // === DIARY LOGGING First Patch ===\
        console.log("DEBUG: Checking diary conditions - diaryEnabled:", diaryLoggingEnabled, "weatherModel exists:", !!currentWeatherModel)\
        if (!currentWeatherModel || currentWeatherModel.temperature === -9999) {\
            console.log("DEBUG: Weather model not ready - exists:", !!currentWeatherModel, "temp:", currentWeatherModel ? currentWeatherModel.temperature : "N/A")\
            dbgprint("Diary: weather model not ready yet")\
            saveToCache()\
            return\
        }\
\
        var today = new Date().toISOString().slice(0, 10)\
        console.log("DEBUG: Date check - today:", today, "lastLogged:", plasmoid.configuration.lastLoggedDate || "(never)", "different:", (plasmoid.configuration.lastLoggedDate || "") !== today)\
        if (diaryLoggingEnabled && (plasmoid.configuration.lastLoggedDate || "") !== today) {\
            console.log("DEBUG: Opening diary dialog!")\
            diaryDialog.showDiaryEntryDialog({\
                temperature: currentWeatherModel.temperature,\
                humidity: currentWeatherModel.humidity,\
                pressureHpa: currentWeatherModel.pressureHpa,\
                condition: currentWeatherModel.condition\
            })\
            plasmoid.configuration.lastLoggedDate = today\
        }\
' "$MAINQML"


# -----------------------------
# Verify
# -----------------------------
grep -q 'import "../code/diary.js"' "$MAINQML" || { echo "❌ diary import missing"; exit 1; }
grep -q 'import "../code/dailyState.js"' "$MAINQML" || { echo "❌ dailyState import missing"; exit 1; }
grep -q 'DiaryUI.DiaryDialog' "$MAINQML" || { echo "❌ DiaryDialog block missing"; exit 1; }
grep -q '=== DIARY LOGGING First Patch ===' "$MAINQML" || { echo "❌ hook missing"; exit 1; }

echo "✓ Imports OK"
echo "✓ Hook OK"

# -----------------------------
# Restart Plasma
# -----------------------------
echo "[+] Restarting Plasma"
kquitapp6 plasmashell && plasmashell &

echo "== Install complete =="
