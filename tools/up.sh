#!/bin/bash
set -e

CONFIG_FILE="$HOME/.config/up/config"

if [ -f "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
else
  echo "❌ up is not configured"
  echo "👉 Run the installer again or create:"
  echo "   $CONFIG_FILE"
  exit 1
fi


# ---------------- Help ----------------
show_help() {
  cat <<EOF
Usage: up [options] <file>

Upload, remove, or inspect files in the CDN GitHub repo.

Options:
  -h, --help          Show this help menu
  -t, --tag <tag>     Create and push a git tag (e.g. v1.0.0)
  -r, --remove        Remove a file from the CDN repo
  -l, --list          List files currently in the CDN repo

Examples:
  up image.png
  up assets/js/app.js
  up -t v1.2.0 styles/main.css
  up -r assets/js/app.js
  up -l
EOF
}

# ---------------- Spinner ----------------
spinner() {
  local pid=$1
  local delay=0.1
  local spin='|/-\'
  while kill -0 "$pid" 2>/dev/null; do
    for i in {0..3}; do
      printf "\r [%c] " "${spin:$i:1}"
      sleep $delay
    done
  done
  printf "\r     \r"
}

run_silent() {
  "$@" >/dev/null 2>&1 &
  spinner $!
}

TAG=""
REMOVE=false
LIST=false

# ---------------- Parse args ----------------
while [[ "$1" == -* ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    -r|--remove)
      REMOVE=true
      shift
      ;;
    -l|--list)
      LIST=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# ---------------- List Mode ----------------
if $LIST; then
  echo "📦 CDN contents:"
  cd "$REPO_DIR"

  if command -v tree >/dev/null; then
    tree -I ".git"
  else
    find . -not -path "./.git*" | sed 's|[^/]*/|│   |g;s|│   \([^│]*\)$|├── \1|'
  fi
  exit 0
fi

FILE="$1"
[ -z "$FILE" ] && show_help && exit 1

# ---------------- REMOVE MODE ----------------
if $REMOVE; then
  cd "$REPO_DIR"

  if [ ! -f "$FILE" ]; then
    echo "❌ File not found in CDN repo: $FILE"
    exit 1
  fi

  read -p "⚠️  Remove '$FILE' from CDN? [y/N]: " CONFIRM
  [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "❌ Cancelled" && exit 0

  echo -n "🗑️ Removing file"
  run_silent git rm "$FILE"
  run_silent git commit -m "cdn: remove $FILE"
  run_silent git push

  echo " [████████████████] done"
  echo "✅ File removed."
  exit 0
fi

# ---------------- UPLOAD MODE (FIXED) ----------------

# Resolve paths BEFORE changing directory
SRC_PWD="$(pwd)"

if [ ! -f "$SRC_PWD/$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

FILE_PATH="$(realpath "$SRC_PWD/$FILE")"
REL_PATH="$(realpath --relative-to="$SRC_PWD" "$FILE_PATH")"
DEST_PATH="$REPO_DIR/$REL_PATH"

echo "📁 Preserving path: $REL_PATH"
mkdir -p "$(dirname "$DEST_PATH")"
cp "$FILE_PATH" "$DEST_PATH"

cd "$REPO_DIR"

echo -n "⏳ Uploading to GitHub"
run_silent git add "$REL_PATH"
run_silent git commit -m "cdn: add $REL_PATH"

if [ -n "$TAG" ]; then
  run_silent git tag "$TAG"
fi

run_silent git push

if [ -n "$TAG" ]; then
  run_silent git push origin "$TAG"
fi

echo " [████████████████] done"

# ---------------- CDN URL ----------------
REPO_SLUG=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
CDN_URL="https://cdn.jsdelivr.net/gh/$REPO_SLUG/$REL_PATH"

echo "🌍 CDN URL:"
echo "$CDN_URL"

# ---------------- Clipboard ----------------
if command -v wl-copy >/dev/null; then
  echo "$CDN_URL" | wl-copy
  echo "📋 URL copied to clipboard"
elif command -v xclip >/dev/null; then
  echo "$CDN_URL" | xclip -selection clipboard
  echo "📋 URL copied to clipboard"
else
  echo "⚠️ Clipboard tool not found"
fi

echo "✅ Upload complete."
