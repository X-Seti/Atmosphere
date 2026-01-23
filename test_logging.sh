#!/bin/bash

# Test script to verify that the diary logging functionality works
echo "Testing the logging functionality..."

# Create a test directory
TEST_LOG_DIR="/tmp/weather_test_logs"
mkdir -p "$TEST_LOG_DIR"

# Create a test diary entry
TEST_ENTRY="Test Entry
Weather: Sunny
Temperature: 25°C
Humidity: 60%
Pressure: 1013 hPa

This is a test entry to verify the logging functionality."

# Write the test entry to the diary file
echo -e "$TEST_ENTRY" >> "$TEST_LOG_DIR/daily_weather_diary.txt"

# Check if the file was created and written to
if [ -f "$TEST_LOG_DIR/daily_weather_diary.txt" ]; then
    echo "SUCCESS: Diary file created successfully!"
    echo "Contents of the diary file:"
    cat "$TEST_LOG_DIR/daily_weather_diary.txt"
else
    echo "FAILURE: Diary file was not created!"
fi

echo "Test completed."