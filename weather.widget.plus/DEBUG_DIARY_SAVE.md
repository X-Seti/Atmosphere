# Diary Save Debugging

## Changes Made

1. **ConfigDiary.qml** - Added file browser button
   - Click "Browse..." to choose diary file location
   - Changed from "directory" to "file" - now saves to specific file
   - Added help text

2. **main.qml** - Added extensive debugging
   - Logs everything when you click Save
   - Shows actual file path in status message
   - Better error messages

## To Debug Why Nothing Is Saving

### 1. Check Console Logs
Run in terminal:
```bash
journalctl -f | grep -i "save\|diary"
```

Then click Save and look for:
- `SAVE CLICKED`
- `Weather data: {...}`
- `User notes: your text`
- `Log path from config: /home/x2/daily_weather_diary.txt`
- `Calling Diary.appendWeather...`
- `Diary.appendWeather completed`

If you see an error, it will show there.

### 2. Test File Writing Manually
Run the test script:
```bash
./test_diary_write.sh
```

This will:
- Check if file exists
- Check if directory is writable
- Write a test entry
- Show you the last 10 lines

### 3. Check File Permissions
```bash
ls -l /home/x2/daily_weather_diary.txt
touch /home/x2/daily_weather_diary.txt  # Create if doesn't exist
```

### 4. Check diary.js Exists
```bash
ls -l ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/code/diary.js
```

If missing, the save won't work.

### 5. Use File Dialog
In widget settings:
1. Go to Diary tab
2. Click "Browse..."
3. Choose `/home/x2/daily_weather_diary.txt`
4. Click Apply
5. Try saving again

## Expected Console Output

When working correctly:
```
==================== SAVE CLICKED ====================
Weather data: {"temperature":22.5,"humidity":65,"pressureHpa":1013}
User notes: Test entry
Log path from config: /home/x2/daily_weather_diary.txt
Layout type: 0
Executable available: true
Calling Diary.appendWeather...
✓ Diary.appendWeather completed
Data should be saved to: /home/x2/daily_weather_diary.txt
=====================================================
```

## Common Issues

### Issue: "Diary.appendWeather is not a function"
**Fix:** diary.js is missing or not loaded properly

### Issue: "Permission denied"
**Fix:** Run `chmod 666 /home/x2/daily_weather_diary.txt`

### Issue: No errors but file is empty
**Fix:** Check if diary.js appendWeather function is actually writing

### Issue: File doesn't exist
**Fix:** Run `touch /home/x2/daily_weather_diary.txt` to create it

## Quick Test

1. Reload widget: `killall plasmashell; plasmashell &`
2. Open console: `journalctl -f | grep diary`
3. Right-click widget → "Add a weather notation"
4. Type something and click Save
5. Watch console for errors
6. Check file: `cat /home/x2/daily_weather_diary.txt`

The status message now shows where it's saving, so you'll see:
"✅ Saved to: /home/x2/daily_weather_diary.txt"
