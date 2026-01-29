// Belongs in ..contents/ui/config/ConfigEffects.qml
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
import QtQuick.Controls 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.5 as Kirigami

Item {
    property alias cfg_weatherEffectsEnabled: weatherEffectsCheckBox.checked
    property alias cfg_particleEffectsEnabled: particleEffectsCheckBox.checked
    property alias cfg_soundEffectsEnabled: soundEffectsCheckBox.checked
    property alias cfg_wallpaperEffectsEnabled: wallpaperEffectsCheckBox.checked
    property alias cfg_feelsLikeTooltipEnabled: feelsLikeTooltipCheckBox.checked
    
    // Wallpaper paths
    property alias cfg_wallpaperMorning: wallpaperMorningField.text
    property alias cfg_wallpaperAfternoon: wallpaperAfternoonField.text
    property alias cfg_wallpaperEvening: wallpaperEveningField.text
    property alias cfg_wallpaperNight: wallpaperNightField.text
    
    // Shade factors
    property alias cfg_shadeFactorMorning: shadeFactorMorningSlider.value
    property alias cfg_shadeFactorAfternoon: shadeFactorAfternoonSlider.value
    property alias cfg_shadeFactorEvening: shadeFactorEveningSlider.value
    property alias cfg_shadeFactorNight: shadeFactorNightSlider.value
    
    property alias cfg_useSunriseSunset: useSunriseSunsetCheckBox.checked

    property int currentWallpaperSelection: 0

    FileDialog {
        id: wallpaperDialog
        title: "Choose wallpaper image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.jpg *.jpeg *.png *.webp)", "All files (*)"]

        onAccepted: {
            var path = selectedFile.toString()
            path = path.replace(/^file:\/\//, "")
            
            switch(currentWallpaperSelection) {
                case 0: wallpaperMorningField.text = path; break
                case 1: wallpaperAfternoonField.text = path; break
                case 2: wallpaperEveningField.text = path; break
                case 3: wallpaperNightField.text = path; break
            }
        }
    }

    Kirigami.FormLayout {

        // === MASTER ENABLE ===
        CheckBox {
            id: weatherEffectsCheckBox
            text: "Enable all weather effects"
            Kirigami.FormData.label: "Weather Effects:"
        }

        Label {
            text: "Master toggle for all atmospheric effects (particles, sounds, wallpapers)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Visual Effects"
        }

        // === PARTICLE EFFECTS ===
        CheckBox {
            id: particleEffectsCheckBox
            text: "Enable rain and snow particles"
            Kirigami.FormData.label: "Particles:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Animated rain drops and snowflakes aligned with wind direction"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        // === FEELS LIKE TOOLTIP ===
        CheckBox {
            id: feelsLikeTooltipCheckBox
            text: "Show 'Feels Like' temperature on hover"
            Kirigami.FormData.label: "Tooltip:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Display wind chill and comfort level when hovering over temperature"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Audio Effects"
        }

        // === SOUND EFFECTS ===
        CheckBox {
            id: soundEffectsCheckBox
            text: "Enable weather sounds"
            Kirigami.FormData.label: "Sounds:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Play ambient sounds for rain, wind, and other weather conditions"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Dynamic Wallpapers"
        }

        // === WALLPAPER EFFECTS ===
        CheckBox {
            id: wallpaperEffectsCheckBox
            text: "Enable dynamic wallpaper changes"
            Kirigami.FormData.label: "Wallpapers:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Automatically change wallpaper based on time of day and weather conditions"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        CheckBox {
            id: useSunriseSunsetCheckBox
            text: "Use sunrise/sunset times (when available)"
            Kirigami.FormData.label: "Timing:"
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Label {
            text: "Use actual sunrise/sunset from weather data instead of fixed times"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Wallpaper Images"
        }

        // === MORNING WALLPAPER ===
        TextField {
            id: wallpaperMorningField
            placeholderText: "/path/to/morning-wallpaper.jpg"
            Kirigami.FormData.label: "Morning (6am-12pm):"
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: {
                currentWallpaperSelection = 0
                wallpaperDialog.open()
            }
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        // === AFTERNOON WALLPAPER ===
        TextField {
            id: wallpaperAfternoonField
            placeholderText: "/path/to/afternoon-wallpaper.jpg"
            Kirigami.FormData.label: "Afternoon (12pm-5pm):"
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: {
                currentWallpaperSelection = 1
                wallpaperDialog.open()
            }
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        // === EVENING WALLPAPER ===
        TextField {
            id: wallpaperEveningField
            placeholderText: "/path/to/evening-wallpaper.jpg"
            Kirigami.FormData.label: "Evening (5pm-8pm):"
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: {
                currentWallpaperSelection = 2
                wallpaperDialog.open()
            }
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        // === NIGHT WALLPAPER ===
        TextField {
            id: wallpaperNightField
            placeholderText: "/path/to/night-wallpaper.jpg"
            Kirigami.FormData.label: "Night (8pm-6am):"
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: {
                currentWallpaperSelection = 3
                wallpaperDialog.open()
            }
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Brightness/Shade Adjustment"
        }

        Label {
            text: "Adjust wallpaper brightness for each time period (0.0 = very dark, 1.0 = original brightness)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        // === MORNING SHADE FACTOR ===
        RowLayout {
            Kirigami.FormData.label: "Morning brightness:"
            Layout.fillWidth: true
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
            
            Slider {
                id: shadeFactorMorningSlider
                from: 0.3
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            Label {
                text: shadeFactorMorningSlider.value.toFixed(2)
                Layout.minimumWidth: 40
            }
        }

        // === AFTERNOON SHADE FACTOR ===
        RowLayout {
            Kirigami.FormData.label: "Afternoon brightness:"
            Layout.fillWidth: true
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
            
            Slider {
                id: shadeFactorAfternoonSlider
                from: 0.3
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            Label {
                text: shadeFactorAfternoonSlider.value.toFixed(2)
                Layout.minimumWidth: 40
            }
        }

        // === EVENING SHADE FACTOR ===
        RowLayout {
            Kirigami.FormData.label: "Evening brightness:"
            Layout.fillWidth: true
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
            
            Slider {
                id: shadeFactorEveningSlider
                from: 0.3
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            Label {
                text: shadeFactorEveningSlider.value.toFixed(2)
                Layout.minimumWidth: 40
            }
        }

        // === NIGHT SHADE FACTOR ===
        RowLayout {
            Kirigami.FormData.label: "Night brightness:"
            Layout.fillWidth: true
            enabled: wallpaperEffectsCheckBox.checked && weatherEffectsCheckBox.checked
            
            Slider {
                id: shadeFactorNightSlider
                from: 0.3
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            
            Label {
                text: shadeFactorNightSlider.value.toFixed(2)
                Layout.minimumWidth: 40
            }
        }

        Label {
            text: "Leave wallpaper paths empty to disable automatic wallpaper changes\nBrightness adjustment uses ImageMagick and will be applied based on time and weather"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
