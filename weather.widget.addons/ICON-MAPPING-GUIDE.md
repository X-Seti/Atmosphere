# Weather Icon Mapping - Complete Guide

## 📋 Overview

The Weather Widget Plus doesn't store text descriptions of weather - it only stores **icon code numbers**. This new `weatherMapping.js` file translates those numbers into human-readable descriptions like "Clear sky", "Rainy", "Cloudy", etc.

---

## 🔢 Icon Code Reference Tables

### OpenWeatherMap (OWM) Icon Codes

| Code | Description |
|------|-------------|
| **Clear** |
| 1 | Clear sky |
| **Clouds** |
| 2 | Few clouds |
| 3 | Scattered clouds |
| 4 | Broken clouds |
| 5 | Overcast |
| **Rain** |
| 9 | Shower rain |
| 10 | Rain |
| 11 | Thunderstorm |
| 12 | Thunderstorm with rain |
| **Snow** |
| 13 | Snow |
| 14 | Light snow |
| 15 | Heavy snow |
| 16 | Sleet |
| **Atmosphere** |
| 50 | Mist |
| 51 | Fog |
| 52 | Haze |
| 53 | Smoke |
| 54 | Dust |
| 55 | Sand |
| 56 | Volcanic ash |
| 57 | Squalls |
| 58 | Tornado |

---

### Met.no Icon Codes

| Code | Description |
|------|-------------|
| 1 | Clear sky |
| 2 | Fair |
| 3 | Partly cloudy |
| 4 | Cloudy |
| 5 | Rain showers |
| 6 | Rain showers and thunder |
| 7 | Sleet showers |
| 8 | Snow showers |
| 9 | Rain |
| 10 | Heavy rain |
| 11 | Heavy rain and thunder |
| 12 | Sleet |
| 13 | Snow |
| 14 | Snow and thunder |
| 15 | Fog |
| 20 | Sleet showers and thunder |
| 21 | Snow showers and thunder |
| 22 | Rain and thunder |
| 23 | Sleet and thunder |
| 24 | Light rain showers and thunder |
| 25 | Heavy rain showers and thunder |
| 26 | Light sleet showers and thunder |
| 27 | Heavy sleet showers and thunder |
| 28 | Light snow showers and thunder |
| 29 | Heavy snow showers and thunder |
| 30 | Light rain and thunder |
| 31 | Light sleet and thunder |
| 32 | Heavy sleet and thunder |
| 33 | Light snow and thunder |
| 34 | Heavy snow and thunder |
| 40 | Light rain showers |
| 41 | Heavy rain showers |
| 42 | Light sleet showers |
| 43 | Heavy sleet showers |
| 44 | Light snow showers |
| 45 | Heavy snow showers |
| 46 | Light rain |
| 47 | Light sleet |
| 48 | Heavy sleet |
| 49 | Light snow |
| 50 | Heavy snow |

---

### Generic Fallback Mapping

If provider is unknown, uses range-based detection:

| Icon Range | Description |
|------------|-------------|
| 1 | Clear sky |
| 2-5 | Cloudy |
| 9-12 | Rainy |
| 13-16 | Snowy |
| 50-60 | Foggy/Misty |
| Other | Unknown (shows code number) |

---

## 📁 Files Structure

```
addons/
└── code/
    ├── diary.js
    ├── dailyState.js
    └── weatherMapping.js  ← NEW FILE
```

---

## 🚀 Installation

### Step 1: Add weatherMapping.js to your addon
```bash
# Create the file in your addon directory
cp weatherMapping.js addons/code/weatherMapping.js
```

### Step 2: Update other files
```bash
# Replace with updated versions
cp install-addon-with-mapping.sh install-addon.sh
cp DiaryDialog-with-mapping.qml addons/ui/gui/DiaryDialog.qml
cp diary-graceful.js addons/code/diary.js
cp config-fixed.qml addons/ui/config.qml
```

### Step 3: Run installer
```bash
chmod +x install-addon.sh
./install-addon.sh
```

The installer will:
1. Add `weatherMapping.js` import to main.qml
2. Use the mapping function to convert icon codes to descriptions
3. Patch the diary logging to include weather descriptions

---

## 📊 Example Diary Entries

### Before (Icon Code Only):
```
Sat, 29 Jan 2026
Weather: Icon 3
Temperature: 6°
Humidity: 87%
Pressure: 976 hPa
```

### After (Human-Readable):
```
Sat, 29 Jan 2026
Weather: Scattered clouds
Temperature: 6°
Humidity: 87%
Pressure: 976 hPa
```

---

