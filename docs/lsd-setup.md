# LSD (LSDeluxe) Setup

**Installed**: 2025-11-25
**Version**: 1.2.0
**Install Method**: Homebrew (`brew install lsd`)

## Overview

`lsd` is a modern replacement for `ls` with:
- File type icons (requires Nerd Font)
- Git status integration
- Color-coded file types
- Tree view built-in

## Aliases (in `.zshrc`)

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `lsd` | Basic listing with icons |
| `ll` | `lsd -l` | Long format |
| `la` | `lsd -la` | Long format with hidden |
| `l` | `lsd -F` | Compact with indicators |
| `lt` | `lsd -l --timesort` | Sort by modification time |
| `tree` | `lsd --tree` | Tree view |

## Key Options

```bash
lsd --tree --depth 2     # Tree with depth limit
lsd -l --blocks permission,user,size,date,name  # Custom columns
lsd --group-dirs first   # Directories first
lsd -S                   # Sort by size
```

## Configuration (Optional)

Config location: `~/.config/lsd/config.yaml`

Example config:
```yaml
color:
  theme: default
icons:
  when: auto
  theme: fancy
sorting:
  dir-grouping: first
```

## Requirements

- Nerd Font for icons (JetBrainsMono Nerd Font already installed with Kitty)

## Recent Configuration Changes

- 2025-11-25: Added lsd aliases to `.zshrc` with fallback to standard `ls`
