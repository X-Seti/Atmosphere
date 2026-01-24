.pragma library
.import "diary.js" as Diary

function handleWeather(currentWeatherModel, currentPlace) {
    if (!currentWeatherModel || currentWeatherModel.temperature === -9999)
        return

    var today = new Date().toISOString().slice(0,10)

    if (plasmoid.configuration.lastLoggedDate === today)
        return

    Diary.appendWeather({
        temperature: currentWeatherModel.temperature,
        humidity: currentWeatherModel.humidity,
        pressure: currentWeatherModel.pressureHpa,
        condition: currentWeatherModel.iconName,
        provider: currentPlace.providerId
    })

    plasmoid.configuration.lastLoggedDate = today
}
