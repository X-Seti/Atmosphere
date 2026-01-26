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

if [[ ! -d "$ADDON_ROOT/contents" ]]; then
  echo "❌ addons/contents missing"
  exit 1
fi

# -----------------------------
# Backup
# -----------------------------
echo "[+] Backing up main.qml"
cp "$MAINQML" "$BACKUP"

# -----------------------------
# Install addon files
# -----------------------------
echo "[+] Installing addon files"
rsync -av "$ADDON_ROOT/contents/" "$PLASMOID/contents/"

# -----------------------------
# Ensure imports
# -----------------------------
ensure_import() {
  local line="$1"
  local anchor='import "../code/unit-utils.js"'

  if grep -Fq "$line" "$MAINQML"; then
    echo "  = import exists: $line"
  else
    sed -i "/$anchor/a $line" "$MAINQML"
    echo "  + added import: $line"
  fi
}

echo "[+] Ensuring imports"
ensure_import 'import "../code/diary.js" as Diary'
ensure_import 'import "../code/dailyState.js" as DailyState'

# -----------------------------
# Ensure hook
# -----------------------------
HOOK='var didLog = DailyState.handleWeather(currentWeatherModel, currentPlace, plasmoid.configuration.lastLoggedDate)
        if (didLog) {
            plasmoid.configuration.lastLoggedDate = new Date().toISOString().slice(0,10)
            dbgprint("Diary: logged new day")
        }'

if grep -Fq "DailyState.handleWeather" "$MAINQML"; then
  echo "[=] Hook already present"
else
  echo "[+] Injecting hook"

  awk -v hook="$HOOK" '
    /function dataLoadedFromInternet\(\)/ { inFunc=1 }
    inFunc && /updateCompactItem\(\)/ && !done {
        print
        print "        " hook
        done=1
        next
    }
    { print }
  ' "$MAINQML" > "$MAINQML.tmp"

  mv "$MAINQML.tmp" "$MAINQML"
fi

if ! grep -q "=== DIARY LOGGING - First Patch ===" "$MAINQML"; then
  sed -i '/dbgprint("meteogramModelChanged:" \+ meteogramModelChanged)/,/saveToCache()/{
    /saveToCache()/i\
   // - DIARY LOGGING - First Patch\
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
            showDiaryEntryDialog({\
                temperature: currentWeatherModel.temperature,\
                humidity: currentWeatherModel.humidity,\
                pressureHpa: currentWeatherModel.pressureHpa,\
                condition: "Weather condition"\
            })\
            plasmoid.configuration.lastLoggedDate = today\
        }\
  }' "$MAINQML"
else
  echo "Patch 1 already applied"
fi


# -----------------------------
# Verify
# -----------------------------
echo "[+] Verifying"

grep -q 'import "../code/diary.js"' "$MAINQML" || { echo "❌ diary import missing"; exit 1; }
grep -q 'import "../code/dailyState.js"' "$MAINQML" || { echo "❌ dailyState import missing"; exit 1; }
grep -q 'DailyState.handleWeather' "$MAINQML" || { echo "❌ hook missing"; exit 1; }

echo "✓ Imports OK"
echo "✓ Hook OK"

# -----------------------------
# Restart Plasma
# -----------------------------
echo "[+] Restarting Plasma"
kquitapp6 plasmashell && plasmashell &

echo "== Install complete =="
