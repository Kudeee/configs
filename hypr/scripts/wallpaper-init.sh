#!/bin/bash
# ~/.config/hypr/scripts/wallpaper-init.sh

CACHE="$HOME/.cache/current_wallpaper"
CACHE_SECOND="$HOME/.cache/current_wallpaper_second"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Keep these in sync with wallpaper.sh
THEME_MONITOR="eDP-1"
SECOND_MONITOR="HDMI-A-1"
SECOND_MATUGEN_CONFIG="$HOME/.config/matugen/config-hdmi.toml"

AWWW_ARGS=(
  --transition-type grow
  --transition-pos center
  --transition-duration 1.5
  --transition-fps 60
)

# Start daemon only if not already running
if ! pgrep -x awww-daemon >/dev/null; then
  awww-daemon &
fi

# Wait until awww is ready (up to 5 seconds)
for i in $(seq 1 10); do
  awww query &>/dev/null && break
  sleep 0.5
done

# Restore last wallpaper or pick a random one
if [ -f "$CACHE" ] && [ -f "$(cat "$CACHE")" ]; then
  WALLPAPER=$(cat "$CACHE")
else
  WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o \
    -iname "*.png" -o -iname "*.webp" \) | shuf -n1)
fi

[ -z "$WALLPAPER" ] && exit 0

echo "$WALLPAPER" >"$CACHE"

# Second monitor: only if it's connected right now.
# Uses its own saved wallpaper, falling back to the main one.
SECOND_WALLPAPER=""
if hyprctl monitors | awk '/^Monitor /{print $2}' | grep -qx "$SECOND_MONITOR"; then
  if [ -f "$CACHE_SECOND" ] && [ -f "$(cat "$CACHE_SECOND")" ]; then
    SECOND_WALLPAPER=$(cat "$CACHE_SECOND")
  else
    SECOND_WALLPAPER="$WALLPAPER"
  fi
fi

# IMPORTANT ORDER:
# 1. Set the wallpaper ourselves with awww (matugen can't do this on CachyOS
#    because its Swww driver hardcodes the binary name 'swww', not 'awww')
# 2. Then call matugen just for color generation (wallpaper_tool = 'None' in config.toml)

if [ -n "$SECOND_WALLPAPER" ]; then
  awww img -o "$THEME_MONITOR" "$WALLPAPER" "${AWWW_ARGS[@]}"
  awww img -o "$SECOND_MONITOR" "$SECOND_WALLPAPER" "${AWWW_ARGS[@]}"
else
  awww img "$WALLPAPER" "${AWWW_ARGS[@]}"
fi

matugen_mode() {
  local b
  b=$(magick identify -format '%[fx:mean*255]' "$1" 2>/dev/null | cut -d. -f1)
  if [ -z "$b" ] || [ "$b" -lt 128 ]; then
    echo dark
  else
    echo light
  fi
}

if command -v matugen &>/dev/null; then
  # Global theme + main bar, from the main screen's wallpaper
  matugen image "$WALLPAPER" --source-color-index 0 -m "$(matugen_mode "$WALLPAPER")"

  # Second bar's colors, from the second screen's wallpaper.
  # No bar reload here: it may still be starting up, and colors.css on disk
  # is already what it read from the previous session.
  if [ -n "$SECOND_WALLPAPER" ] && [ -f "$SECOND_MATUGEN_CONFIG" ]; then
    matugen image "$SECOND_WALLPAPER" --source-color-index 0 \
      -m "$(matugen_mode "$SECOND_WALLPAPER")" \
      --config "$SECOND_MATUGEN_CONFIG"
  fi
fi
