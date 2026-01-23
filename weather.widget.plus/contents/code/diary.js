// File: ~/.local/share/plasma/plasmoids/weather.widget.plus/contents/code/diary.js

.pragma library

function appendWeather(weatherData, notes, executable, logPath, layoutType) {
    console.log("=== Diary Save ===")
    console.log("Weather:", JSON.stringify(weatherData))
    console.log("Notes:", notes)
    console.log("Path:", logPath)
    console.log("Layout:", layoutType)
    
    if (!executable) {
        console.error("Diary: executable is null")
        return
    }
    
    // Determine file path
    var filePath = logPath && logPath !== "" ? logPath : "$HOME/weather_diary.txt"
    console.log("Writing to:", filePath)
    
    // Get timestamp
    var now = new Date()
    var date = Qt.formatDate(now, "yyyy-MM-dd")
    var time = Qt.formatTime(now, "HH:mm")
    
    // Build entry based on layout type
    var entry = ""
    
    if (layoutType === 0) {
        // Compact
        entry = date + " " + time + " | Temp: " + weatherData.temperature + "° | Humidity: " + weatherData.humidity + "% | Pressure: " + weatherData.pressureHpa + " hPa"
        if (notes && notes.trim() !== "") {
            entry += " | Notes: " + notes.trim()
        }
        entry += "\\n"
    } else if (layoutType === 1) {
        // Detailed
        entry = "\\n=== " + date + " " + time + " ===\\n"
        entry += "Temperature: " + weatherData.temperature + "°\\n"
        entry += "Humidity: " + weatherData.humidity + "%\\n"
        entry += "Pressure: " + weatherData.pressureHpa + " hPa\\n"
        if (notes && notes.trim() !== "") {
            entry += "Notes: " + notes.trim() + "\\n"
        }
        entry += "---\\n"
    } else {
        // Markdown
        entry = "\\n## " + date + " " + time + "\\n\\n"
        entry += "- **Temperature:** " + weatherData.temperature + "°\\n"
        entry += "- **Humidity:** " + weatherData.humidity + "%\\n"
        entry += "- **Pressure:** " + weatherData.pressureHpa + " hPa\\n"
        if (notes && notes.trim() !== "") {
            entry += "\\n**Notes:** " + notes.trim() + "\\n"
        }
        entry += "\\n---\\n"
    }
    
    // Use echo to append to file
    var cmd = "echo -e '" + entry + "' >> " + filePath
    console.log("Executing:", cmd)
    
    try {
        executable.exec(cmd)
        console.log("Diary saved successfully")
    } catch (e) {
        console.error("Diary save error:", e.message)
    }
}
