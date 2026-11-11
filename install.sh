#!/usr/bin/env bash
# =============================================================================
#  install.sh — deploy this dotfiles repo (Hyprland / Wayland desktop) on Arch
# =============================================================================
#  Put this file in the ROOT of your config repo (next to hypr/, waybar/, nvim/…)
#  and run it as your normal user:
#
#      ./install.sh --dry-run     # preview everything, change nothing
#      ./install.sh               # full install (asks once before starting)
#
#  Works on Arch Linux and CachyOS (auto-detected, override with --distro).
#
#  What it does (every step is idempotent, safe to re-run):
#    1. enables [multilib] (steam + lib32-* need it), full-upgrades, installs
#       your pacman packages; anything not in the official repos goes to the AUR.
#       Packages already satisfied by an installed provider are left alone
#       (e.g. power-profiles-daemon when CachyOS's tuned-cachy-ppd provides it)
#    2. installs the fonts the config uses but pacman doesn't ship
#       (Silkscreen, Press Start 2P, Cozette)
#    3. adds Flathub + the Zen browser flatpak (hyprland.lua launches it)
#    4. symlinks the repo into ~/.config (existing files are moved to a backup)
#    5. creates ~/Pictures/{wallpapers,screenshots} (scripts/keybinds expect them)
#    6. enables the services the config relies on, sets fish as login shell
#    7. installs Node LTS via nvm.fish and restores Neovim plugins from
#       lazy-lock.json
# =============================================================================
set -Eeuo pipefail

# ─────────────────────────────── options ─────────────────────────────────────
DRY_RUN=0
ASSUME_YES=0
COPY_MODE=0
DO_PACKAGES=1
DO_LINKS=1
DO_SERVICES=1
DO_BOOTSTRAP=1
DISTRO=auto # auto | arch | cachyos

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  -n, --dry-run      print what would happen, change nothing
  -y, --yes          don't ask for confirmation; pass --noconfirm to pacman/yay
      --copy         copy files into ~/.config instead of symlinking them
      --distro NAME  arch | cachyos (default: auto-detect)
      --no-packages  skip packages, fonts and flatpak
      --no-services  skip systemd services, groups and chsh
      --no-bootstrap skip Node (nvm) install and Neovim plugin restore
      --links-only   only deploy the config files (same as the three --no-* above)
  -h, --help         show this help

Existing files in ~/.config are never deleted: they are moved to
~/.dotfiles-backup/<timestamp>/ first.
EOF
}

while (($#)); do
  case "$1" in
  -n | --dry-run) DRY_RUN=1 ;;
  -y | --yes) ASSUME_YES=1 ;;
  --copy) COPY_MODE=1 ;;
  --distro)
    shift
    DISTRO="${1:-}"
    ;;
  --distro=*) DISTRO="${1#--distro=}" ;;
  --no-packages) DO_PACKAGES=0 ;;
  --no-services) DO_SERVICES=0 ;;
  --no-bootstrap) DO_BOOTSTRAP=0 ;;
  --links-only)
    DO_PACKAGES=0
    DO_SERVICES=0
    DO_BOOTSTRAP=0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

case "$DISTRO" in
auto | arch | cachyos) ;;
*)
  echo "Invalid --distro '$DISTRO' (use arch or cachyos)" >&2
  exit 2
  ;;
esac

# ─────────────────────────────── paths ───────────────────────────────────────
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# The configs hard-code ~/.config/... in many places (waybar, hyprland.lua,
# matugen, rofi), so this is intentionally NOT derived from XDG_CONFIG_HOME.
CONFIG_HOME="$HOME/.config"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BACKED_UP=0
ME="$(id -un)"

# Top-level items of the repo that map 1:1 to ~/.config/<item>.
# (gtk-3.0 is handled separately — see link_gtk.)
LINK_ITEMS=(
  fastfetch
  fish
  hypr
  kitty
  matugen
  nvim
  rofi
  rofimoji
  rofimoji.rc
  scripts
  waybar
  waybar-hdmi
)

# ─────────────────────────────── packages ────────────────────────────────────
# Taken from your `pacman -Qqe`, minus: yay + yay-debug (AUR; bootstrapped below)
# and the typo'd first line ("acman -Qqe").

