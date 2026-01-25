#!/usr/bin/env bash

SRC="$HOME/GitHub/Atmosphere/weather.widget.plus"
DST="$HOME/.local/share/plasma/plasmoids/weather.widget.plus"

echo "== Restoring widget to stock =="

rsync -av --delete "$SRC/" "$DST/"

echo "[+] Clearing Plasma cache..."
rm -rf ~/.cache/plasma* ~/.cache/org.kde.plasma.*

kquitapp6 plasmashell || true
sleep 2
plasmashell &

echo "== Restore complete =="
