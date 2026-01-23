import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.configuration 2.0

Item {
    property alias cfg_logPath: logPathField.text

    Column {
        spacing: 8

        Label {
            text: "Log directory"
        }

        TextField {
            id: logPathField
            placeholderText: "/home/x2/logs"
        }
    }
}