# Base system, split by distro.
# On an existing install these are no-ops (--needed). NOTE: this only installs
# *packages*; /etc configs for limine, snapper and ufw are not part of the repo
# and are not touched.
PKG_BASE_COMMON=(
  base-devel linux-firmware intel-ucode sof-firmware sudo
  btrfs-progs snapper smartmontools fwupd dmidecode usbutils ufw
)
# Kernel, bootloader and zram are set up by the CachyOS installer / cachyos-settings
# (the kernel there is linux-cachyos). Adding the vanilla `linux` kernel on top would
# create a second kernel + bootloader entry, so these are skipped on CachyOS.
PKG_BASE_ARCH_ONLY=(base linux efibootmgr limine zram-generator)

PKG_NETWORK=(networkmanager iwd bluez bluez-utils bluetui)

PKG_HYPRLAND=(
  hyprland hyprpolkitagent hyprshutdown hyprsunset xdg-desktop-portal-hyprland
  uwsm sddm qt5-wayland qt6-wayland
  waybar rofi rofimoji swaync awww matugen nwg-displays
  grim slurp satty cliphist brightnessctl power-profiles-daemon
  gnome-keyring imagemagick
)

PKG_APPS=(
  kitty thunar thunar-archive-plugin thunar-media-tags-plugin tumbler gvfs ark
  pavucontrol code obsidian obs-studio vlc vlc-plugins-all guvcview
  btop fastfetch flatpak flatseal
)

PKG_DEV=(fish neovim git fzf nasm postgresql python-pip python-docx img2pdf)

PKG_AUDIO=(
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber libpulse
  gst-plugin-pipewire gst-plugins-base gst-plugins-good gst-plugins-bad
  gst-plugins-ugly qt6-multimedia
)

# lib32-* + steam come from [multilib] → enable_multilib runs first.
PKG_GPU_GAMING=(
  vulkan-intel lib32-vulkan-intel lib32-mesa intel-gpu-tools
  steam gamemode lib32-gamemode mangohud lib32-mangohud
)

PKG_VIRT=(qemu-desktop qemu-emulators-full libvirt virt-manager swtpm dnsmasq iptables)

PKG_PRINT=(cups cups-pk-helper system-config-printer gutenprint ghostscript gsfonts)

PKG_FONTS=(ttf-jetbrains-mono-nerd noto-fonts-cjk ttf-croscore ttf-liberation)

# NOT in your package list, but your config calls them. (pacman -Qqe only lists
# explicitly-installed packages, so some of these may already be there as
# dependencies — --needed makes that harmless.)
#   wl-clipboard      hyprland.lua autostart (wl-paste), rofimoji.rc (wl-copy), SUPER+C
#   playerctl         hyprland.lua media keys
#   wtype             rofimoji.rc "typer = wtype"
#   intel-media-driver  hyprland.lua sets LIBVA_DRIVER_NAME=iHD (needs this driver)
#   ripgrep, fd       LazyVim pickers; venv-selector.nvim needs fd
#   tree-sitter-cli   nvim-treesitter (main branch, pinned in lazy-lock.json)
#   chafa             scripts/img2ascii.sh
#   libnotify         notify-send in wallpaper.sh / cycle-power-profile.sh
PKG_EXTRA=(
  wl-clipboard playerctl wtype intel-media-driver
  ripgrep fd tree-sitter-cli chafa libnotify
)

# AUR-only things your config needs (not in your pacman list):
#   cozette-otb  rofi/waybar font "Cozette" (upstream's recommended Arch package)
AUR_EXTRA=(cozette-otb)

ALL_PKGS=()
build_package_list() {
  ALL_PKGS=("${PKG_BASE_COMMON[@]}")
  if [[ $DISTRO != cachyos ]]; then ALL_PKGS+=("${PKG_BASE_ARCH_ONLY[@]}"); fi
  ALL_PKGS+=(
    "${PKG_NETWORK[@]}" "${PKG_HYPRLAND[@]}" "${PKG_APPS[@]}"
    "${PKG_DEV[@]}" "${PKG_AUDIO[@]}" "${PKG_GPU_GAMING[@]}" "${PKG_VIRT[@]}"
    "${PKG_PRINT[@]}" "${PKG_FONTS[@]}" "${PKG_EXTRA[@]}"
  )
}

