// File: ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/ui/DiaryDialog.qml

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/diary.js" as Diary

PlasmaComponents.Dialog {
    id: diaryDialog
    
    property var weatherData: null
    property var executableSource
    property string logPath: ""
    property int layoutType: 0
    
    title: i18n("Add to Daily Diary")
    
    standardButtons: PlasmaComponents.Dialog.Ok | PlasmaComponents.Dialog.Cancel
    
    onAccepted: {
        Diary.appendWeather(weatherData, diaryTextInput.text, executableSource, logPath, layoutType)
        diaryTextInput.text = ""
    }
    
    onRejected: {
        Diary.appendWeather(weatherData, "", executableSource, logPath, layoutType)
        diaryTextInput.text = ""
    }
    
    contentItem: Rectangle {
        implicitWidth: 600
        implicitHeight: 380
        color: Kirigami.Theme.backgroundColor
        border.width: 2
        border.color: Kirigami.Theme.highlightColor
        radius: 8
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                
                Kirigami.Icon {
                    source: "document-edit"
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    color: Kirigami.Theme.highlightColor
                }
                
                PlasmaComponents.Label {
                    text: i18n("Add your health notes for today:")
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: Kirigami.Theme.alternateBackgroundColor
                radius: 4
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 16
                    
                    PlasmaComponents.Label {
                        text: "🌡️ " + (diaryDialog.weatherData ? diaryDialog.weatherData.temperature + "°" : "N/A")
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }
                    
                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                    }
                    
                    PlasmaComponents.Label {
                        text: "💧 " + (diaryDialog.weatherData ? diaryDialog.weatherData.humidity + "%" : "N/A")
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }
                    
                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                    }
                    
                    PlasmaComponents.Label {
                        text: "🔽 " + (diaryDialog.weatherData ? diaryDialog.weatherData.pressureHpa + " hPa" : "N/A")
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }
                    
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
            
            PlasmaComponents.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 180
                
                PlasmaComponents.TextArea {
                    id: diaryTextInput
                    placeholderText: i18n("e.g., not much sleep, Pain is very high 8/10. (in bed)")
                    wrapMode: TextEdit.Wrap
                    focus: true
                    
                    background: Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.width: 1
                        border.color: diaryTextInput.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                        radius: 4
                    }
                    
                    Keys.onReturnPressed: {
                        if (event.modifiers & Qt.ControlModifier) {
                            diaryDialog.accept()
                        }
                    }
                    
                    Keys.onEnterPressed: {
                        if (event.modifiers & Qt.ControlModifier) {
                            diaryDialog.accept()
                        }
                    }
                }
            }
            
            PlasmaComponents.Label {
                text: i18n("💡 Tip: Press Ctrl+Enter to save quickly")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
                Layout.fillWidth: true
            }
            
            Item {
                Layout.fillHeight: true
                Layout.preferredHeight: 16
            }
        }
    }
    
    onOpened: {
        diaryTextInput.forceActiveFocus()
    }
}
