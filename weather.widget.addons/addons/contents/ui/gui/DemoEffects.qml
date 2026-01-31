import QtQuick 2.15
import "../effects"   // adjust if WaterPhysics.qml is elsewhere

Item {
    id: demoRoot
    anchors.fill: parent
    z: 999

    property bool demoWater: plasmoid.configuration.demoWaterEnabled
    property bool demoShade: plasmoid.configuration.demoShadeEnabled

    // Fake wind values
    property real demoWindSpeed: 4
    property real demoWindAngle: 45

    WaterPhysics {
        id: demoRain
        anchors.fill: parent
        enabled: demoWater
        visible: demoWater
        windSpeed: demoRoot.demoWindSpeed
        windAngle: demoRoot.demoWindAngle
        rainIntensity: 1.0
    }

    Rectangle {
        anchors.fill: parent
        visible: demoShade
        color: "black"
        opacity: 0.25
    }
}
