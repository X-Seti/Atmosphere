.pragma library

// Qt 6 compatible diary using bash commands via executable DataSource
console.log("Diary.js (Qt6) loaded")

function diaryPath() {
    return Qt.resolvedUrl("/home/x2/daily_weather_diary.txt").toString().replace("file://", "")
}

function todayHeader() {
    let d = new Date()
    return d.toLocaleDateString(Qt.locale(), "ddd, d MMM yyyy")
}

function appendWeather(model, additionalEntry, executable) {
    if (!executable) {
        console.error("Diary: executable DataSource not provided")
        return
    }
    
    let header = todayHeader()
    let weatherData = "Weather: " + model.condition + "\\n" +
                     "Temperature: " + Math.round(model.temperature) + "°C\\n" +
                     "Humidity: " + model.humidity + "%\\n" +
                     "Pressure: " + Math.round(model.pressureHpa) + " hPa\\n\\n"
    
    let notes = ""
    if (additionalEntry && additionalEntry.trim() !== "") {
        notes = additionalEntry.trim() + "\\n\\n"
    } else {
        notes = "no data entered!\\n\\n"
    }
    
    let fullEntry = header + "\\n" + weatherData + notes
    let filePath = Qt.resolvedUrl("/home/x2/daily_weather_diary.txt").toString().replace("file://", "")
    
    // Escape single quotes in the text
    fullEntry = fullEntry.replace(/'/g, "'\\''")
    
    // Use bash to append to file
    let cmd = "echo '" + fullEntry + "' >> " + filePath
    
    console.log("Diary: Saving entry to " + filePath)
    executable.exec(cmd)
}


//var logDir = plasmoid.configuration.logPath;
//
//if (!logDir || logDir.length === 0) {
//    logDir = Qt.resolvedUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation));
//}
//
//var diaryFile = logDir + "/diary.log";

