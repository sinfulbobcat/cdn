# up

**`up`** is a minimal CLI tool that turns a GitHub repository into a **personal CDN powered by jsDelivr**.

Upload files from anywhere on your system, preserve directory structure, and instantly get globally cached CDN URLs — all from the terminal.

---

## Features

* Upload files to a GitHub-backed CDN
* Preserve folder structure automatically
* Generate jsDelivr URLs instantly
* Copy CDN URLs to clipboard
* List all CDN files with URLs
* Remove files safely
* Git tag support for immutable URLs
* Self-updating CLI
* Interactive installer
* Works with **bash**, **zsh**, and **fish**

---

## Installation

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/sinfulbobcat/cdn/refs/heads/main/tools/install-up.sh | sh
```

or

```bash
wget -qO- https://raw.githubusercontent.com/sinfulbobcat/cdn/refs/heads/main/tools/install-up.sh | sh
```

The installer will:

1. Install `up` into `~/.local/bin`
2. Ask for your local CDN repository path
3. Ask for your GitHub repository URL
4. Clone the repo if it doesn’t exist
5. Create a config file at `~/.config/up/config`
6. Ensure `~/.local/bin` is in your `PATH`

Restart your shell after installation.

---

## Configuration

Configuration is stored in:

```
~/.config/up/config
```

Example:

```ini
REPO_DIR="/home/user/my-cdn"
REPO_URL="https://github.com/username/cdn"
```

You normally don’t need to edit this manually — the installer handles it.

---

## Usage

### Upload a file

```bash
up image.png
```

### Upload while preserving folders

```bash
up assets/js/app.js
```

### Upload with a git tag (immutable CDN URL)

```bash
up -t v1.0.0 styles/main.css
```

Tagged URLs never change:

```
https://cdn.jsdelivr.net/gh/user/repo@v1.0.0/styles/main.css
```

---

### List CDN contents with URLs

```bash
up -l
```

Example output:

```
assets/js/app.js        | https://cdn.jsdelivr.net/gh/user/repo/assets/js/app.js
assets/css/main.css    | https://cdn.jsdelivr.net/gh/user/repo/assets/css/main.css
images/logo.png        | https://cdn.jsdelivr.net/gh/user/repo/images/logo.png
```

---

### Copy a CDN URL

```bash
up -c assets/js/app.js
```

Prints the URL and copies it to the clipboard.

---

### Remove a file from the CDN

```bash
up -r old-image.png
```

You’ll be asked to confirm before deletion.

> Note: Tagged versions remain accessible even after removal.

---

### Update `up`

```bash
up -u
```

Fetches and replaces the current binary with the latest version.

---

### Show version

```bash
up --version
```

---

## Requirements

* `git`
* `curl` or `wget`
* Clipboard support (optional):

  * Wayland: `wl-copy`
  * X11: `xclip`

---

## Uninstall

```bash
rm -f ~/.local/bin/up ~/.local/bin/up.sh
rm -rf ~/.config/up
```

---

## Why jsDelivr?

jsDelivr provides:

* Free global CDN
* GitHub integration
* Automatic caching
* Immutable URLs via git tags
* No account or API keys required

`up` automates the workflow around it.

---

## License

MIT License