// Belongs in ...contents/code/diary.js - Weather diary logging functions
/*
 * X-Seti - Jan 25 2025 - Addons for Weather Widget Plus (Credit - Martin Kotelnik)
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
.pragma library

function openLogFile(logPath, editorType, customEditor) {
    var filePath = logPath
    if (!filePath || filePath === "" || filePath === "/tmp") {
        filePath = "$HOME/weather_diary.txt"
    }

    var editor = "kate"

    if (editorType === 1)      editor = "pluma"
        else if (editorType === 2) editor = customEditor

            var cmd = editor + " '" + filePath + "' &"
            console.log("Opening diary log:", cmd)

            executable.exec(cmd)
}

function appendWeather(weatherData, notes, executable, logPath, layoutType) {
    console.log("diary.js: Weather:", JSON.stringify(weatherData))
    console.log("diary.js: appendWeather called")
    console.log("diary.js: logPath =", logPath)
    console.log("diary.js: notes =", notes)
    console.log("diary.js: weatherData =", JSON.stringify(weatherData))
    console.log("Layout:", layoutType)

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

        entry = dateStr + " " + timeStr + " | Temp: " + weatherData.temperature + "° | Humidity: " + weatherData.humidity + "% | Pressure: " + weatherData.pressureHpa + " hPa"
        entry += "Weather: " + weatherData.condition + "\n"
        entry += "\n"
        if (notes && notes.trim() !== "") {
            entry += " | Notes: " + notes.trim()
        }
        entry += "\n"
    } else if (layoutType === 1) {
        // Detailed
        entry = "\n" + dateStr + " " + timeStr + "\n"
        entry += "Weather: " + weatherData.condition + "\n"
        entry += "Temperature: " + weatherData.temperature + "°\n"
        entry += "Humidity: " + weatherData.humidity + "%\n"
        entry += "Pressure: " + weatherData.pressureHpa + " hPa\n"
        entry += "\n"
        if (notes && notes !== "") {
            entry += "Notes: " + notes + "\n"
        }
        entry += "\n"
    } else {
        // Markdown
        entry = "\n## " + dateStr + " " + timeStr + "\n\n"
        entry += "- **Weather:** " + weatherData.condition  + "\n"
        entry += "- **Temperature:** " + weatherData.temperature + "°\n"
        entry += "- **Humidity:** " + weatherData.humidity + "%\n"
        entry += "- **Pressure:** " + weatherData.pressureHpa + " hPa\n"
        entry += "\n"
        if (notes && notes !== "") {
            entry += "\n**Notes:** " + notes + "\n"
        }
        entry += "\n"
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
