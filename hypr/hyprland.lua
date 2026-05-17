-- =============================================================================
-- hyprland.lua — converted from hyprland.conf (hyprlang → Lua, Hyprland ≥0.55)
-- =============================================================================

--------------------
---- MONITORS ----
--------------------

-- Fallback: any unspecified monitor uses preferred mode, placed automatically
hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = 1,
})

-- Mirror HDMI-A-1 onto eDP-1
hl.monitor({
  output   = "HDMI-A-1",
  mode     = "1882x1080@60",
  position = "auto",
  scale    = 1,
  mirror   = "eDP-1",
})


-----------------------
---- MY PROGRAMS ----
-----------------------

local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi"
local browser     = "brave"
local mainMod     = "SUPER"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("~/.config/hypr/scripts/wallpaper-init.sh")
  hl.exec_cmd("clipse -listen")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Intel Iris Xe — hardware video acceleration
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("WLR_NO_HARDWARE_CURSORS", "0")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in          = 5,
    gaps_out         = 14,

    border_size      = 2,

    col              = {
      active_border   = { colors = { "rgba(7986CBee)", "rgba(4DB6ACee)" }, angle = 45 },
      inactive_border = "rgba(37474Faa)",
    },

    resize_on_border = true,
    allow_tearing    = false,
    layout           = "dwindle",
  },

  decoration = {
    rounding         = 12,
    rounding_power   = 2,

    active_opacity   = 1.0,
    inactive_opacity = 0.93,

    shadow           = {
      enabled      = true,
      range        = 18,
      render_power = 3,
      color        = "rgba(00000060)",
      offset       = { 0, 4 },
    },

    blur             = {
      enabled           = true,
      size              = 6,
      passes            = 3,
      vibrancy          = 0.18,
      vibrancy_darkness = 0.5,
      new_optimizations = true,
      xray              = false,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
    smart_split    = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper      = -1,
    disable_hyprland_logo        = false,
    animate_manual_resizes       = true,
    animate_mouse_windowdragging = true,
    -- FIX: vfr was removed; use render_ahead_of_time or just drop it
    -- vfr = true,
  },
})


--------------------
---- ANIMATIONS ----
--------------------

-- Bezier curves
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("easeOutBack", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.curve("easeInOutSine", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Windows
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutBack" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "easeOutBack", style = "popin 75%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeInOutSine", style = "popin 80%" })

-- Fades
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "easeInOutSine" })

-- Border
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "easeOutExpo" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 80, bezier = "linear", style = "loop" })

-- Layers
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "easeOutExpo" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "easeInOutSine", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "linear" })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutExpo", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "easeOutExpo", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "easeInOutSine", style = "slidefade 20%" })


---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout    = "us",
    kb_variant   = "",
    kb_model     = "",
    kb_options   = "",
    kb_rules     = "",

    follow_mouse = 1,
    sensitivity  = 0.3,

    touchpad     = {
      natural_scroll       = true,
      tap_to_click         = true,
      drag_lock            = true,
      disable_while_typing = true,
    },
  },

  gestures = {
    workspace_swipe_distance           = 250,
    workspace_swipe_invert             = true,
    workspace_swipe_min_speed_to_force = 15,
    workspace_swipe_cancel_ratio       = 0.15,
    workspace_swipe_create_new         = true,
  },
})

-- 3-finger horizontal swipe to switch workspaces
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})

-- Per-device sensitivity override
hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + R",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/appmenu.rasi || pkill -x rofi"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("rofimoji"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.exec_cmd("rofimoji --files ~/.config/rofimoji/material_design.csv"))
hl.bind(mainMod .. " + CTRL + period", hl.dsp.exec_cmd("rofimoji --files ~/.config/rofimoji/cozette.csv"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 1 }))

-- Wallpaper picker
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.config/rofi/wallpaper.sh"))

-- Clipboard
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("kitty --class clipse -e clipse"))

-- Power menu
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("~/.config/rofi/powermenu.sh"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename -'))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | satty --filename -"))
hl.bind(mainMod .. " + CTRL + Print",
  hl.dsp.exec_cmd(
    'grim -g "$(slurp)" ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png && notify-send "Screenshot saved"'))

-- Reload waybar
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pkill waybar && waybar &"))

-- Focus movement
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Resize windows with keyboard (repeating)
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Workspaces
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume (locked = works on lockscreen)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media keys
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })


------------------------------
---- WINDOWS AND WORKSPACES --
------------------------------

-- Suppress maximize events for all windows
hl.window_rule({
  name           = "suppress-maximize-events",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix XWayland drag ghost windows getting focus
hl.window_rule({
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- Move hyprland-run floating bar to bottom-left
hl.window_rule({
  name  = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move  = { "20", "monitor_h-120" },
  float = true,
})

-- Float common utility apps
hl.window_rule({
  name         = "float-utilities",
  match        = { class = "^(org%.pulseaudio%.pavucontrol|bluetui|clipse|blueman-manager|tlpui|nmtui|lxappearance|qt5ct|nwg%-look)$" },

  float        = true,
  size         = { 800, 652 },
  center       = true,
  stay_focused = true,
})

-- Float file picker dialogs
hl.window_rule({
  name   = "float-file-dialogs",
  match  = { title = "^(Open|Save|Save As|File Chooser).*$" },
  float  = true,
  center = true,
})

-- Picture-in-picture
hl.window_rule({
  name  = "pip",
  match = { title = "^(Picture in picture)$" },
  float = true,
  pin   = false,
  size  = { 480, 270 },
  move  = { "100%-490", "100%-280" },
})

-- Terminal opacity
hl.window_rule({
  name    = "kitty-opacity",
  match   = { class = "^(kitty)$" },
  opacity = "0.95 0.88",
})

hl.window_rule({
  name = "move-kitty",
  match = { class = "kitty" },
  move = { 100, 100 },
  animation = "popin"
})
