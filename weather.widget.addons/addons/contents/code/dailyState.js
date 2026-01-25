.pragma library
.import "diary.js" as Diary

function handleWeather(model, place, plasmoid) {
    if (!model || model.temperature === -9999)
        return

    var today = new Date().toISOString().slice(0,10)

    if (plasmoid.configuration.lastLoggedDate === today)
        return

    Diary.appendWeather({
        temperature: model.temperature,
        humidity: model.humidity,
        pressureHpa: model.pressureHpa,
        condition: model.iconName
    })

    plasmoid.configuration.lastLoggedDate = today
}
