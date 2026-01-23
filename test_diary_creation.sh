#!/bin/bash

# Test script to simulate diary entry creation

echo "Creating test diary entries..."

# Create test diary entries with different formats
DATE=$(date +"%a, %d %b %Y")

echo "Test 1: Creating entry with Option 1 format (separate lines)"
ENTRY1="$DATE
Weather: Sunny
Temperature: 22°C
Humidity: 65%
Pressure: 1013 hPa

Test note for option 1

"

echo -e "$ENTRY1" > /tmp/test_diary/daily_weather_diary_option1.txt

echo "Test 2: Creating entry with Option 2 format (combined lines)"
ENTRY2="$DATE
Weather: Sunny - Temperature: 22°C
Humidity: 65% - Pressure: 1013 hPa

Test note for option 2

"

echo -e "$ENTRY2" > /tmp/test_diary/daily_weather_diary_option2.txt

echo "Test 3: Creating entry with no data"
ENTRY3="$DATE
Weather: Cloudy
Temperature: 15°C
Humidity: 80%
Pressure: 998 hPa

no data entered!

"

echo -e "$ENTRY3" > /tmp/test_diary/daily_weather_diary_empty.txt

echo "Test diary entries created in /tmp/test_diary/"
echo ""
echo "Contents of Option 1 diary entry:"
cat /tmp/test_diary/daily_weather_diary_option1.txt
echo ""
echo "Contents of Option 2 diary entry:"
cat /tmp/test_diary/daily_weather_diary_option2.txt
echo ""
echo "Contents of Empty diary entry:"
cat /tmp/test_diary/daily_weather_diary_empty.txt