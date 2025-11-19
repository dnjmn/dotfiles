# Tmux Setup

## Overview
Tmux (Terminal Multiplexer) is a powerful tool that allows you to run multiple terminal sessions within a single window. This setup includes sensible defaults, vim-style navigation, and useful plugins managed by TPM. Configuration follows XDG Base Directory specification to keep the home directory clean.

**Installation Date:** 2025-11-13
**Tmux Version:** 3.x+
**Plugin Manager:** TPM (Tmux Plugin Manager)
**Theme:** Gruvbox Dark
**XDG Compliant:** Yes

## What Was Installed

### 1. Tmux Terminal Multiplexer
- **Installation method:** APT package manager
- **Binary location:** `/usr/bin/tmux`
- **Key capability:** Multiple terminal sessions in one window

### 2. TPM (Tmux Plugin Manager)
- **Location:** `~/.local/share/tmux/plugins/tpm` (XDG_DATA_HOME)
- **Purpose:** Install and manage tmux plugins
- **GitHub:** https://github.com/tmux-plugins/tpm

### 3. Pre-configured Plugins

**Session Management:**
- **tmux-resurrect** - Save and restore tmux sessions after reboot
- **tmux-continuum** - Automatic session save/restore every 15 minutes

**Productivity:**
- **tmux-sensible** - Sensible default settings for tmux
- **tmux-yank** - Better copy/paste integration with system clipboard
- **tmux-copycat** - Enhanced search in tmux (regex, file paths, URLs)

## XDG Directory Structure

This setup follows XDG Base Directory specification:

```
~/
├── .config/
│   └── tmux/                                # XDG_CONFIG_HOME
│       └── tmux.conf                        # Main configuration (symlinked from repo)
├── .local/
│   └── share/
│       └── tmux/                            # XDG_DATA_HOME
│           └── plugins/                     # Plugin installation directory
│               ├── tpm/                     # Tmux Plugin Manager
│               ├── tmux-sensible/
│               ├── tmux-resurrect/
│               ├── tmux-continuum/
│               ├── tmux-yank/
│               └── tmux-copycat/
└── Developer/repos/dnjmn/ubuntu-setup/tmux/ # Source (version controlled)
    ├── tmux.conf                            # Configuration file
    └── install.sh                           # Installation script
```

## Key Features

### 1. Ergonomic Prefix Key
- **Changed from:** `Ctrl+b`
- **Changed to:** `Ctrl+a` (easier to reach, inspired by GNU Screen)

### 2. Intuitive Pane Splitting
- **Horizontal split:** `Prefix + |` (Ctrl+a then |)
- **Vertical split:** `Prefix + -` (Ctrl+a then -)
- New splits open in current directory

### 3. Vim-Style Navigation
- **Move between panes:** `Prefix + h/j/k/l`
- **Resize panes:** `Prefix + H/J/K/L` (shift + hjkl)
- **Cycle panes:** `Prefix + o`

### 4. Window Management
- **New window:** `Prefix + c` (opens in current directory)
- **Switch windows:** `Prefix + n/p` (next/previous) or `Prefix + 0-9`
- **Quick window jump:** `Prefix + Ctrl+h/l`

### 5. Copy Mode (Vim-style)
- **Enter copy mode:** `Prefix + Enter`
- **Start selection:** `v`
- **Copy selection:** `y`
- **Rectangle mode:** `Ctrl+v`

### 6. Mouse Support
- Click to select panes
- Drag to resize panes
- Scroll with mouse wheel
- Click to select windows

### 7. Session Persistence
- Sessions automatically saved every 15 minutes
- Restore sessions after reboot with `Prefix + Ctrl+r`
- Manual save with `Prefix + Ctrl+s`

### 8. Visual Styling
- **Theme:** Gruvbox Dark (matches Kitty terminal)
- **Status bar:** Shows session name, window info, time, date, hostname
- **Pane borders:** Active pane highlighted in green
- **256 color support:** Full color support for modern terminals

## Essential Keyboard Shortcuts

### Session Management
| Shortcut | Action |
|----------|--------|
| `tmux` | Start new session |
| `tmux new -s name` | Start named session |
| `tmux ls` | List sessions |
| `tmux attach -t name` | Attach to session |
| `Prefix + d` | Detach from session |
| `Prefix + $` | Rename session |

### Window Management
| Shortcut | Action |
|----------|--------|
| `Prefix + c` | Create new window |
| `Prefix + ,` | Rename window |
| `Prefix + &` | Close window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
| `Prefix + 0-9` | Jump to window number |
| `Prefix + w` | List windows |

### Pane Management
| Shortcut | Action |
|----------|--------|
| `Prefix + \|` | Split horizontal |
| `Prefix + -` | Split vertical |
| `Prefix + x` | Close pane |
| `Prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Prefix + H/J/K/L` | Resize panes (vim-style) |
| `Prefix + o` | Cycle through panes |
| `Prefix + q` | Show pane numbers |
| `Prefix + z` | Toggle pane zoom |
| `Prefix + !` | Break pane into window |
| `Prefix + {/}` | Swap panes |

