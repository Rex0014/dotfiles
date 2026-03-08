#!/bin/sh

CHOSEN=$(printf "\n\n" | rofi -dmenu -i -theme-str '@import "power.rasi"')
echo CHOSEN
case "$CHOSEN" in
    "") poweroff ;;
    "") reboot ;;
    "") systemctl suspend ;;
    *) exit;;
esac
