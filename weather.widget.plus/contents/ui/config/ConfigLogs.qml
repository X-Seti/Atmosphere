import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.configuration 2.0
import org.kde.kirigami as Kirigami

Item {
    property alias cfg_logPath: logPathField.text
    property alias cfg_diaryLayoutType: diaryLayoutCombo.currentIndex

    Column {
        spacing: 8

        Label {
            text: "Log directory"
        }

        TextField {
            id: logPathField
            placeholderText: "/home/x2/logs"
        }

        Item {
            width: 1
            height: 10
        }

        Label {
            text: "Diary Display Format"
        }

        ComboBox {
            id: diaryLayoutCombo
            model: ["Option 1: Separate Lines", "Option 2: Combined Lines"]
            currentIndex: 0
        }

        Item {
            width: 1
            height: 10
        }

        // Preview examples
        GroupBox {
            title: "Preview Examples"
            Layout.fillWidth: true

            Column {
                anchors.fill: parent
                anchors.margins: 8

                Label {
                    text: "Option 1:"
                    font.bold: true
                }
                Label {
                    text: "Fri, 23 Jan 2026\nWeather: Weather condition\nTemperature: 7°C\nHumidity: 98%\nPressure: 982 hPa\n\nno data entered!"
                    font.family: "monospace"
                    wrapMode: Text.Wrap
                }

                Item {
                    width: 1
                    height: 10
                }

                Label {
                    text: "Option 2:"
                    font.bold: true
                }
                Label {
                    text: "Fri, 23 Jan 2026\nWeather: Weather condition - Temperature: 7°C\nHumidity: 98% - Pressure: 982 hPa\n\nno data entered!"
                    font.family: "monospace"
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}

