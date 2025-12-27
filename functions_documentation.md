# Functions Documentation for AtmosphereWidget-v1.0-Sunrise

## JavaScript Functions

### config-utils.js
- **getPlacesArray()**: Returns an array of places parsed from the plasmoid configuration.

### data-loader.js
- **getLastReloadedTimeText(lastReloaded)**: Converts milliseconds to a human-readable time string.
- **scheduleDataReload()**: Schedules a data reload after 10 minutes.
- **getReloadedAgoMs(lastReloaded)**: Calculates the time in milliseconds since the last reload.
- **getPlasmoidStatus(lastReloaded, inTrayActiveTimeoutSec)**: Returns the plasmoid status based on the time since the last reload.
- **generateCacheKey(placeIdentifier)**: Generates a cache key using MD5 hash of the place identifier.
- **isXmlStringValid(xmlString)**: Checks if an XML string is valid by checking for XML declaration.
- **fetchXmlFromInternet(getUrl, successCallback, failureCallback)**: Fetches XML data from the internet.
- **fetchJsonFromInternet(getUrl, successCallback, failureCallback)**: Fetches JSON data from the internet.
- **IsJsonString(str)**: Checks if a string is a valid JSON string.

### icons.js
- **getWindDirectionIconCode(angle)**: Returns the weather icon code for a given wind direction angle.
- **getIconCode(iconName, providerId, partOfDay)**: Returns the weather icon code based on the icon name, provider ID, and time of day.
- **getSunriseIcon()**: Returns the sunrise icon code.
- **getSunsetIcon()**: Returns the sunset icon code.

### model-utils.js
- **createEmptyNextDaysObject()**: Creates an empty object for next days' weather data.
- **populateNextDaysObject(nextDaysObj)**: Populates the next days' weather object with temperature and icon data.

### placesearch-helpers.js
- **getDisplayNames()**: Returns an array of country display names sorted alphabetically.
- **getshortCode(displayName)**: Returns the short code for a given country display name.
- **getDisplayName(shortCode)**: Returns the display name for a given country short code.
- **updateListView(filter)**: Updates the filtered list view based on a filter string.
- **loadCSVDatabase(countryName)**: Loads a CSV database for a specific country.
- **parseCSVLine(line)**: Parses a single line from a CSV file.

### unit-utils.js
- **toFahrenheit(celsia)**: Converts Celsius to Fahrenheit.
- **toKelvin(celsia)**: Converts Celsius to Kelvin.
- **getTemperatureNumberExt(temperatureStr, temperatureType)**: Returns temperature with degree symbol based on temperature type.
- **getTemperatureNumber(temperatureStr, temperatureType)**: Returns temperature number based on the selected temperature type.
- **kelvinToCelsia(kelvin)**: Converts Kelvin to Celsius.
- **getTemperatureEnding(temperatureType)**: Returns the temperature unit ending based on the temperature type.
- **getPressureNumber(hpa, pressureType)**: Returns pressure value based on the selected pressure type.
- **getPressureText(hpa, pressureType)**: Returns pressure with unit text.
- **getPressureEnding(pressureType)**: Returns the pressure unit ending based on the pressure type.
- **getWindSpeedNumber(mps, windSpeedType)**: Returns wind speed value based on the selected wind speed type.
- **getWindSpeedText(mps, windSpeedType)**: Returns wind speed with unit text.
- **getWindSpeedEnding(windSpeedType)**: Returns the wind speed unit ending based on the wind speed type.
- **getHourText(hourNumber, twelveHourClockEnabled)**: Returns the hour in the appropriate format.
- **getAmOrPm(hourNumber)**: Returns AM or PM based on the hour.
- **convertDate(date, timezoneType, offset)**: Converts a date based on timezone type and offset.
- **localTime(gmtDate, offsetinSeconds)**: Converts GMT date to local time using offset in seconds.

## QML Functions

### main.qml
- **fetchSunriseSunset()**: Fetches sunrise and sunset times from the API.
- **action_toggleUpdatingPaused()**: Toggles the updating paused state.
- **setNextPlace(initial, direction)**: Sets the next place to display weather for.
- **dataLoadedFromInternet(contentToCache)**: Handles data loaded from the internet.
- **reloadDataFailureCallback()**: Handles failure when reloading data.
- **reloadData()**: Reloads weather data from the internet.
- **reloadMeteogram()**: Reloads the meteogram image.
- **loadFromCache()**: Loads weather data from cache.
- **handleLoadError()**: Handles loading errors.
- **updateLastReloadedText()**: Updates the text showing when data was last reloaded.
- **updateAdditionalWeatherInfoText()**: Updates additional weather information text.
- **refreshTooltipSubText()**: Refreshes the tooltip sub-text.
- **getPartOfDayIndex()**: Returns whether it's day (0) or night (1) based on sunrise/sunset times.
- **abortTooLongConnection(forceAbort)**: Aborts connections that are taking too long.
- **tryReload()**: Attempts to reload weather data.
- **dbgprint(msg)**: Prints debug messages if debug logging is enabled.
- **dateNow()**: Returns the current time in milliseconds.
- **setDebugFlag(flag)**: Sets the debug logging flag.
- **getLocalTimeZone()**: Gets the local timezone from the data source.

