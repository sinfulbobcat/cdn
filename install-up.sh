#!/bin/sh
set -e

UP_URL="https://cdn.jsdelivr.net/gh/USERNAME/REPO/tools/up.sh"
INSTALL_DIR="$HOME/.local/bin"
UP_SH="$INSTALL_DIR/up.sh"
UP_LINK="$INSTALL_DIR/up"

echo "📦 Installing up…"

# Create install dir
mkdir -p "$INSTALL_DIR"

# Download
echo "⬇️  Downloading up.sh"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$UP_URL" -o "$UP_SH"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$UP_URL" -O "$UP_SH"
else
  echo "❌ curl or wget is required"
  exit 1
fi

# Make executable
chmod +x "$UP_SH"

# Create symlink
ln -sf "$UP_SH" "$UP_LINK"

echo "🔗 Installed as: $UP_LINK"

# Ensure PATH (bash/zsh)
SHELL_NAME="$(basename "$SHELL")"

ensure_path() {
  FILE="$1"
  grep -q 'HOME/.local/bin' "$FILE" 2>/dev/null || \
    echo '\n# Added by up installer\nexport PATH="$HOME/.local/bin:$PATH"' >> "$FILE"
}

case "$SHELL_NAME" in
  bash)
    ensure_path "$HOME/.bashrc"
    ;;
  zsh)
    ensure_path "$HOME/.zshrc"
    ;;
  fish)
    fish -c 'fish_add_path -U ~/.local/bin'
    ;;
esac

echo "✅ Installation complete"
echo ""
echo "➡️  Restart your shell or run:"
echo "    exec $SHELL_NAME"
echo ""
echo "Try:"
echo "    up --help"
