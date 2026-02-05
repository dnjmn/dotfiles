# Tool Detection Wrappers
# Provides enhanced versions if tools are available

# Better diff with delta
if command -v delta &>/dev/null; then
  alias diff="delta"
fi

# Better cat with bat
if command -v bat &>/dev/null; then
  alias cat="bat --style=plain"
  alias ccat="/bin/cat"  # original cat preserved
fi

# Disk usage helpers (cross-platform)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS du uses -d for depth
  alias du1="du -h -d 1 | sort -h"
else
  # GNU du uses --max-depth
  alias du1="du -h --max-depth=1 | sort -h"
fi

# df without tmpfs noise
alias duf="df -h | grep -v tmpfs | grep -v udev | grep -v devfs"

# Toggle kitty theme
# Usage: ktheme              - toggle dark ↔ light within current family
#        ktheme <name>       - set theme (gruvbox-dark, catppuccin-mocha, etc.)
#        ktheme ls           - list available themes
ktheme() {
  local kitty_conf="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
  [[ -f "$kitty_conf" ]] || { echo "kitty.conf not found"; return 1; }

  local config_dir
  config_dir="$(dirname "$(readlink -f "$kitty_conf")")"
  local themes_dir="$config_dir/themes"
  local link="$config_dir/current-theme.conf"

  local current new_theme
  current="$(readlink "$link" 2>/dev/null || echo "")"

  case "${1:-}" in
    ls|list)
      for f in "$themes_dir"/*.conf(N); do
        local name="$(basename "$f" .conf)"
        [[ "$current" == *"$name"* ]] && echo "* $name" || echo "  $name"
      done
      return
      ;;
    "")
      # Toggle dark ↔ light within same family
      case "$current" in
        *gruvbox-dark*)       new_theme="gruvbox-light" ;;
        *gruvbox-light*)      new_theme="gruvbox-dark" ;;
        *catppuccin-mocha*)   new_theme="catppuccin-latte" ;;
        *catppuccin-latte*)   new_theme="catppuccin-mocha" ;;
        *)                    new_theme="gruvbox-dark" ;;
      esac
      ;;
    *) new_theme="$1" ;;
  esac

  local theme_file="$themes_dir/${new_theme}.conf"
  [[ -f "$theme_file" ]] || { echo "Theme not found: $new_theme (try: ktheme ls)"; return 1; }

  ln -sf "themes/${new_theme}.conf" "$link"
  kitty @ set-colors --all --configured "$theme_file"
  echo "kitty: $new_theme"
}
