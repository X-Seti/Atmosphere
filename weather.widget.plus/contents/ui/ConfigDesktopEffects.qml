import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.configuration 2.0

Item {
    property alias cfg_wallpaperBase: wallpaperField.text

    Column {
        spacing: 8

        Label { text: "Base wallpaper image" }

        TextField {
            id: wallpaperField
            placeholderText: "/home/x2/Wallpapers/image.jpg"
        }
    }
}
