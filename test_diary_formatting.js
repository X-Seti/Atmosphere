// Test script to verify diary formatting
.pragma library

// Mock executable object for testing
var mockExecutable = {
    exec: function(cmd) {
        console.log("Executing command:", cmd);
    }
};

// Import the diary functions
.load ../weather.widget.plus/contents/code/diary.js

// Test data
var testData = {
    condition: "Sunny",
    temperature: 22.5,
    humidity: 65,
    pressureHpa: 1013.2
};

console.log("Testing diary formatting...");

// Test option 1 (separate lines)
console.log("\n--- Testing Option 1 (Separate Lines) ---");
appendWeather(testData, "Test note for option 1", mockExecutable, "/tmp", 0);

// Test option 2 (combined lines)  
console.log("\n--- Testing Option 2 (Combined Lines) ---");
appendWeather(testData, "Test note for option 2", mockExecutable, "/tmp", 1);

// Test without specifying layout (should default to option 1)
console.log("\n--- Testing Default (No Layout Specified) ---");
appendWeather(testData, "Test note for default", mockExecutable, "/tmp");

console.log("\nTest completed.");