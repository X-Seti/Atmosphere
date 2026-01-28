// Belongs in ..contents/ui/config/ConfigLogs.qml
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
    property alias cfg_logPath: logPathField.text

    FileDialog {
        id: fileDialog
        title: "Choose diary file location"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "txt"
            nameFilters: ["Text files (*.txt)", "All files (*)"]

            onAccepted: {
                var path = selectedFile.toString()
                path = path.replace(/^file:\/\//, "")
                logPathField.text = path
            }
    }

    Kirigami.FormLayout {

        TextField {
            id: logPathField
            placeholderText: "/home/username/weather_diary.txt"
            Kirigami.FormData.label: "Diary file:"
        }

        Button {
            text: "Browse…"
            icon.name: "document-open"
            onClicked: fileDialog.open()
        }

        Label {
            text: "Leave empty to use ~/weather_diary.txt"
            wrapMode: Text.Wrap
            opacity: 0.7
            Kirigami.FormData.isSection: true
        }
    }
}
