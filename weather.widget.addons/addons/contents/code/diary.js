// diary.js - Weather diary logging functions

.pragma library

function appendWeather(weatherData, notes, executable, logPath, layoutType) {
    console.log("diary.js: appendWeather called")
    console.log("diary.js: logPath =", logPath)
    console.log("diary.js: notes =", notes)
    console.log("diary.js: weatherData =", JSON.stringify(weatherData))
    
    if (!executable) {
        console.error("diary.js: executable is null!")
        return
    }
    
    // Determine file path
    var filePath = logPath
    if (!filePath || filePath === "" || filePath === "/tmp") {
        filePath = "$HOME/weather_diary.txt"
    }
    
    console.log("diary.js: Writing to:", filePath)
    
    // Get current date/time
    var now = new Date()
    var dateStr = now.toISOString().slice(0, 10) // YYYY-MM-DD
    var timeStr = now.toTimeString().slice(0, 5) // HH:MM
    
    // Build entry based on layout type
    var entry = ""
    
    if (layoutType === 0) {
        // Compact
        entry = dateStr + " " + timeStr + " | "
        entry += "Temp: " + weatherData.temperature + "° | "
        entry += "Humidity: " + weatherData.humidity + "% | "
        entry += "Pressure: " + weatherData.pressureHpa + " hPa"
        if (notes && notes !== "") {
            entry += " | Notes: " + notes
        }
        entry += "\n"
    } else if (layoutType === 1) {
        // Detailed
        entry = "\n=== " + dateStr + " " + timeStr + " ===\n"
        entry += "Temperature: " + weatherData.temperature + "°\n"
        entry += "Humidity: " + weatherData.humidity + "%\n"
        entry += "Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes !== "") {
            entry += "Notes: " + notes + "\n"
        }
        entry += "---\n"
    } else {
        // Markdown
        entry = "\n## " + dateStr + " " + timeStr + "\n\n"
        entry += "- **Temperature:** " + weatherData.temperature + "°\n"
        entry += "- **Humidity:** " + weatherData.humidity + "%\n"
        entry += "- **Pressure:** " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes !== "") {
            entry += "\n**Notes:** " + notes + "\n"
        }
        entry += "\n---\n"
    }
    
    console.log("diary.js: Entry to write:", entry)
    
    // Escape single quotes in entry for shell
    var escapedEntry = entry.replace(/'/g, "'\\''")
    
    // Write to file using echo
    var cmd = "echo '" + escapedEntry + "' >> '" + filePath + "'"
    console.log("diary.js: Executing command")
    
    try {
        executable.exec(cmd)
        console.log("diary.js: Command executed successfully")
    } catch (e) {
        console.error("diary.js: Error executing command:", e.message)
    }
}
