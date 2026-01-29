// Belongs in ...contents/ui/gui/WaterPhysics.qml
/*
 * X-Seti - Jan 29 2026 - Realistic Rain Effect
 * Rain droplets with wind direction and mouse interaction
 */

import QtQuick 2.15

Item {
    id: rainOverlay
    anchors.fill: parent
    
    // Configuration from WeatherEffects
    property bool enabled: false
    property real windAngle: 0  // Degrees: 0=North, 90=East, 180=South, 270=West
    property real windSpeed: 0  // m/s
    property real rainIntensity: 1.0  // 0.0 to 1.0
    property real mouseInfluence: 30  // Pixels - how far mouse affects droplets
    
    // Internal properties
    property int maxDroplets: 50
    property point mousePos: Qt.point(-1000, -1000)
    
    // Calculate fall angle from wind
    property real fallAngleX: Math.sin(windAngle * Math.PI / 180) * windSpeed * 0.3
    property real fallAngleY: 2.0 + (windSpeed * 0.1)
    
    visible: enabled
    
    // Mouse tracking
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        
        onPositionChanged: (mouse) => {
            mousePos = Qt.point(mouse.x, mouse.y)
        }
        
        onExited: {
            mousePos = Qt.point(-1000, -1000)
        }
        
        // Don't consume events - let them pass through
        onPressed: (mouse) => { mouse.accepted = false }
        onReleased: (mouse) => { mouse.accepted = false }
        onClicked: (mouse) => { mouse.accepted = false }
    }
    
    // Droplet model
    ListModel {
        id: dropletModel
    }
    
    // Droplet spawner
    Timer {
        id: spawner
        interval: Math.max(50, 500 / (rainIntensity * 10))
        running: enabled && dropletModel.count < maxDroplets
        repeat: true
        
        onTriggered: {
            if (dropletModel.count < maxDroplets) {
                createDroplet()
            }
        }
    }
    
    // Create new droplet
    function createDroplet() {
        var size = Math.random() * 10 + 5  // 5-15px radius
        var x = Math.random() * width
        var y = -size
        
        dropletModel.append({
            "dropX": x,
            "dropY": y,
            "dropSize": size,
            "dropVelocityX": fallAngleX + (Math.random() - 0.5) * 0.5,
            "dropVelocityY": fallAngleY + Math.random() * 0.5,
            "dropOpacity": Math.random() * 0.3 + 0.5,
            "dropRotation": Math.random() * 360
        })
    }
    
    // Droplet physics updater
    Timer {
        id: physicsTimer
        interval: 16  // ~60 FPS
        running: enabled && dropletModel.count > 0
        repeat: true
        
        onTriggered: {
            updatePhysics()
        }
    }
    
    function updatePhysics() {
        for (var i = dropletModel.count - 1; i >= 0; i--) {
            var drop = dropletModel.get(i)
            
            // Apply gravity and wind
            var newX = drop.dropX + drop.dropVelocityX
            var newY = drop.dropY + drop.dropVelocityY
            
            // Mouse interaction - gentle repulsion
            if (mousePos.x > -500 && mousePos.y > -500) {
                var dx = newX - mousePos.x
                var dy = newY - mousePos.y
                var distance = Math.sqrt(dx * dx + dy * dy)
                
                if (distance < mouseInfluence && distance > 0) {
                    // Gentle push away from mouse
                    var force = (mouseInfluence - distance) / mouseInfluence
                    var pushX = (dx / distance) * force * 2
                    var pushY = (dy / distance) * force * 2
                    
                    newX += pushX
                    newY += pushY
                }
            }
            
            // Increase velocity slightly (gravity acceleration)
            drop.dropVelocityY += 0.05
            
            // Check boundaries
            if (newY > height + drop.dropSize) {
                // Remove droplet that went off screen
                dropletModel.remove(i)
                continue
            }
            
            if (newX < -drop.dropSize || newX > width + drop.dropSize) {
                // Remove droplet that went off sides
                dropletModel.remove(i)
                continue
            }
            
            // Update position
            dropletModel.setProperty(i, "dropX", newX)
            dropletModel.setProperty(i, "dropY", newY)
            
            // Slight rotation as it falls
            var newRotation = drop.dropRotation + drop.dropVelocityY * 0.5
            dropletModel.setProperty(i, "dropRotation", newRotation)
            
            // Check for merging with other droplets
            checkMerging(i)
        }
    }
    
    function checkMerging(index) {
        if (index >= dropletModel.count) return
        
        var drop1 = dropletModel.get(index)
        
        for (var i = dropletModel.count - 1; i >= 0; i--) {
            if (i === index) continue
            
            var drop2 = dropletModel.get(i)
            var dx = drop1.dropX - drop2.dropX
            var dy = drop1.dropY - drop2.dropY
            var distance = Math.sqrt(dx * dx + dy * dy)
            var minDist = drop1.dropSize + drop2.dropSize
            
            // If droplets touch, merge them
            if (distance < minDist) {
                // Larger droplet absorbs smaller one
                var newSize = Math.sqrt(drop1.dropSize * drop1.dropSize + drop2.dropSize * drop2.dropSize)
                var newVelX = (drop1.dropVelocityX + drop2.dropVelocityX) / 2
                var newVelY = (drop1.dropVelocityY + drop2.dropVelocityY) / 2
                
                dropletModel.setProperty(index, "dropSize", Math.min(newSize, 25))
                dropletModel.setProperty(index, "dropVelocityX", newVelX)
                dropletModel.setProperty(index, "dropVelocityY", newVelY)
                dropletModel.setProperty(index, "dropOpacity", Math.min(drop1.dropOpacity + 0.1, 0.9))
                
                // Remove the absorbed droplet
                dropletModel.remove(i)
                
                if (i < index) {
                    index--  // Adjust index after removal
                }
            }
        }
    }
    
    // Render droplets
    Repeater {
        model: dropletModel
        
        delegate: Item {
            id: dropletContainer
            x: dropX - dropSize
            y: dropY - dropSize
            width: dropSize * 2
            height: dropSize * 2
            rotation: dropRotation
            
            // Water droplet appearance
            Rectangle {
                id: droplet
                anchors.centerIn: parent
                width: dropSize * 2
                height: dropSize * 2
                radius: dropSize
                
                // Gradient for 3D effect
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, dropOpacity * 0.8) }
                    GradientStop { position: 0.5; color: Qt.rgba(0.9, 0.95, 1, dropOpacity * 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.7, 0.8, 0.9, dropOpacity * 0.4) }
                }
                
                // Shine highlight
                Rectangle {
                    x: dropSize * 0.3
                    y: dropSize * 0.3
                    width: dropSize * 0.5
                    height: dropSize * 0.5
                    radius: dropSize * 0.25
                    color: Qt.rgba(1, 1, 1, dropOpacity * 0.6)
                }
                
                // Shadow/depth
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
    
    // Cleanup when disabled
    onEnabledChanged: {
        if (!enabled) {
            dropletModel.clear()
        }
    }
    
    Component.onDestruction: {
        dropletModel.clear()
    }
}
