#!/bin/bash
# ~/.config/hypr/scripts/wallpaper.sh
# Rofi wallpaper picker — sets via awww, regenerates matugen colors

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
mkdir -p "$CACHE_DIR"

# Start daemon only if not already running
if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon &
fi

# Wait until awww is ready (up to 5 seconds)
for i in $(seq 1 10); do
    awww query &>/dev/null && break
    sleep 0.5
done

# Collect supported image formats
IMAGES=$(find "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o \
    -iname "*.png" -o -iname "*.webp" -o \
    -iname "*.gif" \) | sort)

if [ -z "$IMAGES" ]; then
    notify-send "Wallpaper Picker" "No images found in $WALLPAPER_DIR" --icon=dialog-error
    exit 1
fi

# Generate thumbnails for rofi preview
generate_thumbnail() {
    local img="$1"
    local thumb="$CACHE_DIR/$(echo "$img" | md5sum | cut -d' ' -f1).png"
    if [ ! -f "$thumb" ]; then
        ffmpeg -i "$img" -vf "scale=512:288:force_original_aspect_ratio=increase,crop=512:288" \
            -frames:v 1 "$thumb" -y -loglevel quiet 2>/dev/null ||
            convert "$img" -resize 512x288^ -gravity center -extent 512x288 "$thumb" 2>/dev/null
    fi
    echo "$thumb"
}

# Build rofi input: "filename \0icon\x1fthumbnail"
ROFI_INPUT=""
while IFS= read -r img; do
    name=$(basename "$img")
    thumb=$(generate_thumbnail "$img")
    ROFI_INPUT+="$name\0icon\x1f$thumb\n"
done <<< "$IMAGES"

# Show rofi picker
CHOSEN=$(printf "%b" "$ROFI_INPUT" | rofi \
    -dmenu \
    -p "Wallpaper" \
    -show-icons \
    -theme-str '
        window { width: 900px; }
        listview { columns: 4; lines: 3; }
        element { orientation: vertical; }
        element-icon { size: 128px; }
        element-text { horizontal-align: 0.5; }
    ')

[ -z "$CHOSEN" ] && exit 0

# Resolve full path from filename
SELECTED=$(find "$WALLPAPER_DIR" -type f -name "$CHOSEN" | head -1)
[ -z "$SELECTED" ] && exit 0

# IMPORTANT ORDER:
# 1. Set wallpaper with awww ourselves (matugen's Swww driver calls 'swww' which
#    doesn't exist on CachyOS — it's 'awww'. wallpaper_tool = 'None' in config.toml)
# 2. Then run matugen purely for color generation

awww img "$SELECTED" \
    --transition-type grow \
    --transition-pos center \
    --transition-duration 1.5 \
    --transition-fps 60

if command -v matugen &>/dev/null; then
    matugen image "$SELECTED"
fi

echo "$SELECTED" > "$HOME/.cache/current_wallpaper"
notify-send "Wallpaper" "$(basename "$SELECTED")" --icon="$SELECTED"
