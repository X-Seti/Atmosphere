#!/usr/bin/env bash

WIDGET="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"
MAINQML="$WIDGET/contents/ui/main.qml"

echo "=== Weather Widget Plus Addon Verifier ==="

fail=0

# --- Files ---
echo "[1] Checking addon files..."
for f in \
  "$WIDGET/contents/code/diary.js" \
  "$WIDGET/contents/code/dailyState.js"
do
  if [[ -f "$f" ]]; then
    echo "  ✓ $f"
  else
    echo "  ✗ MISSING: $f"
    fail=1
  fi
done

# --- Imports ---
echo "[2] Checking imports in main.qml..."

grep -q 'import "../code/diary.js" as Diary' "$MAINQML" \
  && echo "  ✓ diary import" \
  || { echo "  ✗ diary import missing"; fail=1; }

grep -q 'import "../code/dailyState.js" as DailyState' "$MAINQML" \
  && echo "  ✓ dailyState import" \
  || { echo "  ✗ dailyState import missing"; fail=1; }

# --- Hook ---
echo "[3] Checking function hook..."

grep -q 'DailyState.handleWeather' "$MAINQML" \
  && echo "  ✓ hook present" \
  || { echo "  ✗ hook missing"; fail=1; }

# --- Duplicate imports ---
echo "[4] Checking duplicate imports..."

diaryCount=$(grep -c 'import "../code/diary.js" as Diary' "$MAINQML")
stateCount=$(grep -c 'import "../code/dailyState.js" as DailyState' "$MAINQML")

if [[ $diaryCount -gt 1 || $stateCount -gt 1 ]]; then
  echo "  ✗ duplicate imports detected"
  fail=1
else
  echo "  ✓ no duplicate imports"
fi

# --- Result ---
if [[ $fail -eq 0 ]]; then
  echo "=== Verification OK ==="
else
  echo "=== Verification FAILED ==="
fi

exit $fail
