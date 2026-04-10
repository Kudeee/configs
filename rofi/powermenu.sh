#!/usr/bin/env bash

# ─────────────────────────────────────────────
#  Rofi Power Menu
#  Place this file anywhere in your $PATH
#  and make it executable: chmod +x powermenu.sh
# ─────────────────────────────────────────────

THEME="$HOME/.config/rofi/powermenu.rasi"

# ── Options ──────────────────────────────────
shutdown="󰐥  Shutdown"
reboot="󰑓  Reboot"
suspend="󰤄  Suspend"
hibernate="󰒲  Hibernate"
logout="󰍃  Logout"
lock="󰌾  Lock"

# ── Prompt rofi ──────────────────────────────
chosen=$(printf '%s\n' \
    "$lock" \
    "$suspend" \
    "$hibernate" \
    "$logout" \
    "$reboot" \
    "$shutdown" \
  | rofi \
      -dmenu \
      -theme "$THEME" \
      -p "  Power" \
      -selected-row 0)

# ── Execute ───────────────────────────────────
case "$chosen" in
    "$shutdown")
        systemctl poweroff ;;
    "$reboot")
        systemctl reboot ;;
    "$suspend")
        systemctl suspend ;;
    "$hibernate")
        systemctl hibernate ;;
    "$logout")
        # Adjust the command below to match your DE/WM:
        #   GNOME  → gnome-session-quit --no-prompt
        #   KDE    → qdbus org.kde.ksmserver /KSMServer logout 0 0 0
        #   i3     → i3-msg exit
        #   Hyprland → hyprctl dispatch exit
        #   XFCE   → xfce4-session-logout --logout
        #   generic → loginctl terminate-session "$XDG_SESSION_ID"
        loginctl terminate-session "$XDG_SESSION_ID" ;;
    "$lock")
        # Adjust to your locker:
        #   swaylock   → swaylock -f -c 000000
        #   i3lock     → i3lock -c 000000
        #   betterlockscreen → betterlockscreen -l dim
        loginctl lock-session ;;
esac
