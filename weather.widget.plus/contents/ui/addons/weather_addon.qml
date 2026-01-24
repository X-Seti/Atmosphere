pragma Singleton
property bool weatherEffectsEnabled: false
    // === ATMOSPHERE WIDGET (ALL-IN-ONE) ===
    Item {
    property bool effectsEnabled: plasmoid.configuration.weatherEffectsEnabled

        id: atmosphereWidget
        anchors.fill: parent
        z: 1002 // Highest layer — above everything

        // --- SOUND EFFECTS ---
        property bool soundEnabled: plasmoid.configuration.soundEffectsEnabled !== false
        property string soundDir: "qrc:/sounds/"

        SoundEffect {
            id: hourlyDing
            source: soundDir + "ding.mp3"
            volume: 0.3
        }

        SoundEffect {
            id: windWhoosh
            source: soundDir + "wind.mp3"
            volume: 0.2
        }

        SoundEffect {
            id: rainPatter
            source: soundDir + "rain.mp3"
            volume: 0.25
        }

        SoundEffect {
            id: snowCrunch
            source: soundDir + "snow.mp3"
            volume: 0.2
        }

        // --- WALLPAPER PATHS (USE YOUR EXACT PATHS) ---

        // --- BASE IMAGE FOR BRIGHTNESS ADJUSTMENT ---

        // --- CALCULATE TIME-BASED WALLPAPER ---

            var now = new Date().getTime()
            var useSun = plasmoid.configuration.useSunriseSunset && hasSunData

            if (useSun && localSunrise.getTime() > 0 && localSunset.getTime() > 0) {
                var sunrise = localSunrise.getTime()
                var sunset = localSunset.getTime()

                // Morning: 1 hour before sunrise → 1 hour after sunrise
                if (now > sunrise - 3600000 && now < sunrise + 3600000) return morningWallpaper
                    // Day: between sunrise + 1h and sunset - 1h
                    else if (now > sunrise + 3600000 && now < sunset - 3600000) return afternoonWallpaper
                        // Evening: 1 hour before sunset → 1 hour after sunset
                        else if (now > sunset - 3600000 && now < sunset + 3600000) return eveningWallpaper
                            // Night: everything else
                            else return nightWallpaper
            }

            // Fallback to time-based if API fails or disabled
            var hour = new Date().getHours()
            if (hour >= 6 && hour < 12) return morningWallpaper
                else if (hour >= 12 && hour < 17) return afternoonWallpaper
                    else if (hour >= 17 && hour < 20) return eveningWallpaper
                        else return nightWallpaper
        }

        // --- CALCULATE BRIGHTNESS (TIME + WEATHER) ---
        property real calculatedBrightness: {
            var now = new Date().getTime()
            var useSun = plasmoid.configuration.useSunriseSunset && hasSunData

            if (useSun && localSunrise.getTime() > 0 && localSunset.getTime() > 0) {
                var sunrise = localSunrise.getTime()
                var sunset = localSunset.getTime()
                var dayLength = sunset - sunrise
                var timeSinceSunrise = now - sunrise

                if (timeSinceSunrise < 0) return 20  // Before sunrise
                    if (timeSinceSunrise > dayLength) return 20  // After sunset

                        // Linear interpolation: darkest at sunrise/sunset, brightest at noon
                        var progress = Math.max(0, Math.min(1, timeSinceSunrise / dayLength))
                        var base = 100 * (1 - Math.abs(progress - 0.5) * 2) // Triangle wave: peaks at noon
                        return Math.round(base)
            }

            // Fallback to time-based brightness (from your original script)
            var hour = new Date().getHours()
            var brightness_levels = {
                0: 20, 1: 30, 2: 35, 3: 40, 4: 45, 5: 50,
                6: 60, 7: 70, 8: 80, 9: 85, 10: 90, 11: 95,
                12: 100, 13: 100, 14: 95, 15: 90, 16: 85, 17: 80,
                18: 70, 19: 60, 20: 50, 21: 40, 22: 30, 23: 25
            }
            var base = brightness_levels[hour] || 40

            // Weather adjustment
            var cond = currentProvider ? currentProvider.currentCondition.toLowerCase() : ""
            var weatherAdj = 0
            if (cond.includes("snow")) weatherAdj = 15
                else if (cond.includes("sun") || cond.includes("clear")) weatherAdj = 10
                    else if (cond.includes("rain") || cond.includes("drizzle")) weatherAdj = -20
                        else if (cond.includes("cloudy") || cond.includes("overcast")) weatherAdj = -15

                            return Math.max(15, Math.min(100, base + weatherAdj))
        }

        // --- WALLPAPER ADJUSTMENT FUNCTION ---
        function applyWallpaperWithBrightness() {
            var path = selectedWallpaper
            if (!Qt.canOpenFile(path)) {
                console.warn("Wallpaper not found:", path)
                return
            }

            var tempPath = Qt.resolvedUrl("file:///tmp/plasma-adjusted-wallpaper-" + plasmoid.id + ".jpg")

            if (calculatedBrightness === 100) {
                setPlasmaWallpaper(path)
            } else {
                var cmd = "convert \"" + path + "\" -modulate 100," + calculatedBrightness + ",100 \"" + tempPath + "\""
                var process = new QtObject()
                process.execute = function(command) {
                    var result = Qt.runCommand(command)
                    return result
                }
                process.execute(cmd)

                setTimeout(function() {
                    if (Qt.fileExists(tempPath)) {
                        setPlasmaWallpaper(tempPath)
                    } else {
                        setPlasmaWallpaper(path)
                    }
                }, 1000)
            }
        }

        // --- SET WALLPAPER VIA DBUS ---
        function setPlasmaWallpaper(path) {
            if (!path) return;

                var escapedPath = path.replace(/"/g, '\\"')
                var script = `
                var allDesktops = desktops();
            for (i=0; i<allDesktops.length; i++) {
                d = allDesktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                d.writeConfig('Image', 'file://${escapedPath}');
            }
            `

            try {
                var cmd = "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \"" + script + "\""
                executable.exec(cmd)
                console.log("Wallpaper updated:", path, "brightness:", calculatedBrightness)
            } catch (e) {
                console.error("DBus wallpaper error:", e.message)
            }
        }

        // --- SUN GLINT (GENTLE HIGHLIGHT ON SUNNY DAYS) ---
        Rectangle {
    property bool effectsEnabled: plasmoid.configuration.weatherEffectsEnabled

            id: sunGlint
            width: 40
            height: 40
            radius: 20
            color: "white"
            opacity: 0
            z: 1003
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            visible: !currentProvider ? false : (
                !currentProvider.currentCondition.toLowerCase().includes("cloud") &&
                !currentProvider.currentCondition.toLowerCase().includes("rain") &&
                !currentProvider.currentCondition.toLowerCase().includes("snow") &&
                calculatedBrightness > 85
            )

            Behavior on opacity { NumberAnimation { duration: 1500 } }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: visible
                PropertyAnimation { to: parent.width / 2 - 20; duration: 4000 }
                PropertyAnimation { to: parent.width / 2 + 20; duration: 4000 }
            }

            Timer {
                interval: 3000
                repeat: true
                running: visible
                onTriggered: {
                    opacity = 0.9
                    setTimeout(() => opacity = 0, 600)
                }
            }
        }

        // --- RAIN AND SNOW PARTICLES WITH WIND ALIGNMENT ---
        property real windDirection: meteogramModel.count > 0 ? meteogramModel.get(0).windDirection : 0

        Item {
    property bool effectsEnabled: plasmoid.configuration.weatherEffectsEnabled

            id: rainContainer
            anchors.fill: parent
            rotation: windDirection - 90
            visible: currentProvider && (
                currentProvider.currentCondition.toLowerCase().includes("rain") ||
                currentProvider.currentCondition.toLowerCase().includes("drizzle")
            )

            ParticleSystem {
                id: rainSystem
                width: parent.width
                height: parent.height

                ImageParticle {
                    source: "qrc:/effects/samples.webp"
                    alpha: 0.7
                }

                Emitter {
                    velocity: AngleDirection {
                        angle: 90
                        magnitude: 110
                        angleVariation: 0
                        magnitudeVariation: 30
                    }
                    anchors.fill: parent
                    emitRate: 150
                    lifeSpan: 1500
                    lifeSpanVariation: 200
                }
            }
        }

        Item {
    property bool effectsEnabled: plasmoid.configuration.weatherEffectsEnabled

            id: snowContainer
            anchors.fill: parent
            rotation: windDirection - 90
            visible: currentProvider && (
                currentProvider.currentCondition.toLowerCase().includes("snow") ||
                currentProvider.currentCondition.toLowerCase().includes("sleet")
            )

            ParticleSystem {
                id: snowSystem
                width: parent.width
                height: parent.height

                ImageParticle {
                    source: "qrc:/effects/snowflake.svg"
                    alpha: 0.9
                }
                Emitter {
                    anchors.fill: parent
                    emitRate: 60
                    velocity: AngleDirection {
                        angle: 90
                        magnitude: 20
                        angleVariation: 0
                        magnitudeVariation: 30
                    }
                    lifeSpan: 4000
                    lifeSpanVariation: 500
                }
            }
        }

        // --- DAY/NIGHT OVERLAY (SOFT DIMMING) ---
        Rectangle {
    property bool effectsEnabled: plasmoid.configuration.weatherEffectsEnabled

            id: lightingOverlay
            anchors.fill: parent
            color: "black"
            z: 1001

            Behavior on opacity {
                NumberAnimation {
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            opacity: {
                var cond = currentProvider ? currentProvider.currentCondition.toLowerCase() : ""
                var hour = new Date().getHours()

                if (cond.includes("snow")) return 0.5
                    else if (cond.includes("rain") || cond.includes("drizzle")) return 0.4
                        else if (cond.includes("cloudy") || cond.includes("overcast")) return 0.3
                            else if (hour >= 18 || hour < 6) return 0.6
                                else return 0.0
            }
        }

        // --- SOUND TRIGGERS ---
        function playSound(soundName) {
            if (!atmosphereWidget.soundEnabled) return;

                switch (soundName) {
                    case "ding": hourlyDing.play(); break
                    case "wind": windWhoosh.play(); break
                    case "rain": rainPatter.play(); break
                    case "snow": snowCrunch.play(); break
                }
        }


        // --- UPDATE LOGIC ---
        Component.onCompleted: {
            // Load sounds from resource if they exist
            var soundFiles = ["ding.mp3", "wind.mp3", "rain.mp3", "snow.mp3"]
            soundFiles.forEach(file => {
                if (!Qt.resourceExists(atmosphereWidget.soundDir + file)) {
                    console.warn("Sound file missing:", atmosphereWidget.soundDir + file)
                }
            })

            // Initial wallpaper update
            applyWallpaperWithBrightness()

            // Watch weather condition changes
            if (currentProvider) {
                currentProvider.onCurrentConditionChanged.connect(function() {
                    var cond = currentProvider.currentCondition.toLowerCase()
                    if (cond.includes("rain") && !rainContainer.visible) playSound("rain");
                    if (cond.includes("snow") && !snowContainer.visible) playSound("snow");
                        applyWallpaperWithBrightness();
                })
            }

            // Watch wind speed/direction changes
            meteogramModel.onDataChanged.connect(function() {
                if (meteogramModel.count > 0) {
                    windDirection = meteogramModel.get(0).windDirection
                    var windSpeed = meteogramModel.get(0).windSpeedMps
                    if (windSpeed > 7) {
                        playSound("wind")
                    }
                }
            })

            // Ensure we get initial wind direction
            if (meteogramModel.count > 0) {
                windDirection = meteogramModel.get(0).windDirection
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            dbgprint2("Timer Triggered")
            var now=dateNow()
            dbgprint("*** loadingData Flag : " + loadingData.loadingDatainProgress)
            dbgprint("*** loadingData failedAttemptCount : " + loadingData.failedAttemptCount)
            dbgprint("*** Last Load Success: " + (loadingData.lastloadingSuccessTime))
            dbgprint("*** Next Load Due    : " + (currentPlace.nextReload))
            dbgprint("*** Time Now         : " + now)
            dbgprint("*** Next Load in     : " + Math.round((currentPlace.nextReload - now) / 1000) + " sec = "+ ((currentPlace.nextReload - now) / 60000).toFixed(2) + " min")

            updateLastReloadedText()
            // if ((loadingData.lastloadingSuccessTime === 0) && (updatingPaused)) {
                // currentPlace.nextReload=now + 60000()
            // }

            if (loadingData.loadingDatainProgress) {
                dbgprint("Timeout in:" + (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs - now))
                if (now > (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs)) {
                    loadingData.failedAttemptCount++
                    let retryTime = Math.min(loadingData.failedAttemptCount, 30) * 30
                    console.log("Timed out downloading weather data - aborting attempt. Retrying in " + retryTime  +" seconds time.")
                    loadingData.loadingDatainProgress = false
                    loadingData.lastloadingSuccessTime = 0
                    currentPlace.nextReload = now + (retryTime * 1000)
                    loadingDataComplete = true
                }
            } else {
                if (now > currentPlace.nextReload) {
                    loadDataFromInternet()
                }
            }
        }
    }
