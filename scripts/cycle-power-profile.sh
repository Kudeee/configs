#!/usr/bin/env bash
# ~/.config/scripts/cycle-power-profile.sh

profiles=(power-saver balanced performance)
current=$(powerprofilesctl get)

for i in "${!profiles[@]}"; do
  if [[ "${profiles[$i]}" == "$current" ]]; then
    next="${profiles[$(((i + 1) % ${#profiles[@]}))]}"
    powerprofilesctl set "$next"
    notify-send "Power Profile" "Switched to: $next" --expire-time=2000
    exit 0
  fi
done
