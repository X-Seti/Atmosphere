// Belongs in ..contents/ui/gui/DiaryDialog.qml
/*
 * X-Seti - Jan 25 2025 - Addons for Weather Widget Plus (Credit - Martin Kotelnik)
 *
 * Diary entry dialog only. Context-menu actions live in main.qml
 * (Preview rain/snow/sun/night + exclude toggles use testEffectMode there).
 */

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
    id: diaryRoot

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
                        text: diaryDialogWindow.weatherData
                              ? "Temp: " + diaryDialogWindow.weatherData.temperature + "°"
                              : "No data"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }

                    Label {
                        text: diaryDialogWindow.weatherData
                              ? " Humidity: " + diaryDialogWindow.weatherData.humidity + "%"
                              : ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }

                    Label {
                        text: diaryDialogWindow.weatherData
                              ? " Pressure: " + diaryDialogWindow.weatherData.pressureHpa + " hPa"
                              : ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                        font.bold: true
                    }

                    Label {
                        visible: diaryDialogWindow.weatherData
                                 && diaryDialogWindow.weatherData.condition
                                 && diaryDialogWindow.weatherData.condition !== ""
                        text: diaryDialogWindow.weatherData && diaryDialogWindow.weatherData.condition
                              ? " Condition: " + diaryDialogWindow.weatherData.condition
                              : ""
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

                Button {
                    text: i18n("Show in Editor")
                    icon.name: "document-open"
                    onClicked: {
                        Diary.appendWeather(
                            diaryDialogWindow.weatherData,
                            diaryTextInput.text,
                            executable,
                            plasmoid.configuration.logPath,
                            plasmoid.configuration.diaryLayoutType
                        )
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
}
