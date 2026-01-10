#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Constants & Config
# =========================
CONFIG_FILE="$HOME/.config/up/config"
UPDATE_URL="https://raw.githubusercontent.com/sinfulbobcat/cdn/refs/heads/main/tools/up.sh"

# =========================
# Error handling
# =========================
die() {
  echo "❌ $*" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# =========================
# Load config
# =========================
[[ -f "$CONFIG_FILE" ]] || die "up is not configured. Run the installer first."
# shellcheck disable=SC1090
source "$CONFIG_FILE"

[[ -d "$REPO_DIR/.git" ]] || die "Invalid git repo: $REPO_DIR"

require git
require realpath

# =========================
# Helpers
# =========================
repo_slug() {
  git -C "$REPO_DIR" remote get-url origin \
    | sed -E 's#(https://github.com/|git@github.com:)([^/]+/[^/.]+)(\.git)?#\2#'
}

cdn_url() {
  local path="$1"
  echo "https://cdn.jsdelivr.net/gh/$(repo_slug)/$path"
}

copy_clipboard() {
  local text="$1"

  if command -v wl-copy >/dev/null 2>&1; then
    printf "%s" "$text" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf "%s" "$text" | xclip -selection clipboard
  fi
}

spinner() {
  local pid="$1"
  local chars='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for c in $chars; do
      printf "\r [%c] " "$c"
      sleep 0.1
    done
  done
  printf "\r     \r"
}

run_silent() {
  "$@" >/dev/null 2>&1 &
  spinner $!
}

# =========================
# Commands
# =========================
cmd_update() {
  require curl
  echo "⬇️  Updating up..."
  curl -fsSL "$UPDATE_URL" -o "$0"
  chmod +x "$0"
  echo "✅ Updated successfully"
}

cmd_list() {
  cd "$REPO_DIR"
  find . -type f ! -path "./.git/*" \
    | sed 's|^\./||' \
    | while read -r f; do
        printf "%-35s | %s\n" "$f" "$(cdn_url "$f")"
      done
}

cmd_copy() {
  local file="$1"
  cd "$REPO_DIR"
  [[ -f "$file" ]] || die "File not found: $file"
  local url
  url="$(cdn_url "$file")"
  echo "$url"
  echo "$url" | copy_clipboard
}

cmd_remove() {
  local file="$1"
  cd "$REPO_DIR"
  [[ -f "$file" ]] || die "File not found: $file"
  read -rp "Remove '$file'? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
  run_silent git rm "$file"
  run_silent git commit -m "cdn: remove $file"
  run_silent git push
}

cmd_upload() {
  local src="$1"
  local tag="${2:-}"

  [[ -f "$src" ]] || die "File not found: $src"

  local abs rel dest
  abs="$(realpath "$src")"
  rel="$(realpath --relative-to="$(pwd)" "$abs")"
  dest="$REPO_DIR/$rel"

  mkdir -p "$(dirname "$dest")"
  cp "$abs" "$dest"

  cd "$REPO_DIR"
  run_silent git add "$rel"
  run_silent git commit -m "cdn: add $rel"

  if [[ -n "$tag" ]]; then
    run_silent git tag "$tag"
  fi

  run_silent git push
  [[ -n "$tag" ]] && run_silent git push origin "$tag"

  local url
  url="$(cdn_url "$rel")"
  echo "$url"
  echo "$url" | copy_clipboard
}

# =========================
# Help
# =========================
show_help() {
  cat <<EOF
Usage: up [options] <file>

Options:
  -l, --list              List CDN files with URLs
  -c, --copy <file>       Copy CDN URL of file
  -r, --remove <file>     Remove file from CDN
  -t, --tag <tag>         Upload with git tag
  -u, --update            Update up itself
  -h, --help              Show this help

Examples:
  up image.png
  up -t v1.0.0 styles/main.css
  up -l
  up -c assets/js/app.js
  up -r old.png
  up -u
EOF
}

# =========================
# Argument parsing
# =========================
TAG=""
MODE="upload"
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--list) MODE="list"; shift ;;
    -c|--copy) MODE="copy"; TARGET="$2"; shift 2 ;;
    -r|--remove) MODE="remove"; TARGET="$2"; shift 2 ;;
    -t|--tag) TAG="$2"; shift 2 ;;
    -u|--update) MODE="update"; shift ;;
    -h|--help) show_help; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) TARGET="$1"; shift ;;
  esac
done

# =========================
# Dispatch
# =========================
case "$MODE" in
  update)  cmd_update ;;
  list)    cmd_list ;;
  copy)    cmd_copy "$TARGET" ;;
  remove)  cmd_remove "$TARGET" ;;
  upload)
    [[ -n "$TARGET" ]] || die "No file specified"
    cmd_upload "$TARGET" "$TAG"
    ;;
esac
