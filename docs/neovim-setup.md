# Neovim Setup Guide

**Installation Date**: 2025-11-13
**Version**: LazyVim Distribution
**Package Manager**: lazy.nvim
**Location**: `~/.config/nvim/`

## What Was Installed

### Core Components
- **LazyVim**: Modern Neovim configuration framework
- **lazy.nvim**: Plugin manager with lazy-loading
- **Gruvbox Dark**: Color scheme (matches Kitty terminal theme)
- **snacks.nvim**: Terminal and UI utilities

### Key Plugins
- **LSP**: nvim-lspconfig, mason.nvim, mason-lspconfig
- **Completion**: blink.cmp, minuet-ai.nvim (Claude AI completions)
- **Treesitter**: Syntax highlighting and code understanding
- **Git**: gitsigns.nvim
- **UI**: bufferline, lualine, which-key, noice.nvim
- **Editing**: mini.pairs, mini.ai, flash.nvim
- **Utilities**: trouble.nvim, todo-comments.nvim, persistence.nvim

## Configuration Structure

```
~/.config/nvim/
├── init.lua                    # Entry point (bootstraps LazyVim)
├── lua/
│   ├── config/
│   │   ├── lazy.lua           # Plugin manager setup
│   │   ├── options.lua        # Nvim options
│   │   ├── keymaps.lua        # Custom keymaps
│   │   └── autocmds.lua       # Autocommands
│   └── plugins/
│       ├── colorscheme.lua    # Gruvbox configuration
│       ├── snacks.lua         # Terminal configuration
│       └── example.lua        # Template for new plugins
├── lazy-lock.json             # Plugin version lock file
└── lazyvim.json               # LazyVim configuration
```

## Terminal Configuration

### Features
- **Floating Window**: Centered overlay terminal
- **Size**: 70% of screen width and height
- **Border**: Rounded corners
- **Persistence**: Terminal persists when toggled off
- **Start Mode**: Normal mode (not insert)

### Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `CTRL+/` | Normal/Terminal | Toggle terminal window |
| `ESC` | Terminal | Exit to normal mode |
| `i` or `a` | Normal (in terminal) | Enter insert mode to type |
| `CTRL+h/j/k/l` | Terminal | Navigate between windows |

### Usage
1. Press `CTRL+/` to open floating terminal (70% size)
2. Terminal opens in normal mode
3. Press `i` to start typing commands
4. Press `ESC` to return to normal mode for navigation
5. Press `CTRL+/` again to hide terminal (keeps running)

## Essential Keyboard Shortcuts

### General
| Key | Action |
|-----|--------|
| `Space` | Leader key (most commands start here) |
| `Space` `f` `f` | Find files |
| `Space` `/` | Search in files |
| `Space` `e` | File explorer |
| `Space` `q` `q` | Quit |

### Window Management
| Key | Action |
|-----|--------|
| `CTRL+h/j/k/l` | Navigate between splits |
| `CTRL+w` `s` | Horizontal split |
| `CTRL+w` `v` | Vertical split |
| `CTRL+w` `q` | Close window |

### LSP Features
| Key | Action |
|-----|--------|
| `g` `d` | Go to definition |
| `g` `r` | Go to references |
| `K` | Hover documentation |
| `Space` `c` `a` | Code actions |
| `Space` `c` `r` | Rename symbol |

## Configuration File Locations

- **Main Config**: `~/.config/nvim/init.lua`
- **Plugin Specs**: `~/.config/nvim/lua/plugins/*.lua`
- **Custom Keymaps**: `~/.config/nvim/lua/config/keymaps.lua`
- **Options**: `~/.config/nvim/lua/config/options.lua`
- **Terminal Config**: `~/.config/nvim/lua/plugins/snacks.lua`
- **AI Completion Config**: `~/.config/nvim/lua/plugins/minuet.lua`

## AI-Powered Code Completion

### Minuet-AI with Claude
**Installed**: 2025-11-14
**Provider**: Anthropic Claude (Claude Sonnet 4.5)
**Integration**: blink.cmp completion source

### Features
- Claude-powered code completions as you type
- Integrated with blink.cmp completion menu
- Uses Claude Code OAuth token (no separate API key needed)
- Automatically syncs with Claude Code credentials
- High priority in completion suggestions (score_offset: 50)

### Configuration
- **Config File**: `~/.config/nvim/lua/plugins/minuet.lua:1`
- **Model**: claude-sonnet-4-5-20250929
- **Context Window**: 12,288 tokens (~12K)
- **Max Tokens**: 512 per completion
- **Request Timeout**: 3 seconds
- **Throttle**: 1000ms between requests
- **Debounce**: 400ms before triggering

### Authentication
Minuet-AI reads Claude Code's OAuth token from:
```
~/.claude/.credentials.json
```

No separate API key configuration needed. The plugin automatically uses your Claude Code authentication.

### How It Works
1. As you type, minuet monitors for completion opportunities
2. After 400ms of inactivity (debounce), sends context to Claude
3. Claude generates intelligent code suggestions
4. Completions appear in blink.cmp menu with high priority
5. Select suggestions using standard completion keybindings

### Troubleshooting
If completions don't work:
1. Ensure Claude Code is authenticated: `claude auth`
2. Check credentials file exists: `ls ~/.claude/.credentials.json`
3. Verify plugin loaded: `:Lazy` (should show minuet-ai.nvim)
4. Check for errors: `:messages`

## Recent Configuration Changes

### 2025-11-14: Neo-tree Explorer Behavior
- Created `lua/plugins/neo-tree.lua` to override default file explorer behavior
- Changed Explorer to use current working directory (cwd) instead of git repository root
- Fixed duplicate explorer issue: `<leader>e` now toggles single left sidebar explorer
- Disabled floating explorer keybindings to prevent conflicts
- Enabled `bind_to_cwd` and `follow_current_file` for better directory navigation
- Added keybindings: `.` to set root, `<bs>` to navigate up, `H` to toggle hidden files

### 2025-11-14: AI Code Completion
- Installed minuet-ai.nvim for Claude-powered code completions
- Configured to use Claude Sonnet 4.5 model
- Integrated with blink.cmp as completion source
- Configured to read authentication from Claude Code credentials (~/.claude/.credentials.json)
- Set completion priority with score_offset: 50 for prominent AI suggestions
- No separate API key required - reuses Claude Code OAuth token

### 2025-11-13: Terminal Setup
- Created `lua/plugins/snacks.lua` to customize terminal behavior
- Configured terminal as 70% floating window with rounded borders
- Terminal opens in normal mode by default
- Integrated with existing CTRL+/ keybinding from snacks.nvim

## Adding New Plugins

Create a new file in `~/.config/nvim/lua/plugins/`:

```lua
return {
  "author/plugin-name",
  opts = {
    -- plugin configuration
  },
}
```

LazyVim will automatically detect and load it on next restart.

## XDG Compliance

Neovim follows XDG Base Directory specification:
- **Config**: `~/.config/nvim/` (XDG_CONFIG_HOME)
- **Data**: `~/.local/share/nvim/` (plugins, state)
- **Cache**: `~/.cache/nvim/` (temporary files)

## Useful Commands

```bash
# Open Neovim
nvim

# Open with specific file
nvim <filename>

# Check LazyVim health
:checkhealth

# Update plugins
:Lazy update

# View plugin status
:Lazy
```

## Resources

- **LazyVim Docs**: https://www.lazyvim.org/
- **Neovim Docs**: https://neovim.io/doc/
- **Plugin Manager**: https://github.com/folke/lazy.nvim

---

**Last Updated**: 2025-11-14
