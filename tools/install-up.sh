#!/bin/sh
set -e

# ---------------- Constants ----------------
UP_URL="https://cdn.jsdelivr.net/gh/sinfulbobcat/cdn@main/tools/up.sh"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/up"
CONFIG_FILE="$CONFIG_DIR/config"

echo "📦 up — interactive installer"
echo "--------------------------------"

# ---------------- Install binary ----------------
mkdir -p "$INSTALL_DIR"

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

echo "✅ Installed binary: $INSTALL_DIR/up"

# ---------------- Interactive config ----------------
mkdir -p "$CONFIG_DIR"

echo ""
echo "🛠️  Configuration"
echo "-----------------"

printf "Enter local path for your CDN repo: "
read REPO_DIR < /dev/tty

if [ -z "$REPO_DIR" ]; then
  echo "❌ Repo directory cannot be empty"
  exit 1
fi

# Expand ~
REPO_DIR=$(eval echo "$REPO_DIR")

printf "Enter GitHub repo URL (HTTPS or SSH): "
read REPO_URL < /dev/tty

if [ -z "$REPO_URL" ]; then
  echo "❌ Repo URL cannot be empty"
  exit 1
fi

# Clone if repo does not exist
if [ ! -d "$REPO_DIR/.git" ]; then
  echo ""
  echo "📁 Repo not found locally."

  printf "Do you want to clone it now? [y/N]: "
  read CLONE < /dev/tty

  if [ "$CLONE" = "y" ] || [ "$CLONE" = "Y" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
  else
    echo "❌ Cannot continue without a local repo"
    exit 1
  fi
fi

# Validate git repo
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "❌ $REPO_DIR is not a git repository"
  exit 1
fi

# Write config
cat > "$CONFIG_FILE" <<EOF
REPO_DIR=$REPO_DIR
REPO_URL=$REPO_URL
EOF

echo "✅ Configuration written to:"
echo "   $CONFIG_FILE"

# ---------------- PATH handling ----------------
ensure_path() {
  FILE="$1"
  grep -q 'HOME/.local/bin' "$FILE" 2>/dev/null || \
    printf '\n# Added by up installer\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$FILE"
}

if command -v fish >/dev/null 2>&1 && [ -n "$FISH_VERSION" ]; then
  fish -c 'fish_add_path -U ~/.local/bin'
elif [ -n "$BASH_VERSION" ]; then
  ensure_path "$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
  ensure_path "$HOME/.zshrc"
else
  ensure_path "$HOME/.profile"
fi

echo ""
echo "🎉 Installation complete"
echo ""
echo "➡️  Restart your shell or run:"
echo "    exec \$SHELL"
echo ""
echo "Try:"
echo "    up --help"