detect_distro() {
  if [[ $DISTRO != auto ]]; then return 0; fi
  # /etc/os-release has ID=cachyos but (as of 2025) no ID_LIKE, so also look for
  # the [cachyos*] repo sections that every CachyOS pacman.conf has.
  if grep -qiE '^ID="?cachyos"?$' /etc/os-release 2>/dev/null ||
    grep -qE '^\[cachyos' /etc/pacman.conf 2>/dev/null; then
    DISTRO=cachyos
  else
    DISTRO=arch
  fi
}

# Fonts that pacman doesn't ship. Pinned to the google/fonts repo (OFL licensed).
GF_RAW="https://raw.githubusercontent.com/google/fonts/main/ofl"
FONT_URLS=(
  "Silkscreen-Regular.ttf|$GF_RAW/silkscreen/Silkscreen-Regular.ttf"
  "Silkscreen-Bold.ttf|$GF_RAW/silkscreen/Silkscreen-Bold.ttf"
  "PressStart2P-Regular.ttf|$GF_RAW/pressstart2p/PressStart2P-Regular.ttf"
)

ZEN_FLATPAK="app.zen_browser.zen" # matches `browser` in hypr/hyprland.lua

# ─────────────────────────────── helpers ─────────────────────────────────────
if [[ -t 1 ]]; then
  C_RED=$'\033[31m' C_GRN=$'\033[32m' C_YLW=$'\033[33m' C_BLU=$'\033[34m' C_BLD=$'\033[1m' C_OFF=$'\033[0m'
else
  C_RED='' C_GRN='' C_YLW='' C_BLU='' C_BLD='' C_OFF=''
fi

