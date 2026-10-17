/*
 * X-Seti - Living desktop atmosphere for Weather Widget Plus
 * Full-screen overlay: rain, snow, wind, sunshine, night dimming
 * Stacks under normal windows when possible; can hide for excluded apps
 */
import QtQuick
import QtQuick.Window
import org.kde.plasma.plasma5support as Plasma5Support

Window {
    id: atmosphere

    // ---- API from main.qml ----
    property bool masterEnabled: false
    property bool particlesEnabled: true
    property bool glassMode: false   // wet glass pane vs streak rain
    property bool isRaining: false
    property bool isSnowing: false
    property bool isClearSky: false
    property bool isDaytime: true
    property real rainIntensity: 0.5
    property real windAngle: 0
    property real windSpeed: 0
    property real cloudiness: 0
    property string excludeApps: ""
    property bool hideOnExcludedFocus: true
    property bool hideOnFullscreen: true

    // Internal
    property bool suppressedByApp: false
    property string activeWindowClass: ""
    property real nightDimOpacity: 0
    property real sunGlowOpacity: 0
    property real windEffect: Math.min(1.0, windSpeed / 15.0)

    title: "Weather Atmosphere"
    color: "transparent"
    flags: Qt.FramelessWindowHint
           | Qt.WindowStaysOnBottomHint
           | Qt.WindowDoesNotAcceptFocus
           | Qt.WindowTransparentForInput
    visibility: (masterEnabled && !suppressedByApp) ? Window.FullScreen : Window.Hidden

    // Cover primary screen
    x: 0
    y: 0
    width: Screen.width
    height: Screen.height

    onVisibleChanged: {
        if (visible) {
            width = Screen.width
            height = Screen.height
        }
    }

    // ---- Active window / exclude list ----
    Plasma5Support.DataSource {
        id: winProbe
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim().toLowerCase()
            disconnectSource(sourceName)
            activeWindowClass = out
            evaluateSuppression()
        }
        function probe() {
            // Best-effort: xdotool (X11) or kdotool
            connectSource("bash -c 'xdotool getactivewindow getwindowclassname 2>/dev/null || kdotool getactivewindow classname 2>/dev/null || true'")
        }
    }

    Timer {
        interval: 1500
        running: masterEnabled && (hideOnExcludedFocus || hideOnFullscreen)
        repeat: true
        triggeredOnStart: true
        onTriggered: winProbe.probe()
    }

    function evaluateSuppression() {
        if (!hideOnExcludedFocus && !hideOnFullscreen) {
            suppressedByApp = false
            return
        }
        var cls = (activeWindowClass || "").toLowerCase()
        if (!cls.length) {
            suppressedByApp = false
            return
        }
        var list = (excludeApps || "").toLowerCase().split(/[,;\n]+/)
        var hit = false
        for (var i = 0; i < list.length; i++) {
            var token = list[i].trim()
            if (token.length && cls.indexOf(token) !== -1) {
                hit = true
                break
            }
        }
        suppressedByApp = hit
    }

    // ---- Night dimming ----
    Rectangle {
        id: nightDim
        anchors.fill: parent
        color: "#000018"
        opacity: atmosphere.nightDimOpacity
        visible: opacity > 0.01
    }

    // ---- Sunshine (warm sky wash + soft rays when clear + day) ----
    Item {
        id: sunLayer
        anchors.fill: parent
        visible: atmosphere.isDaytime && atmosphere.isClearSky && atmosphere.sunGlowOpacity > 0.01
        opacity: atmosphere.sunGlowOpacity * (1.0 - atmosphere.cloudiness / 150.0)

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1.0, 0.92, 0.55, 0.22) }
                GradientStop { position: 0.35; color: Qt.rgba(1.0, 0.85, 0.4, 0.08) }
                GradientStop { position: 1.0; color: Qt.rgba(1.0, 0.9, 0.6, 0.0) }
            }
        }

        // Soft radial glow top-right (sun direction approximation)
        Rectangle {
            width: parent.width * 0.55
            height: parent.height * 0.55
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -width * 0.15
            anchors.topMargin: -height * 0.2
            radius: width
            color: Qt.rgba(1.0, 0.95, 0.7, 0.18)
        }
    }

    // ---- Wind streaks ----
    Item {
        id: windLayer
        anchors.fill: parent
        visible: atmosphere.particlesEnabled && atmosphere.windEffect > 0.15
                 && !atmosphere.isRaining && !atmosphere.isSnowing

        property int streakCount: Math.round(8 + atmosphere.windEffect * 20)

        Repeater {
            model: windLayer.visible ? windLayer.streakCount : 0
            Rectangle {
                id: streak
                property real phase: Math.random()
                property real speed: 2 + Math.random() * 4 * atmosphere.windEffect
                property real yBase: Math.random() * atmosphere.height
                width: 40 + Math.random() * 80 * atmosphere.windEffect
                height: 1 + Math.random() * 2
                color: Qt.rgba(1, 1, 1, 0.08 + Math.random() * 0.12)
                x: -width
                y: yBase
                rotation: atmosphere.windAngle - 90

                Timer {
                    interval: 32
                    running: windLayer.visible
                    repeat: true
                    onTriggered: {
                        var dir = Math.sin(atmosphere.windAngle * Math.PI / 180)
                        streak.x += streak.speed * (dir >= 0 ? 1 : -1) * (0.5 + atmosphere.windEffect)
                        streak.y = streak.yBase + Math.sin(streak.phase * Math.PI * 2) * 8
                        streak.phase += 0.02
                        if (streak.x > atmosphere.width + 20 || streak.x < -streak.width - 20) {
                            streak.x = dir >= 0 ? -streak.width : atmosphere.width + 10
                            streak.yBase = Math.random() * atmosphere.height
                        }
                    }
                }
            }
        }
    }

    // ---- Rain ----
    Item {
        id: rainLayer
        anchors.fill: parent
        visible: atmosphere.particlesEnabled && atmosphere.isRaining && !atmosphere.glassMode
        property int maxDrops: Math.round(40 + atmosphere.rainIntensity * 80)
        property real fallX: Math.sin(atmosphere.windAngle * Math.PI / 180) * atmosphere.windSpeed * 0.35
        property real fallY: 6 + atmosphere.rainIntensity * 10 + atmosphere.windSpeed * 0.15

        ListModel { id: rainModel }

        Timer {
            interval: Math.max(20, 120 / Math.max(0.2, atmosphere.rainIntensity * 3))
            running: rainLayer.visible && rainModel.count < rainLayer.maxDrops
            repeat: true
            onTriggered: {
                rainModel.append({
                    "px": Math.random() * atmosphere.width,
                    "py": -10 - Math.random() * 40,
                    "len": 8 + Math.random() * 14 * atmosphere.rainIntensity,
                    "spd": rainLayer.fallY * (0.7 + Math.random() * 0.6),
                    "op": 0.25 + Math.random() * 0.45
                })
            }
        }

        Timer {
            interval: 16
            running: rainLayer.visible && rainModel.count > 0
            repeat: true
            onTriggered: {
                for (var i = rainModel.count - 1; i >= 0; i--) {
                    var d = rainModel.get(i)
                    var nx = d.px + rainLayer.fallX
                    var ny = d.py + d.spd
                    if (ny > atmosphere.height + 20 || nx < -20 || nx > atmosphere.width + 20) {
                        rainModel.remove(i)
                    } else {
                        rainModel.setProperty(i, "px", nx)
                        rainModel.setProperty(i, "py", ny)
                    }
                }
            }
        }

        Repeater {
            model: rainModel
            Rectangle {
                x: px
                y: py
                width: 1.5
                height: len
                radius: 1
                color: Qt.rgba(0.75, 0.85, 1.0, op)
                rotation: Math.atan2(rainLayer.fallX, rainLayer.fallY) * 180 / Math.PI
            }
        }

        onVisibleChanged: if (!visible) rainModel.clear()
    }



    // ---- Glass pane rain (beads + rivulets + specular highlights) ----
    Item {
        id: glassLayer
        anchors.fill: parent
        visible: atmosphere.particlesEnabled && atmosphere.isRaining && atmosphere.glassMode

        // Meteorological wind FROM degrees → push on glass (screen: +x right, +y down)
        property real windFrom: atmosphere.windAngle
        property real windSpd: atmosphere.windSpeed
        property real windPushX: -Math.sin(windFrom * Math.PI / 180) * windSpd * 0.08
        property real windPushY: -Math.cos(windFrom * Math.PI / 180) * windSpd * 0.02

        // Heavier rain → more / larger beads
        property int maxBeads: Math.round(18 + atmosphere.rainIntensity * 70)
        property real spawnMs: Math.max(40, 320 - atmosphere.rainIntensity * 240)

        // Soft glass fog (heavier when raining hard)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.65, 0.8, 0.95, 0.03 + atmosphere.rainIntensity * 0.04)
        }

        ListModel { id: glassModel }

        function spawnBead() {
            // Light rain: mostly small; heavy: mix including larger
            var r = Math.random()
            var sz
            if (atmosphere.rainIntensity < 0.35)
                sz = 2.5 + r * 4
            else if (atmosphere.rainIntensity < 0.7)
                sz = 3 + r * 7
            else
                sz = 3.5 + r * 10

            // Start near top third of the pane
            glassModel.append({
                "px": Math.random() * atmosphere.width,
                "py": -sz - Math.random() * 30,
                "sz": sz,
                "mass": sz,
                "vy": 0.05 + Math.random() * 0.15,
                "vx": glassLayer.windPushX * (0.2 + Math.random() * 0.4),
                "phase": Math.random() * Math.PI * 2,
                "sliding": 0,
                "op": 0.4 + Math.random() * 0.45,
                "friction": 0.55 + Math.random() * 0.4,
                "trailLen": 0
            })
        }

        Timer {
            interval: glassLayer.spawnMs
            running: glassLayer.visible && glassModel.count < glassLayer.maxBeads
            repeat: true
            onTriggered: glassLayer.spawnBead()
        }

        Timer {
            interval: 16
            running: glassLayer.visible && glassModel.count > 0
            repeat: true
            onTriggered: {
                var H = atmosphere.height
                var W = atmosphere.width
                var intensity = atmosphere.rainIntensity
                // Gravity along glass; heavier mass slides faster once moving
                var g = 0.018 + intensity * 0.03

                for (var i = glassModel.count - 1; i >= 0; i--) {
                    var d = glassModel.get(i)
                    var sz = d.sz
                    var mass = d.mass
                    var vy = d.vy
                    var vx = d.vx
                    var py = d.py
                    var px = d.px
                    var sliding = d.sliding
                    var phase = d.phase + 0.025
                    var friction = d.friction
                    var trailLen = d.trailLen

                    // Sit / creep: surface tension resists motion
                    if (sliding < 0.5) {
                        // Slow growth (collecting)
                        mass += (0.004 + intensity * 0.012) * (0.5 + Math.random())
                        sz = mass

                        // Tiny jitter from wind while stuck
                        px += glassLayer.windPushX * 0.15 + Math.sin(phase) * 0.08
                        py += 0.02 + Math.max(0, glassLayer.windPushY) * 0.1

                        // Heavier drops overcome friction sooner
                        var threshold = (6 + friction * 8) * (1.15 - intensity * 0.4)
                        if (mass >= threshold || (mass > 5 && Math.random() < 0.0015 * intensity)) {
                            sliding = 1
                            vy = 0.25 + (mass * 0.04) * (1.1 - friction * 0.3)
                        }
                    } else {
                        // Running down: gravity + mass, reduced by friction
                        var accel = g * (0.6 + mass * 0.05) * (1.2 - friction * 0.5)
                        vy += accel
                        // Terminal velocity scales with mass
                        var vmax = 1.2 + mass * 0.22 + intensity * 1.5
                        if (vy > vmax)
                            vy = vmax

                        // Wind: horizontal dominant; strong wind also skews path
                        vx = vx * 0.92 + glassLayer.windPushX * 0.35
                        vx += Math.sin(phase * 1.3) * 0.12
                        vy += glassLayer.windPushY * 0.05

                        trailLen = Math.min(55, trailLen * 0.97 + vy * 2.2)
                    }

                    px += vx
                    py += sliding > 0.5 ? vy : vy * 0.15

                    // Merge: slower drop absorbs into nearby; combined runs faster
                    if (i % 2 === 0) {
                        for (var j = glassModel.count - 1; j >= 0; j--) {
                            if (j === i) continue
                            var o = glassModel.get(j)
                            var dx = o.px - px
                            var dy = o.py - py
                            var dist = Math.sqrt(dx * dx + dy * dy)
                            var touch = (sz + o.sz) * 0.5
                            if (dist < touch) {
                                // Keep the lower / larger as survivor
                                var keepSelf = (mass >= o.mass && py >= o.py)
                                if (keepSelf) {
                                    mass += o.mass * 0.65
                                    sz = Math.min(24, 2 + mass * 0.85)
                                    if (o.sliding > 0.5 || mass > 10)
                                        sliding = 1
                                    vy = Math.max(vy, o.vy) * 0.9 + 0.15
                                    glassModel.remove(j)
                                    if (j < i) i--
                                } else {
                                    // mark self for removal by zeroing and remove
                                    glassModel.remove(i)
                                    i--
                                    keepSelf = false
                                }
                                break
                            }
                        }
                        if (i < 0 || i >= glassModel.count)
                            continue
                    }

                    if (py > H + 40 || px < -50 || px > W + 50) {
                        glassModel.remove(i)
                        continue
                    }

                    glassModel.setProperty(i, "px", px)
                    glassModel.setProperty(i, "py", py)
                    glassModel.setProperty(i, "sz", sz)
                    glassModel.setProperty(i, "mass", mass)
                    glassModel.setProperty(i, "vy", vy)
                    glassModel.setProperty(i, "vx", vx)
                    glassModel.setProperty(i, "phase", phase)
                    glassModel.setProperty(i, "sliding", sliding)
                    glassModel.setProperty(i, "trailLen", trailLen)
                }
            }
        }

        Repeater {
            model: glassModel
            Item {
                id: bead
                x: px - sz
                y: py - sz
                width: sz * 2
                height: sz * 2 + Math.max(0, trailLen)
                opacity: op
                z: Math.round(sz)

                // Trail BELOW the drop (direction of travel = down the glass)
                Rectangle {
                    visible: sliding > 0.5 && trailLen > 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Start just under the bead body
                    y: sz * 2 - 1
                    width: Math.max(1.5, sz * 0.28)
                    height: trailLen
                    radius: width / 2
                    gradient: Gradient {
                        // Strongest at the drop, fades further down the path
                        GradientStop { position: 0.0; color: Qt.rgba(0.8, 0.9, 1.0, 0.35 * op) }
                        GradientStop { position: 0.4; color: Qt.rgba(0.7, 0.85, 1.0, 0.12 * op) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.6, 0.75, 0.95, 0.0) }
                    }
                }

                // Drop body (slightly elongated when sliding fast)
                Rectangle {
                    id: body
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    width: sz * 2
                    height: sz * 2 * (sliding > 0.5 ? 1.0 + Math.min(0.25, vy * 0.04) : 1.0)
                    radius: width / 2
                    border.width: 1
                    border.color: Qt.rgba(0.5, 0.65, 0.85, 0.3 * op)

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.97, 0.99, 1.0, 0.6 * op) }
                        GradientStop { position: 0.4; color: Qt.rgba(0.75, 0.88, 1.0, 0.3 * op) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.35, 0.5, 0.7, 0.4 * op) }
                    }
                }

                // Specular reflection (upper-left)
                Rectangle {
                    width: Math.max(2, sz * 0.5)
                    height: Math.max(2, sz * 0.35)
                    radius: width / 2
                    x: sz * 0.35
                    y: sz * 0.28
                    color: Qt.rgba(1, 1, 1, 0.8 * op)
                    rotation: -18
                }

                Rectangle {
                    width: Math.max(1.5, sz * 0.2)
                    height: Math.max(1.5, sz * 0.16)
                    radius: width / 2
                    x: sz * 0.58
                    y: sz * 0.52
                    color: Qt.rgba(1, 1, 1, 0.35 * op)
                }
            }
        }

        onVisibleChanged: {
            if (!visible)
                glassModel.clear()
        }
    }

    // ---- Snow ----
    Item {
        id: snowLayer
        anchors.fill: parent
        visible: atmosphere.particlesEnabled && atmosphere.isSnowing
        property int maxFlakes: Math.round(30 + 50 * Math.min(1, atmosphere.rainIntensity + 0.3))
        property real drift: Math.sin(atmosphere.windAngle * Math.PI / 180) * atmosphere.windSpeed * 0.25

        ListModel { id: snowModel }

        Timer {
            interval: Math.max(40, 200 / Math.max(0.3, atmosphere.rainIntensity + 0.5))
            running: snowLayer.visible && snowModel.count < snowLayer.maxFlakes
            repeat: true
            onTriggered: {
                var sz = 2 + Math.random() * 5
                snowModel.append({
                    "px": Math.random() * atmosphere.width,
                    "py": -10,
                    "sz": sz,
                    "spd": 0.8 + Math.random() * 1.8,
                    "wob": Math.random() * Math.PI * 2,
                    "op": 0.5 + Math.random() * 0.4
                })
            }
        }

        Timer {
            interval: 16
            running: snowLayer.visible && snowModel.count > 0
            repeat: true
            onTriggered: {
                for (var i = snowModel.count - 1; i >= 0; i--) {
                    var f = snowModel.get(i)
                    var wob = f.wob + 0.04
                    var nx = f.px + snowLayer.drift + Math.sin(wob) * 0.8
                    var ny = f.py + f.spd
                    if (ny > atmosphere.height + 10) {
                        snowModel.remove(i)
                    } else {
                        snowModel.setProperty(i, "px", nx)
                        snowModel.setProperty(i, "py", ny)
                        snowModel.setProperty(i, "wob", wob)
                    }
                }
            }
        }

        Repeater {
            model: snowModel
            Rectangle {
                x: px
                y: py
                width: sz
                height: sz
                radius: sz
                color: Qt.rgba(1, 1, 1, op)
                border.color: Qt.rgba(0.9, 0.95, 1, op * 0.5)
                border.width: 1
            }
        }

        onVisibleChanged: if (!visible) snowModel.clear()
    }

    // ---- Smooth day/night / sun targets ----
    Timer {
        interval: 500
        running: atmosphere.masterEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var targetNight = atmosphere.isDaytime ? 0.0 : (0.22 + Math.min(0.2, atmosphere.cloudiness / 200.0))
            var targetSun = (atmosphere.isDaytime && atmosphere.isClearSky)
                ? (0.35 + 0.25 * (1.0 - atmosphere.cloudiness / 100.0))
                : 0.0
            atmosphere.nightDimOpacity = atmosphere.nightDimOpacity * 0.9 + targetNight * 0.1
            atmosphere.sunGlowOpacity = atmosphere.sunGlowOpacity * 0.9 + targetSun * 0.1
        }
    }

    onMasterEnabledChanged: {
        if (!masterEnabled)
            suppressedByApp = false
    }
}
