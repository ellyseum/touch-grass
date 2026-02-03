#!/bin/bash
# touch-grass installer
# curl -fsSL https://raw.githubusercontent.com/ellyseum/touch-grass/main/install.sh | bash

set -e

INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/touch-grass"
REPO_URL="https://raw.githubusercontent.com/ellyseum/touch-grass/main"

echo "🌱 Installing touch-grass..."
echo ""

# Check dependencies
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh) is required but not installed."
  echo "   Install it: https://cli.github.com/"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed."
  echo "   Install it: sudo apt install jq (or brew install jq)"
  exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
  echo "❌ GitHub CLI is not authenticated."
  echo "   Run: gh auth login"
  exit 1
fi

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Download the script
echo "📥 Downloading touch-grass..."
curl -fsSL "$REPO_URL/touch-grass" -o "$INSTALL_DIR/touch-grass"
chmod +x "$INSTALL_DIR/touch-grass"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
  zsh)  SHELL_RC="$HOME/.zshrc" ;;
  bash) SHELL_RC="$HOME/.bashrc" ;;
  *)    SHELL_RC="" ;;
esac

# Git wrapper function (with markers for uninstall)
GIT_WRAPPER='
# >>> touch-grass >>>
git() {
  local cmd="$1"
  local resolved=$(command git config --get "alias.$cmd" 2>/dev/null | awk '\''{print $1}'\'')
  [[ -n "$resolved" ]] && cmd="$resolved"
  local origin=$(command git remote get-url origin 2>/dev/null)
  if [[ "$origin" == *github.com* ]]; then
    if [[ "$cmd" == "commit" || "$cmd" == "push" ]]; then
      ~/.local/bin/touch-grass "$cmd" "$@" || return 1
    fi
  fi
  command git "$@"
}
# <<< touch-grass <<<'

# Ask about TARGET_MAX
echo ""
echo "📊 Fetching your contribution stats..."
HISTORICAL_MAX=$(gh api graphql -f query='query { viewer { contributionsCollection { contributionCalendar { weeks { contributionDays { contributionCount } } } } } }' --jq '[.data.viewer.contributionsCollection.contributionCalendar.weeks[].contributionDays[].contributionCount] | max' 2>/dev/null || echo "50")
echo "   Your historical max: $HISTORICAL_MAX commits/day"
echo ""
if [[ -t 0 ]]; then
  read -p "🎯 Set your target max (default: $HISTORICAL_MAX): " TARGET_MAX
else
  { read -p "🎯 Set your target max (default: $HISTORICAL_MAX): " TARGET_MAX < /dev/tty; } 2>/dev/null || true
fi
TARGET_MAX=${TARGET_MAX:-$HISTORICAL_MAX}

# Save config
{
  echo "# touch-grass config"
  echo "TARGET_MAX=$TARGET_MAX"
  echo "# SOFT_BUFFER=10  # Warn this many commits before target"
} > "$CONFIG_DIR/config"

# Save installed version hashes for update checking
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/touch-grass"
mkdir -p "$CACHE_DIR"
SCRIPT_HASH=$(gh api repos/ellyseum/touch-grass/contents/touch-grass --jq '.sha' 2>/dev/null || echo "unknown")
INSTALLER_HASH=$(gh api repos/ellyseum/touch-grass/contents/install.sh --jq '.sha' 2>/dev/null || echo "unknown")
jq -n --arg s "$SCRIPT_HASH" --arg i "$INSTALLER_HASH" '{script_hash: $s, installer_hash: $i}' > "$CACHE_DIR/cache.json"

# Add to shell config
if [[ -n "$SHELL_RC" ]]; then
  # Check if ~/.local/bin is in PATH
  if ! grep -q 'local/bin' "$SHELL_RC" 2>/dev/null && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added ~/.local/bin to PATH"
  fi

  if grep -q "touch-grass" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  touch-grass already in $SHELL_RC, skipping..."
  else
    echo "" >> "$SHELL_RC"
    echo "$GIT_WRAPPER" >> "$SHELL_RC"
    echo "✅ Added git wrapper to $SHELL_RC"
  fi
else
  echo ""
  echo "⚠️  Could not detect shell config. Add this to your shell RC file:"
  echo "$GIT_WRAPPER"
fi

echo ""
echo "✅ touch-grass installed!"
echo ""
echo "   Target: $TARGET_MAX commits/day"
echo "   Warning at: $((TARGET_MAX - 10)) commits"
echo "   Config: $CONFIG_DIR/config"
echo ""
echo "   Restart your shell or run: source $SHELL_RC"
echo ""
echo "🌿 Now go touch some real grass!"
