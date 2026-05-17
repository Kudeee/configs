#!/bin/bash
# Rofi wallpaper picker — sets via awww, regenerates matugen colors

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
ENTRIES_FILE=$(mktemp /tmp/rofi-wallpaper-XXXXXX)
trap 'rm -f "$ENTRIES_FILE"' EXIT

mkdir -p "$CACHE_DIR"

# ── Daemon ────────────────────────────────────────────────────────────────────
if ! pgrep -x awww-daemon >/dev/null; then
  awww-daemon &
fi
for i in $(seq 1 10); do
  awww query &>/dev/null && break
  sleep 0.5
done

# ── Find images ───────────────────────────────────────────────────────────────
readarray -t IMAGES < <(find "$WALLPAPER_DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o \
  -iname "*.png" -o -iname "*.webp" -o \
  -iname "*.gif" \) | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
  notify-send "Wallpaper Picker" "No images found in $WALLPAPER_DIR" --icon=dialog-error
  exit 1
fi

# ── Generate thumbnails + build entries file ──────────────────────────────────
for img in "${IMAGES[@]}"; do
  [ -f "$img" ] || continue

  name=$(basename "$img")
  hash=$(printf '%s' "$img" | md5sum | cut -d' ' -f1)
  thumb="$CACHE_DIR/${hash}.png"

  if [ ! -f "$thumb" ]; then
    if command -v ffmpeg &>/dev/null; then
      ffmpeg -y -i "$img" \
        -vf "scale=200:200:force_original_aspect_ratio=increase,crop=200:200" \
        -frames:v 1 "$thumb" -loglevel quiet 2>/dev/null
    fi
    if [ ! -f "$thumb" ] && command -v magick &>/dev/null; then
      magick "$img" -resize 200x200^ -gravity center -extent 200x200 "$thumb" 2>/dev/null
    fi
    if [ ! -f "$thumb" ] && command -v convert &>/dev/null; then
      convert "$img" -resize 200x200^ -gravity center -extent 200x200 "$thumb" 2>/dev/null
    fi
  fi

  # Write entry: name + NUL + icon metadata
  # \0 = field separator within entry; \037 = unit separator (0x1f), octal-safe
  if [ -f "$thumb" ]; then
    printf '%s\0icon\037%s\n' "$name" "$thumb" >>"$ENTRIES_FILE"
  else
    printf '%s\n' "$name" >>"$ENTRIES_FILE"
  fi
done

# Bail if nothing was written (shouldn't happen but just in case)
if [ ! -s "$ENTRIES_FILE" ]; then
  notify-send "Wallpaper Picker" "Failed to build entry list" --icon=dialog-error
  exit 1
fi

# ── Show picker ───────────────────────────────────────────────────────────────
CHOSEN=$(rofi \
  -dmenu \
  -p "Wallpaper" \
  -show-icons \
  -theme ~/.config/rofi/wallpaper.rasi \
  <"$ENTRIES_FILE")

[ -z "$CHOSEN" ] && exit 0

SELECTED=$(find "$WALLPAPER_DIR" -type f -name "$CHOSEN" | head -1)
[ -z "$SELECTED" ] && exit 0

# ── Set wallpaper ─────────────────────────────────────────────────────────────
awww img "$SELECTED" \
  --transition-type grow \
  --transition-pos center \
  --transition-duration 1.5 \
  --transition-fps 60

# ── Regenerate colors ─────────────────────────────────────────────────────────
if command -v matugen &>/dev/null; then
  BRIGHTNESS=$(magick identify -format '%[fx:mean*255]' "$SELECTED" 2>/dev/null | cut -d. -f1)
  if [ -z "$BRIGHTNESS" ] || [ "$BRIGHTNESS" -lt 128 ]; then
    MATUGEN_MODE="dark"
  else
    MATUGEN_MODE="light"
  fi
  matugen image "$SELECTED" --source-color-index 0 -m "$MATUGEN_MODE"
fi

echo "$SELECTED" >"$HOME/.cache/current_wallpaper"
notify-send "Wallpaper" "$(basename "$SELECTED")" --icon="$SELECTED"
