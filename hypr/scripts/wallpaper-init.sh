#!/bin/bash
# ~/.config/hypr/scripts/wallpaper-init.sh

CACHE="$HOME/.cache/current_wallpaper"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Start daemon only if not already running
if ! pgrep -x awww-daemon > /dev/null; then
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

echo "$WALLPAPER" > "$HOME/.cache/current_wallpaper"

# IMPORTANT ORDER:
# 1. Set the wallpaper ourselves with awww (matugen can't do this on CachyOS
#    because its Swww driver hardcodes the binary name 'swww', not 'awww')
# 2. Then call matugen just for color generation (wallpaper_tool = 'None' in config.toml)

awww img "$WALLPAPER" \
    --transition-type grow \
    --transition-pos center \
    --transition-duration 1.5 \
    --transition-fps 60

if command -v matugen &>/dev/null; then
    matugen image "$WALLPAPER"
fi
