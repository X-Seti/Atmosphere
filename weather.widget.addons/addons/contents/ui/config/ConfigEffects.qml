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
    property alias cfg_desktopAtmosphereEnabled: desktopAtmosphereCheckBox.checked
    property alias cfg_glassModeEnabled: glassModeCheckBox.checked
    property alias cfg_excludeApps: excludeAppsField.text
    property alias cfg_hideEffectsOnExcluded: hideExcludedCheckBox.checked
    property string cfg_testEffectMode: "none"
    property alias cfg_soundEffectsEnabled: soundEffectsCheckBox.checked
    property alias cfg_wallpaperEffectsEnabled: wallpaperEffectsCheckBox.checked
    property alias cfg_feelsLikeTooltipEnabled: feelsLikeTooltipCheckBox.checked
    
    // Wallpaper paths
    property alias cfg_wallpaperMorning: wallpaperMorningField.text
    property alias cfg_wallpaperAfternoon: wallpaperAfternoonField.text
    property alias cfg_wallpaperEvening: wallpaperEveningField.text
    property alias cfg_wallpaperNight: wallpaperNightField.text
    
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
            text: "Master toggle for atmospheric effects (desktop overlay, particles, sounds, wallpapers)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Test preview"
        }

        ComboBox {
            id: testEffectModeCombo
            Kirigami.FormData.label: "Force effect:"
            enabled: weatherEffectsCheckBox.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Off — use live weather", value: "none" },
                { text: "Test rain", value: "rain" },
                { text: "Test snow", value: "snow" },
                { text: "Test sunshine (day)", value: "clear" },
                { text: "Test night dimming", value: "night" }
            ]
            Component.onCompleted: {
                var v = cfg_testEffectMode || "none"
                for (var j = 0; j < model.length; j++) {
                    if (model[j].value === v) {
                        currentIndex = j
                        break
                    }
                }
            }
            onActivated: cfg_testEffectMode = currentValue
        }

        Label {
            text: "Preview an effect on the desktop without waiting for real weather. Set back to Off when finished."
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Visual Effects"
        }

        CheckBox {
            id: particleEffectsCheckBox
            text: "Enable rain and snow particles"
            Kirigami.FormData.label: "Particles:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Animated rain and snow driven by weather (or test mode above)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        CheckBox {
            id: desktopAtmosphereCheckBox
            text: "Full desktop atmosphere (rain, snow, wind, sun, night dim)"
            Kirigami.FormData.label: "Desktop:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Draw effects across the whole screen (under windows when supported)."
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        CheckBox {
            id: glassModeCheckBox
            text: "Turn desktop into wet glass"
            Kirigami.FormData.label: "Glass rain:"
            enabled: weatherEffectsCheckBox.checked && desktopAtmosphereCheckBox.checked
        }

        Label {
            text: "Rain beads on a glass pane with reflections and run-down rivulets. When off, uses streak (outdoor) rain instead."
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Exclude apps / windows"
        }

        CheckBox {
            id: hideExcludedCheckBox
            text: "Hide effects while an excluded app is focused"
            Kirigami.FormData.label: "Auto-hide:"
            enabled: weatherEffectsCheckBox.checked && desktopAtmosphereCheckBox.checked
        }

        TextArea {
            id: excludeAppsField
            Kirigami.FormData.label: "Exclude list:"
            placeholderText: "One app per line or comma-separated:\nvlc\nmpv\nsteam\nzoom"
            enabled: weatherEffectsCheckBox.checked && desktopAtmosphereCheckBox.checked
            Layout.fillWidth: true
            implicitHeight: 90
            wrapMode: TextEdit.Wrap
        }

        Label {
            text: "Match is substring on the active window class / app id (case-insensitive). Examples: vlc, mpv, firefox, steam, obs, zoom, teams. Requires xdotool (X11) or kdotool."
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Label {
            text: "Tip: run  xdotool getactivewindow getwindowclassname  in a terminal while the app is focused to see the name to add."
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }


        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Audio and tooltip"
        }

        CheckBox {
            id: soundEffectsCheckBox
            text: "Enable weather sounds"
            Kirigami.FormData.label: "Sounds:"
            enabled: weatherEffectsCheckBox.checked
        }

        Label {
            text: "Ambient rain/wind sounds when conditions match (optional)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        CheckBox {
            id: feelsLikeTooltipCheckBox
            text: "Show Feels Like temperature on hover"
            Kirigami.FormData.label: "Tooltip:"
            enabled: weatherEffectsCheckBox.checked
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
            Kirigami.FormData.label: "Morning:"
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
            Kirigami.FormData.label: "Afternoon:"
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
            Kirigami.FormData.label: "Evening:"
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
            Kirigami.FormData.label: "Night:"
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

        Label {
            text: "Leave wallpaper paths empty to disable automatic wallpaper changes\nWallpapers will be brightness-adjusted based on time and weather"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
