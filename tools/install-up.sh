#!/bin/sh
set -e

UP_URL="https://cdn.jsdelivr.net/gh/sinfulbobcat/cdn/tools/up.sh"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/up"
CONFIG_FILE="$CONFIG_DIR/config"

echo "📦 up — interactive installer"
echo "--------------------------------"

# --- sanity checks ---
command -v git >/dev/null 2>&1 || {
  echo "❌ git is required but not installed"
  exit 1
}

# --- install binary ---
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

echo "⬇️  Downloading up.sh"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$UP_URL" -o "$INSTALL_DIR/up.sh"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$UP_URL" -O "$INSTALL_DIR/up.sh"
else
  echo "❌ curl or wget is required"
  exit 1
fi

chmod +x "$INSTALL_DIR/up.sh"
ln -sf "$INSTALL_DIR/up.sh" "$INSTALL_DIR/up"

echo "✅ Installed: $INSTALL_DIR/up"

# --- interactive config ---
printf "Enter local path for your CDN repo: " > /dev/tty
IFS= read -r REPO_DIR < /dev/tty

[ -z "$REPO_DIR" ] && { echo "❌ Repo directory cannot be empty"; exit 1; }

case "$REPO_DIR" in
  "~"*) REPO_DIR="$HOME${REPO_DIR#\~}" ;;
esac

printf "Enter GitHub repo URL (HTTPS or SSH): " > /dev/tty
IFS= read -r REPO_URL < /dev/tty

[ -z "$REPO_URL" ] && { echo "❌ Repo URL cannot be empty"; exit 1; }

if [ ! -d "$REPO_DIR/.git" ]; then
  echo ""
  printf "Repo not found locally. Clone now? [y/N]: " > /dev/tty
  IFS= read -r CLONE < /dev/tty

  if [ "$CLONE" = "y" ] || [ "$CLONE" = "Y" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
  else
    echo "❌ Cannot continue without a local repo"
    exit 1
  fi
fi

[ -d "$REPO_DIR/.git" ] || { echo "❌ Not a git repo: $REPO_DIR"; exit 1; }

cat > "$CONFIG_FILE" <<EOF
REPO_DIR="$REPO_DIR"
REPO_URL="$REPO_URL"
EOF

echo "✅ Configuration written to $CONFIG_FILE"

# --- PATH ---
if command -v fish >/dev/null 2>&1 && [ -n "$FISH_VERSION" ]; then
  fish -c 'fish_add_path -U ~/.local/bin'
elif [ -n "$BASH_VERSION" ]; then
  grep -q 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null || \
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
  grep -q 'HOME/.local/bin' "$HOME/.zshrc" 2>/dev/null || \
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
fi

echo ""
echo "🎉 Installation complete"
echo "Restart your shell and run:"
echo "  up --help"
