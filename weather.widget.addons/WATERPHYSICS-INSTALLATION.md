# Where to Add WaterPhysics in main.qml

## 📍 Exact Location

Add the WaterPhysics component **after the DiaryDialog** (around line 661).

---

## 📝 Current Structure (Lines 658-662)

```qml
    // Import DiaryDialog
    DiaryUI.DiaryDialog {
        id: diaryDialog
    }
    Timer {
        interval: 10000
```

---

## ✅ Modified Structure (Add WaterPhysics)

```qml
    // Import DiaryDialog
    DiaryUI.DiaryDialog {
        id: diaryDialog
    }
    
    // ADD THIS SECTION HERE ↓↓↓
    
    // Rain overlay effect
    DiaryUI.WaterPhysics {
        id: rainEffect
        anchors.fill: parent
        z: 9999  // On top of everything
        
        enabled: isRaining && plasmoid.configuration.weatherEffectsEnabled && 
                 plasmoid.configuration.particleEffectsEnabled
        
        windAngle: currentWeatherModel ? currentWeatherModel.windDirection : 0
        windSpeed: currentWeatherModel ? currentWeatherModel.windSpeedMps : 0
        rainIntensity: calculateRainIntensity()
        mouseInfluence: 30
    }
    
    // Helper property - determines if it's currently raining
    property bool isRaining: {
        if (!currentWeatherModel || !currentWeatherModel.iconName) return false
        
        var iconCode = currentWeatherModel.iconName
        
        // OpenWeatherMap rain codes
        if (iconCode >= 200 && iconCode <= 299) return true  // Thunderstorm
        if (iconCode >= 300 && iconCode <= 321) return true  // Drizzle
        if (iconCode >= 500 && iconCode <= 531) return true  // Rain
        
        // Simple icon codes
        if (iconCode >= 9 && iconCode <= 12) return true
        
        return false
    }
    
    // Helper function - calculates rain intensity based on weather code
    function calculateRainIntensity() {
        if (!currentWeatherModel || !currentWeatherModel.iconName) return 0
        
        var code = currentWeatherModel.iconName
        
        // Heavy rain
        if (code >= 502 && code <= 504) return 1.0
        if (code === 212) return 1.0  // Heavy thunderstorm
        if (code === 212 || code === 522) return 1.0
        
        // Moderate rain
        if (code === 501 || code === 521) return 0.6
        if (code === 10 || code === 11) return 0.6
        if (code >= 200 && code <= 211) return 0.6  // Thunderstorm
        
        // Light rain
        if (code === 500 || code === 520) return 0.3
        if (code === 9) return 0.3
        
        // Drizzle
        if (code >= 300 && code <= 321) return 0.2
        
        return 0.5  // Default moderate
    }
    
    // END OF ADDITION ↑↑↑
    
    Timer {
        interval: 10000
```

---

## 🔧 Step-by-Step Instructions

### **Option 1: Manual Edit**

1. Open your main.qml file
2. Find line 661 (after `DiaryDialog`)
3. Add the WaterPhysics section shown above
4. Save the file

### **Option 2: Use sed (Automated)**

