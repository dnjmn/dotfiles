# Dotfiles Repository Reorganization

**Date:** 2026-02-02
**Status:** Approved

## Goals

1. **Discoverability** - Easy to find configs and scripts at a glance
2. **Scalability** - Adding new tools follows clear, consistent pattern
3. **Consistency** - Every tool follows same structure
4. **Separation of concerns** - Configs separate from install logic

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Overall approach | Config vs Install split | Clean separation, easy symlink management |
| Install-only tools | No config entry | Minimal - only create what's needed |
| Claude structure | Nested in config/ | Self-contained including plugins |
| Documentation | Per-tool README | Docs live close to what they describe |
| Orchestration | None | Run scripts directly, no magic |
| Brewfile | Removed | Each script declares own dependencies |
| Shared utilities | lib/ at root | Scripts source from central location |

## Final Structure

```
dotfiles/
├── config/
│   ├── zsh/
│   │   ├── .zshrc
│   │   ├── .zshenv
│   │   ├── .p10k.zsh
│   │   ├── aliases/
│   │   ├── functions/
│   │   ├── config/
│   │   └── README.md
│   ├── tmux/
│   │   ├── tmux.conf
│   │   ├── statusline.conf
│   │   └── README.md
│   ├── kitty/
│   │   ├── kitty.conf
│   │   ├── session.conf
│   │   └── README.md
│   ├── neovim/
│   │   ├── init.lua
│   │   ├── lua/
│   │   └── README.md
│   └── claude/
│       ├── CLAUDE.md
│       ├── settings.json
│       ├── plugins/
│       └── README.md
├── install/
│   ├── zsh.sh
│   ├── tmux.sh
│   ├── kitty.sh
│   ├── neovim.sh
│   ├── claude.sh
│   ├── docker.sh
│   ├── golang.sh
│   ├── ollama.sh
│   ├── obsidian.sh
│   ├── notion.sh
│   └── lsd.sh
├── lib/
│   └── platform.sh
├── README.md
└── CLAUDE.md
```

## Install Script Pattern

Each install script follows this template:

```bash
#!/bin/bash
# install/<tool>.sh - <Brief description>

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="<tool>"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly DEPS=(<brew-packages>)

install_deps() {
    for dep in "${DEPS[@]}"; do
        pkg_install "$dep"
    done
}

link_configs() {
    local target="$XDG_CONFIG_HOME/$NAME"
    symlink_with_backup "$CONFIG_DIR" "$target"
}

post_install() {
    echo "<Post-install instructions>"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    link_configs
    post_install
    echo "==> Done"
}

main "$@"
```

**Conventions:**
- Readonly vars prevent accidental mutation
- Three-phase structure: deps → links → post
- Symlinks entire config dir when possible
- Minimal output, actionable post-install message

## lib/platform.sh Enhancements

Add to existing platform.sh:

```bash
# XDG defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Output helpers
info()  { printf '\033[0;32m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m==> %s\033[0m\n' "$*"; }
error() { printf '\033[0;31m==> %s\033[0m\n' "$*" >&2; }

# Check if command exists
has() { command -v "$1" &>/dev/null; }

# Ensure homebrew is available
ensure_brew() {
    has brew && return
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}
```

## Config README Template

Each config dir gets a README.md:

```markdown
# <Tool>

<One-line description>

## Structure

- `file.conf` - Description
- `subdir/` - Description

## Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+X` | Does Y |

## Customization

<How to personalize>
```

## Migration Mapping

| Current Location | New Location |
|------------------|--------------|
| `zsh/*` | `config/zsh/` |
| `zsh/install.sh` | `install/zsh.sh` |
| `tmux/tmux.conf, statusline.conf` | `config/tmux/` |
| `tmux/install.sh` | `install/tmux.sh` |
| `kitty/*` | `config/kitty/` |
| `kitty/install.sh` | `install/kitty.sh` |
| `neovim/*` | `config/neovim/` |
| `neovim/install.sh` | `install/neovim.sh` |
| `claude/config/*` | `config/claude/` |
| `claude/install.sh` | `install/claude.sh` |
| `docker/install.sh` | `install/docker.sh` |
| `golang/install.sh` | `install/golang.sh` |
| `ollama/install.sh` | `install/ollama.sh` |
| `obsidian/install.sh` | `install/obsidian.sh` |
| `notion/install.sh` | `install/notion.sh` |
| `lsd/install.sh` | `install/lsd.sh` |
| `homebrew/` | **Removed** (deps in each script) |
| `docs/*` | **Merged** into `config/*/README.md` |
| `lib/platform.sh` | `lib/platform.sh` (unchanged) |
| `install.sh` | **Removed** (run scripts directly) |
| `tools/` | **Removed** (empty) |

## Usage After Migration

```bash
# Install a single tool
./install/zsh.sh

# Install multiple tools
./install/zsh.sh && ./install/tmux.sh && ./install/kitty.sh

# Install everything
for script in install/*.sh; do "$script"; done
```

## Implementation Order

1. Create `config/` and `install/` directories
2. Move configs (zsh, tmux, kitty, neovim, claude)
3. Extract install scripts to `install/`
4. Merge docs into per-tool READMEs
5. Update lib/platform.sh with enhancements
6. Remove old directories and files
7. Update root README.md and CLAUDE.md
