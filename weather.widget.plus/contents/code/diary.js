.pragma library

// Qt 6 compatible diary using bash commands via executable DataSource
console.log("Diary.js (Qt6) loaded")

function diaryPath(logPath) {
    // Use provided log path if available, otherwise default to home directory
    if (!logPath || logPath.trim() === "") {
        // Default to home directory - attempt to determine home directory
        // For the executable DataSource, we can run a command to get the home directory
        return "/home/" + (process.env.USER || "user") + "/daily_weather_diary.txt";
    }
    if (!logPath.endsWith("/")) {
        logPath += "/";
    }
    return logPath + "daily_weather_diary.txt";
}

function todayHeader() {
    let d = new Date()
    return d.toLocaleDateString(Qt.locale(), "ddd, d MMM yyyy")
}

function appendWeather(model, additionalEntry, executable, logPath, diaryLayoutType) {
    if (!executable) {
        console.error("Diary: executable DataSource not provided")
        return
    }
    
    let header = todayHeader()
    
    // Determine the layout type - default to 0 (option 1) if not specified
    let layoutType = diaryLayoutType !== undefined ? diaryLayoutType : 0;
    
    let weatherData = "";
    if (layoutType === 0) {
        // Option 1: Original layout
        weatherData = "Weather: " + model.condition + "\\n" +
                     "Temperature: " + Math.round(model.temperature) + "°C\\n" +
                     "Humidity: " + model.humidity + "%\\n" +
                     "Pressure: " + Math.round(model.pressureHpa) + " hPa\\n\\n"
    } else if (layoutType === 1) {
        // Option 2: Compact layout
        weatherData = "Weather: " + model.condition + " - Temperature: " + Math.round(model.temperature) + "°C\\n" +
                     "Humidity: " + model.humidity + "% - Pressure: " + Math.round(model.pressureHpa) + " hPa\\n\\n"
    }
    
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
    
    // Use bash to append to file - properly format for multiple lines
    let cmd = "printf '" + fullEntry + "' >> " + filePath
    
    console.log("Diary: Saving entry to " + filePath)
    console.log("Diary: Entry content: " + fullEntry)
    executable.exec(cmd)
}


//var logDir = plasmoid.configuration.logPath;
//
//if (!logDir || logDir.length === 0) {
//    logDir = Qt.resolvedUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation));
//}
//
//var diaryFile = logDir + "/diary.log";

