// Belongs in ...contents/code/weatherMapping.js - Icon to weather description mapping
/*
 * X-Seti - Jan 29 2026 - Weather Icon Mapping
 *
 * Maps weather icon codes to human-readable descriptions
 * Supports multiple weather providers: OpenWeatherMap, Met.no, etc.
 */
.pragma library

// OpenWeatherMap FULL API code mappings
// Based on: https://openweathermap.org/weather-conditions
function getWeatherDescriptionOWM(iconCode) {
    var mappings = {
        // Group 2xx: Thunderstorm
        200: "Thunderstorm with light rain",
        201: "Thunderstorm with rain",
        202: "Thunderstorm with heavy rain",
        210: "Light thunderstorm",
        211: "Thunderstorm",
        212: "Heavy thunderstorm",
        221: "Ragged thunderstorm",
        230: "Thunderstorm with light drizzle",
        231: "Thunderstorm with drizzle",
        232: "Thunderstorm with heavy drizzle",
        
        // Group 3xx: Drizzle
        300: "Light drizzle",
        301: "Drizzle",
        302: "Heavy drizzle",
        310: "Light drizzle rain",
        311: "Drizzle rain",
        312: "Heavy drizzle rain",
        313: "Shower rain and drizzle",
        314: "Heavy shower rain and drizzle",
        321: "Shower drizzle",
        
        // Group 5xx: Rain
        500: "Light rain",
        501: "Moderate rain",
        502: "Heavy rain",
        503: "Very heavy rain",
        504: "Extreme rain",
        511: "Freezing rain",
        520: "Light shower rain",
        521: "Shower rain",
        522: "Heavy shower rain",
        531: "Ragged shower rain",
        
        // Group 6xx: Snow
        600: "Light snow",
        601: "Snow",
        602: "Heavy snow",
        611: "Sleet",
        612: "Light shower sleet",
        613: "Shower sleet",
        615: "Light rain and snow",
        616: "Rain and snow",
        620: "Light shower snow",
        621: "Shower snow",
        622: "Heavy shower snow",
        
        // Group 7xx: Atmosphere
        701: "Mist",
        711: "Smoke",
        721: "Haze",
        731: "Sand/dust whirls",
        741: "Fog",
        751: "Sand",
        761: "Dust",
        762: "Volcanic ash",
        771: "Squalls",
        781: "Tornado",
        
        // Group 800: Clear
        800: "Clear sky",
        
        // Group 80x: Clouds
        801: "Few clouds",
        802: "Scattered clouds",
        803: "Broken clouds",
        804: "Overcast clouds",
        
        // Legacy simple codes (for backwards compatibility)
        1: "Clear sky",
        2: "Few clouds",
        3: "Scattered clouds",
        4: "Broken clouds",
        5: "Overcast",
        9: "Shower rain",
        10: "Rain",
        11: "Thunderstorm",
        12: "Thunderstorm with rain",
        13: "Snow",
        14: "Light snow",
        15: "Heavy snow",
        16: "Sleet",
        50: "Mist",
        51: "Fog",
        52: "Haze",
        53: "Smoke",
        54: "Dust",
        55: "Sand",
        56: "Volcanic ash",
        57: "Squalls",
        58: "Tornado"
    }
    
    return mappings[iconCode] || "Unknown (" + iconCode + ")"
}

// Met.no icon code mappings
// Based on: https://api.met.no/weatherapi/weathericon/2.0/documentation
function getWeatherDescriptionMetNo(iconCode) {
    var mappings = {
        1: "Clear sky",
        2: "Fair",
        3: "Partly cloudy",
        4: "Cloudy",
        5: "Rain showers",
        6: "Rain showers and thunder",
        7: "Sleet showers",
        8: "Snow showers",
        9: "Rain",
        10: "Heavy rain",
        11: "Heavy rain and thunder",
        12: "Sleet",
        13: "Snow",
        14: "Snow and thunder",
        15: "Fog",
        20: "Sleet showers and thunder",
        21: "Snow showers and thunder",
        22: "Rain and thunder",
        23: "Sleet and thunder",
        24: "Light rain showers and thunder",
        25: "Heavy rain showers and thunder",
        26: "Light sleet showers and thunder",
        27: "Heavy sleet showers and thunder",
        28: "Light snow showers and thunder",
        29: "Heavy snow showers and thunder",
        30: "Light rain and thunder",
        31: "Light sleet and thunder",
        32: "Heavy sleet and thunder",
        33: "Light snow and thunder",
        34: "Heavy snow and thunder",
        40: "Light rain showers",
        41: "Heavy rain showers",
        42: "Light sleet showers",
        43: "Heavy sleet showers",
        44: "Light snow showers",
        45: "Heavy snow showers",
        46: "Light rain",
        47: "Light sleet",
        48: "Heavy sleet",
        49: "Light snow",
        50: "Heavy snow"
    }
    
    return mappings[iconCode] || "Unknown (" + iconCode + ")"
}

// Generic fallback based on icon number ranges
function getWeatherDescriptionGeneric(iconCode) {
    // Handle 800-series cloud codes
    if (iconCode >= 800 && iconCode <= 804) {
        if (iconCode === 800) return "Clear sky"
        if (iconCode === 801) return "Few clouds"
        if (iconCode === 802) return "Scattered clouds"
        if (iconCode === 803) return "Broken clouds"
        if (iconCode === 804) return "Overcast clouds"
    }
    
    // Handle other ranges
    if (iconCode === 1) return "Clear sky"
    if (iconCode >= 2 && iconCode <= 5) return "Cloudy"
    if (iconCode >= 200 && iconCode <= 299) return "Thunderstorm"
    if (iconCode >= 300 && iconCode <= 399) return "Drizzle"
    if (iconCode >= 500 && iconCode <= 599) return "Rain"
    if (iconCode >= 600 && iconCode <= 699) return "Snow"
    if (iconCode >= 700 && iconCode <= 799) return "Atmosphere"
    
    return "Unknown (" + iconCode + ")"
}

// Main function - auto-detects provider or uses generic mapping
function getWeatherDescription(iconCode, providerId) {
    if (!iconCode || iconCode === 0) {
        return ""
    }
    
    // Convert to number if string
    var code = parseInt(iconCode)
    
    // Provider-specific mappings
    if (providerId === "owm") {
        return getWeatherDescriptionOWM(code)
    } else if (providerId === "metno") {
        return getWeatherDescriptionMetNo(code)
    }
    
    // Generic fallback
    return getWeatherDescriptionGeneric(code)
}
