#!/bin/bash

W="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents"
MAIN="$W/ui/main.qml"
DIARY="$HOME/daily_weather_diary.txt"

echo "=== Weather Widget Plus Addon Verifier ==="

echo
echo "[1] Checking addon files..."

for f in \
"$W/code/dailyState.js" \
"$W/code/diary.js" \
"$W/ui/DiaryDialog.qml" \
"$W/ui/config/ConfigDiary.qml"
do
    if [ -f "$f" ]; then
        echo "  ✓ $f"
    else
        echo "  ✗ MISSING: $f"
    fi
done

echo
echo "[2] Checking imports in main.qml..."

grep -q 'import "../code/diary.js" as Diary' "$MAIN" \
  && echo "  ✓ diary import" || echo "  ✗ diary import missing"

grep -q 'import "../code/dailyState.js" as DailyState' "$MAIN" \
  && echo "  ✓ dailyState import" || echo "  ✗ dailyState import missing"

echo
echo "[3] Checking function hook..."

grep -q 'DailyState.handleWeather(currentWeatherModel, currentPlace)' "$MAIN" \
  && echo "  ✓ hook present" || echo "  ✗ hook missing"

echo
echo "[4] Checking diary file..."

if [ -f "$DIARY" ]; then
    echo "  ✓ $DIARY exists"
else
    echo "  ⚠ creating $DIARY"
    touch "$DIARY"
fi

if [ -w "$DIARY" ]; then
    echo "  ✓ diary writable"
else
    echo "  ✗ diary NOT writable"
fi

echo
echo "[5] Checking QML syntax hazards..."

if grep -q 'let today' "$MAIN"; then
    echo "  ✗ found 'let' (QML will break)"
else
    echo "  ✓ no 'let' usage"
fi

echo
echo "=== Verification Complete ==="