```bash
# Backup first
cp ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml \
   ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml.backup

# Insert WaterPhysics after DiaryDialog
sed -i '/DiaryUI.DiaryDialog/,/^    }/a\
    \
    // Rain overlay effect\
    DiaryUI.WaterPhysics {\
        id: rainEffect\
        anchors.fill: parent\
        z: 9999\
        \
        enabled: isRaining && plasmoid.configuration.weatherEffectsEnabled && \
                 plasmoid.configuration.particleEffectsEnabled\
        \
        windAngle: currentWeatherModel ? currentWeatherModel.windDirection : 0\
        windSpeed: currentWeatherModel ? currentWeatherModel.windSpeedMps : 0\
        rainIntensity: calculateRainIntensity()\
        mouseInfluence: 30\
    }\
    \
    property bool isRaining: {\
        if (!currentWeatherModel || !currentWeatherModel.iconName) return false\
        var iconCode = currentWeatherModel.iconName\
        if (iconCode >= 200 && iconCode <= 299) return true\
        if (iconCode >= 300 && iconCode <= 321) return true\
        if (iconCode >= 500 && iconCode <= 531) return true\
        if (iconCode >= 9 && iconCode <= 12) return true\
        return false\
    }\
    \
    function calculateRainIntensity() {\
        if (!currentWeatherModel || !currentWeatherModel.iconName) return 0\
        var code = currentWeatherModel.iconName\
        if (code >= 502 && code <= 504) return 1.0\
        if (code === 501 || code === 521) return 0.6\
        if (code === 10 || code === 11) return 0.6\
        if (code >= 200 && code <= 211) return 0.6\
        if (code === 500 || code === 520) return 0.3\
        if (code === 9) return 0.3\
        if (code >= 300 && code <= 321) return 0.2\
        return 0.5\
    }
' ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml

# Restart Plasma
kquitapp6 plasmashell && kstart plasmashell &
```

---

## 📦 Complete Installation

```bash
# 1. Copy WaterPhysics to addon
cp WaterPhysics.qml addons/ui/gui/WaterPhysics.qml

# 2. Re-run installer (it will copy WaterPhysics)
./install-addon.sh

# 3. Add the WaterPhysics component to main.qml
#    (Use manual edit or sed command above)

# 4. Restart Plasma
kquitapp6 plasmashell && kstart plasmashell &
```

---

## 🎯 What This Does

### **The Component:**
```qml
DiaryUI.WaterPhysics {
    id: rainEffect
    anchors.fill: parent  // Covers entire widget
    z: 9999              // On top of everything
    enabled: isRaining   // Only when raining
}
```

### **The Helper Property:**
```qml
property bool isRaining: {
    // Checks icon code to determine if raining
    // Returns true for rain/drizzle/thunderstorm codes
}
```

### **The Helper Function:**
```qml
function calculateRainIntensity() {
    // Returns 0.0 to 1.0 based on rain type
    // Heavy rain = 1.0
    // Light rain = 0.3
    // Drizzle = 0.2
}
```

---

## 🔍 Visual Reference

```
main.qml structure:
├── PlasmoidItem {
│   ├── ... (other properties)
│   ├── DiaryDialog { }          ← Line 659-661
│   ├── WaterPhysics { }         ← ADD HERE (after DiaryDialog)
│   ├── isRaining property       ← ADD HERE
│   ├── calculateRainIntensity() ← ADD HERE
│   └── Timer {                  ← Line 662 (existing)
```

---

## ✅ Verification

After adding, check that:

1. **File has no syntax errors:**
   ```bash
   qmlscene ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml
   ```

2. **WaterPhysics is imported:**
   ```bash
   grep -n "WaterPhysics" ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml
   ```

3. **Helper functions are present:**
   ```bash
   grep -n "isRaining\|calculateRainIntensity" ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml
   ```

---

## 🎮 Testing

Force enable for testing (temporary):

```qml
DiaryUI.WaterPhysics {
    id: rainEffect
    anchors.fill: parent
    z: 9999
    
    enabled: true  // Force enable
    windAngle: 90
    windSpeed: 5
    rainIntensity: 0.8
}
```

You should see droplets falling at an angle!

---

## 🐛 Troubleshooting

### **No droplets appear:**
- Check console for errors: `journalctl -f | grep plasma`
- Verify `enabled: true` for testing
- Check z-index is high (9999)

### **Wrong wind direction:**
- Verify `currentWeatherModel.windDirection` exists
- Check console: `console.log("Wind:", windAngle, windSpeed)`

### **Syntax errors:**
- Make sure all braces match `{ }`
- Check for missing commas
- Verify property names match exactly

---

## 📝 Summary

**Add after line 661** (right after DiaryDialog, before Timer):
1. WaterPhysics component
2. isRaining property
3. calculateRainIntensity() function

Then restart Plasma and enjoy realistic rain! 🌧️✨
