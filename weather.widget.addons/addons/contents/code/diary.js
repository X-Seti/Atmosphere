.pragma library
.import QtQuick 2.0 as QtQuick

function path() {
    return Qt.resolvedUrl("file://" + QtQuick.Qt.homePath() + "/daily_weather_diary.txt")
}

function appendWeather(d) {
    var f = Qt.openFile(path(), "a")

    var now = new Date()
    var dateStr = now.toLocaleDateString(Qt.locale(), {
        weekday: "short", day: "numeric", month: "short", year: "numeric"
    })

    f.write(
        dateStr + "\n" +
        "Weather: " + d.condition + "\n" +
        "Temperature: " + Math.round(d.temperature) + "°C\n" +
        "Humidity: " + d.humidity + "%\n" +
        "Pressure: " + d.pressure + " hPa\n\n" +
        "not data entered!\n\n"
    )

    f.close()
}
