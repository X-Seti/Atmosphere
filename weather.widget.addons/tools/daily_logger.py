#!/usr/bin/env python3
"""
Append last 6 months of daily 8am weather data for
Ludlow, Shropshire, UK to ~/daily_weather_diary.txt
"""

import requests
from datetime import datetime, timedelta
from pathlib import Path

sethour =8
setwayback =60
setdays =1

# --------------------------------------------------
# Weather code mapping (Open-Meteo)
# --------------------------------------------------
WEATHER_CODES = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    71: "Slight snow",
    73: "Moderate snow",
    75: "Heavy snow",
    80: "Rain showers",
    95: "Thunderstorm",
}

# --------------------------------------------------
def fetch_ludlow_weather():
    """Fetch last 6 months of weather data for Ludlow."""

    lat = 52.3676
    lon = -2.7167

    end_date = datetime.now()
    start_date = end_date - timedelta(days=setdays)  # ~6 months

    print(f"Fetching weather data from {start_date.date()} to {end_date.date()}")

    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date.strftime("%Y-%m-%d"),
        "end_date": end_date.strftime("%Y-%m-%d"),
        "hourly": (
            "temperature_2m,"
            "relative_humidity_2m,"
            "surface_pressure,"
            "weathercode"
        ),
        "timezone": "Europe/London"
    }

    response = requests.get(url, params=params, timeout=30)
    response.raise_for_status()
    return response.json()

# --------------------------------------------------
def format_daily_entries(data):
    """Extract and format 8am entries."""

    times = data["hourly"]["time"]
    temps = data["hourly"]["temperature_2m"]
    humidity = data["hourly"]["relative_humidity_2m"]
    pressure = data["hourly"]["surface_pressure"]
    codes = data["hourly"]["weathercode"]

    entries = []

    for i, timestamp in enumerate(times):
        dt = datetime.fromisoformat(timestamp)

        if dt.hour == sethour:
            date_str = dt.strftime("%a, %-d %b %Y")
            temp = round(temps[i])
            hum = round(humidity[i])
            pres = round(pressure[i])
            condition = WEATHER_CODES.get(codes[i], "Unknown")

            entry = (
                f"{date_str}\n"
                f"Weather: {condition}\n"
                f"Temperature: {temp}°C\n"
                f"Humidity: {hum}%\n"
                f"Pressure: {pres} hPa\n"
            )

            entries.append(entry)

    return entries

# --------------------------------------------------
def append_to_diary(entries):
    """Append entries to ~/daily_weather_diary.txt"""

    diary_path = Path.home() / "daily_weather_diary.txt"

    with open(diary_path, "a", encoding="utf-8") as f:
        for entry in entries:
            f.write(entry)
            f.write("\n")

    print(f"✓ Appended {len(entries)} days to {diary_path}")

# --------------------------------------------------
def main():
    print(setwayback)
    print("Ludlow Weather Diary — 6 Month Backfill")
    print(setwayback)

    try:
        data = fetch_ludlow_weather()
    except Exception as e:
        print(f"✗ Failed to fetch data: {e}")
        return

    entries = format_daily_entries(data)

    if not entries:
        print("✗ No 8am data found.")
        return

    append_to_diary(entries)
    print("✓ Backfill complete")

# --------------------------------------------------
if __name__ == "__main__":
    main()
