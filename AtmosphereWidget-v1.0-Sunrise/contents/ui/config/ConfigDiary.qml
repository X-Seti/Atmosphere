// Belongs in ..contents/ui/config/ConfigDiary.qml
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
import org.kde.kirigami 2.5 as Kirigami

Item {
    property alias cfg_diaryLoggingEnabled: diaryLoggingCheckBox.checked
    property alias cfg_logPath: logPathField.text
    property alias cfg_diaryLayoutType: layoutTypeComboBox.currentIndex
    property alias cfg_diaryEditorType: editorComboBox.currentIndex
    property alias cfg_diaryCustomEditor: customEditorField.text
    property alias cfg_diaryAutoPopupEnabled: autoPopupCheckBox.checked
    property alias cfg_diaryAutoPopupHour: autoPopupHourSpinBox.value

    FileDialog {
        id: fileDialog
        title: "Choose diary file location"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "txt"
        nameFilters: ["Text files (*.txt)", "Markdown files (*.md)", "All files (*)"]

        onAccepted: {
            var path = selectedFile.toString()
            path = path.replace(/^file:\/\//, "")
            logPathField.text = path
        }
    }

    Kirigami.FormLayout {

        // === ENABLE DIARY ===
        CheckBox {
            id: diaryLoggingCheckBox
            text: "Enable diary logging"
            Kirigami.FormData.label: "Diary:"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "File Location"
        }

        // === LOG FILE PATH ===
        TextField {
            id: logPathField
            placeholderText: "/home/username/weather_diary.txt"
            Kirigami.FormData.label: "Diary file:"
            enabled: diaryLoggingCheckBox.checked
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: fileDialog.open()
            enabled: diaryLoggingCheckBox.checked
        }

        Label {
            text: "Leave empty to use ~/weather_diary.txt\nEntries are always appended - existing logs will never be overwritten"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Format & Style"
        }

        // === LAYOUT TYPE ===
        ComboBox {
            id: layoutTypeComboBox
            model: ["Legacy", "Compact", "Detailed", "Markdown", "Alternative Date"]
            Kirigami.FormData.label: "Entry format:"
            enabled: diaryLoggingCheckBox.checked
        }

        Label {
            id: layoutDescription
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            text: {
                switch(layoutTypeComboBox.currentIndex) {
                    case 0:
                        return "Legacy: Original multi-line format\nSat, 24 Jan 2026\nWeather: Overcast\nTemperature: 6°C..."
                    case 1:
                        return "Compact: Single line with dashes\nSat, 24 Jan 2026 12:25 - Weather: Overcast\nTemperature: 6° - Humidity: 87%..."
                    case 2:
                        return "Detailed: Full day name\nWednesday, 28 January 2026 12:25 - Weather: Overcast\nTemperature: 6° - Humidity: 87%..."
                    case 3:
                        return "Markdown: Bullet point format\nSat, 24 Jan 2026 22:54\n* Weather: Overcast\n* Temperature: 6°..."
                    case 4:
                        return "Alternative Date: Month name first\nSat, January 28, 2026 15:14\nWeather: Overcast\nTemperature: 6°..."
                    default:
                        return ""
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Editor Settings"
        }

        // === EDITOR TYPE ===
        ComboBox {
            id: editorComboBox
            model: ["Kate", "Pluma", "Other"]
            Kirigami.FormData.label: "Text editor:"
        }

        TextField {
            id: customEditorField
            placeholderText: "Custom editor command (e.g., gedit, nano, vim)"
            visible: editorComboBox.currentIndex === 2
            Kirigami.FormData.label: "Custom editor:"
        }

        Label {
            text: "Editor used to open the diary log file from the right-click menu"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Auto Popup"
        }

        // === AUTO POPUP ===
        CheckBox {
            id: autoPopupCheckBox
            text: "Enable automatic daily popup"
            Kirigami.FormData.label: "Daily reminder:"
        }

        SpinBox {
            id: autoPopupHourSpinBox
            from: 0
            to: 23
            Kirigami.FormData.label: "Popup hour:"
            enabled: autoPopupCheckBox.checked
        }

        Label {
            text: "Popup appears once per day at the selected hour (24-hour format, e.g., 20 = 8:00 PM)"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
