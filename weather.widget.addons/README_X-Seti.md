# Atmosphere Widget Addons - X-Seti - Aug 14 2025
A reimagined version of Weather Widget 2 / plus versions — now with living atmosphere.

## Prerequisite

**Weather Widget Plus must be installed before running the addon installer.**

Install it from the KDE Store:
- Right-click desktop > Add Widgets > Get New Widgets
- Search: **Weather Widget Plus**

Or from the original repo: https://github.com/blackadderkate/weather-widget-2

The addon patches the stock widget's main.qml in place. Without the base widget installed at:
    ~/.local/share/plasma/plasmoids/weather.widget.plus/
the installer will exit with an error.

## Features
- Dynamic wallpaper brightness (time + weather)
- Weather Logging with user notations
- Animated rain/snow with wind direction
- Theme-aware design - works in light/dark modes

## Install

```bash
git clone https://github.com/X-Seti/Atmosphere
cd Atmosphere/weather.widget.addons
./install-addon.sh
```

## Uninstall

```bash
./uninstall-addon.sh
```

Restores the original main.qml from backup.

## Requirements
- KDE Plasma 6
- Weather Widget Plus (base widget) - installed first
- ImageMagick (sudo apt install imagemagick)

## Credits
Based on: https://github.com/blackadderkate/weather-widget-2
Built by X-Seti (2025)
