# Changelog - X-Seti Weather Diary Addon

All notable changes to the X-Seti Weather Diary addon will be documented in this file.

## [Unreleased]

### Added
- Five distinct diary entry formats to choose from:
  - **Legacy** - Original multi-line format (preserves compatibility with existing logs)
  - **Compact** - Single-line format with dash separators and divider line
  - **Detailed** - Full day names with extended information
  - **Markdown** - Bullet-point format for markdown compatibility
  - **Alternative Date** - Month-first date ordering (e.g., "Sat, January 28, 2026")
- Live format preview in configuration panel showing example of selected layout
- Unified "Weather Diary" configuration tab combining all diary-related settings
- File path browser with directory auto-creation
- Safety checks to prevent log file overwriting (append-only mode)
- Proper date formatting with readable day and month names
- File header auto-creation for new diary files
- Enhanced error handling and logging

### Changed
- Consolidated diary settings from multiple tabs into single "Weather Diary" tab
- Moved log file path configuration from "Logging" tab to "Weather Diary" tab
- Updated dropdown from 3 to 5 layout options
- Improved date/time formatting across all layouts
- Enhanced ConfigDiary.qml with dynamic layout descriptions
- Updated main.xml configuration schema for better organization

### Fixed
- **Critical:** Fixed "Weather: undefined" bug appearing in both DiaryDialog window and log entries
  - Now properly handles missing weather condition data
  - Falls back to "N/A" when condition is unavailable
- **Critical:** Fixed "Show notation log" right-click menu option not working
  - Added missing `executable` parameter to `openLogFile()` function
  - Properly passes executable context from DiaryDialog
- **Critical:** Fixed potential log file overwrite issue
  - Changed from single `>` to double `>>` append operator
  - Added file existence checks before writing
- Fixed date format showing ISO format (YYYY-MM-DD) instead of readable format
- Fixed missing null checks for weather data fields
- Fixed configuration options not appearing in settings panel
- Fixed ConfigDiary not being registered in config.qml

### Removed
- Separate "Logging" configuration tab (merged into "Weather Diary")
- Redundant ConfigLogs.qml file (functionality merged into ConfigDiary.qml)

---

## [Version 10] - 2025-01-25

### Initial Release
- Basic diary logging functionality
- Right-click menu for adding weather notations
- Automatic daily popup reminders
- Basic text editor integration (Kate, Pluma, Custom)
- Temperature, humidity, pressure, and weather condition logging
- Manual note entry support

---

## Format Examples

### Legacy Format (Layout 0)
```
Sat, 24 Jan 2026
Weather: Overcast
Temperature: 6°C
Humidity: 87%
Pressure: 976 hPa

Notes: User notes here

```

### Compact Format (Layout 1)
```
Sat, 24 Jan 2026 12:25 - Weather: Overcast
Temperature: 6°C - Humidity: 87% - Pressure: 976 hPa

Notes: User notes here

-----

```

### Detailed Format (Layout 2)
```
Wednesday, 28 January 2026 12:25 - Weather: Overcast
Temperature: 6°C - Humidity: 87% - Pressure: 976 hPa

Notes: User notes here

```

### Markdown Format (Layout 3)
```
Sat, 24 Jan 2026 22:54
* Weather: Overcast
* Temperature: 6°C
* Humidity: 87%
* Pressure: 976 hPa

Notes: User notes here

```

### Alternative Date Format (Layout 4)
```
Sat, January 28, 2026 15:14
Weather: Overcast
Temperature: 6°C
Humidity: 87%
Pressure: 976 hPa

Notes: User notes here

```

---

## Configuration Changes

### Files Modified
- `contents/code/diary.js` - Date formatting, 5 layouts, safety checks
- `contents/ui/config/ConfigDiary.qml` - Unified settings panel with 5 layouts
- `contents/ui/gui/DiaryDialog.qml` - Fixed undefined condition handling
- `contents/ui/config.qml` - Added Weather Diary tab, removed Logging tab
- `config/main.xml` - Reorganized configuration groups

### Files Added
- None (all changes are modifications to existing files)

### Files Removed
- `contents/ui/config/ConfigLogs.qml` - Merged into ConfigDiary.qml

---

## Upgrade Notes

### From Version 10 to Unreleased
- Existing logs will be preserved (append-only mode ensures no data loss)
- Default layout is set to "Legacy" (Layout 0) to maintain compatibility
- Log file path setting has moved from "Logging" tab to "Weather Diary" tab
- All previous diary entries remain readable and unchanged
- Configuration will automatically migrate to new schema

---

## Known Issues
- None currently

---

## Credits
- **X-Seti Addon:** X-Seti (2025)
- **Weather Widget Plus:** Martin Kotelnik (Original widget)
- **License:** GNU General Public License v2.0 or later

---

## Support
For bug reports and feature requests, please refer to the project documentation.