step() { printf '\n%s==>%s %s%s%s\n' "$C_BLU" "$C_OFF" "$C_BLD" "$*" "$C_OFF"; }
info() { printf '    %s\n' "$*"; }
ok() { printf '    %s✓%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '    %s!%s %s\n' "$C_YLW" "$C_OFF" "$*" >&2; }
die() {
  printf '%sError:%s %s\n' "$C_RED" "$C_OFF" "$*" >&2
  exit 1
}

trap 'printf "%sFailed%s at line %s: %s\n" "$C_RED" "$C_OFF" "$LINENO" "$BASH_COMMAND" >&2' ERR

# Run a command, or just print it in --dry-run mode.
run() {
  if ((DRY_RUN)); then
    printf '    [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

NOCONFIRM=()
if ((ASSUME_YES)); then NOCONFIRM=(--noconfirm); fi

confirm() {
  if ((ASSUME_YES || DRY_RUN)); then return 0; fi
  local reply
  read -r -p "$1 [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]]
}

# ─────────────────────────────── preflight ───────────────────────────────────
preflight() {
  step "Preflight"
  if ((EUID == 0)); then die "Run as your normal user, not root (sudo is used where needed)."; fi
  command -v pacman >/dev/null || die "pacman not found — this script targets Arch Linux."
  if ((DO_PACKAGES || DO_SERVICES)); then
    command -v sudo >/dev/null || die "sudo not found (it is in your package list: pacman -S sudo as root)."
  fi
  if [[ -n ${XDG_CONFIG_HOME:-} && $XDG_CONFIG_HOME != "$CONFIG_HOME" ]]; then
    warn "XDG_CONFIG_HOME=$XDG_CONFIG_HOME, but the configs hard-code ~/.config — using ~/.config."
  fi

  local item missing=0
  for item in "${LINK_ITEMS[@]}" gtk-3.0; do
    if [[ ! -e $REPO_DIR/$item ]]; then
      warn "not found in repo: $item"
      missing=1
    fi
  done
  if ((missing)); then warn "Run this script from the root of your config repo."; fi

  detect_distro
  build_package_list
  info "distro:    $DISTRO"
  info "repo:      $REPO_DIR"
  info "target:    $CONFIG_HOME"
  info "mode:      $( ((COPY_MODE)) && echo copy || echo symlink )$( ((DRY_RUN)) && echo ', dry-run' )"
  info "stages:    packages=$DO_PACKAGES links=$DO_LINKS services=$DO_SERVICES bootstrap=$DO_BOOTSTRAP"

  if ! confirm "Continue?"; then die "Aborted."; fi

  if ((!DRY_RUN && (DO_PACKAGES || DO_SERVICES))); then
    sudo -v
    # keep the sudo timestamp fresh during long builds
    (while true; do
      sudo -n true
      sleep 50
      kill -0 "$$" 2>/dev/null || exit 0
    done) >/dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
  fi
}

# ─────────────────────────────── packages ────────────────────────────────────
multilib_enabled() {
  grep -qE '^\[multilib\]' /etc/pacman.conf &&
    grep -A1 -E '^\[multilib\]' /etc/pacman.conf | grep -qE '^Include'
}

enable_multilib() {
  if multilib_enabled; then
    ok "[multilib] already enabled"
    return 0
  fi
  info "enabling [multilib] in /etc/pacman.conf (needed by steam and lib32-*)"
  run sudo cp /etc/pacman.conf "/etc/pacman.conf.bak.$(date +%s)"
  if grep -qE '^#\[multilib\]$' /etc/pacman.conf; then
    # uncomment ONLY the header and the Include line directly below it
    run sudo sed -i '/^#\[multilib\]$/{s/^#//;n;s/^#Include/Include/}' /etc/pacman.conf
  else
    run bash -c "printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null"
  fi
  if ! ((DRY_RUN)) && ! multilib_enabled; then
    die "Could not enable [multilib] automatically. Edit /etc/pacman.conf and uncomment [multilib] and the Include line under it, then re-run."
  fi
}

AUR_HELPER=""
detect_aur_helper() {
  AUR_HELPER=""
  local h
  for h in yay paru; do
    if command -v "$h" >/dev/null 2>&1; then
      AUR_HELPER="$h"
      return 0
    fi
  done
  return 0
}

ensure_aur_helper() {
  detect_aur_helper
  # Prefer yay (it's in your package list). CachyOS carries it in its own repo
  # (sudo pacman -S yay); on plain Arch it has to come from the AUR.
  if [[ $AUR_HELPER != yay ]] && pacman -Si yay >/dev/null 2>&1; then
    info "installing yay from the enabled repos"
    run sudo pacman -S --needed "${NOCONFIRM[@]}" yay
    detect_aur_helper
    if ((DRY_RUN)); then AUR_HELPER="yay"; fi
  fi
  if [[ -n $AUR_HELPER ]]; then
    ok "AUR helper: $AUR_HELPER"
    return 0
  fi
  info "bootstrapping yay-bin from the AUR (prebuilt, so no Go toolchain needed)"
  local tmp
  tmp="$(mktemp -d)"
  run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && run makepkg -si --needed "${NOCONFIRM[@]}")
  rm -rf "$tmp"
  detect_aur_helper
  if ((DRY_RUN)); then AUR_HELPER="yay"; fi
  [[ -n $AUR_HELPER ]] || die "Could not set up an AUR helper."
}

install_packages() {
  step "Packages"
  enable_multilib

  info "full system upgrade first (Arch does not support partial upgrades)"
  run sudo pacman -Syu "${NOCONFIRM[@]}"

  if ((DRY_RUN)); then
    info "would install ${#ALL_PKGS[@]} packages with: pacman -S --needed"
    info "…anything pacman can't find in the official repos is built from the AUR"
    info "plus AUR: ${AUR_EXTRA[*]}"
    return 0
  fi

  # Decide official vs AUR by asking pacman, instead of hard-coding it.
  # `pacman -T` is satisfied by any installed *provider*, so a package is left
  # alone when something equivalent is already there (CachyOS's tuned-cachy-ppd
  # provides power-profiles-daemon and conflicts with it; rofi-wayland provides
  # rofi; and so on). Installing those blindly would abort the whole transaction.
  local pkg official=() aur=("${AUR_EXTRA[@]}") provided=()
  for pkg in "${ALL_PKGS[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      continue # already installed
    elif pacman -T "$pkg" >/dev/null 2>&1; then
      provided+=("$pkg")
    elif pacman -Si "$pkg" >/dev/null 2>&1; then
      official+=("$pkg")
    else
      aur+=("$pkg")
    fi
  done

  if ((${#provided[@]})); then
    info "left alone (an installed package already provides them): ${provided[*]}"
  fi
  if ((${#official[@]})); then
    info "${#official[@]} packages to install from the official repos"
    sudo pacman -S --needed "${NOCONFIRM[@]}" "${official[@]}"
  else
    ok "nothing missing from the official repos"
  fi

  if ((${#aur[@]})); then
    info "${#aur[@]} from the AUR: ${aur[*]}"
    ensure_aur_helper
    "$AUR_HELPER" -S --needed "${NOCONFIRM[@]}" "${aur[@]}" ||
      warn "some AUR packages failed — re-run later: $AUR_HELPER -S --needed ${aur[*]}"
  fi
}

install_fonts() {
  step "Fonts (Silkscreen, Press Start 2P)"
  local dir="$DATA_HOME/fonts/dotfiles" entry name url
  run mkdir -p "$dir"
  for entry in "${FONT_URLS[@]}"; do
    name="${entry%%|*}"
    url="${entry#*|}"
    if [[ -s $dir/$name ]]; then
      ok "$name already installed"
      continue
    fi
    info "downloading $name"
    if run curl -fsSL --retry 3 -o "$dir/$name.part" "$url"; then
      run mv -f -- "$dir/$name.part" "$dir/$name"
    else
      rm -f -- "$dir/$name.part"
      warn "could not download $name from $url"
    fi
  done
  if command -v fc-cache >/dev/null 2>&1 || ((DRY_RUN)); then run fc-cache -f "$dir"; fi
  info "Cozette comes from the AUR (cozette-otb) in the package step above"
}

install_flatpaks() {
  step "Flatpak ($ZEN_FLATPAK)"
  if ! command -v flatpak >/dev/null 2>&1 && ! ((DRY_RUN)); then
    warn "flatpak not installed — skipping"
    return 0
  fi
  run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  run sudo flatpak install -y --noninteractive flathub "$ZEN_FLATPAK" ||
    warn "Zen install failed — retry: sudo flatpak install flathub $ZEN_FLATPAK"
  if ! ((DRY_RUN)) && [[ ! -x /var/lib/flatpak/exports/bin/$ZEN_FLATPAK ]]; then
    warn "expected launcher /var/lib/flatpak/exports/bin/$ZEN_FLATPAK not found"
  fi
}

# ─────────────────────────────── config files ────────────────────────────────
backup_existing() {
  local path="$1" rel
  rel="${path#"$HOME"/}"
  info "backing up existing ~/${rel} → ${BACKUP_DIR/#"$HOME"/\~}/${rel}"
  run mkdir -p -- "$BACKUP_DIR/$(dirname -- "$rel")"
  run mv -- "$path" "$BACKUP_DIR/$rel"
  BACKED_UP=1
}

link_one() {
  local src="$1" dst="$2"
  if [[ ! -e $src ]]; then
    warn "missing in repo, skipped: ${src#"$REPO_DIR"/}"
    return 0
  fi
  if ((COPY_MODE)); then
    if [[ -e $dst && ! -L $dst ]] && diff -rq -- "$src" "$dst" >/dev/null 2>&1; then
      ok "up to date: ${dst/#"$HOME"/\~}"
      return 0
    fi
  elif [[ -L $dst && "$(readlink -f -- "$dst")" == "$(readlink -f -- "$src")" ]]; then
    ok "already linked: ${dst/#"$HOME"/\~}"
    return 0
  fi
  if [[ -e $dst || -L $dst ]]; then backup_existing "$dst"; fi
  run mkdir -p -- "$(dirname -- "$dst")"
  if ((COPY_MODE)); then
    info "copy ${src#"$REPO_DIR"/} → ${dst/#"$HOME"/\~}"
    run cp -a -- "$src" "$dst"
  else
    info "link ${dst/#"$HOME"/\~} → $src"
    run ln -s -- "$src" "$dst"
  fi
}

# gtk-3.0 is deployed file-by-file because `bookmarks` contains absolute
# file:///home/<user>/… URIs. It is generated for the current $HOME instead of
# being linked, so Thunar's sidebar works under any username and bookmarks you
# add later don't end up in the repo.
link_gtk() {
  local src="$REPO_DIR/gtk-3.0" dst="$CONFIG_HOME/gtk-3.0" f
  [[ -d $src ]] || return 0
  if [[ -L $dst ]]; then backup_existing "$dst"; fi
  run mkdir -p -- "$dst"
  for f in "$src"/*; do
    [[ -e $f ]] || continue
    [[ $(basename -- "$f") == bookmarks ]] && continue
    link_one "$f" "$dst/$(basename -- "$f")"
  done
  if [[ -f $src/bookmarks ]]; then
    if [[ -f $dst/bookmarks && ! -L $dst/bookmarks ]]; then
      ok "keeping existing ~/.config/gtk-3.0/bookmarks"
    else
      if [[ -L $dst/bookmarks ]]; then backup_existing "$dst/bookmarks"; fi
      info "generating gtk-3.0/bookmarks for $HOME"
      local esc_home
      esc_home="$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')"
      if ((DRY_RUN)); then
        info "[dry-run] sed … $src/bookmarks > $dst/bookmarks"
      else
        sed -E "s|^file:///home/[^/]+/|file://${esc_home}/|" "$src/bookmarks" >"$dst/bookmarks"
      fi
    fi
  fi
}

fix_exec_bits() {
  local d f
  for d in hypr rofi scripts waybar waybar-hdmi; do
    [[ -e $CONFIG_HOME/$d ]] || continue
    while IFS= read -r -d '' f; do
      [[ -x $f ]] || run chmod +x -- "$f" || warn "could not chmod +x ${f/#"$HOME"/\~}"
    done < <(find -L "$CONFIG_HOME/$d" -type f -name '*.sh' -print0)
  done
}

deploy_configs() {
  step "Config files → ~/.config"
  if [[ "$(readlink -f -- "$REPO_DIR")" == "$(readlink -f -- "$CONFIG_HOME")" ]]; then
    ok "repo already lives in ~/.config — nothing to link"
  else
    run mkdir -p -- "$CONFIG_HOME"
    local item
    for item in "${LINK_ITEMS[@]}"; do
      link_one "$REPO_DIR/$item" "$CONFIG_HOME/$item"
    done
    link_gtk
  fi
  fix_exec_bits

  step "Directories the scripts and keybinds expect"
  # wallpaper-init.sh / wallpaper.sh read ~/Pictures/wallpapers;
  # the Ctrl+Print binding saves to ~/Pictures/screenshots (grim fails if it is missing);
  # gtk-3.0/bookmarks points at Downloads, Pictures and Documents.
  run mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/screenshots" "$HOME/Downloads" "$HOME/Documents"
}

# ─────────────────────────────── services ────────────────────────────────────
enable_unit() { # enable_unit <unit> [--now]
  local unit="$1"
  shift
  if ((DRY_RUN)) || systemctl cat "$unit" >/dev/null 2>&1; then
    run sudo systemctl enable "$@" "$unit"
  else
    warn "unit not found, skipped: $unit"
  fi
}

setup_services() {
  step "Services"
  # NetworkManager is only *enabled* (no --now): starting it mid-run could drop your connection.
  enable_unit NetworkManager.service
  enable_unit bluetooth.service --now           # waybar bluetooth module / bluetui
  enable_unit power-profiles-daemon.service --now # scripts/cycle-power-profile.sh
  enable_unit cups.service --now                # printing

  if ((DRY_RUN)) || systemctl cat libvirtd.service >/dev/null 2>&1; then
    enable_unit libvirtd.service --now
  else
    warn "libvirtd.service not found — newer libvirt may use modular daemons (see the Arch wiki 'libvirt' page)"
  fi

  if getent group libvirt >/dev/null 2>&1 || ((DRY_RUN)); then
    if id -nG "$ME" | tr ' ' '\n' | grep -qx libvirt; then
      ok "$ME is already in the libvirt group"
    else
      run sudo usermod -aG libvirt "$ME"
      info "log out and back in for the libvirt group to apply"
    fi
  fi

  # Usually already enabled by the packages' presets; this is a harmless safety net.
  run systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service ||
    warn "could not enable user audio services (no user session?) — they normally start by themselves"

  step "Login shell"
  # config.fish starts Hyprland from tty1 via `start-hyprland`, so fish must be the login shell.
  local fish_path="/usr/bin/fish" current
  current="$(getent passwd "$ME" | cut -d: -f7)"
  if [[ $current == "$fish_path" ]]; then
    ok "login shell is already fish"
  else
    run sudo chsh -s "$fish_path" "$ME"
  fi
}

# ─────────────────────────────── bootstrap ───────────────────────────────────
bootstrap_toolchain() {
  step "Node.js + Neovim"
  if command -v fish >/dev/null 2>&1 || ((DRY_RUN)); then
    info "Node LTS via nvm.fish (what nvim/lua/config/options.lua looks for)"
    run fish -c 'nvm install lts' || warn "nvm install failed — run 'nvm install lts' in fish later"
  fi
  if command -v nvim >/dev/null 2>&1 || ((DRY_RUN)); then
    info "restoring plugins to the exact commits in nvim/lazy-lock.json"
    run nvim --headless "+Lazy! restore" +qa || warn "plugin restore failed — open nvim and run :Lazy restore"
    info "first interactive launch of nvim finishes Mason + treesitter installs"
  fi
}

# ─────────────────────────────── summary ─────────────────────────────────────
summary() {
  step "Done"
  if ((BACKED_UP)); then info "previous configs were moved to ${BACKUP_DIR/#"$HOME"/\~}"; fi

  # ── checks worth reporting, instead of leaving them as surprises ──
  if ! ((DRY_RUN)) && ! command -v powerprofilesctl >/dev/null 2>&1; then
    warn "powerprofilesctl not found — the battery module's click action (scripts/cycle-power-profile.sh) needs it."
    if [[ $DISTRO == cachyos ]]; then
      warn "(expected if tuned-cachy-ppd replaces power-profiles-daemon on this system)"
    fi
  fi
  if [[ $DISTRO == cachyos && -e $BACKUP_DIR/.config/fish ]]; then
    info "CachyOS's stock fish setup (cachyos-fish-config) was replaced by yours; the old one is in the backup folder."
  fi
  local dm=""
  if systemctl is-enabled display-manager.service >/dev/null 2>&1; then
    dm="$(systemctl show -p Id --value display-manager.service 2>/dev/null || true)"
  fi

  cat <<EOF

    Manual steps left:
      • Put wallpapers in ~/Pictures/wallpapers — hypr/scripts/wallpaper-init.sh
        exits early without one, so matugen won't regenerate colours until you do.
EOF
  if [[ -n $dm ]]; then
    cat <<EOF
      • A display manager is enabled ($dm), so you'll get a graphical login at boot.
        Your config.fish only starts Hyprland when you log in on tty1. Either pick the
        Hyprland session in $dm, or run: sudo systemctl disable $dm
EOF
  else
    cat <<'EOF'
      • Log out. fish starts Hyprland on tty1 (config.fish). If you'd rather use
        SDDM, run: sudo systemctl enable sddm   (this script does not enable it).
EOF
  fi
  if [[ $DISTRO == cachyos ]]; then
    cat <<'EOF'
      • CachyOS: kernel, bootloader and zram were left to the installer
        (skipped: base, linux, efibootmgr, limine, zram-generator).
EOF
  else
    cat <<'EOF'
      • Not handled (live in /etc, not in this repo): limine entries, snapper
        configs, /etc/systemd/zram-generator.conf, 'sudo ufw enable'.
EOF
  fi
  cat <<'EOF'
      • Check video acceleration after the first boot:  vainfo
        (hyprland.lua forces LIBVA_DRIVER_NAME=iHD)
EOF
}

# ─────────────────────────────── main ────────────────────────────────────────
main() {
  preflight
  if ((DO_PACKAGES)); then
    install_packages
    install_fonts
    install_flatpaks
  fi
  if ((DO_LINKS)); then deploy_configs; fi
  if ((DO_SERVICES)); then setup_services; fi
  if ((DO_BOOTSTRAP)); then bootstrap_toolchain; fi
  summary
}

main "$@"
