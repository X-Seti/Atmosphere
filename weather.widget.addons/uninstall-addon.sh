#!/usr/bin/env bash

WIDGET="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
MAINQML="$WIDGET/contents/ui/main.qml"

echo "== Uninstalling Weather Widget Plus Addon =="

# --- Remove imports ---
sed -i \
  -e '/import "..\/code\/diary.js" as Diary/d' \
  -e '/import "..\/code\/dailyState.js" as DailyState/d' \
  "$MAINQML"

# --- Remove hook block ---
sed -i '/var didLog = DailyState.handleWeather/,/dbgprint("Diary: logged new day")/d' "$MAINQML"

# --- Remove addon files ---
rm -f "$WIDGET/contents/code/diary.js"
rm -f "$WIDGET/contents/code/dailyState.js"

# --- Restart Plasma ---
if command -v kquitapp6 >/dev/null; then
  kquitapp6 plasmashell && plasmashell &
else
  kquitapp5 plasmashell && plasmashell &
fi

echo "== Uninstall complete =="
