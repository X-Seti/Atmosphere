#!/bin/bash

# Test the diary logging functionality by creating a mock environment
echo "Testing diary logging functionality..."

# Create the diary file in the expected location
DIARY_FILE="/tmp/daily_weather_diary.txt"

# Check if the diary file exists
if [ -f "$DIARY_FILE" ]; then
    echo "Diary file exists at $DIARY_FILE"
    echo "Contents:"
    cat "$DIARY_FILE"
else
    echo "Diary file does not exist at $DIARY_FILE"
fi

# Create a test entry using the same approach as the widget
TEST_ENTRY="Test Entry $(date '+%a, %d %b %Y')
Weather: sunny
Temperature: 22°C
Humidity: 45%
Pressure: 1013 hPa

Test note for diary logging.

"

# Ensure directory exists and append the test entry
mkdir -p "$(dirname "$DIARY_FILE")"
echo -e "$TEST_ENTRY" >> "$DIARY_FILE"

echo "Test entry added to $DIARY_FILE"
echo "Updated contents:"
cat "$DIARY_FILE"