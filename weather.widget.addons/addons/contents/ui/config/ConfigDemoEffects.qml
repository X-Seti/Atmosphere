import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.5 as Kirigami

Item {
    property alias cfg_demoWaterEnabled: demoWaterCheckBox.checked
    property alias cfg_demoShadeEnabled: demoShadeCheckBox.checked

    Kirigami.FormLayout {

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Demo / Preview Effects"
        }

        CheckBox {
            id: demoWaterCheckBox
            text: "Test Water Demo (rain / snow)"
            Kirigami.FormData.label: "Particles:"
        }

        Label {
            text: "Forces rain/snow effect even when weather is dry"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        CheckBox {
            id: demoShadeCheckBox
            text: "Test Shading / Wallpaper overlay"
            Kirigami.FormData.label: "Shading:"
        }

        Label {
            text: "Forces wallpaper shading so brightness logic can be tested"
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }
    }
}
