#!/usr/bin/env bash
set -euo pipefail

# deps: hyprctl, jq, rofi
# Lists windows in special workspace, lets you pick one, moves it to current workspace.

target_ws="$(hyprctl activeworkspace -j | jq -r '.name')"
echo $target_ws
clients_json="$(hyprctl clients -j)"

# Hyprland usually names the special workspace "special:special"
# We'll match any workspace name starting with "special:" to be robust.
menu="$(
  echo "$clients_json" | jq -r '
    .[]
    | select(.workspace.name | startswith("special:"))
    | "\(.title)\t\(.address)"
  '
)"

if [[ -z "${menu}" ]]; then
  notify-send "Hyprland" "No windows in special workspace."
  exit 0
fi

#Choose the bloody window.

choice="$(
  echo "$menu" \
  | rofi -dmenu -i -p -theme tabbingmenu.rasi \
  | awk -F'\t' '{print $2}'
)"

[[ -z "${choice}" ]] && exit 0

# Focus the chosen window, then pull it to the current workspace.
hyprctl dispatch movetoworkspace ${target_ws}, address:${choice}
hyprctl dispatch focuswindow address:${choice}
