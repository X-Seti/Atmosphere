#!/usr/bin/env bash
# install-waterphysics.sh - Adds WaterPhysics to main.qml automatically

set -e

MAINQML="$HOME/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/main.qml"
BACKUP="$MAINQML.backup-waterphysics.$(date +%s)"

echo "== WaterPhysics Installer =="

# Check if main.qml exists
if [[ ! -f "$MAINQML" ]]; then
    echo "✗ main.qml not found at $MAINQML"
    exit 1
fi

# Check if already installed
if grep -q "WaterPhysics" "$MAINQML"; then
    echo "⚠ WaterPhysics already added to main.qml"
    echo "   Remove it first if you want to reinstall"
    exit 0
fi

# Backup
echo "[+] Backing up main.qml to:"
echo "    $BACKUP"
cp "$MAINQML" "$BACKUP"

# Find the DiaryDialog section
if ! grep -q "DiaryUI.DiaryDialog" "$MAINQML"; then
    echo "✗ DiaryDialog not found in main.qml"
    echo "   Run install-addon.sh first"
    exit 1
fi

echo "[+] Adding WaterPhysics component..."

# Insert WaterPhysics after DiaryDialog
# This is a multi-line insertion, so we use a here-doc
cat > /tmp/waterphysics-insertion.txt << 'EOF'

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
        if (code === 522) return 1.0
        
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
EOF

# Use awk to insert after the DiaryDialog block
awk '
/DiaryUI.DiaryDialog/,/^    \}$/ {
    print
    if (/^    \}$/ && !inserted) {
        while ((getline line < "/tmp/waterphysics-insertion.txt") > 0) {
            print line
        }
        close("/tmp/waterphysics-insertion.txt")
        inserted = 1
    }
    next
}
{ print }
' "$MAINQML" > "$MAINQML.tmp"

mv "$MAINQML.tmp" "$MAINQML"

# Cleanup
rm /tmp/waterphysics-insertion.txt

# Verify
if grep -q "WaterPhysics" "$MAINQML" && \
   grep -q "isRaining" "$MAINQML" && \
   grep -q "calculateRainIntensity" "$MAINQML"; then
    echo "✓ WaterPhysics added successfully!"
else
    echo "✗ Something went wrong during installation"
    echo "   Restoring backup..."
    cp "$BACKUP" "$MAINQML"
    exit 1
fi

echo ""
echo "== Installation Complete =="
echo ""
echo "Next steps:"
echo "1. Make sure WaterPhysics.qml is in the gui folder"
echo "2. Restart Plasma: kquitapp6 plasmashell && kstart plasmashell &"
echo "3. Enable 'Particle Effects' in Weather Effects settings"
echo "4. Wait for rain! Move your mouse to interact with droplets"
echo ""
echo "To test without rain, edit main.qml and temporarily set:"
echo "  enabled: true  // Instead of: enabled: isRaining && ..."
