.pragma library

// Qt 6 compatible diary using bash commands via executable DataSource
console.log("Diary.js (Qt6) loaded")

function diaryPath(logPath) {
    // Use provided log path if available, otherwise default to home directory
    if (!logPath || logPath.trim() === "") {
        // Default to home directory - this should be passed from the QML side
        logPath = "/tmp"  // fallback path, but ideally this should come from QML
    }
    if (!logPath.endsWith("/")) {
        logPath += "/"
    }
    return logPath + "daily_weather_diary.txt"
}

function todayHeader() {
    let d = new Date()
    return d.toLocaleDateString(Qt.locale(), "ddd, d MMM yyyy")
}

function appendWeather(model, additionalEntry, executable, logPath) {
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
    let filePath = diaryPath(logPath)
    
    // Ensure the directory exists
    let dirPath = filePath.substring(0, filePath.lastIndexOf("/"))
    let mkdirCmd = "mkdir -p '" + dirPath + "'"
    executable.exec(mkdirCmd)
    
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

