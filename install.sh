#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/REPLACE_USERNAME/summit-desktop-stack/main"

say() { printf "\n\033[1m%s\033[0m\n" "$*"; }

say "Summit Desktop Stack installer"

# Xcode CLT
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools…"
  echo "Complete the macOS prompt, then re-run the installer if needed."
  xcode-select --install || true
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  say "Homebrew not found. Installing…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

say "Installing packages…"
curl -fsSL "$REPO_RAW_BASE/Brewfile" -o /tmp/SummitBrewfile
brew bundle --file /tmp/SummitBrewfile

say "Downloading configs…"
TMPDIR="$(mktemp -d)"
cd "$TMPDIR"

curl -fsSL "$REPO_RAW_BASE/repo.tar.gz" -o repo.tar.gz
tar -xzf repo.tar.gz

say "Installing configs…"
mkdir -p "$HOME/.config/aerospace" "$HOME/.config/sketchybar" "$HOME/.config/borders"
cp -a "configs/aerospace/." "$HOME/.config/aerospace/"
cp -a "configs/sketchybar/." "$HOME/.config/sketchybar/"
cp -a "configs/borders/." "$HOME/.config/borders/" 2>/dev/null || true
chmod +x "$HOME/.config/sketchybar/sketchybarrc" 2>/dev/null || true

say "Installing LaunchAgents…"
mkdir -p "$HOME/Library/LaunchAgents"
cp -a "launchagents/." "$HOME/Library/LaunchAgents/"

UID_NUM="$(id -u)"

say "Loading LaunchAgents…"
launchctl bootout "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.summit.sketchybar.plist" 2>/dev/null || true
launchctl bootout "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.summit.borders.plist"   2>/dev/null || true

launchctl bootstrap "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.summit.sketchybar.plist"
launchctl bootstrap "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.summit.borders.plist"

launchctl kickstart -k "gui/$UID_NUM/com.summit.sketchybar"
launchctl kickstart -k "gui/$UID_NUM/com.summit.borders"

say "Done ✅"
echo
echo "IMPORTANT:"
echo "System Settings → Privacy & Security → Accessibility"
echo "Enable: AeroSpace, sketchybar, borders"
