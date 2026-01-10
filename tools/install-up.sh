#!/usr/bin/env sh
set -eu

# =========================
# Constants
# =========================
UP_URL="https://raw.githubusercontent.com/sinfulbobcat/cdn/refs/heads/main/tools/up.sh"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/up"
CONFIG_FILE="$CONFIG_DIR/config"

# =========================
# Helpers
# =========================
die() {
  echo "❌ $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

prompt() {
  printf "%s" "$1" > /dev/tty
  IFS= read -r REPLY < /dev/tty || true
  printf "%s" "$REPLY"
}

expand_tilde() {
  case "$1" in
    "~"*) printf "%s\n" "$HOME${1#\~}" ;;
    *)    printf "%s\n" "$1" ;;
  esac
}

# =========================
# Sanity checks
# =========================
need git
need sed

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  die "curl or wget is required"
fi

# =========================
# Install up.sh
# =========================
echo "📦 up — installer"
echo "-----------------"

mkdir -p "$INSTALL_DIR"

echo "⬇️  Downloading up.sh"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$UP_URL" -o "$INSTALL_DIR/up.sh"
else
  wget -q "$UP_URL" -O "$INSTALL_DIR/up.sh"
fi

chmod +x "$INSTALL_DIR/up.sh"
ln -sf "$INSTALL_DIR/up.sh" "$INSTALL_DIR/up"

echo "✅ Installed binary: $INSTALL_DIR/up"

# =========================
# Interactive configuration
# =========================
mkdir -p "$CONFIG_DIR"

echo ""
echo "🛠️  Configuration"
echo "-----------------"

REPO_DIR="$(prompt "Local path for your CDN repo: ")"
[ -n "$REPO_DIR" ] || die "Repo directory cannot be empty"
REPO_DIR="$(expand_tilde "$REPO_DIR")"

REPO_URL="$(prompt "GitHub repo URL (HTTPS or SSH): ")"
[ -n "$REPO_URL" ] || die "Repo URL cannot be empty"

# Basic URL sanity check
echo "$REPO_URL" | grep -Eq '(github.com[:/].+/.+)' \
  || die "Invalid GitHub repository URL"

# Clone if needed
if [ ! -d "$REPO_DIR/.git" ]; then
  echo ""
  CLONE="$(prompt "Repo not found locally. Clone it now? [y/N]: ")"
  if [ "$CLONE" = "y" ] || [ "$CLONE" = "Y" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
  else
    die "Cannot continue without a local git repository"
  fi
fi

[ -d "$REPO_DIR/.git" ] || die "Not a git repository: $REPO_DIR"

# =========================
# Write config
# =========================
cat > "$CONFIG_FILE" <<EOF
REPO_DIR="$REPO_DIR"
REPO_URL="$REPO_URL"
EOF

echo "✅ Configuration written to $CONFIG_FILE"

# =========================
# PATH handling
# =========================
add_path() {
  FILE="$1"
  grep -q 'HOME/.local/bin' "$FILE" 2>/dev/null || \
    printf '\n# Added by up installer\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$FILE"
}

if command -v fish >/dev/null 2>&1 && [ -n "${FISH_VERSION:-}" ]; then
  fish -c 'fish_add_path -U ~/.local/bin'
elif [ -n "${BASH_VERSION:-}" ]; then
  add_path "$HOME/.bashrc"
elif [ -n "${ZSH_VERSION:-}" ]; then
  add_path "$HOME/.zshrc"
else
  add_path "$HOME/.profile"
fi

# =========================
# Done
# =========================
echo ""
echo "🎉 Installation complete"
echo ""
echo "Restart your shell or run:"
echo "  exec \$SHELL"
echo ""
echo "Try:"
echo "  up --help"
