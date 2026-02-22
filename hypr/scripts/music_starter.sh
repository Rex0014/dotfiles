#!/usr/bin/env bash

spotify &
easyeffects &

# wait for windows to actually exist
sleep 1

hyprctl dispatch workspace 5 silent

# focus easyeffects then swap it into master/left position
hyprctl dispatch focuswindow class:'easyeffects'
hyprctl dispatch layoutmsg swapwithmaster

# now set split ratio (master/left size)
hyprctl dispatch splitratio 0.4
