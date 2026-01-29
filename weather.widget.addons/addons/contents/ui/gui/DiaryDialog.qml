// Belongs in ..contents/ui/gui/DiaryDialog.qml version 10
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
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
*/

//import QtQuick 2.15
//import QtQuick.Layouts 1.15
//import QtQuick.Controls 2.15
//import QtQuick.Window 2.15

//import org.kde.plasma.plasmoid 2.0
//import org.kde.plasma.core 2.0 as PlasmaCore
//import org.kde.kirigami 2.5 as Kirigami
//import org.kde.plasma.components 3.0 as PlasmaComponents
//import org.kde.plasma.plasma5support as Plasma5Support

import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Window 2.15
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import "../../code/diary.js" as Diary
import "../../code/weatherMapping.js" as WeatherMap

Item {

    // === DIARY FUNCTIONS ===
    function showDiaryEntryDialog(weatherData) {
        if (!plasmoid.configuration.diaryLoggingEnabled)
            return

            diaryDialogWindow.weatherData = weatherData
            diaryDialogWindow.visible = true

            if (diaryDialogWindow.raise)
                diaryDialogWindow.raise()

                if (diaryDialogWindow.requestActivate)
                    diaryDialogWindow.requestActivate()
    }

    // === DIARY WINDOW ===
    Window {
        id: diaryDialogWindow

        property var weatherData: null

        width: 600
        height: 450
        modality: Qt.NonModal
        flags: Qt.Window
        visible: false
        title: i18n("Add to Daily Diary")
        color: Kirigami.Theme.backgroundColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Label {
                text: i18n("Add Weather Notation")
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 4
                color: Kirigami.Theme.alternateBackgroundColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 7

                    Label {
                        text: diaryDialogWindow.weatherData ?
                        "Temp: " + diaryDialogWindow.weatherData.temperature + "°" :
                        "No data"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }

                    Label {
                        text: diaryDialogWindow.weatherData ?
                        " Humidity: " + diaryDialogWindow.weatherData.humidity + "%" :
                        ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }

                    Label {
                        text: diaryDialogWindow.weatherData ?
                        " Pressure: " + diaryDialogWindow.weatherData.pressureHpa + " hPa" :
                        ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }
                    
                    // Show condition if available
                    Label {
                        visible: diaryDialogWindow.weatherData && diaryDialogWindow.weatherData.condition && diaryDialogWindow.weatherData.condition !== ""
                        text: diaryDialogWindow.weatherData && diaryDialogWindow.weatherData.condition ? 
                              " Condition: " + diaryDialogWindow.weatherData.condition : ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }
                }
            }

            TextArea {
                id: diaryTextInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: i18n("Enter your notes here...")
                wrapMode: TextEdit.Wrap
            }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                Button { //TODO show in editor, Diary Editor needs to be fixed first.
                    text: i18n("Show in Editor")
                    icon.name: "dialog-ok"
                    highlighted: true
                    onClicked: {
                        Diary.appendWeather(
                            diaryDialogWindow.weatherData,
                            diaryTextInput.text,
                            executable,
                            plasmoid.configuration.logPath,
                            plasmoid.configuration.diaryLayoutType
                        )
                        // FIX: Actually open the log file in editor
                        Diary.openLogFile(
                            plasmoid.configuration.logPath,
                            plasmoid.configuration.diaryEditorType,
                            plasmoid.configuration.diaryCustomEditor,
                            executable
                        )
                        diaryTextInput.text = ""
                        diaryDialogWindow.visible = false
                    }
                }
                Button {
                    text: i18n("Skip")
                    icon.name: "dialog-cancel"
                    onClicked: {
                        Diary.appendWeather(
                            diaryDialogWindow.weatherData,
                            "",
                            executable,
                            plasmoid.configuration.logPath,
                            plasmoid.configuration.diaryLayoutType
                        )
                        diaryTextInput.text = ""
                        diaryDialogWindow.visible = false
                    }
                }

                Button {
                    text: i18n("Save")
                    icon.name: "dialog-ok"
                    highlighted: true
                    onClicked: {
                        Diary.appendWeather(
                            diaryDialogWindow.weatherData,
                            diaryTextInput.text,
                            executable,
                            plasmoid.configuration.logPath,
                            plasmoid.configuration.diaryLayoutType
                        )
                        diaryTextInput.text = ""
                        diaryDialogWindow.visible = false
                    }
                }
            }
        }
    }

    // === RIGHT CLICK MENU ===
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add a weather notation")
            icon.name: "document-edit"
            onTriggered: {
                // Get weather description from icon code
                var weatherCondition = WeatherMap.getWeatherDescription(
                    currentWeatherModel ? currentWeatherModel.iconName : 0,
                    currentPlace ? currentPlace.providerId : ""
                )
                
                var tempWeatherData = {
                    temperature: currentWeatherModel ? currentWeatherModel.temperature : "N/A",
                    humidity: currentWeatherModel ? currentWeatherModel.humidity : "N/A",
                    pressureHpa: currentWeatherModel ? currentWeatherModel.pressureHpa : "N/A",
                    condition: weatherCondition
                }
                showDiaryEntryDialog(tempWeatherData)
            }
        },
        PlasmaCore.Action {
            text: i18n("Show notation log")
            icon.name: "document-open"
            onTriggered: {
                Diary.openLogFile(
                    plasmoid.configuration.logPath,
                    plasmoid.configuration.diaryEditorType,
                    plasmoid.configuration.diaryCustomEditor,
                    executable  // FIX: Add executable parameter
                )
            }
        }
    ]
}

