// Simulate the diary logging functionality
const fs = require('fs');

// Mock the executable DataSource
const executable = {
    exec: function(command) {
        console.log("Executing command:", command);
        // In real Qt environment, this would execute the bash command
        // For our test, we'll simulate the command execution
        
        // Extract the content to append (this is a simplified simulation)
        if (command.startsWith("echo ")) {
            const contentStart = command.indexOf("'");
            const contentEnd = command.lastIndexOf("' >>");
            if (contentStart !== -1 && contentEnd !== -1) {
                const content = command.substring(contentStart + 1, contentEnd);
                const filePath = command.substring(contentEnd + 4).trim();
                
                console.log("Appending content to file:", filePath);
                console.log("Content:", content);
                
                // Write to the file
                try {
                    fs.appendFileSync(filePath, content);
                    console.log("Successfully wrote to diary file!");
                } catch (error) {
                    console.error("Error writing to diary file:", error);
                }
            }
        }
    }
};

// Mock diary.js functions (simplified)
const Diary = {
    diaryPath: function(logPath) {
        if (!logPath || logPath.trim() === "") {
            logPath = "/tmp";  // fallback path
        }
        if (!logPath.endsWith("/")) {
            logPath += "/";
        }
        return logPath + "daily_weather_diary.txt";
    },
    
    todayHeader: function() {
        const d = new Date();
        return d.toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
    },
    
    appendWeather: function(model, additionalEntry, executable, logPath) {
        if (!executable) {
            console.error("Diary: executable DataSource not provided");
            return;
        }
        
        let header = this.todayHeader();
        let weatherData = "Weather: " + model.condition + "\\n" +
                         "Temperature: " + Math.round(model.temperature) + "°C\\n" +
                         "Humidity: " + model.humidity + "%\\n" +
                         "Pressure: " + Math.round(model.pressureHpa) + " hPa\\n\\n";
        
        let notes = "";
        if (additionalEntry && additionalEntry.trim() !== "") {
            notes = additionalEntry.trim() + "\\n\\n";
        } else {
            notes = "no data entered!\\n\\n";
        }
        
        let fullEntry = header + "\\n" + weatherData + notes;
        let filePath = this.diaryPath(logPath);
        
        // Ensure the directory exists (simplified)
        let dirPath = filePath.substring(0, filePath.lastIndexOf("/"));
        let mkdirCmd = "mkdir -p '" + dirPath + "'";
        executable.exec(mkdirCmd);
        
        // Escape single quotes in the text
        fullEntry = fullEntry.replace(/'/g, "'\\''");
        
        // Use bash to append to file
        let cmd = "echo '" + fullEntry + "' >> " + filePath;
        
        console.log("Diary: Saving entry to " + filePath);
        executable.exec(cmd);
    }
};

// Test the diary functionality
console.log("Testing diary logging functionality...");

const weatherData = {
    temperature: 22.5,
    humidity: 65,
    pressureHpa: 1013.2,
    condition: "Partly Cloudy"
};

const notes = "Feeling well today, went for a walk in the park.";

Diary.appendWeather(weatherData, notes, executable, "");

console.log("Check /tmp/daily_weather_diary.txt for the entry.");