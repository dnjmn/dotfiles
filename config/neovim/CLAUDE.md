# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Neovim configuration based on LazyVim starter template. Uses lazy.nvim for plugin management.

## Commands

```bash
# Install/update
./install.sh                    # Full setup (installs nvim, deps, plugins)
nvim --headless "+Lazy! sync" +qa  # Headless plugin sync

# Format Lua files
stylua lua/

# Health check
nvim -c ':checkhealth'
```

## Architecture

```
neovim/
├── init.lua                 # Entry point (loads config.lazy)
├── lua/
│   ├── config/
│   │   ├── lazy.lua         # lazy.nvim bootstrap + plugin spec
│   │   ├── options.lua      # Vim options (extends LazyVim defaults)
│   │   ├── keymaps.lua      # Custom keymaps (extends LazyVim defaults)
│   │   └── autocmds.lua     # Autocommands
│   └── plugins/             # Plugin specs (each file returns a table)
│       ├── colorscheme.lua  # Gruvbox theme
│       ├── minuet.lua       # AI completion (Claude via OAuth)
│       ├── neo-tree.lua     # File explorer (cwd-based)
│       └── snacks.lua       # Terminal float config
├── lazy-lock.json           # Plugin version lockfile
└── stylua.toml              # Lua formatter config (2-space indent)
```

### Plugin Configuration Pattern

Each file in `lua/plugins/` returns a table (or list of tables) following lazy.nvim spec:

```lua
return {
  "author/plugin-name",
  opts = { ... },           -- Passed to setup()
  config = function() ... end,  -- Custom setup
  keys = { ... },           -- Keymaps
}
```

To override LazyVim defaults, use the same plugin name with new opts.

### Key Customizations

- **Theme**: Gruvbox Dark (not TokyoNight)
- **Neo-tree**: Uses `cwd` instead of git root (`<leader>e`)
- **Terminal**: Floating 85% window via snacks.nvim (`Ctrl+/`)
- **AI Completion**: minuet-ai reads token from `~/.claude/.credentials.json`

### LazyVim Keymaps

Leader key: `Space`
- `<leader>ff` - Find files
- `<leader>/` - Live grep
- `<leader>e` - File explorer (cwd)
- `Ctrl+/` - Terminal

## Data Paths (XDG)

- Config: `~/.config/nvim/` (symlinked from this dir)
- Data: `~/.local/share/nvim/`
- Plugins: `~/.local/share/nvim/lazy/`
- State: `~/.local/state/nvim/`
- Cache: `~/.cache/nvim/`