### Copy Mode
| Shortcut | Action |
|----------|--------|
| `Prefix + Enter` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy selection & exit |
| `Ctrl+v` | Rectangle selection |
| `q` | Exit copy mode |

### System
| Shortcut | Action |
|----------|--------|
| `Prefix + r` | Reload config |
| `Prefix + I` | Install plugins |
| `Prefix + U` | Update plugins |
| `Prefix + ?` | List all keybindings |
| `Prefix + t` | Show clock |

## Configuration File Locations

### Main Configuration
- **Path:** `~/.config/tmux/tmux.conf`
- **Source:** Symlinked from `~/Developer/repos/dnjmn/ubuntu-setup/tmux/tmux.conf`
- **Edit:** Edit the file in the repo to keep changes version controlled

### Plugin Installation
- **Path:** `~/.local/share/tmux/plugins/`
- **Managed by:** TPM (Tmux Plugin Manager)

## Post-Installation Steps

### 1. Start Tmux
```bash
tmux
```

### 2. Install Plugins
Press `Prefix + I` (Ctrl+a then Shift+i) to install all plugins

### 3. Reload Configuration
Press `Prefix + r` (Ctrl+a then r) to reload configuration

## Common Workflows

### Workflow 1: Development Session
```bash
# Start named session
tmux new -s dev

# Split into editor and terminal
Prefix + |    # Split horizontal
Prefix + -    # Split terminal pane vertical

# Navigate between panes
Prefix + h/j/k/l
```

### Workflow 2: Multiple Projects
```bash
# Create windows for each project
Prefix + c    # New window
Prefix + ,    # Rename to "frontend"

Prefix + c    # Another window
Prefix + ,    # Rename to "backend"

# Switch between windows
Prefix + n/p  # Next/previous
Prefix + 0-9  # Direct jump
```

### Workflow 3: Session Persistence
```bash
# Your work is automatically saved every 15 minutes

# After reboot, restore session
tmux
Prefix + Ctrl+r    # Restore last session
```

## Customization

### Change Status Bar Colors
Edit `~/.config/tmux/tmux.conf` lines 76-90 (Status Bar Configuration section)

### Add More Plugins
1. Add plugin line to config: `set -g @plugin 'user/plugin-name'`
2. Reload config: `Prefix + r`
3. Install plugin: `Prefix + I`

### Change Prefix Key
Edit line 38 in `tmux.conf`:
```bash
set -g prefix C-a    # Change C-a to your preferred key
```

## Troubleshooting

### Colors Look Wrong
Ensure your terminal supports 256 colors:
```bash
echo $TERM    # Should show tmux-256color or similar
```

### Plugins Not Working
1. Verify TPM is installed: `ls ~/.local/share/tmux/plugins/tpm`
2. Reinstall plugins: `Prefix + I`
3. Check plugin path in config matches XDG location

### Config Not Loading
1. Check symlink: `ls -la ~/.config/tmux/tmux.conf`
2. Verify XDG_CONFIG_HOME: `echo $XDG_CONFIG_HOME`
3. Reload manually: `tmux source ~/.config/tmux/tmux.conf`

### Mouse Not Working
Check if mouse support is enabled:
```bash
tmux show -g mouse    # Should show "mouse on"
```

## Useful Commands

### Session Management
```bash
tmux ls                        # List all sessions
tmux new -s name               # Create named session
tmux attach -t name            # Attach to session
tmux kill-session -t name      # Kill specific session
tmux kill-server               # Kill all sessions
```

### Configuration Testing
```bash
# Test config without affecting running sessions
tmux -f ~/.config/tmux/tmux.conf new

# Source config in running session
tmux source ~/.config/tmux/tmux.conf
```

## Advanced Features

### Nested Sessions
When SSH'd into another machine running tmux:
- Use `Prefix + Prefix` to send commands to inner session
- Example: `Ctrl+a, Ctrl+a, c` creates window in remote session

### Copy to System Clipboard
With tmux-yank plugin:
- Copy selection: `y` in copy mode → copies to clipboard
- Mouse selection → automatically copies to clipboard

### Search in Panes (tmux-copycat)
- Search files: `Prefix + Ctrl+f`
- Search URLs: `Prefix + Ctrl+u`
- Search git status: `Prefix + Ctrl+g`
- Search IP addresses: `Prefix + Alt+i`

## Recent Configuration Changes

### 2025-11-13 - Initial Setup
- Created XDG-compliant configuration
- Set prefix to Ctrl+a
- Added vim-style navigation
- Configured Gruvbox Dark theme
- Installed TPM and essential plugins
- Enabled mouse support
- Configured session persistence

## Resources

- **Tmux Manual:** `man tmux`
- **Official Wiki:** https://github.com/tmux/tmux/wiki
- **TPM:** https://github.com/tmux-plugins/tpm
- **Tmux Cheat Sheet:** https://tmuxcheatsheet.com/

---

**Last updated:** 2025-11-13
