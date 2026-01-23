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
    property int inTrayActiveTimeoutSec: plasmoid.configuration.inTrayActiveTimeoutSec
    property bool diaryLoggingEnabled: plasmoid.configuration.diaryLoggingEnabled !== undefined ? plasmoid.configuration.diaryLoggingEnabled : true
    property bool diaryAutoPopupEnabled: plasmoid.configuration.diaryAutoPopupEnabled !== undefined ? plasmoid.configuration.diaryAutoPopupEnabled : false
    property int diaryAutoPopupHour: plasmoid.configuration.diaryAutoPopupHour !== undefined ? plasmoid.configuration.diaryAutoPopupHour : 20
    property string lastAutoPopupDate: plasmoid.configuration.lastAutoPopupDate || ""
    property string diaryLogPath: {
        // Get the log path from configuration, with fallback to home directory
        var logPath = plasmoid.configuration.logPath !== undefined && plasmoid.configuration.logPath !== "" 
                      ? plasmoid.configuration.logPath 
                      : "";
        
        // If no path is configured, use the home directory
        if (!logPath || logPath === "") {
            // Try to get HOME environment variable or use fallback
            try {
                // For KDE Plasma widgets, we'll use a more robust approach
                // If executable is available, we can use it to get the home directory
                if (executable) {
                    // We'll just return a default home path - the actual home detection 
                    // will be handled in the diary.js file
                    return "";
                } else {
                    return "/tmp";  // Fallback
                }
            } catch (e) {
                return "/tmp";  // Safe fallback
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

    // Current Weather Data
    property var currentWeatherModel: ({
                                           temperature: 0,
                                           temperatureDiff24: 0,
                                           iconName: "",
                                           provider: "",
                                           condition: "",
                                           pressureHpa: 0,
                                           humidity: 0,
                                           nearestStormDistance: 0,
                                           nearestStormBearing: 0,
                                           precipRate: 0,
                                           dewPoint: 0,
                                           windSpeedMps: 0,
                                           windDirection: 0,
                                           cloudAreaFraction: 0,
                                           created: 0
                                       })

    // Meteogram Data
    ListModel { id: meteogramModel }

    // Next Days Data
    ListModel { id: nextDaysModel }

    property var actualWeatherModel: meteogramModel
    property bool updatingPaused: false

    /* General Weather Provider Information */
    // property var providersMap: MetNo {}, OpenWeatherMap {}, OpenMeteo {}
    property var providersMap: [metnoProvider, owmProvider, omProvider]
    property var providerObject
    property var currentProvider

    /* General Formatting */
    function dbgprint(msg) {
        // if (!debugLogging) { return; }
        print('[weatherWidget] ' + msg)
    }
    function dbgprint2(msg) {
        if (!debugLogging) { return; }
        print('[weatherWidget] ' + msg)
    }

    function getTempUnit() {
        return UnitUtils.getTemperatureUnit(temperatureType)
    }

    /* Widget Tooltip */
    function refreshTooltipSubText() {
        var tooltipSubText = []

        var mainText = ""

        var conditionText = currentWeatherModel.condition
        conditionText += " " + parseInt(currentWeatherModel.temperature) + "°" + getTempUnit()

        if (currentWeatherModel.temperatureDiff24 && currentWeatherModel.temperatureDiff24 !== 0) {
            conditionText += " "
            if (currentWeatherModel.temperatureDiff24 > 0) {
                conditionText += "+"
            }
            conditionText += currentWeatherModel.temperatureDiff24.toFixed(1) + "°/24hr"
        }

        mainText += conditionText
        mainText += "\n"

        var dateTimeStr = ""
        var dt = new Date(currentWeatherModel.created)
        dateTimeStr = Qt.formatDateTime(dt, "ddd hh:mm")
        mainText += dateTimeStr

        toolTipMainText = mainText
        toolTipSubText = currentPlace.alias
    }

    function updateCompactItem() {
        iconNameStr = currentWeatherModel.iconName
        temperatureStr = UnitUtils.getTemperatureText(currentWeatherModel.temperature, temperatureType, 1)
    }

    /* NETWORKING */
    function dateNow() {
        return (new Date()).getTime()
    }

    /* Date-Time Utilities */
    function formatTimestamp(timestamp) {
        var dt = new Date(timestamp)
        return Qt.formatDateTime(dt, "ddd yyyy-MM-dd hh:mm:ss")
    }
    function getDayFromSunPositions(sunriseId, sunsetId) {
        return ({
                    iconName: 'wi-day-cloudy',
                    sunriseId: sunriseId,
                    sunsetId: sunsetId
                })
    }

    function reloadData(loadFromCache, periodMinutes) {
        dbgprint2("reloadData()")
        updatingPaused = !loadFromCache

        if (loadFromCache) {
            dbgprint2("Reload Data. Load from cache")

            if (loadFromCache()) {
                dbgprint2("Reloaded cache OK")
            } else {
                dbgprint2("Cache invalid - load from internet")
                var reloadAtTime = dateNow() + 1000
                currentPlace.nextReload = reloadAtTime
                dbgprint2("Next reload = " + formatTimestamp(currentPlace.nextReload))
            }
        } else {
            dbgprint2("Initial load - Skip cache")
            var reloadAtTime = dateNow() + 1000
            currentPlace.nextReload = reloadAtTime
        }
    }

    function reloadMeteogram() {
        // console.log("reloadMeteogram()")
        meteogramModel.clear()
        // meteogramModel = []
    }

    function loadDataFromInternet() {
        console.log("loadDataFromInternet")
        if (loadingData.loadingDatainProgress) {
            console.log("!!! Download already in progress")
            return
        }

        if (loadingData.failedAttemptCount >= 15) {
            console.log("!!! Too many failed attempts - pausing updates. Press 'Reload' button to try again.")
            updatingPaused = true
            currentPlace.nextReload = 2147483647000
            return
        }
        loadingData.loadingDatainProgress = true
        loadingData.lastloadingStartTime = dateNow()

        print("*** loadDataFromInternet")
        print("*** currentPlace.providerId = " + currentPlace.providerId)
        print("*** currentPlace.identifier = " + currentPlace.identifier)
        var providerId = currentPlace.providerId
        if ((!providerId) || (providerId.length === 0) || (providerId === "")) {
            providerId = "metno"
        }
        print("*** set currentPlace.providerId = " + providerId)

        var nextReloadIntervalMs
        var overallSuccess = true

        providerObject = DataLoader.getProviderObject(providerId, providersMap)
        currentProvider = providerObject

        var successCallback = function(completeHourlyData, longTermData) {
            // console.log(JSON.stringify(completeHourlyData))
            console.log("onSuccessCallback")
            overallSuccess = true
            loadingData.loadingError = false

            // processMetNoData(completeHourlyData)
            reloadMeteogram()

            console.log("--Hourly Data - Count=" + completeHourlyData.length)
            // console.log(JSON.stringify(completeHourlyData))
            for (var i = 0; i < completeHourlyData.length; i++) {
                var entry = completeHourlyData[i]
                // console.log(JSON.stringify(entry))
                meteogramModel.append(entry)
            }

            if (meteogramModel.count > 0) {
                var firstEntryFrom = meteogramModel.get(0).from
                currentWeatherModel.temperature = meteogramModel.get(0).temperature
                currentWeatherModel.iconName = meteogramModel.get(0).iconName
                currentWeatherModel.condition = meteogramModel.get(0).iconNameString
                currentWeatherModel.pressureHpa = meteogramModel.get(0).pressureHpa
                currentWeatherModel.humidity = meteogramModel.get(0).humidity
                currentWeatherModel.windSpeedMps = meteogramModel.get(0).windSpeedMps
                currentWeatherModel.windDirection = meteogramModel.get(0).windDirection
                currentWeatherModel.cloudAreaFraction = meteogramModel.get(0).cloudAreaFraction
                currentWeatherModel.created = firstEntryFrom
                currentWeatherModel.precipitationAmount = meteogramModel.get(0).precipitationAmount
            }
            if (longTermData) {
                console.log("--LongTerm Data - Count=" + longTermData.length)
                // console.log(JSON.stringify(longTermData))

                nextDaysModel.clear()
                for (i = 0; i < longTermData.length; i++) {
                    var daydata = longTermData[i]
                    // console.log(JSON.stringify(daydata))
                    nextDaysModel.append(daydata)
                }
                nextDaysCount = nextDaysModel.count
                meteogramModelChanged = !meteogramModelChanged
            }

            currentPlace.provider = providerObject.providerId
            currentPlace.creditLink = providerObject.creditLabel
            currentPlace.creditLabel = providerObject.creditLink
            updateCompactItem()
            refreshTooltipSubText()

            // Save current state to cache
            saveToCache()

            nextReloadIntervalMs = (providerObject.reloadIntervalMin || 60) * 60000
            console.log("Next reload in (Min)=" + (nextReloadIntervalMs / 60000))
            currentPlace.nextReload = loadingData.lastloadingSuccessTime + nextReloadIntervalMs

            loadingData.loadingDatainProgress = false
            loadingData.lastloadingSuccessTime = dateNow()
            loadingData.failedAttemptCount = 0
            updatingPaused = false
        }

        var failureCallback = function(errorStatusText, errorResponseText) {
            console.log("Error downloading weather data:")
            console.log(errorStatusText)
            console.log(errorResponseText)

            if (failureCallback.hasOwnProperty('alreadyHandled') && failureCallback.alreadyHandled) {
                console.log("Error already handled, not processing further")
                return
            }
            failureCallback.alreadyHandled = true

            overallSuccess = false
            loadingData.loadingError = true

            loadingData.failedAttemptCount++

            var reloadAtTime
            var retryDelaySeconds = Math.min(loadingData.failedAttemptCount, 6) * 30
            console.log("Retry in (sec) = " + retryDelaySeconds)
            reloadAtTime = dateNow() + (retryDelaySeconds * 1000)
            currentPlace.nextReload = reloadAtTime

            loadingData.loadingDatainProgress = false
            loadingData.lastloadingSuccessTime = 0
        }

        DataLoader.loadDataFromProvider(providerObject, currentPlace.identifier, successCallback, failureCallback)
    }

    function loadFromCache() {
        dbgprint("loadFromCache")
        let cacheKey = ConfigUtils.buildCacheKey(placesStr, currentPlace.identifier)
        dbgprint2("cacheKey" + cacheKey)

        cacheData.cacheKey = cacheKey

        if (!(cacheData.cacheKey in cacheData.cacheMap)) {
            console.log("Can't find cacheKey in cache: " + cacheData.cacheKey)
            return false
        }

        try {
            currentPlace = JSON.parse( cacheData.cacheMap[cacheData.cacheKey][1])
        } catch (err) {
            dbgprint("Error parsing cache for key: " + cacheData.cacheKey)
            return false
        }

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

    // === DIARY FUNCTIONS ===
    function showDiaryEntryDialog(weatherData) {
        if (!plasmoid.configuration.diaryLoggingEnabled) {
            return
        }
        diaryEntryDialog.weatherData = weatherData
        diaryEntryDialog.open()
    }

    // === DIARY DIALOG (MODULAR VERSION) ===
    DiaryDialog {
        id: diaryEntryDialog
        executableSource: executable
        logPath: diaryLogPath
        layoutType: plasmoid.configuration.diaryLayoutType || 0
    }


    // === AUTOMATIC DIARY POPUP TIMER ===
    Timer {
        id: autoPopupTimer
        interval: 60000 // Check every minute
        running: diaryAutoPopupEnabled && diaryLoggingEnabled
        repeat: true
        onTriggered: {
            var now = new Date()
            var currentHour = now.getHours()
            var currentDateStr = Qt.formatDate(now, "yyyy-MM-dd")
            
            // Check if we should show the popup
            // Only show once per day at the configured hour
            if (currentHour === diaryAutoPopupHour && lastAutoPopupDate !== currentDateStr) {
                // Create temporary weather data for the diary entry
                var tempWeatherData = {
                    temperature: currentWeatherModel ? currentWeatherModel.temperature : "N/A",
                    humidity: currentWeatherModel ? currentWeatherModel.humidity : "N/A",
                    pressureHpa: currentWeatherModel ? currentWeatherModel.pressureHpa : "N/A",
                    condition: currentWeatherModel ? "Current weather" : "No data"
                }
                
                // Show the diary entry dialog
                showDiaryEntryDialog(tempWeatherData)
                
                // Update the last popup date
                plasmoid.configuration.lastAutoPopupDate = currentDateStr
                lastAutoPopupDate = currentDateStr
            }
        }
    }

    // Contextual Actions for System Tray Right-Click Menu
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add a weather notation")
            icon.name: "document-edit"
            onTriggered: {
                // Create temporary weather data for the diary entry
                var tempWeatherData = {
                    temperature: currentWeatherModel ? currentWeatherModel.temperature : "N/A",
                    humidity: currentWeatherModel ? currentWeatherModel.humidity : "N/A",
                    pressureHpa: currentWeatherModel ? currentWeatherModel.pressureHpa : "N/A",
                    condition: currentWeatherModel ? "Current weather" : "No data"
                }
                
                // Show the diary entry dialog with the current weather data
                showDiaryEntryDialog(tempWeatherData)
            }
        },
        PlasmaCore.Action {
            text: i18n("Settings")
            icon.name: "configure"
            onTriggered: plasmoid.expanded = !plasmoid.expanded
        }
    ]
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
