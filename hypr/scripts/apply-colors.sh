#!/bin/bash
# ~/.config/hypr/scripts/apply-colors.sh
# Called by matugen post_hook after writing colors.conf.
# Applies border colors live without a full hyprctl reload.
# This avoids the source= globbing error (source= fails if file
# doesn't exist at parse time, and we can't guarantee it exists on first boot).

COLORS="$HOME/.config/hypr/colors.conf"
[ -f "$COLORS" ] || exit 0

# Parse the two color lines from colors.conf
# Expected format:  col.active_border   = rgba(...)ee rgba(...)ee 45deg
ACTIVE=$(grep 'col.active_border' "$COLORS" | sed 's/.*= *//')
INACTIVE=$(grep 'col.inactive_border' "$COLORS" | sed 's/.*= *//')

[ -n "$ACTIVE" ]   && hyprctl keyword general:col.active_border   "$ACTIVE"
[ -n "$INACTIVE" ] && hyprctl keyword general:col.inactive_border  "$INACTIVE"

# Also reload waybar in case SIGUSR2 wasn't enough
pkill -SIGUSR2 waybar 2>/dev/null || true
