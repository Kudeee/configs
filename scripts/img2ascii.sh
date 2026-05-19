#!/usr/bin/env bash
# img2ascii.sh — convert images in a folder to chafa ASCII art
# Usage: ./img2ascii.sh [folder] [output_dir]

set -euo pipefail

# ─── colors for terminal output ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── defaults ─────────────────────────────────────────────────────────────────
DEFAULT_OUTPUT_DIR="$HOME/.config/fastfetch/ascii"
INPUT_DIR="${1:-}"
OUTPUT_DIR="${2:-$DEFAULT_OUTPUT_DIR}"

# ─── supported image formats ──────────────────────────────────────────────────
IMAGE_EXTENSIONS=(
  jpg jpeg jpe jfif   # JPEG variants
  png                 # PNG
  gif                 # GIF (animated OK, saves first frame)
  webp                # WebP
  avif avifs          # AVIF
  bmp dib             # Bitmap
  tif tiff            # TIFF
  ico cur             # Icon
  pnm pbm pgm ppm pam # Netpbm
  xpm xbm             # X11 formats
  pcx                 # PCX
  tga tpic            # Targa
  svg svgz            # SVG (needs librsvg)
  heic heif           # HEIF/HEIC
  jp2 j2k jpf jpx jpm # JPEG 2000
  exr                 # OpenEXR
  hdr rgbe            # Radiance HDR
  ff farbfeld         # Farbfeld
)

# ─── help ─────────────────────────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}Usage:${RESET}"
  echo -e "  $(basename "$0") <image_folder> [output_dir]"
  echo ""
  echo -e "${BOLD}Arguments:${RESET}"
  echo -e "  image_folder   Folder to scan for images (required)"
  echo -e "  output_dir     Where to save .txt files (default: $DEFAULT_OUTPUT_DIR)"
  echo ""
  echo -e "${BOLD}Example:${RESET}"
  echo -e "  $(basename "$0") ~/Pictures"
  echo -e "  $(basename "$0") ~/Pictures ~/.config/fastfetch"
  echo ""
  echo -e "${BOLD}Options passed to chafa:${RESET}"
  echo -e "  --format symbols --colors full --size 40x40"
  exit 0
}

# ─── checks ───────────────────────────────────────────────────────────────────
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

if [[ -z "$INPUT_DIR" ]]; then
  echo -e "${RED}Error:${RESET} Please provide a folder to scan."
  echo -e "Run ${CYAN}$(basename "$0") --help${RESET} for usage."
  exit 1
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  echo -e "${RED}Error:${RESET} Folder not found: $INPUT_DIR"
  exit 1
fi

if ! command -v chafa &>/dev/null; then
  echo -e "${RED}Error:${RESET} chafa is not installed or not in PATH."
  echo -e "Install it with:"
  echo -e "  ${CYAN}sudo apt install chafa${RESET}       (Debian/Ubuntu)"
  echo -e "  ${CYAN}sudo dnf install chafa${RESET}       (Fedora)"
  echo -e "  ${CYAN}sudo pacman -S chafa${RESET}         (Arch)"
  echo -e "  ${CYAN}brew install chafa${RESET}           (macOS)"
  exit 1
fi

# ─── build regex pattern for find -iregex ────────────────────────────────────
build_regex() {
  local joined
  joined="$(
    IFS='|'
    echo "${IMAGE_EXTENSIONS[*]}"
  )"
  echo ".+\.(${joined})"
}

# ─── create output dir if needed ─────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

# ─── scan for images ──────────────────────────────────────────────────────────
echo -e "${BOLD}Scanning:${RESET} $INPUT_DIR"
echo -e "${BOLD}Output:  ${RESET} $OUTPUT_DIR"
echo ""

REGEX="$(build_regex)"

mapfile -d '' IMAGES < <(
  find "$INPUT_DIR" -maxdepth 5 -type f -regextype egrep -iregex "$REGEX" -print0 2>/dev/null | sort -z
)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No images found in:${RESET} $INPUT_DIR"
  exit 0
fi

echo -e "Found ${CYAN}${#IMAGES[@]}${RESET} image(s). Converting...\n"

# ─── convert each image ───────────────────────────────────────────────────────
SUCCESS=0
FAILED=0
SKIPPED=0

for IMAGE in "${IMAGES[@]}"; do
  [[ -z "$IMAGE" ]] && continue

  BASENAME="$(basename "$IMAGE")"
  # strip extension, keep name
  NAME="${BASENAME%.*}"
  # sanitize: replace spaces/special chars with underscores
  SAFE_NAME="${NAME//[^a-zA-Z0-9._-]/_}"
  OUTPUT_FILE="$OUTPUT_DIR/${SAFE_NAME}.txt"

  # skip if already converted (add --force flag to override)
  if [[ -f "$OUTPUT_FILE" && "${FORCE:-0}" != "1" ]]; then
    echo -e "  ${YELLOW}skip${RESET}  $BASENAME  →  already exists (${SAFE_NAME}.txt)"
    ((SKIPPED++)) || true
    continue
  fi

  # run chafa
  if chafa \
    --format symbols \
    --colors full \
    --size 40x40 \
    "$IMAGE" >"$OUTPUT_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}ok${RESET}    $BASENAME  →  ${SAFE_NAME}.txt"
    ((SUCCESS++)) || true
  else
    echo -e "  ${RED}fail${RESET}  $BASENAME  →  chafa could not read this file"
    rm -f "$OUTPUT_FILE" # remove empty/bad output
    ((FAILED++)) || true
  fi
done

# ─── summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "─────────────────────────────────────"
echo -e "  ${GREEN}Converted:${RESET} $SUCCESS"
[[ $SKIPPED -gt 0 ]] && echo -e "  ${YELLOW}Skipped:${RESET}   $SKIPPED  (already exist)"
[[ $FAILED -gt 0 ]] && echo -e "  ${RED}Failed:${RESET}    $FAILED"
echo -e "  Output dir: $OUTPUT_DIR"
echo -e "─────────────────────────────────────"

# tip: re-run with FORCE=1 to overwrite existing files
if [[ $SKIPPED -gt 0 ]]; then
  echo -e "\n${CYAN}Tip:${RESET} Re-run with ${BOLD}FORCE=1${RESET} to overwrite existing files:"
  echo -e "  FORCE=1 $(basename "$0") $INPUT_DIR $OUTPUT_DIR"
fi