## 🔧 How It Works

### 1. The Mapping Function
```javascript
WeatherMap.getWeatherDescription(iconCode, providerId)
```

**Parameters:**
- `iconCode` - The icon number from currentWeatherModel.iconName
- `providerId` - The weather provider ("owm", "metno", etc.)

**Returns:** Human-readable description like "Scattered clouds"

### 2. Used in install-addon.sh
```javascript
var weatherCondition = WeatherMap.getWeatherDescription(
    currentWeatherModel.iconName, 
    currentPlace.providerId
)
```

### 3. Used in DiaryDialog.qml
```javascript
var weatherCondition = WeatherMap.getWeatherDescription(
    currentWeatherModel ? currentWeatherModel.iconName : 0,
    currentPlace ? currentPlace.providerId : ""
)
```

### 4. diary.js handles gracefully
```javascript
var condition = weatherData.condition || ""
var hasCondition = condition && condition.trim() !== ""

if (hasCondition) {
    entry += "Weather: " + condition + "\n"
}
```

If condition is empty or missing, the "Weather:" line is simply omitted.

---

## 🎯 Provider Detection

The mapping function automatically detects which weather provider you're using:

- **OpenWeatherMap (owm)** - Uses OWM-specific mappings
- **Met.no (metno)** - Uses Met.no-specific mappings  
- **Other/Unknown** - Falls back to generic range-based detection

This means it works automatically with whatever provider you have configured!

---

## 🛠️ Customization

### Add Your Own Mappings

Edit `weatherMapping.js` and add to the appropriate function:

```javascript
function getWeatherDescriptionOWM(iconCode) {
    var mappings = {
        1: "Clear sky",
        2: "Few clouds",
        // Add your custom mappings here:
        99: "My custom weather condition",
        // ...
    }
    return mappings[iconCode] || "Unknown (" + iconCode + ")"
}
```

### Add New Provider Support

```javascript
function getWeatherDescriptionMyProvider(iconCode) {
    var mappings = {
        // Your provider's icon mappings
    }
    return mappings[iconCode] || "Unknown (" + iconCode + ")"
}

// Then add to main function:
function getWeatherDescription(iconCode, providerId) {
    // ... existing code ...
    
    if (providerId === "myprovider") {
        return getWeatherDescriptionMyProvider(code)
    }
    
    // ... rest of code ...
}
```

---

## 📝 What Changed From Previous Version

### Before:
- `condition: currentWeatherModel.condition` ❌ (doesn't exist, always undefined)
- `condition: "Icon " + iconName` ⚠️ (works but not human-readable)

### After:
- `condition: WeatherMap.getWeatherDescription(iconName, providerId)` ✅ (human-readable!)

---

## ✅ Benefits

1. ✅ **Human-readable** - "Scattered clouds" instead of "Icon 3"
2. ✅ **Provider-aware** - Correct mappings for OWM and Met.no
3. ✅ **Graceful fallback** - Generic detection if provider unknown
4. ✅ **Shows code if unknown** - "Unknown (99)" helps debugging
5. ✅ **No crashes** - Safe handling of missing/invalid codes
6. ✅ **Easy to customize** - Add your own mappings easily

---

## 🔍 Debugging

To see what icon codes your weather provider is using:

```javascript
// Add to main.qml temporarily:
console.log("Icon code:", currentWeatherModel.iconName)
console.log("Provider:", currentPlace.providerId)
console.log("Description:", WeatherMap.getWeatherDescription(
    currentWeatherModel.iconName, 
    currentPlace.providerId
))
```

Then check your Plasma logs:
```bash
journalctl -f | grep -i "icon\|provider\|description"
```

---

## 📦 Complete File List

1. **weatherMapping.js** - The icon mapping function (NEW)
2. **install-addon-with-mapping.sh** - Updated installer
3. **DiaryDialog-with-mapping.qml** - Uses mapping function
4. **diary-graceful.js** - Handles empty conditions
5. **config-fixed.qml** - Removed "Logging" tab

---

## 🎉 Result

Your weather diary will now show proper descriptions:

```
Wed, 29 Jan 2026
Weather: Scattered clouds
Temperature: 6°
Humidity: 87%
Pressure: 976 hPa

Notes: Felt quite chilly with the wind
```

Instead of confusing icon numbers or "undefined"!

---

## 📞 Support

If you see "Unknown (X)" in your diary, it means:
- The icon code X is not in our mapping tables
- You can add it manually to `weatherMapping.js`
- Or report it so we can add it to the default mappings

The number in parentheses tells you exactly which icon code to look up!
