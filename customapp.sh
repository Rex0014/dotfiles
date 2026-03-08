#!/bin/sh
set -euo pipefail

THEME="$HOME/.config/rofi/themes/customapp.rasi"

# If you want to ensure only one rofi instance:
pkill -x rofi || true

rofi -show drun -replace -i -theme "$THEME"
