/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Window 2.15
import QtMultimedia 5.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "providers"
import "../code/data-loader.js" as DataLoader
import "../code/config-utils.js" as ConfigUtils
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils
import "../code/timezoneData.js" as TZ
import "../code/diary.js" as Diary
import "../code/dailyState.js" as State
import "gui" as DiaryUI
//import "gui" as AtmosphereWidget

PlasmoidItem {
    id: main

    /* Includes */
    WeatherCache {
        id: weatherCache
        cacheId: cacheData.plasmoidCacheId
    }
    Plasma5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 0
    }
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
        function exec(cmd) {
            connectSource(cmd)
        }
    }
    FontLoader {
        source: "../fonts/weathericons-regular-webfont-2.0.11.ttf"
    }
    OpenMeteo {
        id: omProvider
    }
    MetNo {
        id: metnoProvider
    }
    OpenWeatherMap {
        id: owmProvider
    }
    property bool loadingDataComplete: false

    /* GUI layout stuff */
    property Component fr: FullRepresentation { }
    property Component cr: CompactRepresentation { }
    property Component frInTray: FullRepresentationInTray { }
    property Component crInTray: CompactRepresentationInTray { }

    compactRepresentation: inTray ? crInTray : cr
    fullRepresentation: inTray ? frInTray : fr

    preferredRepresentation: inTray ? undefined : onDesktop ? (desktopMode === 1 ? fullRepresentation : compactRepresentation) : compactRepresentation

    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    property bool onDesktop: (plasmoid.location === PlasmaCore.Types.Desktop || plasmoid.location === PlasmaCore.Types.Floating)

    toolTipTextFormat: Text.RichText

    // User Preferences
    property int mgAxisFontSize: plasmoid.configuration.mgAxisFontSize
    property int mgPressureFontSize: plasmoid.configuration.mgPressureFontSize
    property int mgHoursFontSize: plasmoid.configuration.mgHoursFontSize
    property int mgTrailingZeroesFontSize: plasmoid.configuration.mgTrailingZeroesFontSize

    property int hourSpanOm: plasmoid.configuration.hourSpanOm
    property int widgetWidth: plasmoid.configuration.widgetWidth
    property int widgetHeight: plasmoid.configuration.widgetHeight
    property int layoutType: plasmoid.configuration.layoutType
    property int widgetOrder: plasmoid.configuration.widgetOrder
    property int desktopMode: plasmoid.configuration.desktopMode
    property int iconSizeMode: plasmoid.configuration.iconSizeMode
    property int textSizeMode: plasmoid.configuration.textSizeMode
    property bool debugLogging: plasmoid.configuration.debugLogging
    property int inTrayActiveTimeoutSec: plasmoid.configuration.inTrayActiveTimeoutSec
    property bool diaryLoggingEnabled: plasmoid.configuration.diaryLoggingEnabled !== undefined ? plasmoid.configuration.diaryLoggingEnabled : true
    property bool diaryAutoPopupEnabled: plasmoid.configuration.diaryAutoPopupEnabled !== undefined ? plasmoid.configuration.diaryAutoPopupEnabled : false
    property int diaryAutoPopupHour: plasmoid.configuration.diaryAutoPopupHour !== undefined ? plasmoid.configuration.diaryAutoPopupHour : 20
    property string lastAutoPopupDate: plasmoid.configuration.lastAutoPopupDate || ""
    property string diaryLogPath: {
        var logPath = plasmoid.configuration.logPath !== undefined && plasmoid.configuration.logPath !== ""
                      ? plasmoid.configuration.logPath
                      : "";
        if (!logPath || logPath === "") {
            try {
                if (executable) {
                    return "";
                } else {
                    return "/tmp";
                }
            } catch (e) {
                return "/tmp";
            }
        }
        return logPath;
    }
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "") ? Kirigami.Theme.defaultFont : plasmoid.configuration.widgetFontName
    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property int temperatureType: plasmoid.configuration.temperatureType
    property int timezoneType: plasmoid.configuration.timezoneType
    property int pressureType: plasmoid.configuration.pressureType
    property int windSpeedType: plasmoid.configuration.windSpeedType
    property int precType: plasmoid.configuration.precType
    property bool twelveHourClockEnabled: Qt.locale().timeFormat(Locale.ShortFormat).toString().indexOf('AP') > -1
    property bool env_QML_XHR_ALLOW_FILE_READ: plasmoid.configuration.qml_XHR_ALLOW_FILE_READ
    property bool inTray: (plasmoid.containment.containmentType === 129) && ((plasmoid.formFactor === 2) || (plasmoid.formFactor === 3))
    readonly property string placesStr: plasmoid.configuration.places

    // Cache, Last Load Time, Widget Status
    property string fullRepresentationAlias
    property string iconNameStr
    property string temperatureStr
    property bool meteogramModelChanged: false
    property int nextDaysCount

    property var loadingData: ({
                                   loadingDatainProgress: false,
                                   loadingDataTimeoutMs: 15000,
                                   loadingXhrs: [],
                                   loadingError: false,
                                   lastloadingStartTime: 0,
                                   lastloadingSuccessTime: 0,
                                   failedAttemptCount: 0
                               })
    property string lastReloadedText: "⬇ " + i18n("%1 ago", "?? min")

    property var cacheData: ({
                                 plasmoidCacheId: plasmoid.id,
                                 cacheKey: "",
                                 cacheMap: ({})
                             })

    property var currentPlace: ({
                                    alias: "",
                                    identifier: "",
                                    provider: "",
                                    providerId:"",
                                    timezoneID: 0,
                                    timezoneShortName: "",
                                    timezoneOffset: 0,
                                    creditLink: "",
                                    creditLabel: "",
                                    cacheID: "",
                                    nextReload: 0
                                })

    property int placesCount

    property var timerData: ({
                                 reloadIntervalMin: 0,
                                 reloadIntervalMs: 0,
                                 nextReload: 0
                             })

    property bool useOnlineWeatherData: true

    property var currentWeatherModel
    ListModel {
        id: nextDaysModel
    }
    ListModel {
        id: meteogramModel
    }

    onLoadingDataCompleteChanged: {
        dbgprint2("loadingDataComplete:" + loadingDataComplete)
    }

    onEnv_QML_XHR_ALLOW_FILE_READChanged: {
        plasmoid.configuration.qml_XHR_ALLOW_FILE_READ = env_QML_XHR_ALLOW_FILE_READ
        dbgprint("QML_XHR_ALLOW_FILE_READ Enabled: " + env_QML_XHR_ALLOW_FILE_READ)
    }

    onPlacesStrChanged: {
        let places = ConfigUtils.getPlacesArray()
        let placesCount = places.length - 1
        let i = Math.min(plasmoid.configuration.placeIndex, placesCount)
        if (currentPlace != places[i].placeAlias) {
            setNextPlace(true)
        }
    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print("[kate weatherWidget] " + msg)
    }

    function dbgprint2(msg) {
        if (!debugLogging) {
            return
        }
        console.log("\n\n")
        console.log("*".repeat(msg.length + 4))
        console.log("* " + msg +" *")
        console.log("*".repeat(msg.length + 4))
    }

    function getLocalTimeZone() {
        return dataSource.data["Local"]["Timezone Abbreviation"]
    }

    function dateNow() {
        return new Date().getTime()
    }

    function setCurrentProviderAccordingId(providerId) {
        currentPlace.providerId = providerId
        if (providerId === "owm") return owmProvider
        if (providerId === "metno") return metnoProvider
        if (providerId === "om") return omProvider
    }

    function emptyWeatherModel() {
        return {
            temperature: -9999,
            iconName: 0,
            windDirection: 0,
            windSpeedMps: 0,
            pressureHpa: 0,
            humidity: 0,
            cloudiness: 0,
            sunRise: new Date("2000-01-01T00:00:00"),
            sunSet: new Date("2000-01-01T00:00:00"),
            sunRiseTime: "0:00",
            sunSetTime: "0:00",
            isDay: false,
            nearFutureWeather: {
                iconName: null,
                temperature: null
            }
        }
    }

    function setNextPlace(initial, direction) {
        if (direction === undefined) {
            direction = "+"
        }
        currentWeatherModel = emptyWeatherModel()
        nextDaysModel.clear()
        meteogramModel.clear()

        var places = ConfigUtils.getPlacesArray()
        placesCount = places.length
        var placeIndex = plasmoid.configuration.placeIndex

        if (!initial) {
            (direction === "+") ? placeIndex++ : placeIndex--
        }
        if (placeIndex > places.length - 1) placeIndex = 0
        if (placeIndex < 0) placeIndex = places.length - 1

        plasmoid.configuration.placeIndex = placeIndex
        var placeObject = places[placeIndex]

        currentPlace.identifier = placeObject.placeIdentifier
        currentPlace.alias = placeObject.placeAlias
        currentPlace.timezoneID = placeObject.timezoneID
        currentPlace.providerId = placeObject.providerId
        currentPlace.provider = setCurrentProviderAccordingId(placeObject.providerId)

        currentPlace.timezoneID = placeObject.timezoneID === undefined ? -1 : parseInt(placeObject.timezoneID)

        let tzData = TZ.TZData[currentPlace.timezoneID]
        currentPlace.timezoneShortName = "LOCAL"
        if (tzData) {
            if (currentPlace.providerId === "metno" || currentPlace.providerId === "om") {
                if (TZ.isDST(tzData.DSTData)) {
                    currentPlace.timezoneShortName = tzData.DSTName
                    currentPlace.timezoneOffset = parseInt(tzData.DSTOffset)
                } else {
                    currentPlace.timezoneShortName = tzData.TZName
                    currentPlace.timezoneOffset = parseInt(tzData.Offset)
                }
            }
        }

        fullRepresentationAlias = currentPlace.alias
        cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
        currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)

        var ok = loadFromCache()
        if (!ok) {
            loadDataFromInternet()
        }
    }

    function loadDataFromInternet() {
        if (loadingData.loadingDatainProgress) return
        loadingDataComplete = false
        loadingData.loadingDatainProgress = true
        loadingData.lastloadingStartTime = dateNow()
        loadingData.nextReload = -1
        currentPlace.provider = setCurrentProviderAccordingId(currentPlace.providerId)
        currentPlace.creditLink = currentPlace.provider.getCreditLink(currentPlace.identifier)
        currentPlace.creditLabel = currentPlace.provider.getCreditLabel(currentPlace.identifier)
        loadingData.loadingXhrs = currentPlace.provider.loadDataFromInternet(
                    dataLoadedFromInternet,
                    reloadDataFailureCallback,
                    { placeIdentifier: currentPlace.identifier, timezoneID: currentPlace.timezoneID })
    }

    function dataLoadedFromInternet() {
        loadingData.lastloadingSuccessTime = dateNow()
        loadingData.loadingDatainProgress = false
        loadingData.nextReload = dateNow() + timerData.reloadIntervalMs
        loadingData.failedAttemptCount = 0
        currentPlace.nextReload = dateNow() + timerData.reloadIntervalMs

        nextDaysCount = nextDaysModel.count

        updateLastReloadedText()
        updateCompactItem()
        refreshTooltipSubText()
        meteogramModelChanged = !meteogramModelChanged

        if (!currentWeatherModel || currentWeatherModel.temperature === -9999) {
            saveToCache()
            return
        }

        var today = new Date().toISOString().slice(0, 10)
        if (diaryLoggingEnabled && (plasmoid.configuration.lastLoggedDate || "") !== today) {
            showDiaryEntryDialog({
                temperature: currentWeatherModel.temperature,
                humidity: currentWeatherModel.humidity,
                pressureHpa: currentWeatherModel.pressureHpa,
                condition: currentWeatherModel ? "Current weather" : "No data"
            })
            plasmoid.configuration.lastLoggedDate = today
        }
        saveToCache()
    }

    function reloadDataFailureCallback() {
        cacheData.loadingDatainProgress = false
        loadingData.nextReload = dateNow()
        loadFromCache()
    }

    function updateLastReloadedText() {
        if (loadingData.lastloadingSuccessTime > 0) {
            lastReloadedText = '⬇ ' + DataLoader.getLastReloadedTimeText(dateNow() - loadingData.lastloadingSuccessTime)
        }
        plasmoid.status = DataLoader.getPlasmoidStatus(loadingData.lastloadingSuccessTime, inTrayActiveTimeoutSec)
    }

    function updateCompactItem(){
        let icon = currentWeatherModel.iconName
        iconNameStr = (icon > 0) ? IconTools.getIconCode(icon, currentPlace.providerId, currentWeatherModel.isDay) : '\uf07b'
        temperatureStr = currentWeatherModel.temperature !== 9999 ? UnitUtils.getTemperatureNumberExt(currentWeatherModel.temperature, temperatureType) : '--'
    }

    function refreshTooltipSubText() {
        if (currentWeatherModel === undefined || currentWeatherModel.nearFutureWeather.iconName === null || currentWeatherModel.count === 0) {
            return
        }

        var nearFutureWeather = currentWeatherModel.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentPlace.providerId, (currentWeatherModel.isDay ? 1 : 0))
        var wind1 = Math.round(currentWeatherModel.windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var subText = ""
        subText += "<br /><br /><font size=\"4\" style=\"font-family: weathericons;\">" + windDirectionIcon + "</font><font size=\"4\"> " + wind1 + "\u00B0 &nbsp; @ " + UnitUtils.getWindSpeedText(currentWeatherModel.windSpeedMps, windSpeedType) + "</font>"
        subText += "<br /><font size=\"4\">" + UnitUtils.getPressureText(currentWeatherModel.pressureHpa, pressureType) + "</font>"
        subText += "<br /><table>"
        if ((currentWeatherModel.humidity !== undefined) && (currentWeatherModel.cloudiness !== undefined)) {
            subText += "<tr>"
            subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf07a</font>&nbsp;" + currentWeatherModel.humidity + "%</font></td>"
            subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf013</font>&nbsp;" + currentWeatherModel.cloudiness + "%</font></td>"
            subText += "</tr>"
            subText += "<tr><td>&nbsp;</td><td></td></tr>"
        }
        subText += "<tr>"
        let tzName = "GMT"
        if (timezoneType === 0) tzName = getLocalTimeZone()
        if (timezoneType === 1) tzName = "GMT"
        if (timezoneType === 2) tzName = currentPlace.timezoneShortName
        subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf051</font>&nbsp;" + currentWeatherModel.sunRiseTime + " " + tzName + "&nbsp;&nbsp;&nbsp;</font></td>"
        subText += "</tr>"
        subText += "<tr>"
        subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf052</font>&nbsp;" + currentWeatherModel.sunSetTime + " " + tzName + "</font></td>"
        subText += "</tr>"
        subText += "</table>"

        subText += "<br /><br />"
        subText += "<font size=\"3\">" + i18n("near future") + ":" + "</font>"
        subText += "<b>"
        subText += "<font size=\"6\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + UnitUtils.getTemperatureNumber(nearFutureWeather.temperature, temperatureType) + "°"
        subText += "&nbsp;&nbsp;<font style=\"font-family: weathericons\">" + futureWeatherIcon + "</font></font>"
        subText += "</b>"
        toolTipMainText = currentPlace.alias
        toolTipSubText = lastReloadedText + subText
    }

    Component.onCompleted: {
        if (plasmoid.configuration.firstRun) {
            let URL = Qt.resolvedUrl("../code/db/GI.csv")
            var xhr = new XMLHttpRequest()
            xhr.timeout = loadingData.loadingDataTimeoutMs
            xhr.open('GET', URL)
            xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 ")
            xhr.send()
            xhr.onload = (event) => {
                env_QML_XHR_ALLOW_FILE_READ = true
            }

            if (plasmoid.configuration.widgetFontSize === undefined) {
                plasmoid.configuration.widgetFontSize = 30
                widgetFontSize = 20
            }

            switch (Qt.locale().measurementSystem) {
            case (Locale.MetricSystem):
                plasmoid.configuration.temperatureType = 0
                plasmoid.configuration.pressureType = 0
                plasmoid.configuration.windSpeedType = 2
                break;
            case (Locale.ImperialUSSystem):
                plasmoid.configuration.temperatureType = 1
                plasmoid.configuration.pressureType = 1
                plasmoid.configuration.windSpeedType = 1
                break;
            case (Locale.ImperialUKSystem):
                plasmoid.configuration.temperatureType = 0
                plasmoid.configuration.pressureType = 0
                plasmoid.configuration.windSpeedType = 1
                break;
            }
            plasmoid.configuration.firstRun = false
        }

        timerData.reloadIntervalMin = plasmoid.configuration.reloadIntervalMin
        timerData.reloadIntervalMs = timerData.reloadIntervalMin * 60000

        var cacheContent = weatherCache.readCache()
        if (cacheContent) {
            try {
                cacheData.cacheMap = JSON.parse(cacheContent)
            } catch (error) {
                // Ignore parsing errors
            }
        }
        cacheData.cacheMap = cacheData.cacheMap || {}

        setNextPlace(true)
    }

    onTimezoneTypeChanged: {
        if (currentPlace.identifier !== "") {
            cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
            currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)
            cacheData.alreadyLoadedFromCache = false
            loadDataFromInternet()
            meteogramModelChanged = !meteogramModelChanged
        }
    }

    function loadFromCache() {
        if (cacheData.alreadyLoadedFromCache) return true
        if (!cacheData.cacheMap || !cacheData.cacheMap[cacheData.cacheKey]) return false

        currentPlace = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][1])
        currentPlace.provider = setCurrentProviderAccordingId(currentPlace.providerId)

        currentWeatherModel = cacheData.cacheMap[cacheData.cacheKey][2]
        let meteogramModelData = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][3])
        let nextDaysModelData = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][4])

        meteogramModel.clear()
        for (var i = 0; i < meteogramModelData.length; ++i) {
            meteogramModelData[i]['from'] = new Date(Date.parse(meteogramModelData[i]['from']))
            meteogramModelData[i]['to'] = new Date(Date.parse(meteogramModelData[i]['to']))
            meteogramModel.append(meteogramModelData[i])
        }

        nextDaysModel.clear()
        for (i = 0; i < nextDaysModelData.length; ++i) {
            nextDaysModel.append(nextDaysModelData[i])
        }
        nextDaysCount = nextDaysModel.count

        updateCompactItem()
        refreshTooltipSubText()
        meteogramModelChanged = !meteogramModelChanged

        return true
    }

    function saveToCache() {
        let cacheID = currentPlace.cacheID
        var meteogramModelData = []
        for (var i = 0; i < meteogramModel.count; ++i) {
            meteogramModelData.push(meteogramModel.get(i))
        }

        var nextDayModelData = []
        for (i = 0; i < nextDaysModel.count; ++i) {
            nextDayModelData.push(nextDaysModel.get(i))
        }
        currentPlace.provider = ""

        let contentToCache = {
            1: JSON.stringify(currentPlace),
            2: currentWeatherModel,
            3: JSON.stringify(meteogramModelData),
            4: JSON.stringify(nextDayModelData)
        }
        cacheData.cacheMap[cacheID] = contentToCache
    }

    // Import DiaryDialog
    DiaryUI.DiaryDialog {
        id: diaryDialog
    }

    // Rain overlay effect
    DiaryUI.WaterPhysics {
        id: rainEffect
        anchors.fill: parent
        z: 9999

        enabled: isRaining &&
                 (plasmoid.configuration.weatherEffectsEnabled !== undefined ? plasmoid.configuration.weatherEffectsEnabled : true) &&
                 (plasmoid.configuration.particleEffectsEnabled !== undefined ? plasmoid.configuration.particleEffectsEnabled : true)

        windAngle: currentWeatherModel ? currentWeatherModel.windDirection : 0
        windSpeed: currentWeatherModel ? currentWeatherModel.windSpeedMps : 0
        rainIntensity: calculateRainIntensity()
        mouseInfluence: 30
    }

    // Helper property - determines if it's currently raining
    property bool isRaining: {
        if (!currentWeatherModel || !currentWeatherModel.iconName) return false
        var code = Number(currentWeatherModel.iconName)

        if (code >= 200 && code <= 299) return true
        if (code >= 300 && code <= 321) return true
        if (code >= 500 && code <= 531) return true
        if (code >= 51 && code <= 67) return true
        if (code >= 80 && code <= 82) return true
        if (code >= 95 && code <= 99) return true
        if (code >= 9 && code <= 12) return true

        return false
    }

    // Helper property - determines if it's currently snowing
    property bool isSnowing: {
        if (!currentWeatherModel || !currentWeatherModel.iconName) return false
        var code = Number(currentWeatherModel.iconName)

        if (code >= 600 && code <= 622) return true
        if (code >= 71 && code <= 77) return true
        if (code >= 85 && code <= 86) return true

        return false
    }

    // Single unified rain intensity calculation function
    function calculateRainIntensity() {
        if (!currentWeatherModel || !currentWeatherModel.iconName) return 0
        var code = Number(currentWeatherModel.iconName)

        if ((code >= 502 && code <= 504) || code === 212 || code === 522 || code === 65 || code === 82) return 1.0
        if (code === 501 || code === 521 || code === 10 || code === 11 || (code >= 200 && code <= 211) || code === 63 || code === 81) return 0.6
        if (code === 500 || code === 520 || code === 9 || (code >= 300 && code <= 321) || (code >= 51 && code <= 57) || code === 61 || code === 80) return 0.3

        return 0.5
    }

    // === Sound Effects Handler ===
    property bool soundEnabled: (plasmoid.configuration.weatherEffectsEnabled !== undefined ? plasmoid.configuration.weatherEffectsEnabled : true) &&
                                (plasmoid.configuration.soundEffectsEnabled !== undefined ? plasmoid.configuration.soundEffectsEnabled : false)

    Audio {
        id: weatherAudio
        source: isRaining ? "../sounds/rain.mp3" : ""
        loops: Audio.Infinite
        volume: 0.5
        running: soundEnabled && isRaining
    }

    onIsRainingChanged: {
        if (soundEnabled) {
            if (isRaining && !weatherAudio.isPlaying) {
                weatherAudio.play()
            } else if (!isRaining && weatherAudio.isPlaying) {
                weatherAudio.stop()
            }
        }
    }

    // === Dynamic Wallpaper Handler ===
    Timer {
        id: wallpaperTimer
        interval: 300000
        running: (plasmoid.configuration.weatherEffectsEnabled !== undefined ? plasmoid.configuration.weatherEffectsEnabled : true) &&
                 (plasmoid.configuration.wallpaperEffectsEnabled !== undefined ? plasmoid.configuration.wallpaperEffectsEnabled : false)
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateDynamicWallpaper()
        }
    }

    function updateDynamicWallpaper() {
        var hour = new Date().getHours()
        var wpPath = ""
        var shade = 1.0

        if (hour >= 6 && hour < 12) {
            wpPath = plasmoid.configuration.wallpaperMorning || ""
            shade = plasmoid.configuration.shadeFactorMorning || 1.0
        } else if (hour >= 12 && hour < 17) {
            wpPath = plasmoid.configuration.wallpaperAfternoon || ""
            shade = plasmoid.configuration.shadeFactorAfternoon || 1.0
        } else if (hour >= 17 && hour < 20) {
            wpPath = plasmoid.configuration.wallpaperEvening || ""
            shade = plasmoid.configuration.shadeFactorEvening || 1.0
        } else {
            wpPath = plasmoid.configuration.wallpaperNight || ""
            shade = plasmoid.configuration.shadeFactorNight || 1.0
        }

        if (wpPath !== "") {
            var cmd = "plasmoid-set-wallpaper \"" + wpPath + "\" " + shade
            executable.exec(cmd)
        }
    }

    // ORIGINAL TIMER:
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            var now = dateNow()
            updateLastReloadedText()

            if (loadingData.loadingDatainProgress) {
                if (now > (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs)) {
                    loadingData.failedAttemptCount++
                    let retryTime = Math.min(loadingData.failedAttemptCount, 30) * 30
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
}
