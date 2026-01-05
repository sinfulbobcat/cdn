#!/bin/bash
set -e

# ---------- Config ----------
CONFIG_FILE="$HOME/.config/up/config"
UPDATE_URL="https://cdn.jsdelivr.net/gh/sinfulbobcat/cdn/tools/up.sh"

if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  echo "❌ up is not configured"
  echo "👉 Run the installer first"
  exit 1
fi

# ---------- Helpers ----------
spinner() {
  local pid=$1
  local spin='|/-\'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r [%c] " "${spin:$i:1}"
    sleep 0.1
  done
  printf "\r     \r"
}

run_silent() {
  "$@" >/dev/null 2>&1 &
  spinner $!
}

get_repo_slug() {
  git -C "$REPO_DIR" config --get remote.origin.url \
    | sed 's/.*github.com[:/]\(.*\)\.git/\1/'
}

get_cdn_url() {
  local path="$1"
  echo "https://cdn.jsdelivr.net/gh/$(get_repo_slug)/$path"
}

copy_clipboard() {
  if command -v wl-copy >/dev/null; then
    wl-copy
  elif command -v xclip >/dev/null; then
    xclip -selection clipboard
  fi
}

show_help() {
  cat <<EOF
Usage: up [options] <file>

Options:
  -h, --help              Show help
  -l, --list              List CDN files with URLs
  -c, --copy <file>       Copy CDN URL of file
  -r, --remove <file>     Remove file from CDN repo
  -t, --tag <tag>         Upload with git tag
  -u, --update            Update up to latest version

Examples:
  up image.png
  up assets/js/app.js
  up -t v1.0.0 styles/main.css
  up -l
  up -c assets/js/app.js
  up -r old.png
  up -u
EOF
}

# ---------- Flags ----------
TAG=""
REMOVE=""
LIST=false
COPY=""
UPDATE=false

# ---------- Parse args ----------
while [[ "$1" == -* ]]; do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -l|--list) LIST=true; shift ;;
    -c|--copy) COPY="$2"; shift 2 ;;
    -r|--remove) REMOVE="$2"; shift 2 ;;
    -t|--tag) TAG="$2"; shift 2 ;;
    -u|--update) UPDATE=true; shift ;;
    *) echo "❌ Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# ---------- UPDATE ----------
if $UPDATE; then
  echo "⬇️  Updating up..."
  run_silent curl -fsSL "$UPDATE_URL" -o "$0"
  chmod +x "$0"
  echo "✅ up updated successfully"
  exit 0
fi

# ---------- LIST ----------
if $LIST; then
  cd "$REPO_DIR"
  echo "📦 CDN contents:"
  echo ""
  find . -type f ! -path "./.git/*" | sed 's|^\./||' | while read -r f; do
    printf "%-35s | %s\n" "$f" "$(get_cdn_url "$f")"
  done
  exit 0
fi

# ---------- COPY ----------
if [ -n "$COPY" ]; then
  cd "$REPO_DIR"
  [ ! -f "$COPY" ] && echo "❌ File not found: $COPY" && exit 1
  URL=$(get_cdn_url "$COPY")
  echo "$URL"
  echo "$URL" | copy_clipboard
  echo "📋 URL copied"
  exit 0
fi

# ---------- REMOVE ----------
if [ -n "$REMOVE" ]; then
  cd "$REPO_DIR"
  [ ! -f "$REMOVE" ] && echo "❌ File not found: $REMOVE" && exit 1
  read -p "Remove '$REMOVE'? [y/N]: " CONFIRM
  [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 0
  echo -n "🗑️ Removing"
  run_silent git rm "$REMOVE"
  run_silent git commit -m "cdn: remove $REMOVE"
  run_silent git push
  echo " [done]"
  exit 0
fi

# ---------- UPLOAD ----------
FILE="$1"
[ -z "$FILE" ] && show_help && exit 1

SRC_PWD="$(pwd)"
[ ! -f "$SRC_PWD/$FILE" ] && echo "❌ File not found: $FILE" && exit 1

FILE_PATH="$(realpath "$SRC_PWD/$FILE")"
REL_PATH="$(realpath --relative-to="$SRC_PWD" "$FILE_PATH")"
DEST="$REPO_DIR/$REL_PATH"

echo "📁 Preserving path: $REL_PATH"
mkdir -p "$(dirname "$DEST")"
cp "$FILE_PATH" "$DEST"

cd "$REPO_DIR"

echo -n "⏳ Uploading"
run_silent git add "$REL_PATH"
run_silent git commit -m "cdn: add $REL_PATH"

[ -n "$TAG" ] && run_silent git tag "$TAG"
run_silent git push
[ -n "$TAG" ] && run_silent git push origin "$TAG"

URL=$(get_cdn_url "$REL_PATH")
echo " [done]"
echo ""
echo "🌍 CDN URL:"
echo "$URL"
echo "$URL" | copy_clipboard
echo "📋 URL copied"

echo "✅ Upload complete"