## C++ Functions

### backend.cpp
- **Backend(QObject *parent)**: Constructor for the Backend class.
- **~Backend()**: Destructor for the Backend class.
- **writeCache(const QString &cacheContent, const QString &plasmoidId)**: Writes cache content to a file.
- **readCache(const QString &plasmoidId)**: Reads cache content from a file.

## Constants and Enums

### unit-utils.js
- **TemperatureType**: Enum for temperature units (CELSIUS, FAHRENHEIT, KELVIN).
- **PressureType**: Enum for pressure units (HPA, INHG, MMHG).
- **WindSpeedType**: Enum for wind speed units (MPS, MPH, KMH).
- **TimezoneType**: Enum for timezone types (USER_LOCAL_TIME, UTC, LOCATION_LOCAL_TIME).

## Properties in main.qml

### Main Properties
- **placeIdentifier**: Identifier for the current place.
- **placeAlias**: Alias name for the current place.
- **cacheKey**: Key used for caching weather data.
- **timezoneID**: ID of the timezone for the current place.
- **timezoneShortName**: Short name of the timezone.
- **timezoneOffset**: Offset of the timezone in seconds.
- **cacheMap**: Map containing cached weather data.
- **renderMeteogram**: Whether to render the meteogram.
- **temperatureType**: Selected temperature unit type.
- **pressureType**: Selected pressure unit type.
- **windSpeedType**: Selected wind speed unit type.
- **timezoneType**: Selected timezone type.
- **widgetFontName**: Name of the font used in the widget.
- **widgetFontSize**: Size of the font used in the widget.
- **twelveHourClockEnabled**: Whether twelve-hour clock format is enabled.
- **placesJsonStr**: JSON string containing places configuration.
- **onlyOnePlace**: Whether there is only one place configured.

### Weather Properties
- **feelsLikeTemp**: Calculated "feels like" temperature based on actual temperature, wind speed, and humidity.
- **comfortLevel**: Comfort level based on temperature.
- **weatherMood**: Current weather mood based on conditions and wind speed.

### Data Loading Properties
- **lastloadingStartTime**: Time when the last loading attempt started.
- **lastloadingSuccessTime**: Time when the last loading attempt was successful.
- **nextReload**: Time when the next reload is due.
- **loadingData**: Flag indicating if data is currently being loaded.
- **loadingDataTimeoutMs**: Timeout for data loading in milliseconds.
- **loadingXhrs**: Array of XMLHttpRequest objects for loading data.
- **loadingError**: Flag indicating if the last loading attempt had an error.
- **imageLoadingError**: Flag indicating if there was an image loading error.
- **alreadyLoadedFromCache**: Flag indicating if data has already been loaded from cache.

### UI Properties
- **vertical**: Whether the widget is in vertical layout.
- **onDesktop**: Whether the widget is on the desktop.
- **inTray**: Whether the widget is in the system tray.
- **plasmoidCacheId**: Cache ID for the plasmoid.
- **inTrayActiveTimeoutSec**: Timeout for active status in the system tray.
- **nextDaysCount**: Number of days to show in the forecast.
- **textColorLight**: Whether the text color is light.
- **layoutType**: Type of layout (standard, vertical, compact).
- **updatingPaused**: Whether updating is paused.
- **currentProvider**: Current weather data provider.
- **meteogramModelChanged**: Whether the meteogram model has changed.
- **lastReloadedText**: Text showing when data was last reloaded.
- **tooltipSubText**: Sub-text for the tooltip.

## Special Features

### Sunrise/Sunset API Manager
- **sunriseSunsetUrl**: URL for the sunrise/sunset API.
- **latitude**: Latitude of the current location.
- **longitude**: Longitude of the current location.
- **localSunrise**: Local sunrise time.
- **localSunset**: Local sunset time.
- **hasSunData**: Whether sunrise/sunset data is available.
- **lastSunUpdate**: Timestamp of the last successful update.

### Dynamic Effects
- **feelsLikeTemp**: Calculated "feels like" temperature with wind chill and humidity effects.
- **comfortLevel**: Comfort level based on temperature ranges.
- **weatherMood**: Current weather mood based on conditions and wind speed.
- **applyWallpaperWithBrightness()**: Function to apply wallpaper with dynamic brightness.
- **setPlasmaWallpaper(path)**: Function to set the Plasma wallpaper via DBus.