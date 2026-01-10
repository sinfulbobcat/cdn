#!/bin/bash
set -e

CONFIG_FILE="$HOME/.config/up/config"
UPDATE_URL="https://cdn.jsdelivr.net/gh/sinfulbobcat/cdn/tools/up.sh"

[ -f "$CONFIG_FILE" ] || { echo "❌ up is not configured"; exit 1; }
. "$CONFIG_FILE"

# --- helpers ---
repo_slug() {
  git -C "$REPO_DIR" config --get remote.origin.url \
    | sed 's|.*github.com[:/]\(.*\)\.git|\1|'
}

cdn_url() {
  echo "https://cdn.jsdelivr.net/gh/$(repo_slug)/$1"
}

copy_clip() {
  if command -v wl-copy >/dev/null; then
    wl-copy
  elif command -v xclip >/dev/null; then
    xclip -selection clipboard
  fi
}

spinner() {
  local pid=$1
  local s='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for c in $s; do
      printf "\r [%c] " "$c"
      sleep 0.1
    done
  done
  printf "\r     \r"
}

run() {
  "$@" >/dev/null 2>&1 &
  spinner $!
}

# --- flags ---
LIST=false
COPY=""
REMOVE=""
TAG=""
UPDATE=false

while [[ "$1" == -* ]]; do
  case "$1" in
    -l|--list) LIST=true; shift ;;
    -c|--copy) COPY="$2"; shift 2 ;;
    -r|--remove) REMOVE="$2"; shift 2 ;;
    -t|--tag) TAG="$2"; shift 2 ;;
    -u|--update) UPDATE=true; shift ;;
    -h|--help)
      echo "up [-l] [-c file] [-r file] [-t tag] [-u] <file>"
      exit 0
      ;;
    *) echo "❌ Unknown option: $1"; exit 1 ;;
  esac
done

# --- update ---
if $UPDATE; then
  echo "⬇️  Updating up..."
  curl -fsSL "$UPDATE_URL" -o "$0"
  chmod +x "$0"
  echo "✅ Updated"
  exit 0
fi

# --- list ---
if $LIST; then
  cd "$REPO_DIR"
  find . -type f ! -path "./.git/*" | sed 's|^\./||' | while read -r f; do
    printf "%-35s | %s\n" "$f" "$(cdn_url "$f")"
  done
  exit 0
fi

# --- copy ---
if [ -n "$COPY" ]; then
  cd "$REPO_DIR"
  [ -f "$COPY" ] || { echo "❌ File not found"; exit 1; }
  URL="$(cdn_url "$COPY")"
  echo "$URL"
  echo "$URL" | copy_clip
  exit 0
fi

# --- remove ---
if [ -n "$REMOVE" ]; then
  cd "$REPO_DIR"
  [ -f "$REMOVE" ] || { echo "❌ File not found"; exit 1; }
  read -p "Remove '$REMOVE'? [y/N]: " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0
  run git rm "$REMOVE"
  run git commit -m "cdn: remove $REMOVE"
  run git push
  exit 0
fi

# --- upload ---
FILE="$1"
[ -z "$FILE" ] && { echo "❌ No file provided"; exit 1; }

SRC="$(pwd)/$FILE"
[ -f "$SRC" ] || { echo "❌ File not found"; exit 1; }

REL="$(realpath --relative-to="$(pwd)" "$SRC")"
DEST="$REPO_DIR/$REL"

mkdir -p "$(dirname "$DEST")"
cp "$SRC" "$DEST"

cd "$REPO_DIR"
run git add "$REL"
run git commit -m "cdn: add $REL"
[ -n "$TAG" ] && run git tag "$TAG"
run git push
[ -n "$TAG" ] && run git push origin "$TAG"

URL="$(cdn_url "$REL")"
echo "$URL"
echo "$URL" | copy_clip
