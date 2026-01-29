// WaterPhysics-test.qml - Standalone test for rain effect
// Run with: qml WaterPhysics-test.qml

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Window {
    id: testWindow
    visible: true
    width: 800
    height: 600
    title: "Water Physics Test - Move mouse to interact!"
    color: "#2c3e50"
    
    // Background pattern to see droplets better
    Rectangle {
        anchors.fill: parent
        color: "#34495e"
        
        Grid {
            anchors.fill: parent
            rows: 20
            columns: 20
            
            Repeater {
                model: 400
                Rectangle {
                    width: testWindow.width / 20
                    height: testWindow.height / 20
                    color: index % 2 === 0 ? "#2c3e50" : "#34495e"
                }
            }
        }
    }
    
    // Rain effect (same as WaterPhysics.qml - inline for testing)
    Item {
        id: rainOverlay
        anchors.fill: parent
        
        property bool enabled: true
        property real windAngle: windAngleSlider.value
        property real windSpeed: windSpeedSlider.value
        property real rainIntensity: rainIntensitySlider.value
        property real mouseInfluence: mouseInfluenceSlider.value
        
        property int maxDroplets: 50
        property point mousePos: Qt.point(-1000, -1000)
        
        property real fallAngleX: Math.sin(windAngle * Math.PI / 180) * windSpeed * 0.3
        property real fallAngleY: 2.0 + (windSpeed * 0.1)
        
        visible: enabled
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            
            onPositionChanged: (mouse) => {
                mousePos = Qt.point(mouse.x, mouse.y)
            }
            
            onExited: {
                mousePos = Qt.point(-1000, -1000)
            }
        }
        
        ListModel {
            id: dropletModel
        }
        
        Timer {
            interval: Math.max(50, 500 / (rainOverlay.rainIntensity * 10))
            running: rainOverlay.enabled && dropletModel.count < rainOverlay.maxDroplets
            repeat: true
            
            onTriggered: {
                if (dropletModel.count < rainOverlay.maxDroplets) {
                    var size = Math.random() * 10 + 5
                    var x = Math.random() * testWindow.width
                    var y = -size
                    
                    dropletModel.append({
                        "dropX": x,
                        "dropY": y,
                        "dropSize": size,
                        "dropVelocityX": rainOverlay.fallAngleX + (Math.random() - 0.5) * 0.5,
                        "dropVelocityY": rainOverlay.fallAngleY + Math.random() * 0.5,
                        "dropOpacity": Math.random() * 0.3 + 0.5,
                        "dropRotation": Math.random() * 360
                    })
                }
            }
        }
        
        Timer {
            interval: 16
            running: rainOverlay.enabled && dropletModel.count > 0
            repeat: true
            
            onTriggered: {
                for (var i = dropletModel.count - 1; i >= 0; i--) {
                    var drop = dropletModel.get(i)
                    var newX = drop.dropX + drop.dropVelocityX
                    var newY = drop.dropY + drop.dropVelocityY
                    
                    if (rainOverlay.mousePos.x > -500 && rainOverlay.mousePos.y > -500) {
                        var dx = newX - rainOverlay.mousePos.x
                        var dy = newY - rainOverlay.mousePos.y
                        var distance = Math.sqrt(dx * dx + dy * dy)
                        
                        if (distance < rainOverlay.mouseInfluence && distance > 0) {
                            var force = (rainOverlay.mouseInfluence - distance) / rainOverlay.mouseInfluence
                            newX += (dx / distance) * force * 2
                            newY += (dy / distance) * force * 2
                        }
                    }
                    
                    drop.dropVelocityY += 0.05
                    
                    if (newY > testWindow.height + drop.dropSize || 
                        newX < -drop.dropSize || 
                        newX > testWindow.width + drop.dropSize) {
                        dropletModel.remove(i)
                        continue
                    }
                    
                    dropletModel.setProperty(i, "dropX", newX)
                    dropletModel.setProperty(i, "dropY", newY)
                    dropletModel.setProperty(i, "dropRotation", drop.dropRotation + drop.dropVelocityY * 0.5)
                }
            }
        }
        
        Repeater {
            model: dropletModel
            
            delegate: Item {
                x: dropX - dropSize
                y: dropY - dropSize
                width: dropSize * 2
                height: dropSize * 2
                rotation: dropRotation
                
                Rectangle {
                    anchors.centerIn: parent
                    width: dropSize * 2
                    height: dropSize * 2
                    radius: dropSize
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, dropOpacity * 0.8) }
                        GradientStop { position: 0.5; color: Qt.rgba(0.9, 0.95, 1, dropOpacity * 0.6) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.7, 0.8, 0.9, dropOpacity * 0.4) }
                    }
                    
                    Rectangle {
                        x: dropSize * 0.3
                        y: dropSize * 0.3
                        width: dropSize * 0.5
                        height: dropSize * 0.5
                        radius: dropSize * 0.25
                        color: Qt.rgba(1, 1, 1, dropOpacity * 0.6)
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: dropSize
                        color: "transparent"
                        border.color: Qt.rgba(0.4, 0.5, 0.6, dropOpacity * 0.3)
                        border.width: 1
                    }
                }
            }
        }
    }
    
    // Control panel
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 180
        color: Qt.rgba(0, 0, 0, 0.8)
        
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5
            
            Label {
                text: "🌧️ Rain Effect Controls - Move mouse to push droplets!"
                font.bold: true
                color: "white"
            }
            
            Row {
                spacing: 10
                Label { text: "Wind Angle:"; color: "white"; width: 100 }
                Slider {
                    id: windAngleSlider
                    from: 0
                    to: 360
                    value: 90
                    width: 200
                }
                Label { text: windAngleSlider.value.toFixed(0) + "°"; color: "white"; width: 50 }
            }
            
            Row {
                spacing: 10
                Label { text: "Wind Speed:"; color: "white"; width: 100 }
                Slider {
                    id: windSpeedSlider
                    from: 0
                    to: 10
                    value: 3
                    width: 200
                }
                Label { text: windSpeedSlider.value.toFixed(1) + " m/s"; color: "white"; width: 50 }
            }
            
            Row {
                spacing: 10
                Label { text: "Rain Intensity:"; color: "white"; width: 100 }
                Slider {
                    id: rainIntensitySlider
                    from: 0.1
                    to: 1.0
                    value: 0.6
                    width: 200
                }
                Label { text: (rainIntensitySlider.value * 100).toFixed(0) + "%"; color: "white"; width: 50 }
            }
            
            Row {
                spacing: 10
                Label { text: "Mouse Influence:"; color: "white"; width: 100 }
                Slider {
                    id: mouseInfluenceSlider
                    from: 10
                    to: 100
                    value: 30
                    width: 200
                }
                Label { text: mouseInfluenceSlider.value.toFixed(0) + " px"; color: "white"; width: 50 }
            }
        }
    }
    
    // Stats
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        text: "Droplets: " + dropletModel.count + "/" + rainOverlay.maxDroplets
        color: "white"
        font.bold: true
        style: Text.Outline
        styleColor: "black"
    }
}
