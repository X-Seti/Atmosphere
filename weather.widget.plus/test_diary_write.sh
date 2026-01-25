#!/bin/bash

# Test script to check if diary file can be written

DIARY_FILE="/home/x2/daily_weather_diary.txt"

echo "Testing diary file write..."
echo "Target file: $DIARY_FILE"

# Check if file exists
if [ -f "$DIARY_FILE" ]; then
    echo "✓ File exists"
    ls -lh "$DIARY_FILE"
else
    echo "✗ File does not exist"
fi

# Check if directory is writable
DIR=$(dirname "$DIARY_FILE")
if [ -w "$DIR" ]; then
    echo "✓ Directory $DIR is writable"
else
    echo "✗ Directory $DIR is NOT writable"
fi

# Try to write a test entry
echo "" >> "$DIARY_FILE"
echo "=== TEST ENTRY $(date) ===" >> "$DIARY_FILE"
echo "This is a test entry" >> "$DIARY_FILE"
echo "" >> "$DIARY_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Successfully wrote test entry"
    echo ""
    echo "Last 10 lines of file:"
    tail -10 "$DIARY_FILE"
else
    echo "✗ Failed to write test entry"
fi
