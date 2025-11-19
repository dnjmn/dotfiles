# Kitty Terminal Setup

## Overview
Kitty is a fast, feature-rich, GPU-accelerated terminal emulator installed with productivity-focused configuration.

**Installation Date:** 2025-10-20
**Version:** 0.43.1
**Location:** `~/.local/kitty.app/`

## What Was Installed

### 1. Kitty Terminal Emulator
- **Installed via:** Official installer script from sw.kovidgoyal.net
- **Binary location:** `~/.local/bin/kitty`
- **Config location:** `~/.config/kitty/kitty.conf`

### 2. JetBrainsMono Nerd Font
- **Version:** 3.2.1
- **Location:** `~/.local/share/fonts/`
- **Features:**
  - Programming ligatures
  - Icon glyphs (Nerd Font patches)
  - Excellent readability

## Key Features

### Visual Enhancements
- **Color Scheme:** Gruvbox Dark (retro groove with warm, earthy tones)
- **Opacity:** 95% background opacity for subtle transparency
- **Font Size:** 12pt (adjustable with Ctrl+Shift+Plus/Minus)
- **Window Padding:** 4px for better spacing
- **Window Size:** 85% screen size (1632x918 on FHD displays)

### Performance Optimizations
- GPU-accelerated rendering
- Sync to monitor for smooth scrolling
- Low input/repaint delay (3ms/10ms)

### Productivity Features
- **Scrollback:** 10,000 lines of history
- **Copy on select:** Automatic clipboard on text selection
- **URL detection:** Clickable URLs (Ctrl+Left Click)
- **Multiple layouts:** Support for splits and stacks
- **Tab management:** Powerline-style tabs with slanted edges

## Essential Keyboard Shortcuts

### Tabs
- `Ctrl+Shift+T` - New tab
- `Ctrl+Shift+Q` - Close tab
- `Ctrl+Shift+Right/Left` - Navigate tabs
- `Ctrl+Shift+Alt+T` - Rename tab

### Windows (Splits)
- `Ctrl+Shift+Enter` - New window (split)
- `Ctrl+Shift+W` - Close window
- `Ctrl+Shift+]` - Next window
- `Ctrl+Shift+[` - Previous window
- `Ctrl+Shift+R` - Resize mode
- `Ctrl+Shift+Z` - Toggle stack layout

### Clipboard
- `Ctrl+Shift+C` - Copy
- `Ctrl+Shift+V` - Paste
- `Ctrl+Shift+S` - Paste from selection

### Font Size
- `Ctrl+Shift+=` - Increase font size
- `Ctrl+Shift+-` - Decrease font size
- `Ctrl+Shift+0` - Reset to default size

### Scrolling
- `Ctrl+Shift+Up/Down` - Line by line
- `Ctrl+Shift+Page Up/Down` - Page by page
- `Ctrl+Shift+Home/End` - Jump to start/end
- `Ctrl+Shift+H` - View scrollback in pager

### Configuration
- `Ctrl+Shift+F5` - Reload config file
- `Ctrl+Shift+Escape` - Open kitty shell

## How to Launch

### From Terminal
```bash
kitty
```

### With Specific Options
```bash
# Start in a specific directory
kitty --directory /path/to/dir

# Start with a specific session
kitty --session /path/to/session.conf

# Override config
kitty --config /path/to/kitty.conf
```

## Configuration File

Location: `~/.config/kitty/kitty.conf`

### Key Configuration Sections
1. **Fonts** - JetBrainsMono Nerd Font configuration
2. **Colors** - Gruvbox Dark theme (easily changeable - see theme guide)
3. **Cursor** - Beam shape with smooth blinking
4. **Mouse** - URL handling, copy on select
5. **Windows/Tabs** - Layout and styling (80% screen size)
6. **Keyboard** - All shortcuts defined here

### To Modify
Edit `~/.config/kitty/kitty.conf` and reload with `Ctrl+Shift+F5`

## Advanced Features

### Remote Control
Kitty supports remote control via socket:
```bash
kitty @ --to unix:/tmp/kitty ls
```

### Kittens (Extensions)
Useful built-in kittens:
```bash
# Unicode input
Ctrl+Shift+U

# Diff files
kitty +kitten diff file1 file2

# SSH with terminfo
kitty +kitten ssh hostname
```

### Custom Themes
To change color scheme, see the [Kitty Theme Changing Guide](./kitty-theme-changing-guide.md) for detailed instructions.

**Quick theme change:**
1. Run `kitty +kitten themes` for interactive theme browser
2. Or manually edit color values in `kitty.conf` lines 71-107
3. Reload with `Ctrl+Shift+F5`

Popular themes: Gruvbox (current), Tokyo Night, Catppuccin, Dracula, Nord

## Troubleshooting

### Font Not Rendering
```bash
# Verify font is installed
fc-list | grep -i jetbrains

# Rebuild font cache
fc-cache -f -v
```

### Config Not Loading
```bash
# Check for syntax errors
kitty --config ~/.config/kitty/kitty.conf
```

### Performance Issues
- Reduce `scrollback_lines` in config
- Disable background opacity
- Check GPU drivers

## Resources

- [Official Documentation](https://sw.kovidgoyal.net/kitty/)
- [Kitty Config Reference](https://sw.kovidgoyal.net/kitty/conf/)
- [Kittens Documentation](https://sw.kovidgoyal.net/kitty/kittens_intro/)

## Recent Configuration Changes

**2025-11-19 Window Size Adjustment:**
- Changed window size to 85% screen size
- Set `initial_window_width` to 1632 (85% of 1920)
- Set `initial_window_height` to 918 (85% of 1080)
- Configuration: `~/.config/kitty/kitty.conf:50-52`

**2025-11-17 Window Size Adjustment:**
- Changed window size from full screen to 80% screen size
- Set `initial_window_width` to 1536 (80% of 1920)
- Set `initial_window_height` to 864 (80% of 1080)
- Disabled `remember_window_size` to always use configured dimensions
- Configuration: `~/.config/kitty/kitty.conf:50-52`

**2025-11-11 Desktop File Fix:**
- Fixed Kitty not launching from app gallery
- Updated desktop file to use absolute paths for `Exec` and `TryExec`
- Changed from `kitty` to `/home/dhananjay-meena/.local/bin/kitty`
- Updated desktop database with `update-desktop-database`
- Location: `~/.local/share/applications/kitty.desktop`

**2025-10-20 Updates:**
- Changed color scheme from Tokyo Night to Gruvbox Dark
- Configured to open in full window mode (initial_window_width/height = 0)
- Added comprehensive [theme changing guide](./kitty-theme-changing-guide.md)

## Next Steps

Consider adding:
1. Custom session layouts
2. Integration with tmux (if needed)
3. Custom kittens for specific workflows
4. Shell integration (fish/zsh hints)

---

*Last updated: 2025-11-19*
