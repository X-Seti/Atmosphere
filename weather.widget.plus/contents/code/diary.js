.pragma library

print("Diary.js loaded")
function diaryPath() {
    return Qt.platform.homePath + "/daily_weather_diary.txt"
}

function todayHeader() {
    let d = new Date()
    return d.toLocaleDateString(Qt.locale(), "ddd, d MMM yyyy")
}

function appendWeather(model) {
    let file = Qt.openFile(diaryPath(), "a")

    file.write(
        todayHeader() + "\n" +
        "Weather: " + model.condition + "\n" +
        "Temperature: " + Math.round(model.temperature) + "°C\n" +
        "Humidity: " + model.humidity + "%\n" +
        "Pressure: " + Math.round(model.pressureHpa) + " hPa\n\n" +
        "Health:\n" +
        "not data entered!\n\n"
    )

    file.close()
}
