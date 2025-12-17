# CLAUDE.md

Dotfiles repo for **one-command setup** on new machines. Supports **macOS** and **Linux**.

## Core Philosophy: Script Everything

**Goal**: `./install.sh --all` should fully configure a new machine with zero manual intervention.

If you can't script it, document the manual step in `docs/` with a `TODO: automate` note—but always try to automate first.

### Platform Support

| Platform | Package Manager | Status |
|----------|----------------|--------|
| macOS (Apple Silicon) | Homebrew | ✅ Supported |
| macOS (Intel) | Homebrew | ✅ Supported |
| Linux (Ubuntu/Debian) | Linuxbrew | ✅ Supported |

All software is installed at **user level** - no sudo/root required.

### What "Script Everything" Means

| Scenario | Approach |
|----------|----------|
| Installing a package | `pkg_install` (Homebrew/Linuxbrew abstraction) |
| Config files | Store in repo, symlink via script |
| Interactive installers | Use `--unattended`, `-y`, or heredoc for input |
| GUI-only settings | Export via `dconf dump`, `gsettings`, or config files |
| Secrets/API keys | Placeholder in repo + prompt user or source `~/.config/<tool>/secrets` |
| Plugin managers | Auto-install plugins in script (e.g., TPM's `run-shell ~/.tmux/plugins/tpm/bin/install_plugins`) |

### Script Requirements

Every `<tool>/install.sh` must be:
- **Idempotent** - Safe to run repeatedly (check before install)
- **Non-interactive** - No prompts; use defaults or flags
- **Self-contained** - Install dependencies within the script
- **Exit on error** - Use `set -e`

## Quick Reference

| Tool | Config | Install | Status |
|------|--------|---------|--------|
| Homebrew | `lib/platform.sh` | `homebrew/install.sh` | ✅ scripted |
| Kitty | `kitty/` → `~/.config/kitty/` | `kitty/install.sh` | ✅ scripted |
| Zsh | `zsh/` (ZDOTDIR) | `zsh/install.sh` | ✅ scripted |
| Tmux | `tmux/` → `~/.config/tmux/` | `tmux/install.sh` | ✅ scripted |
| Obsidian | `~/.config/obsidian/` | `obsidian/install.sh` | ✅ scripted |
| Neovim | `neovim/` → `~/.config/nvim/` | `neovim/install.sh` | ✅ scripted |
| LSD | `~/.config/lsd/` | `lsd/install.sh` | ✅ scripted |
| Notion | `~/.local/share/notion/` | `notion/install.sh` | ✅ scripted |
| Claude | `claude/` → `~/.claude/` | `claude/install.sh` | ✅ scripted |

**Full setup**: `./install.sh --all`

## Rules for Claude

### Always
1. **Script first** - Automate before documenting manual steps
2. **Symlink configs** - Keep source of truth in repo
3. **XDG paths** - `~/.config`, `~/.local/share`, `~/.cache`, `~/.local/state`
4. **Update master** - Register new tools in root `install.sh`
5. **Document** - Create `docs/<tool>-setup.md`

### Never
- Leave manual steps without `TODO: automate`
- Hardcode absolute paths (use `$HOME`, `$XDG_CONFIG_HOME`)
- Put dotfiles in `~/` root
- Require user interaction during install

## Structure

```
<tool>/
├── install.sh          # Fully automated installer
├── *.conf              # Configs (symlinked to ~/.config/<tool>/)
└── templates/          # Optional templates

docs/
└── <tool>-setup.md     # Reference: shortcuts, troubleshooting, changelog
```

## Install Script Template

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper (provides print_*, pkg_install, is_macos, etc.)
source "$REPO_DIR/lib/platform.sh"

# Print platform info
print_platform_info

# Ensure Homebrew is available
ensure_homebrew
init_brew || true

# Idempotency check
if command -v <tool> &>/dev/null; then
    print_ok "<tool> already installed ($(tool --version))"
    # Still continue to ensure config is linked
fi

# 1. Install binary/package
print_info "Installing <tool>..."
if is_macos; then
    pkg_install <tool>  # or pkg_install_cask for GUI apps
else
    pkg_install <tool>  # Linuxbrew
fi

# 2. Create XDG directories
mkdir -p "$XDG_CONFIG_HOME/<tool>"
mkdir -p "$XDG_DATA_HOME/<tool>"

# 3. Symlink config from repo
print_info "Linking configuration..."
ln -sf "$SCRIPT_DIR/<tool>.conf" "$XDG_CONFIG_HOME/<tool>/<tool>.conf"

# 4. Install plugins (if applicable)
# print_info "Installing plugins..."

print_ok "<tool> setup complete!"
```

## Doc Template

```markdown
# <Tool> Setup

**Installed**: YYYY-MM-DD | **Version**: x.x.x

## Quick Install
\`\`\`bash
./tool/install.sh
\`\`\`

## Config Locations
| Type | Path |
|------|------|
| Config | `~/.config/<tool>/` |
| Data | `~/.local/share/<tool>/` |

## Key Shortcuts
| Key | Action |
|-----|--------|

## Changelog
| Date | Change |
|------|--------|
```

## Current Stack
- **Terminal**: Kitty + JetBrainsMono Nerd Font
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k
- **Editor**: Neovim (LazyVim) + minuet-ai
- **Multiplexer**: Tmux + TPM
- **Notes**: Obsidian
- **AI**: Claude Code (custom agents + global instructions)
- **Theme**: Gruvbox Dark (all tools)
