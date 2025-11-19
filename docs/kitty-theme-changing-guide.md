# Kitty Theme Changing Guide

## Quick Theme Change

The easiest way to change themes in Kitty is to replace the color scheme section in your config file.

### Current Theme: Gruvbox Dark

Location: `~/.config/kitty/kitty.conf` (lines 71-107)

### How to Change Themes

#### Method 1: Manual Edit (Recommended)

1. Open your kitty config:
   ```bash
   nvim ~/.config/kitty/kitty.conf
   ```

2. Find the `# ===== COLOR SCHEME` section (around line 71)

3. Replace the color values with your preferred theme

4. Reload the config: Press `Ctrl+Shift+F5` or restart kitty

#### Method 2: Using Kitty Themes Repository

Kitty has an official themes repository with hundreds of pre-made themes.

1. Clone the themes repository:
   ```bash
   git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
   ```

2. Create a symlink to your chosen theme:
   ```bash
   cd ~/.config/kitty
   ln -sf ./kitty-themes/themes/gruvbox_dark.conf theme.conf
   ```

3. Include the theme in your `kitty.conf`:
   ```bash
   echo "include ./theme.conf" >> ~/.config/kitty/kitty.conf
   ```

   (Comment out the manual color scheme section first)

4. To switch themes, just update the symlink:
   ```bash
   ln -sf ./kitty-themes/themes/nord.conf ~/.config/kitty/theme.conf
   ```

   Then reload with `Ctrl+Shift+F5`

#### Method 3: Using kitten themes (Easiest)

Kitty has a built-in theme browser:

1. Run the theme kitten:
   ```bash
   kitty +kitten themes
   ```

2. Browse themes with arrow keys, preview in real-time

3. Press Enter to apply your chosen theme

4. The theme will be automatically saved to your config

## Popular Themes

### Gruvbox Dark (Current)
Retro groove color scheme with warm, earthy tones. Great for long coding sessions.

### Tokyo Night
Modern dark theme with vibrant colors and excellent contrast.

### Nord
Arctic, north-bluish color palette. Clean and easy on the eyes.

### Catppuccin
Pastel color scheme with multiple variants (Latte, Frappe, Macchiato, Mocha).

### Dracula
Dark theme with vibrant purple and pink accents.

### One Dark
Atom's iconic One Dark theme.

### Solarized
Classic theme available in dark and light variants.

## Theme Configuration Templates

### Gruvbox Dark (Current Active Theme)
```
foreground #ebdbb2
background #282828
selection_foreground #ebdbb2
selection_background #504945

color0 #282828
color8 #928374
color1 #cc241d
color9 #fb4934
color2  #98971a
color10 #b8bb26
color3  #d79921
color11 #fabd2f
color4  #458588
color12 #83a598
color5  #b16286
color13 #d3869b
color6  #689d6a
color14 #8ec07c
color7  #a89984
color15 #ebdbb2
```

### Tokyo Night
```
foreground #c0caf5
background #1a1b26
selection_foreground #c0caf5
selection_background #33467c

color0 #15161e
color8 #414868
color1 #f7768e
color9 #f7768e
color2  #9ece6a
color10 #9ece6a
color3  #e0af68
color11 #e0af68
color4  #7aa2f7
color12 #7aa2f7
color5  #bb9af7
color13 #bb9af7
color6  #7dcfff
color14 #7dcfff
color7  #a9b1d6
color15 #c0caf5
```

### Nord
```
foreground #d8dee9
background #2e3440
selection_foreground #d8dee9
selection_background #4c566a

color0 #3b4252
color8 #4c566a
color1 #bf616a
color9 #bf616a
color2  #a3be8c
color10 #a3be8c
color3  #ebcb8b
color11 #ebcb8b
color4  #81a1c1
color12 #81a1c1
color5  #b48ead
color13 #b48ead
color6  #88c0d0
color14 #8fbcbb
color7  #e5e9f0
color15 #eceff4
```

### Dracula
```
foreground #f8f8f2
background #282a36
selection_foreground #ffffff
selection_background #44475a

color0 #21222c
color8 #6272a4
color1 #ff5555
color9 #ff6e6e
color2  #50fa7b
color10 #69ff94
color3  #f1fa8c
color11 #ffffa5
color4  #bd93f9
color12 #d6acff
color5  #ff79c6
color13 #ff92df
color6  #8be9fd
color14 #a4ffff
color7  #f8f8f2
color15 #ffffff
```

### Catppuccin Mocha
```
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

color0 #45475a
color8 #585b70
color1 #f38ba8
color9 #f38ba8
color2  #a6e3a1
color10 #a6e3a1
color3  #f9e2af
color11 #f9e2af
color4  #89b4fa
color12 #89b4fa
color5  #f5c2e7
color13 #f5c2e7
color6  #94e2d5
color14 #94e2d5
color7  #bac2de
color15 #a6adc8
```

## Quick Switch Script

Create a theme switcher script for even faster theme changes:

```bash
#!/bin/bash
# Save as: ~/.local/bin/kitty-theme-switch

THEME=$1
CONFIG="$HOME/.config/kitty/kitty.conf"

if [ -z "$THEME" ]; then
    echo "Usage: kitty-theme-switch <theme-name>"
    echo "Available: gruvbox, tokyo-night, nord, dracula, catppuccin"
    exit 1
fi

# Backup current config
cp "$CONFIG" "$CONFIG.backup"

# Replace theme section based on argument
case "$THEME" in
    "gruvbox")
        # Replace colors with Gruvbox
        ;;
    "tokyo-night")
        # Replace colors with Tokyo Night
        ;;
    # Add more themes as needed
esac

# Reload all kitty instances
killall -SIGUSR1 kitty
```

## Tips

1. **Test Before Committing**: Use `kitty +kitten themes` to preview themes live before editing your config

2. **Keep Backups**: Always backup your config before making changes:
   ```bash
   cp ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.backup
   ```

3. **Match Border Colors**: When changing themes, update the border colors too:
   - `active_border_color`: Should match a prominent theme color
   - `inactive_border_color`: Should be a muted background shade

4. **Opacity Matters**: Adjust `background_opacity` to complement your theme:
   - Dark themes: 0.90-0.95 works well
   - Light themes: 0.85-0.90 for better readability

5. **URL Colors**: Update `url_color` to match your theme's accent color

## Resources

- [Kitty Themes Repository](https://github.com/dexpota/kitty-themes)
- [Kitty Color Configuration Docs](https://sw.kovidgoyal.net/kitty/conf/#color-scheme)
- [Terminal Color Scheme Designer](https://terminal.sexy/)
- [Kitty Themes Gallery](https://github.com/kovidgoyal/kitty-themes)

---

*Last updated: 2025-10-20*
