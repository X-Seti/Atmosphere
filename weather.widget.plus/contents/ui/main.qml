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
import QtQuick.Controls
import QtQuick.Controls.Material
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
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

    // switchWidth: inTray ? 256 : undefined
    // switchHeight: inTray ? 128 : undefined

    preferredRepresentation: inTray ? undefined : onDesktop ? (desktopMode === 1 ? fullRepresentation : compactRepresentation) : compactRepresentation

    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    property bool onDesktop: (plasmoid.location === PlasmaCore.Types.Desktop || plasmoid.location === PlasmaCore.Types.Floating)


    toolTipTextFormat: Text.RichText

    // User Preferences
    property int mgAxisFontSize: plasmoid.configuration.mgAxisFontSize
    property int mgPressureFontSize: plasmoid.configuration.mgPressureFontSize
    property int mgHoursFontSize: plasmoid.configuration.mgHoursFontSize
    property int mgTrailingZeroesFontSize: plasmoid.configuration.mgTrailingZeroesFontSize
    // property int tempLabelPosition: plasmoid.configuration.tempLabelPosition
    // property int pressureLabelPosition: plasmoid.configuration.pressureLabelPosition

    property int hourSpanOm: plasmoid.configuration.hourSpanOm
    property int widgetWidth: plasmoid.configuration.widgetWidth
    property int widgetHeight: plasmoid.configuration.widgetHeight
    property int layoutType: plasmoid.configuration.layoutType
    property int widgetOrder: plasmoid.configuration.widgetOrder
    property int desktopMode: plasmoid.configuration.desktopMode
    property int iconSizeMode: plasmoid.configuration.iconSizeMode
    property int textSizeMode: plasmoid.configuration.textSizeMode
    property bool debugLogging: plasmoid.configuration.debugLogging
    property bool diaryLoggingEnabled: plasmoid.configuration.diaryLoggingEnabled
    property int inTrayActiveTimeoutSec: plasmoid.configuration.inTrayActiveTimeoutSec
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
                                   loadingDatainProgress: false,            // Download Attempt in progress Flag.
                                   loadingDataTimeoutMs: 15000,             // Download Timeout in ms.
                                   loadingXhrs: [],                         // Array of Download Attempt Objects
                                   loadingError: false,                     // Whether the last Download Attempt was successful
                                   lastloadingStartTime: 0,                 // Time download last attempted.
                                   lastloadingSuccessTime: 0,               // Time download last successful.
                                   failedAttemptCount: 0
                               })
    property string lastReloadedText: "⬇ " + i18n("%1 ago", "?? min")

    property var cacheData: ({
                                 plasmoidCacheId: plasmoid.id,
                                 cacheKey: "",
                                 cacheMap: ({})
                             })

    // Current Place Data
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
                                 reloadIntervalMin: 0 ,   // Download Attempt Frequency in minutes
                                 reloadIntervalMs: 0,               // Download Attempt Frequency in milliseconds
                                 nextReload: 0                 // Time next download is due.
                             })

    property bool useOnlineWeatherData: true

    // === SUNRISE/SUNSET API MANAGER ===

    property string sunriseSunsetUrl: "https://api.sunrise-sunset.org/json?lat=" + latitude + "&lng=" + longitude + "&formatted=0"
    property real latitude: 0
    property real longitude: 0
    property date localSunrise: new Date(0)
    property date localSunset: new Date(0)
    property bool hasSunData: false
    property int lastSunUpdate: 0 // timestamp of last successful fetch



    /* Data Models */
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
        var now=new Date().getTime()
        return now
    }

    function setCurrentProviderAccordingId(providerId) {
        currentPlace.providerId = providerId
        if (providerId === "owm") {
            dbgprint("setting provider OpenWeatherMap")
            return owmProvider
        }
        if (providerId === "metno") {
            dbgprint("setting provider metno")
            return metnoProvider
        }
        if (providerId === "om") {
            dbgprint("setting provider OpenMeteo")
            return omProvider
        }
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
    function setNextPlace(initial,direction) {
        if (direction === undefined) {
            direction = "+"
        }
        currentWeatherModel=emptyWeatherModel()
        nextDaysModel.clear()
        meteogramModel.clear()


        var places = ConfigUtils.getPlacesArray()
        placesCount = places.length
        var placeIndex = plasmoid.configuration.placeIndex
        dbgprint("places count=" + placesCount + ", placeIndex=" + plasmoid.configuration.placeIndex)
        if (!initial) {
            (direction === "+") ? placeIndex++ : placeIndex--
        }
        if (placeIndex > places.length - 1) {
            placeIndex = 0
        }
        if (placeIndex < 0 ) {
            placeIndex = places.length - 1
        }
        plasmoid.configuration.placeIndex = placeIndex
        dbgprint("placeIndex now: " + plasmoid.configuration.placeIndex)
        var placeObject = places[placeIndex]

        currentPlace.identifier = placeObject.placeIdentifier
        currentPlace.alias = placeObject.placeAlias
        currentPlace.timezoneID = placeObject.timezoneID
        currentPlace.providerId = placeObject.providerId
        currentPlace.provider = setCurrentProviderAccordingId(placeObject.providerId)

        if (placeObject.timezoneID === undefined) {
            currentPlace.timezoneID = -1
        } else {
            currentPlace.timezoneID = parseInt(placeObject.timezoneID)
        }


        let tzData = TZ.TZData[currentPlace.timezoneID]
        currentPlace.timezoneShortName = "LOCAL"
        if (currentPlace.providerId === "metno") {
            if (TZ.isDST(tzData.DSTData)){
                currentPlace.timezoneShortName = tzData.DSTName
                currentPlace.timezoneOffset = parseInt(tzData.DSTOffset)
            } else {
                currentPlace.timezoneShortName = tzData.TZName
                currentPlace.timezoneOffset = parseInt(tzData.Offset)
            }
        }
        if (currentPlace.providerId === "om") {
            if (TZ.isDST(tzData.DSTData)){
                currentPlace.timezoneShortName = tzData.DSTName
                currentPlace.timezoneOffset = parseInt(tzData.DSTOffset)
            } else {
                currentPlace.timezoneShortName = tzData.TZName
                currentPlace.timezoneOffset = parseInt(tzData.Offset)
            }
        }

        fullRepresentationAlias = currentPlace.alias


        cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
        currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)
        dbgprint("cacheKey for " + currentPlace.identifier + " is: " + currentPlace.cacheID)
        cacheData.alreadyLoadedFromCache = false

        var ok = loadFromCache()
        dbgprint("CACHE " + ok)
        if (!ok) {
            loadDataFromInternet()
        }
    }
    function loadDataFromInternet() {
        dbgprint2("loadDataFromInternet")

        if (loadingData.loadingDatainProgress) {
            dbgprint("still loading")
            return
        }
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
        dbgprint2("dataLoadedFromInternet")
        dbgprint("Data Loaded From Internet successfully")

        loadingData.lastloadingSuccessTime = dateNow()
        loadingData.loadingDatainProgress = false
        loadingData.nextReload = dateNow() + timerData.reloadIntervalMs
        loadingData.failedAttemptCount = 0
        currentPlace.nextReload = dateNow() + timerData.reloadIntervalMs

        nextDaysCount = nextDaysModel.count

        updateLastReloadedText()
        updateCompactItem()
        refreshTooltipSubText()

        // ✅ UI refresh should ALWAYS happen
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)
        meteogramModelChanged = !meteogramModelChanged
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)

        // ✅ GUARD (logic-only)
        if (!currentWeatherModel || currentWeatherModel.temperature === -9999) {
            dbgprint("Diary: weather model not ready yet")
            saveToCache()
            return
        }

        // ✅ DAILY LOGGING
        var today = new Date().toISOString().slice(0, 10)

        if (plasmoid.configuration.diaryLoggingEnabled && plasmoid.configuration.lastLoggedDate !== today) {
            // Show diary entry dialog to get additional information
            showDiaryEntryDialog({
                temperature: currentWeatherModel.temperature,
                humidity: currentWeatherModel.humidity,
                pressureHpa: currentWeatherModel.pressureHpa,
                condition: IconTools.getConditionText(
                    currentWeatherModel.iconName,
                    currentPlace.providerId
                )
            })
            plasmoid.configuration.lastLoggedDate = today
        }

        saveToCache()
    }

    function reloadDataFailureCallback() {
        dbgprint("Failed to Load Data successfully")
        cacheData.loadingDatainProgress = false
        dbgprint("Error getting weather data. Scheduling data reload...")
        loadingData.nextReload = dateNow()
        loadFromCache()
    }
    function updateLastReloadedText() {
        dbgprint("updateLastReloadedText: " + loadingData.lastloadingSuccessTime)
        if (loadingData.lastloadingSuccessTime > 0) {
            lastReloadedText = '⬇ ' + DataLoader.getLastReloadedTimeText(dateNow() - loadingData.lastloadingSuccessTime)
        }
        plasmoid.status = DataLoader.getPlasmoidStatus(loadingData.lastloadingSuccessTime, inTrayActiveTimeoutSec)
        dbgprint(plasmoid.status)
    }
    function updateCompactItem(){
        dbgprint2("updateCompactItem")
        dbgprint(JSON.stringify(currentWeatherModel))
        let icon = currentWeatherModel.iconName
        iconNameStr = (icon > 0) ? IconTools.getIconCode(icon, currentPlace.providerId, currentWeatherModel.isDay) : '\uf07b'
        temperatureStr = currentWeatherModel.temperature !== 9999 ? UnitUtils.getTemperatureNumberExt(currentWeatherModel.temperature, temperatureType) : '--'
    }

    function refreshTooltipSubText() {
        // dbgprint(JSON.stringify(currentWeatherModel))
        dbgprint2("refreshTooltipSubText")
        if (currentWeatherModel === undefined || currentWeatherModel.nearFutureWeather.iconName === null || currentWeatherModel.count === 0) {
            dbgprint("model not yet ready")
            return
        }
        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }
        // for(const [key,value] of Object.entries(currentWeatherModel)) { console.log(`  ${key}: ${value}`) }

        var nearFutureWeather = currentWeatherModel.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentPlace.providerId, (currentWeatherModel.isDay ? 1 : 0))
        var wind1=Math.round(currentWeatherModel.windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var lastReloadedSubText = lastReloadedText
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
        if (timezoneType === 0) { tzName = getLocalTimeZone() }
        if (timezoneType === 1) { tzName = "GMT" }
        if (timezoneType === 2) { tzName = currentPlace.timezoneShortName }
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

    // Other code - X-Seti
    function fetchSunriseSunset() {
        if (!plasmoid.configuration.useSunriseSunset) return

            var xhr = new XMLHttpRequest()
            xhr.open("GET", sunriseSunsetUrl, true)
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var data = JSON.parse(xhr.responseText)
                            if (data.status === "OK") {
                                // Parse ISO8601 strings into Date objects
                                var sunriseUTC = new Date(data.results.sunrise)
                                var sunsetUTC = new Date(data.results.sunset)

                                // Convert UTC to local time using timezoneOffset
                                var offsetMs = timezoneOffset * 60 * 1000 // offset in milliseconds
                                localSunrise = new Date(sunriseUTC.getTime() + offsetMs)
                                localSunset = new Date(sunsetUTC.getTime() + offsetMs)

                                // Log for debugging
                                dbgprint("Sunrise: " + Qt.formatDateTime(localSunrise, Qt.DefaultLocaleShortDate))
                                dbgprint("Sunset: " + Qt.formatDateTime(localSunset, Qt.DefaultLocaleShortDate))

                                hasSunData = true
                                lastSunUpdate = Date.now()

                                // Trigger wallpaper and effect updates
                                applyWallpaperWithBrightness()
                                updateAdditionalWeatherInfoText()
                            }
                        } catch (e) {
                            dbgprint("Error parsing sunrise/sunset API: " + e.message)
                            hasSunData = false
                        }
                    } else {
                        dbgprint("Sunrise/sunset API request failed: " + xhr.status)
                        hasSunData = false
                    }
                }
            }
            xhr.send()
    }


    // --- INITIALIZE LOCATION ---
    Component.onCompleted: {
        dbgprint2("MAIN.QML")
        dbgprint((currentPlace))

        if (plasmoid.configuration.firstRun) {
            let URL =  Qt.resolvedUrl("../code/db/GI.csv")   // DEBUGGING ONLY
            var xhr = new XMLHttpRequest()
            xhr.timeout = loadingData.loadingDataTimeoutMs;
            dbgprint('Test local file opening - url: ' + URL)
            xhr.open('GET', URL)
            xhr.setRequestHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 ")
            xhr.send()
            xhr.onload =  (event) => {
                dbgprint("env_QML_XHR_ALLOW_FILE_READ = 1. Using Builtin Location databases...")
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
        timerData.reloadIntervalMin=plasmoid.configuration.reloadIntervalMin
        timerData.reloadIntervalMs=timerData.reloadIntervalMin * 60000

        dbgprint("plasmoid.formFactor:" + plasmoid.formFactor)
        dbgprint("plasmoid.location:" + plasmoid.location)
        dbgprint("plasmoid.configuration.layoutType:" + plasmoid.configuration.layoutType)
        dbgprint("plasmoid.containment.containmentType:" + plasmoid.containment.containmentType)
        if (inTray) {
            dbgprint("IN TRAY!")
        }

        dbgprint2(" Load Cache")
        var cacheContent = weatherCache.readCache()

        dbgprint("readCache result length: " + cacheContent.length)

        // fill cache
        if (cacheContent) {
            try {
                cacheData.cacheMap = JSON.parse(cacheContent)
                dbgprint("cacheMap initialized - keys:")
                for (var key in cacheData.cacheMap) {
                    dbgprint("  " + key + ", data: " + cacheData.cacheMap[key])
                }
            } catch (error) {
                dbgprint("error parsing cacheContent")
            }
        }
        cacheData.cacheMap = cacheData.cacheMap || {}

        dbgprint2("get Default Place")
        setNextPlace(true)

    }

    onTimezoneTypeChanged: {
        if (currentPlace.identifier !== "") {
            dbgprint2('timezoneType changed')
            cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
            currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)
            dbgprint("cacheKey for " + currentPlace.identifier + " is: " + currentPlace.cacheID)
            cacheData.alreadyLoadedFromCache = false
            loadDataFromInternet()
            meteogramModelChanged = ! meteogramModelChanged
        }
    }

    function loadFromCache() {
        dbgprint2("loadFromCache")
        dbgprint('loading from cache, config key: ' + cacheData.cacheKey)

        if (cacheData.alreadyLoadedFromCache) {
            dbgprint('already loaded from cache')
            return true
        }
        if (!cacheData.cacheMap || !cacheData.cacheMap[cacheData.cacheKey]) {
            dbgprint('cache not available')
            return false
        }

        currentPlace = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][1])
        currentPlace.provider = setCurrentProviderAccordingId(currentPlace.providerId)

        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }

        currentWeatherModel = cacheData.cacheMap[cacheData.cacheKey][2]
        // dbgprint("currentPlace:\t"  + currentPlace.alias + "\t" + currentPlace.identifier + "\t" + currentPlace.timezoneID + "\t" + currentPlace.timezoneShortName + "\t")
        // dbgprint(JSON.stringify(currentWeatherModel))
        let meteogramModelData = JSON.parse( cacheData.cacheMap[cacheData.cacheKey][3])
        let nextDaysModelData = JSON.parse( cacheData.cacheMap[cacheData.cacheKey][4])
        // dbgprint(cacheData.cacheMap[cacheData.cacheKey][4])
        meteogramModel.clear()
        for (var i = 0; i < meteogramModelData.length; ++i) {
            meteogramModelData[i]['from'] = new Date(Date.parse(meteogramModelData[i]['from']))
            meteogramModelData[i]['to'] = new Date(Date.parse(meteogramModelData[i]['to']))
            meteogramModel.append(meteogramModelData[i])
        }

        nextDaysModel.clear()
        for (var i = 0; i < nextDaysModelData.length; ++i) {
            // meteogramModelData[i]['from'] = new Date(Date.parse(meteogramModelData[i]['from']))
            // meteogramModelData[i]['to'] = new Date(Date.parse(meteogramModelData[i]['to']))
            nextDaysModel.append(nextDaysModelData[i])
        }
        dbgprint(nextDaysModelData.length)
        nextDaysCount = nextDaysModel.count

        updateCompactItem()
        refreshTooltipSubText()
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)
        meteogramModelChanged = !meteogramModelChanged
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)

        return true
    }


    function saveToCache() {
        dbgprint2("saveCache")
        dbgprint(currentPlace.alias)
        let cacheID = currentPlace.cacheID


        var meteogramModelData = ([])
        for (var i = 0; i < meteogramModel.count; ++i) {
            meteogramModelData.push(meteogramModel.get(i))
        }

        var nextDayModelData = ([])
        for (i = 0; i < nextDaysModel.count; ++i) {
            // dbgprint(JSON.stringify(nextDaysModel.get(i)))
            nextDayModelData.push(nextDaysModel.get(i))
        }
        currentPlace.provider = ""
        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }

        let contentToCache = {1: JSON.stringify(currentPlace), 2: currentWeatherModel, 3: JSON.stringify(meteogramModelData), 4: JSON.stringify(nextDayModelData)}
        print("saving cacheKey = " + cacheID)
        cacheData.cacheMap[cacheID] = contentToCache
    }

    function showDiaryEntryDialog(weatherData) {
        // Check if diary logging is enabled
        if (!plasmoid.configuration.diaryLoggingEnabled) {
            return;
        }
        
        // Create and show the diary entry dialog
        diaryEntryDialog.weatherData = weatherData;
        diaryEntryDialog.open();
    }

    // Diary Entry Dialog Component
    PlasmaComponents.Dialog {
        id: diaryEntryDialog
        title: i18n("Add to Daily Diary")

        //flags: Qt.Dialog | Qt.WindowCloseButtonHint
        
        property var weatherData: null
        
        standardButtons: PlasmaComponents.Dialog.Ok | PlasmaComponents.Dialog.Cancel
        
        onAccepted: {
            // Save the diary entry with the user input
            Diary.appendWeather(diaryEntryDialog.weatherData, diaryTextInput.text);
        }
        
        onRejected: {
            // Save the diary entry with no additional input
            Diary.appendWeather(diaryEntryDialog.weatherData, "");
        }
        
        contentItem: Item {
            id: dialogContentItem
            width: 400
            height: 200
            
            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                PlasmaComponents.Label {
                    text: i18n("Add your health notes for today:")
                    wrapMode: Text.Wrap
                }
                
                TextArea {
                    id: diaryTextInput
                    placeholderText: i18n("e.g., not much sleep, Pain is very high 8/10. (in bed)")
                    selectByMouse: true
                    focus: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    Keys.onReturnPressed: {
                        if (Qt.keyboard.modifiers & Qt.ControlModifier) {
                            diaryEntryDialog.accept();
                        }
                    }
                    Keys.onEnterPressed: {
                        if (Qt.keyboard.modifiers & Qt.ControlModifier) {
                            diaryEntryDialog.accept();
                        }
                    }
                }
            }
        }
    }


    // X-Seti July 14 - 2025

    function updateAdditionalWeatherInfoText() {
        if (additionalWeatherInfo === undefined || additionalWeatherInfo.nearFutureWeather.iconName === null || actualWeatherModel.count === 0) {
            dbgprint('model not yet ready')
            return
        }

        // Update sunrise/sunset times if available
        if (hasSunData) {
            additionalWeatherInfo.sunRise = localSunrise
            additionalWeatherInfo.sunSet = localSunset
        }

        var sunRise = UnitUtils.convertDate(additionalWeatherInfo.sunRise, timezoneType, timezoneOffset)
        var sunSet = UnitUtils.convertDate(additionalWeatherInfo.sunSet, timezoneType, timezoneOffset)
        additionalWeatherInfo.sunRiseTime = Qt.formatTime(sunRise, Qt.locale().timeFormat(Locale.ShortFormat))
        additionalWeatherInfo.sunSetTime = Qt.formatTime(sunSet, Qt.locale().timeFormat(Locale.ShortFormat))

        var nearFutureWeather = additionalWeatherInfo.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentProvider.providerId, getPartOfDayIndex())
        var wind1 = Math.round(actualWeatherModel.get(0).windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var subText = ''
        subText += '<br /><font size="4" style="font-family: weathericons;">' + windDirectionIcon + '</font><font size="4"> ' + wind1 + '\u00B0 &nbsp; @ ' + UnitUtils.getWindSpeedText(actualWeatherModel.get(0).windSpeedMps, windSpeedType) + '</font>'
        subText += '<br /><font size="4">' + UnitUtils.getPressureText(actualWeatherModel.get(0).pressureHpa, pressureType) + '</font>'
        subText += '<br /><table>'
        if ((actualWeatherModel.get(0).humidity !== undefined) && (actualWeatherModel.get(0).cloudiness !== undefined)) {
            subText += '<tr>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf07a</font>&nbsp;' + actualWeatherModel.get(0).humidity + '%</font></td>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf013</font>&nbsp;' + actualWeatherModel.get(0).cloudiness + '%</font></td>'
            subText += '</tr>'
            subText += '<tr><td>&nbsp;</td><td></td></tr>'
        }
        subText += '<tr>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf051</font>&nbsp;' + additionalWeatherInfo.sunRiseTime + ' '+timezoneShortName + '&nbsp;&nbsp;&nbsp;</font></td>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf052</font>&nbsp;' + additionalWeatherInfo.sunSetTime + ' '+timezoneShortName + '</font></td>'
        subText += '</tr>'
        subText += '</table>'

        subText += '<br /><br />'
        subText += '<font size="3">' + i18n("near future") + '</font>'
        subText += '<b>'
        subText += '<font size="6">&nbsp;&nbsp;&nbsp;' + UnitUtils.getTemperatureNumber(nearFutureWeather.temperature, temperatureType) + UnitUtils.getTemperatureEnding(temperatureType)
        subText += '&nbsp;&nbsp;&nbsp;<font style="font-family: weathericons">' + futureWeatherIcon + '</font></font>'
        subText += '</b>'
        tooltipSubText = subText
    }

    function refreshTooltipSubText() {
        dbgprint('refreshing sub text')
        if (additionalWeatherInfo === undefined || additionalWeatherInfo.nearFutureWeather.iconName === null || actualWeatherModel.count === 0) {
            dbgprint('model not yet ready')
            return
        }
        updateAdditionalWeatherInfoText()
        var nearFutureWeather = additionalWeatherInfo.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentProvider.providerId, getPartOfDayIndex())
        var wind1=Math.round(actualWeatherModel.get(0).windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var subText = ''
        subText += '<br /><font size="4" style="font-family: weathericons;">' + windDirectionIcon + '</font><font size="4"> ' + wind1 + '\u00B0 &nbsp; @ ' + UnitUtils.getWindSpeedText(actualWeatherModel.get(0).windSpeedMps, windSpeedType) + '</font>'
        subText += '<br /><font size="4">' + UnitUtils.getPressureText(actualWeatherModel.get(0).pressureHpa, pressureType) + '</font>'
        subText += '<br /><table>'
        if ((actualWeatherModel.get(0).humidity !== undefined) && (actualWeatherModel.get(0).cloudiness !== undefined)) {
            subText += '<tr>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf07a</font>&nbsp;' + actualWeatherModel.get(0).humidity + '%</font></td>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf013</font>&nbsp;' + actualWeatherModel.get(0).cloudiness + '%</font></td>'
            subText += '</tr>'
            subText += '<tr><td>&nbsp;</td><td></td></tr>'
        }
        subText += '<tr>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf051</font>&nbsp;' + additionalWeatherInfo.sunRiseTime + ' '+timezoneShortName + '&nbsp;&nbsp;&nbsp;</font></td>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf052</font>&nbsp;' + additionalWeatherInfo.sunSetTime + ' '+timezoneShortName + '</font></td>'
        subText += '</tr>'
        subText += '</table>'

        subText += '<br /><br />'
        subText += '<font size="3">' + i18n("near future") + '</font>'
        subText += '<b>'
        subText += '<font size="6">&nbsp;&nbsp;&nbsp;' + UnitUtils.getTemperatureNumber(nearFutureWeather.temperature, temperatureType) + UnitUtils.getTemperatureEnding(temperatureType)
        subText += '&nbsp;&nbsp;&nbsp;<font style="font-family: weathericons">' + futureWeatherIcon + '</font></font>'
        subText += '</b>'
        tooltipSubText = subText
    }

    function getPartOfDayIndex() {
        var now = new Date().getTime()
        let sunrise1 = additionalWeatherInfo.sunRise.getTime()
        let sunset1 = additionalWeatherInfo.sunSet.getTime()
        let icon = ((now > sunrise1) && (now < sunset1)) ? 0 : 1
        // setDebugFlag(true)
        dbgprint(JSON.stringify(additionalWeatherInfo))
        dbgprint("NOW = " + now + "\tSunrise = " + sunrise1 + "\tSunset = " + sunset1 + "\t" + (icon === 0 ? "isDay" : "isNight"))
        dbgprint("\t > Sunrise:" + (now > sunrise1) + "\t\t Sunset:" + (now < sunset1))
        // setDebugFlag(false)

        return icon
    }

    function abortTooLongConnection(forceAbort) {
        if (!loadingData) {
            return
        }
        if (forceAbort) {
            dbgprint('timeout reached, aborting existing xhrs')
            loadingXhrs.forEach(function (xhr) {
                xhr.abort()
            })
            reloadDataFailureCallback()
        } else {
            dbgprint('regular loading, no aborting yet')
            return
        }
    }

    function tryReload() {
        updateLastReloadedText()

        if (updatingPaused) {
            return
        }

        reloadData()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            var now=dateNow()
            dbgprint("*** Timer triggered")
            dbgprint("*** loadingData Flag : " + loadingData)
            dbgprint("*** Last Load Success: " + (lastloadingSuccessTime))
            dbgprint("*** Next Load Due    : " + (nextReload))
            dbgprint("*** Time Now         : " + now)
            dbgprint("*** Next Load in     : " + Math.round((nextReload - now) / 1000) + " sec = "+ ((nextReload - now) / 60000).toFixed(2) + " min")

            updateLastReloadedText()
            if ((lastloadingSuccessTime===0) && (updatingPaused)) {
                toggleUpdatingPaused()
            }

            if (loadingData) {
                dbgprint("Timeout in:" + (lastloadingStartTime + loadingDataTimeoutMs - now))
                if (now > (lastloadingStartTime + loadingDataTimeoutMs)) {
                    console.log("Timed out downloading weather data - aborting attempt. Retrying in 60 seconds time.")
                    abortTooLongConnection(true)
                    nextReload=now + 60000
                }
            } else {
                if (now > nextReload) {
                    tryReload()
                }
            }
        }
    }

    onTemperatureTypeChanged: {
        refreshTooltipSubText()
    }

    onPressureTypeChanged: {
        refreshTooltipSubText()
    }

    onWindSpeedTypeChanged: {
        refreshTooltipSubText()
    }

    onTwelveHourClockEnabledChanged: {
        refreshTooltipSubText()
    }

    onTimezoneTypeChanged: {
        if (lastloadingSuccessTime > 0) {
            refreshTooltipSubText()
        }
    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print('[weatherWidget] ' + msg)
    }

    function dateNow() {
        var now=new Date().getTime()
        return now
    }

    function setDebugFlag(flag) {
        debugLogging = flag
    }

    function getLocalTimeZone() {
        return dataSource.data["Local"]["Timezone Abbreviation"]
    }

    // === HOVER FEELS LIKE TOOLTIP ===
    Item {
        id: feelsLikeTooltip
        width: 180
        height: 80
        visible: false
        z: 2000 // Always on top
        opacity: 0
        property real targetX: 0
        property real targetY: 0

        // Background with subtle blur
        Rectangle {
            anchors.fill: parent
            color: textColorLight ? "#111111" : "#eeeeee"
            radius: 12
            border.color: textColorLight ? "#333333" : "#dddddd"
            border.width: 1
            opacity: 0.95

            // Subtle inner glow for depth
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: textColorLight ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.1)"
                border.width: 1
                radius: 11
            }
        }

        // Text content
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: i18n("Feels like %1°", atmosphereWidget.feelsLikeTemp)
                font.pixelSize: widgetFontSize * 0.75
                color: textColorLight ? "#ffffff" : "#111111"
                font.bold: true
            }
            Text {
                text: atmosphereWidget.comfortLevel + " • " + atmosphereWidget.weatherMood
                font.pixelSize: widgetFontSize * 0.65
                color: textColorLight ? "#cccccc" : "#555555"
            }
        }

        // Animation: Fade in/out
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        // Position: Centered above the temperature display
        x: atmosphereWidget.temperatureLabel.x + (atmosphereWidget.temperatureLabel.width - width) / 2
        y: atmosphereWidget.temperatureLabel.y - height - 10

        // Hide by default
        Component.onCompleted: {
            visible = false
            opacity = 0
        }
    }

    // --- MOUSE AREA TO TRIGGER TOOLTIP ---
    MouseArea {
        id: tempHoverArea
        anchors.fill: temperatureLabel // <-- This assumes your main temp label is named 'temperatureLabel'
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            feelsLikeTooltip.visible = true
            feelsLikeTooltip.opacity = 1
        }

        onExited: {
            feelsLikeTooltip.opacity = 0
            setTimeout(function() {
                feelsLikeTooltip.visible = false
            }, 250)
        }
    }
    // === ATMOSPHERE WIDGET (ALL-IN-ONE) ===
    Item {
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
            enabled: atmosphereWidget.soundEnabled
        }

        SoundEffect {
            id: windWhoosh
            source: soundDir + "wind.mp3"
            volume: 0.2
            enabled: atmosphereWidget.soundEnabled
        }

        SoundEffect {
            id: rainPatter
            source: soundDir + "rain.mp3"
            volume: 0.25
            enabled: atmosphereWidget.soundEnabled
        }

        SoundEffect {
            id: snowCrunch
            source: soundDir + "snow.mp3"
            volume: 0.2
            enabled: atmosphereWidget.soundEnabled
        }

        // --- WALLPAPER PATHS (USE YOUR EXACT PATHS) ---
        property string morningWallpaper: "/home/x2/Wallpapers/System-Defaults/fruitdark.jpg"
        property string afternoonWallpaper: "/home/x2/Wallpapers/System-Defaults/fruit.jpg"
        property string eveningWallpaper: "/home/x2/Wallpapers/System-Defaults/fruitdarker.jpg"
        property string nightWallpaper: "/home/x2/Wallpapers/System-Defaults/fruitdarkest.jpg"

        // --- BASE IMAGE FOR BRIGHTNESS ADJUSTMENT ---
        property string baseWallpaper: afternoonWallpaper // Use brightest as base for modulate

        // --- CALCULATE TIME-BASED WALLPAPER ---

        property string selectedWallpaper: {
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
            if (!path) return

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
                qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript(script)
                console.log("Wallpaper updated:", path, "brightness:", calculatedBrightness)
            } catch (e) {
                console.error("DBus wallpaper error:", e.message)
            }
        }

        // --- SUN GLINT (GENTLE HIGHLIGHT ON SUNNY DAYS) ---
        Item {
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
        property real windDirection: actualWeatherModel.count > 0 ? actualWeatherModel.get(0).windDirection : 0

        Item {
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
                    colorVariation: 0.1
                    alpha: 0.7
                    size: 8
                    sizeVariation: 3
                    lifeSpan: 1500
                    velocityFromAngle: 90
                    velocityFromMagnitude: 110 + (actualWeatherModel.count > 0 ? actualWeatherModel.get(0).windSpeedMps * 8 : 0)
                    velocityVariation: 30
                }

                Emitter {
                    anchors.fill: parent
                    emitRate: 150
                    lifeSpan: 1500
                    lifeSpanVariation: 200
                }
            }
        }

        Item {
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
                    color: "#ffffff"
                    alpha: 0.9
                    size: 12
                    sizeVariation: 4
                    lifeSpan: 4000
                    velocityFromAngle: 90
                    velocityFromMagnitude: 15 + (actualWeatherModel.count > 0 ? actualWeatherModel.get(0).windSpeedMps * 2 : 0)
                    velocityVariation: 30
                    rotationSpeed: 100
                    rotationSpeedVariation: 50
                }

                Emitter {
                    anchors.fill: parent
                    emitRate: 60
                    lifeSpan: 4000
                    lifeSpanVariation: 500
                }
            }
        }

        // --- DAY/NIGHT OVERLAY (SOFT DIMMING) ---
        Rectangle {
            id: lightingOverlay
            anchors.fill: parent
            color: "black"
            opacity: 0
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
            if (!atmosphereWidget.soundEnabled) return

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

            // Update every minute (for time changes)
            Timer {
                interval: 60 * 1000
                repeat: true
                running: true
                onTriggered: {
                    applyWallpaperWithBrightness()

                    // Play ding on the hour
                    var now = new Date()
                    if (now.getMinutes() === 0) {
                        playSound("ding")
                    }

                    // Trigger wind sound on high wind
                    if (actualWeatherModel.count > 0) {
                        var windSpeed = actualWeatherModel.get(0).windSpeedMps
                        if (windSpeed > 7) {
                            playSound("wind")
                        }
                    }
                }
            }

            // Watch weather condition changes
            if (currentProvider) {
                currentProvider.onCurrentConditionChanged.connect(function() {
                    var cond = currentProvider.currentCondition.toLowerCase()
                    if (cond.includes("rain") && !rainContainer.visible) playSound("rain")
                        if (cond.includes("snow") && !snowContainer.visible) playSound("snow")
                            applyWallpaperWithBrightness()
                })
            }

            // Watch wind speed/direction changes
            actualWeatherModel.onDataChanged.connect(function() {
                if (actualWeatherModel.count > 0) {
                    windDirection = actualWeatherModel.get(0).windDirection
                    var windSpeed = actualWeatherModel.get(0).windSpeedMps
                    if (windSpeed > 7) {
                        playSound("wind")
                    }
                }
            })

            // Ensure we get initial wind direction
            if (actualWeatherModel.count > 0) {
                windDirection = actualWeatherModel.get(0).windDirection
            }
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
}
