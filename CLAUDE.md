# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles for macOS and Linux. All software installs at user-level (no sudo). Follows XDG Base Directory specification. Primary platform is macOS (Apple Silicon).

## Commands

```bash
# Install a single tool
./install/<tool>.sh        # e.g., ./install/zsh.sh

# Install everything
for script in install/*.sh; do "$script"; done
```

## Architecture

Three layers: `config/` (dotfiles), `install/` (setup scripts), `lib/` (shared utilities).

### Symlink Mapping (what's live)

| Repo Source | Symlinked To |
|-------------|-------------|
| `config/claude/` (entire dir) | `~/.claude` |
| `config/zsh/*` | `~/.config/zsh/*` |
| `config/tmux/*.conf` | `~/.config/tmux/*.conf` |
| `config/kitty/*.conf` | `~/.config/kitty/*.conf` |
| `config/neovim/*` | `~/.config/nvim/*` |

**Changes to these files take effect immediately** (or after reload — see below).

### Sub-directory CLAUDE.md Files

`config/zsh/CLAUDE.md` and `config/neovim/CLAUDE.md` contain detailed architecture for those subsystems (file loading order, plugin patterns, module conventions). Read those when working in their directories.

### lib/platform.sh

Source in any install script: `source "$REPO_ROOT/lib/platform.sh"`

Key functions: `has()`, `detect_os()`, `is_macos()`, `is_linux()`, `pkg_install()`, `pkg_install_cask()`, `symlink_with_backup()`, `get_github_release_url()`, `download_verified()`, `ensure_homebrew()`

### Install Script Convention

All scripts in `install/` follow the same pattern: set `REPO_ROOT`, source `platform.sh`, define `install_deps()` → `link_configs()` → `post_install()`, run via `main()`. Read any existing script as a template before creating new ones.

### Kitty Theme System

Themes live in `config/kitty/themes/`. Active theme is `config/kitty/current-theme.conf` (a symlink, gitignored so theme choice is local). Toggle with the `ktheme` shell command.

## When Editing

- `lib/platform.sh` changes affect all install scripts
- `config/claude/` is live — it **is** `~/.claude` via symlink
- Zsh reload: `exec zsh`
- Tmux reload: `prefix + r` (prefix = `Ctrl+a`)
- Kitty reload: `Cmd+Shift+R`
- Neovim plugins: `nvim --headless "+Lazy! sync" +qa`
- Test on macOS first; Linux paths differ for casks and desktop entries
