import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.configuration 2.0
import org.kde.kirigami 2.5 as Kirigami

Item {
    property alias cfg_diaryLoggingEnabled: diaryLoggingCheckBox.checked
    property alias cfg_diaryAutoPopupEnabled: autoPopupCheckBox.checked
    property alias cfg_diaryAutoPopupHour: autoPopupHourSpinBox.value
    property alias cfg_diaryLayoutType: layoutTypeComboBox.currentIndex

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        GroupBox {
            title: "Diary Logging"
            Layout.fillWidth: true

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                anchors.fill: parent

                CheckBox {
                    id: diaryLoggingCheckBox
                    text: "Enable diary logging"
                    Layout.fillWidth: true
                }

                Label {
                    text: "Layout type:"
                }

                ComboBox {
                    id: layoutTypeComboBox
                    Layout.fillWidth: true
                    model: ["Compact", "Detailed", "Markdown"]
                }
                
                Label {
                    text: "Configure file location in the 'Logs' tab"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                    font.italic: true
                    Layout.fillWidth: true
                }
            }
        }

        GroupBox {
            title: "Automatic Popup"
            Layout.fillWidth: true

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                anchors.fill: parent

                CheckBox {
                    id: autoPopupCheckBox
                    text: "Enable automatic daily popup"
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true
                    enabled: autoPopupCheckBox.checked

                    Label {
                        text: "Popup time:"
                    }

                    SpinBox {
                        id: autoPopupHourSpinBox
                        from: 0
                        to: 23
                        value: 20
                    }

                    Label {
                        text: ":00 (24-hour format)"
                    }
                }

                Label {
                    text: "The diary popup will appear once per day at the specified hour."
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    enabled: autoPopupCheckBox.checked
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
