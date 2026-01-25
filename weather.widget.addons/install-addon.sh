#!/usr/bin/env bash
set -e

WIDGET="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
ADDON_DIR="$(cd "$(dirname "$0")" && pwd)/addons"
MAINQML="$WIDGET/contents/ui/main.qml"
STAMP=$(date +%Y%m%d-%H%M%S)

echo "== Installing Weather Widget Plus Addon =="

if [[ ! -f "$MAINQML" ]]; then
  echo "main.qml not found at:"
  echo "   $MAINQML"
  exit 1
fi

echo "[+] Backup:"
BACKUP="$WIDGET/contents.BACKUP.$STAMP"
cp -a "$WIDGET/contents" "$BACKUP"
echo "    $BACKUP"

echo "[+] Installing addon files..."
rsync -av "$ADDON_DIR/contents/" "$WIDGET/contents/"

echo "[+] Checking imports..."

if ! grep -q 'import "../code/diary.js" as Diary' "$MAINQML"; then

  echo "[+] applying import ../code/diary"
  sed -i '/import "..\/code\/unit-utils.js"/a import "../code/diary.js" as Diary' "$MAINQML"
fi

if ! grep -q 'import "../code/dailyState.js" as DailyState' "$MAINQML"; then
   echo "[+] applying import ../code/dailyState"
  sed -i '/import "..\/code\/diary.js"/a import "../code/dailyState.js" as DailyState' "$MAINQML"
fi

echo "[+] Checking hook..."

if grep -q 'Diary: logged new day' "$MAINQML"; then
  echo "    Hook already present"
else
  echo "    -> Inserting hook"

echo "[+] applying function dataLoadedFromInternet() attemped 3"

# Insert marker
sed -i '/updateCompactItem()/a XXX_HOOK_MARKER_XXX' "$MAINQML"

# Replace marker with real code (using sed with N or just another pass)
sed -i 's/XXX_HOOK_MARKER_XXX/\
\
        var didLog = DailyState.handleWeather(\
            currentWeatherModel,\
            currentPlace,\
            plasmoid.configuration.lastLoggedDate\
        )\
\
        if (didLog) {\
            plasmoid.configuration.lastLoggedDate = new Date().toISOString().slice(0,10)\
            dbgprint("Diary: logged new day")\
        }\
/g' "$MAINQML"

fi

echo "[+] Verifying syntax..."
if grep -q 'Script import qualifiers must be unique' <(qmlcachegen "$MAINQML" 2>&1); then
  echo "QML import error detected — restoring backup"
  rm -rf "$WIDGET/contents"
  cp -a "$BACKUP" "$WIDGET/contents"
  exit 1
fi

echo "[+] Restarting Plasma..."
kquitapp6 plasmashell || true
sleep 2
plasmashell &

echo "== Install complete =="
echo "If widget shows C--, run: restore2stock.sh"
