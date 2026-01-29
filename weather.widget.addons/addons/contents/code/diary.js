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

// Helper function to get short day name
function getShortDay(date) {
    var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return days[date.getDay()]
}

// Helper function to get full day name
function getFullDay(date) {
    var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    return days[date.getDay()]
}

// Helper function to get short month name
function getShortMonth(date) {
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return months[date.getMonth()]
}

// Helper function to get full month name
function getFullMonth(date) {
    var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return months[date.getMonth()]
}

// Helper function to pad numbers
function pad(num) {
    return (num < 10 ? "0" : "") + num
}

function openLogFile(logPath, editorType, customEditor, executable) {
    if (!executable) {
        console.error("diary.js: openLogFile - executable is null!")
        return
    }

    var filePath = logPath
    if (!filePath || filePath === "" || filePath === "/tmp") {
        filePath = "$HOME/weather_diary.txt"
    }

    var editor = "kate"

    if (editorType === 1)      editor = "pluma"
        else if (editorType === 2) editor = customEditor

            var cmd = editor + " '" + filePath + "' &"
            console.log("Opening diary log:", cmd)

            try {
                executable.exec(cmd)
                console.log("diary.js: Opened log file in " + editor)
            } catch (e) {
                console.error("diary.js: Error opening log file:", e.message)
            }
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

    // === SAFETY: Ensure directory exists ===
    var dirCmd = "mkdir -p \"$(dirname '" + filePath + "')\""
    try {
        executable.exec(dirCmd)
    } catch (e) {
        console.error("diary.js: Error creating directory:", e.message)
    }

    // === SAFETY: Create file with header if it doesn't exist ===
    var checkCmd = "[ ! -f '" + filePath + "' ] && echo '# Weather Diary Log\n# Created: " + new Date().toISOString() + "\n' > '" + filePath + "' || true"
    try {
        executable.exec(checkCmd)
    } catch (e) {
        console.error("diary.js: Error in file check:", e.message)
    }

    // Get current date/time
    var now = new Date()
    var day = now.getDate()
    var year = now.getFullYear()
    var hours = pad(now.getHours())
    var minutes = pad(now.getMinutes())
    
    // Format date strings for different layouts
    var dateShort = getShortDay(now) + ", " + day + " " + getShortMonth(now) + " " + year
    var dateFull = getFullDay(now) + ", " + day + " " + getFullMonth(now) + " " + year
    var dateAlt = getShortDay(now) + ", " + getFullMonth(now) + " " + day + ", " + year
    
    // Get weather condition, handle undefined
    var condition = weatherData.condition || "Unknown"

    // Build entry based on layout type
    var entry = ""

    if (layoutType === 0) {
        // LEGACY FORMAT - Original style
        entry = "\n" + dateShort + "\n"
        entry += "Weather: " + condition + "\n"
        entry += "Temperature: " + weatherData.temperature + "°\n"
        entry += "Humidity: " + weatherData.humidity + "%\n"
        entry += "Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes.trim() !== "") {
            entry += "\nNotes: " + notes.trim() + "\n"
        }
        entry += "\n"
        
    } else if (layoutType === 1) {
        // COMPACT FORMAT - Single line
        entry = dateShort + " " + hours + ":" + minutes + " - Weather: " + condition + "\n"
        entry += "Temperature: " + weatherData.temperature + "° - Humidity: " + weatherData.humidity + "% - Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes.trim() !== "") {
            entry += "\nNotes: " + notes.trim() + "\n"
        }
        entry += "\n-----\n\n"
        
    } else if (layoutType === 2) {
        // DETAILED FORMAT - Full day name
        entry = dateFull + " " + hours + ":" + minutes + " - Weather: " + condition + "\n"
        entry += "Temperature: " + weatherData.temperature + "° - Humidity: " + weatherData.humidity + "% - Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes.trim() !== "") {
            entry += "\nNotes: " + notes.trim() + "\n"
        }
        entry += "\n"
        
    } else if (layoutType === 3) {
        // MARKDOWN FORMAT - Bullet points
        entry = "\n" + dateShort + " " + hours + ":" + minutes + "\n"
        entry += "* Weather: " + condition + "\n"
        entry += "* Temperature: " + weatherData.temperature + "°\n"
        entry += "* Humidity: " + weatherData.humidity + "%\n"
        entry += "* Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes.trim() !== "") {
            entry += "\nNotes: " + notes.trim() + "\n"
        }
        entry += "\n"
        
    } else {
        // ALTERNATIVE DATE FORMAT - Month name first
        entry = "\n" + dateAlt + " " + hours + ":" + minutes + "\n"
        entry += "Weather: " + condition + "\n"
        entry += "Temperature: " + weatherData.temperature + "°\n"
        entry += "Humidity: " + weatherData.humidity + "%\n"
        entry += "Pressure: " + weatherData.pressureHpa + " hPa\n"
        if (notes && notes.trim() !== "") {
            entry += "\nNotes: " + notes.trim() + "\n"
        }
        entry += "\n"
    }

    console.log("diary.js: Entry to write:", entry)

    // Escape single quotes in entry for shell
    var escapedEntry = entry.replace(/'/g, "'\\''")

    // === APPEND ONLY - NEVER OVERWRITE ===
    var cmd = "echo '" + escapedEntry + "' >> '" + filePath + "'"
    console.log("diary.js: Executing APPEND command (>>)")
    console.log("diary.js: This will NEVER overwrite existing log entries")

    try {
        executable.exec(cmd)
        console.log("diary.js: Entry appended successfully to log file")
        console.log("diary.js: Your previous entries are safe and preserved")
    } catch (e) {
        console.error("diary.js: Error executing command:", e.message)
    }
}
