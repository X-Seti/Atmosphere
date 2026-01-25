import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.plasma.configuration 2.0
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
            // Convert file:// URL to path
            var path = selectedFile.toString()
            path = path.replace(/^file:\/\//, '')
            logPathField.text = path
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        anchors.fill: parent

        Label {
            text: "Diary File Location"
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.fillWidth: true

            Label {
                text: "Diary file:"
            }

            TextField {
                id: logPathField
                placeholderText: "~/daily_weather_diary.txt"
                Layout.fillWidth: true
            }
            
            Button {
                text: "Browse..."
                icon.name: "document-open"
                onClicked: fileDialog.open()
            }
        }
        
        Label {
            text: "Full path to diary file (e.g., /home/username/daily_weather_diary.txt)\nLeave empty to use ~/weather_diary.txt"
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
