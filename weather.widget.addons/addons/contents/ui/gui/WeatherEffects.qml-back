// Belongs in ..contents/ui/gui/WeatherEffects.qml
/*
 * X-Seti - Jan 25 2025 - Addons for Weather Widget Plus (Credit - Martin Kotelnik)
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import Qt.labs.platform 1.1

Item {
    id: weatherEffectsRoot
    anchors.fill: parent
    visible: plasmoid.configuration.weatherEffectsEnabled
    z: 1000

    // === CALCULATED PROPERTIES ===
    
    // Feels Like Temperature (Wind Chill + Humidity)
    property real feelsLikeTemp: {
        if (!currentWeatherModel || currentWeatherModel.count === 0) return 0
        
        var temp = currentWeatherModel.temperature || 0
        var windSpeed = currentWeatherModel.windSpeedMps || 0
        var humidity = currentWeatherModel.humidity || 0

        // Wind chill (if temp < 10°C and wind > 3km/h)
        var windChill = temp
        if (temp <= 10 && windSpeed > 0.83) { // 3km/h ≈ 0.83m/s
            windChill = 13.12 + 0.6215 * temp - 11.37 * Math.pow(windSpeed, 0.16) + 0.3965 * temp * Math.pow(windSpeed, 0.16)
        }

        // Humidity effect (if temp > 15°C)
        var humidityEffect = 0
        if (temp > 15 && humidity > 70) {
            humidityEffect = (humidity - 70) / 10
        }

        return Math.round(windChill + humidityEffect)
    }

    // Comfort Level
    property string comfortLevel: {
        if (!currentWeatherModel) return "Unknown"
        
        var temp = currentWeatherModel.temperature || 0

        if (temp < 5) return "Freezing"
        else if (temp < 10) return "Cold"
        else if (temp < 15) return "Cool"
        else if (temp < 20) return "Comfortable"
        else if (temp < 25) return "Warm"
        else if (temp < 30) return "Hot"
        else return "Very Hot"
    }

    // Weather Mood
    property string weatherMood: {
        if (!currentWeatherModel) return "Calm"
        
        var windSpeed = currentWeatherModel.windSpeedMps || 0
        var cond = currentWeatherModel.condition ? currentWeatherModel.condition.toLowerCase() : ""

        if (cond.includes("storm") || cond.includes("thunder")) return "Stormy"
        else if (windSpeed > 15) return "Gusty"
        else if (windSpeed > 8) return "Breezy"
        else if (cond.includes("rain") || cond.includes("drizzle")) return "Wet"
        else if (cond.includes("snow")) return "Snowy"
        else if (cond.includes("cloudy") || cond.includes("overcast")) return "Overcast"
        else return "Calm"
    }

    // Wind Direction
    property real windDirection: currentWeatherModel && currentWeatherModel.windDirection ? currentWeatherModel.windDirection : 0

    // === PARTICLE EFFECTS ===
    
    Item {
        id: particleEffectsContainer
        anchors.fill: parent
        visible: plasmoid.configuration.particleEffectsEnabled
        z: 1001

        // Rain Particles
        Item {
            id: rainContainer
            anchors.fill: parent
            rotation: windDirection - 90
            visible: currentWeatherModel && (
                currentWeatherModel.condition.toLowerCase().includes("rain") ||
                currentWeatherModel.condition.toLowerCase().includes("drizzle")
            )

            Repeater {
                model: 50
                delegate: Rectangle {
                    width: 2
                    height: Math.random() * 15 + 10
                    color: "rgba(200, 220, 255, 0.7)"
                    radius: 1
                    x: Math.random() * parent.width
                    y: -height

                    NumberAnimation on y {
                        from: -height
                        to: parent.height + height
                        duration: Math.random() * 1000 + 1000
                        loops: Animation.Infinite
                    }

                    Component.onCompleted: {
                        // Stagger start times
                        y = Math.random() * parent.height
                    }
                }
            }
        }

        // Snow Particles
        Item {
            id: snowContainer
            anchors.fill: parent
            rotation: windDirection - 90
            visible: currentWeatherModel && (
                currentWeatherModel.condition.toLowerCase().includes("snow") ||
                currentWeatherModel.condition.toLowerCase().includes("sleet")
            )

            Repeater {
                model: 30
                delegate: Rectangle {
                    width: Math.random() * 6 + 4
                    height: width
                    color: "rgba(255, 255, 255, 0.9)"
                    radius: width / 2
                    x: Math.random() * parent.width
                    y: -height

                    NumberAnimation on y {
                        from: -height
                        to: parent.height + height
                        duration: Math.random() * 3000 + 3000
                        loops: Animation.Infinite
                    }

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: Math.random() * 2000 + 2000
                        loops: Animation.Infinite
                    }

                    Component.onCompleted: {
                        y = Math.random() * parent.height
                    }
                }
            }
        }

        // Sun Glint
        Rectangle {
            id: sunGlint
            width: 40
            height: 40
            radius: 20
            color: "white"
            opacity: 0
            z: 1003
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            visible: currentWeatherModel && (
                !currentWeatherModel.condition.toLowerCase().includes("cloud") &&
                !currentWeatherModel.condition.toLowerCase().includes("rain") &&
                !currentWeatherModel.condition.toLowerCase().includes("snow")
            )

            Behavior on opacity {
                NumberAnimation { duration: 1500 }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: visible
                PropertyAnimation { to: parent.width / 2 - 20; duration: 4000 }
                PropertyAnimation { to: parent.width / 2 + 20; duration: 4000 }
            }

            Timer {
                interval: 3000
                repeat: true
                running: parent.visible
                onTriggered: {
                    parent.opacity = 0.9
                    opacityTimer.start()
                }

                Timer {
                    id: opacityTimer
                    interval: 600
                    onTriggered: sunGlint.opacity = 0
                }
            }
        }

        // Day/Night Overlay
        Rectangle {
            id: lightingOverlay
            anchors.fill: parent
            color: "black"
            z: 999

            Behavior on opacity {
                NumberAnimation {
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            opacity: {
                if (!currentWeatherModel) return 0
                
                var cond = currentWeatherModel.condition.toLowerCase()
                var hour = new Date().getHours()

                if (cond.includes("snow") || cond.includes("sleet")) return 0.5
                else if (cond.includes("rain") || cond.includes("drizzle")) return 0.4
                else if (cond.includes("cloudy") || cond.includes("overcast")) return 0.3
                else if (hour >= 18 || hour < 6) return 0.6
                else return 0.0
            }
        }
    }

    // === FEELS LIKE TOOLTIP ===
    
    Item {
        id: feelsLikeTooltip
        width: 180
        height: 80
        visible: false
        z: 2000
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            color: theme.backgroundColor
            radius: 12
            border.color: theme.textColor
            border.width: 1
            opacity: 0.95

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.1)
                border.width: 1
                radius: 11
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: "Feels like " + feelsLikeTemp + "°"
                font.pixelSize: 14
                color: theme.textColor
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: comfortLevel + " • " + weatherMood
                font.pixelSize: 11
                color: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.7)
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // === SOUND EFFECTS ===
    
    QtObject {
        id: soundEffects
        property bool enabled: plasmoid.configuration.soundEffectsEnabled

        // Sound effect placeholders - implement with actual audio files
        function playRainSound() {
            if (!enabled) return
            console.log("Playing rain sound")
            // TODO: Implement actual audio playback
        }

        function playWindSound() {
            if (!enabled) return
            console.log("Playing wind sound")
            // TODO: Implement actual audio playback
        }

        function playSnowSound() {
            if (!enabled) return
            console.log("Playing snow sound")
            // TODO: Implement actual audio playback
        }
    }

    // === WALLPAPER CONTROLLER ===
    
    QtObject {
        id: wallpaperController
        property bool enabled: plasmoid.configuration.wallpaperEffectsEnabled

        function updateWallpaper() {
            if (!enabled) return
            if (!executable) {
                console.error("WeatherEffects: executable not available")
                return
            }

            var wallpaperPath = getWallpaperPath()
            if (!wallpaperPath || wallpaperPath === "") return

            var brightness = calculateBrightness()
            console.log("Updating wallpaper:", wallpaperPath, "brightness:", brightness)

            // TODO: Implement wallpaper setting via executable
            // Similar to the diary.js approach
        }

        function getWallpaperPath() {
            var hour = new Date().getHours()
            var useSunData = plasmoid.configuration.useSunriseSunset

            // TODO: Implement sunrise/sunset logic when available
            
            if (hour >= 6 && hour < 12) return plasmoid.configuration.wallpaperMorning
            else if (hour >= 12 && hour < 17) return plasmoid.configuration.wallpaperAfternoon
            else if (hour >= 17 && hour < 20) return plasmoid.configuration.wallpaperEvening
            else return plasmoid.configuration.wallpaperNight
        }

        function calculateBrightness() {
            var hour = new Date().getHours()
            var baseBrightness = 100

            if (hour >= 6 && hour < 12) baseBrightness = 85
            else if (hour >= 12 && hour < 17) baseBrightness = 100
            else if (hour >= 17 && hour < 20) baseBrightness = 75
            else baseBrightness = 40

            // Adjust for weather
            if (!currentWeatherModel) return baseBrightness

            var cond = currentWeatherModel.condition.toLowerCase()
            var weatherAdj = 0

            if (cond.includes("snow")) weatherAdj = 10
            else if (cond.includes("rain") || cond.includes("drizzle")) weatherAdj = -15
            else if (cond.includes("cloudy") || cond.includes("overcast")) weatherAdj = -20
            else if (cond.includes("clear") || cond.includes("sun")) weatherAdj = 5

            return Math.max(20, Math.min(100, baseBrightness + weatherAdj))
        }
    }

    // === INITIALIZATION ===
    
    Component.onCompleted: {
        console.log("WeatherEffects initialized")
        
        // Initial wallpaper update
        wallpaperController.updateWallpaper()

        // Watch for weather changes
        if (currentWeatherModel) {
            currentWeatherModel.onConditionChanged.connect(function() {
                var cond = currentWeatherModel.condition.toLowerCase()
                
                if (cond.includes("rain") && soundEffects.enabled) {
                    soundEffects.playRainSound()
                }
                if (cond.includes("snow") && soundEffects.enabled) {
                    soundEffects.playSnowSound()
                }
                
                wallpaperController.updateWallpaper()
            })
        }
    }

    // === UPDATE TIMER ===
    
    Timer {
        interval: 5 * 60 * 1000 // 5 minutes
        repeat: true
        running: wallpaperController.enabled
        onTriggered: wallpaperController.updateWallpaper()
    }
}
