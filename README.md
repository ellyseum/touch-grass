# 🌱 touch-grass

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Shell: bash | zsh](https://img.shields.io/badge/shell-bash%20|%20zsh-green.svg)]()
[![Requires: gh + jq](https://img.shields.io/badge/requires-gh%20+%20jq-blue.svg)](https://cli.github.com/)
[![GitHub last commit](https://img.shields.io/github/last-commit/ellyseum/touch-grass)](https://github.com/ellyseum/touch-grass/commits/main)

**Stop touching grass (green squares). Go touch real grass.**

A git commit limiter that protects your GitHub contribution graph from yourself.

## The Problem

GitHub's contribution graph uses *relative* coloring. Your darkest green is based on your personal max.

So if you:
- Usually do 20-30 commits/day → dark green
- One manic day hit 150 commits → now 30 commits is light green forever

Your past work looks worse because you had one productive day. That's backwards.

## The Solution

`touch-grass` warns you when you're approaching your commit limit for the day:

```
🌿 Heads up: 38 commits today (GitHub: 35 + Local: 2 + 1)
   Approaching your target of 47. The grass isn't going anywhere!
```

And blocks you (with override) when you hit it:

```
🌱 Whoa there! You've touched 47 grass squares today!
   GitHub: 44 | Local unpushed: 2 | This commit: +1
   Your target max is 47 (historical max: 50)

   Maybe go touch some real grass? 🌿

Continue anyway? [y/N]
```

## Features

- 🎯 **Dynamic limits** - Fetches your actual historical max from GitHub
- 📊 **Target override** - Set a target below your max to protect your graph
- 🌿 **Soft warnings** - Heads up when approaching limit
- 🚫 **Hard block** - Confirmation required at limit
- 🌳 **Branch aware** - Different warnings for feature branches
- 📅 **Date aware** - Only counts today's commits, not yesterday's unpushed work
- ⚡ **Cached** - Historical max cached daily, minimal API calls

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ellyseum/touch-grass/main/install.sh | bash
```

Then restart your shell or `source ~/.zshrc` (or `.bashrc`).

### Requirements

**Supported shells:** bash, zsh (fish/csh not supported)

**Dependencies:**

| Dependency | macOS | Ubuntu/Debian | Arch |
|------------|-------|---------------|------|
| [GitHub CLI](https://cli.github.com/) | `brew install gh` | `sudo apt install gh` | `sudo pacman -S github-cli` |
| jq | `brew install jq` | `sudo apt install jq` | `sudo pacman -S jq` |

After installing gh, authenticate with: `gh auth login`

## Configuration

Config file: `~/.config/touch-grass/config`

```bash
# Your target max commits per day
TARGET_MAX=47

# How many commits before target to start warning (default: 10)
SOFT_BUFFER=10
```

Or set via environment:

```bash
export TARGET_MAX=47
export SOFT_BUFFER=10
```

## How It Works

The installer adds a git wrapper function to your shell that intercepts `commit` and `push` commands for GitHub repos:

```bash
git() {
  # Resolves aliases (git ci → git commit)
  # Only runs for GitHub repos (checks origin URL)
  if [[ "$cmd" == "commit" || "$cmd" == "push" ]]; then
    ~/.local/bin/touch-grass "$cmd" "$@" || return 1
  fi
  command git "$@"
}
```

**On commit:** Checks your current count and warns/blocks before you commit.

**On push:** Counts how many commits you're about to push and warns if it would exceed your target.

### Edge Cases Handled

- **Non-GitHub repos**: Skipped entirely (Bitbucket, GitLab, local-only)
- **New repos without remote**: Skipped until you add a GitHub origin
- **Bulk pushing old commits**: Warns before push if total would exceed target
- **Feature branches**: Warns about merge impact, suggests squashing
- **Midnight boundary**: Only today's author dates count
- **Git aliases**: Resolves aliases to catch `git ci`, `git p`, etc.
- **Rebasing**: Only amended commit counts (descendants keep original dates)

## Commands

```bash
touch-grass config     # View/edit configuration (TARGET_MAX, SOFT_BUFFER)
touch-grass update     # Update to latest version
touch-grass uninstall  # Remove everything cleanly
touch-grass help       # Show help
```

The script also checks for updates daily and will notify you:
```
🌱 Update available! Run: touch-grass update
```

## FAQ

**Q: Does this count private repos?**

A: Yes, it uses your total contribution count from GitHub's API.

**Q: What if I rebase and change 20 commits?**

A: GitHub uses author dates, not committer dates. Rebased commits keep their original dates, so they don't spike your count.

**Q: What about merge commits?**

A: They count as +1. But if you're a rebase purist (clean git log gang), you probably don't do merge commits anyway.

**Q: Can I bypass the block?**

A: Yes, press `y` when prompted. It's about awareness, not enforcement. You're an adult (presumably).

**Q: Why not just... commit less?**

A: you ask too many questions

## License

MIT

---

*Now go touch some real grass.* 🌿
