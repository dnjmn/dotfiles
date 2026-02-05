#!/bin/bash
# install/kitty.sh - GPU-accelerated terminal emulator with JetBrainsMono Nerd Font

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="kitty"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly KITTY_XDG_DIR="$XDG_CONFIG_HOME/kitty"
readonly FONT_DIR="$(get_font_dir)"
readonly NERD_FONT_VERSION="v3.3.0"

install_kitty() {
    if command -v kitty &>/dev/null; then
        print_ok "Kitty already installed"
        return
    fi

    ensure_homebrew
    if is_macos; then
        pkg_install_cask kitty
    else
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    fi
    print_ok "Kitty installed"
}

create_cli_symlinks() {
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    if is_macos && [[ -x "/Applications/kitty.app/Contents/MacOS/kitty" ]]; then
        ln -sf "/Applications/kitty.app/Contents/MacOS/kitty" "$bin_dir/kitty"
        ln -sf "/Applications/kitty.app/Contents/MacOS/kitten" "$bin_dir/kitten"
    elif [[ -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
        ln -sf "$HOME/.local/kitty.app/bin/kitty" "$bin_dir/kitty"
        ln -sf "$HOME/.local/kitty.app/bin/kitten" "$bin_dir/kitten"
    fi
}

install_font() {
    # Check if already installed
    if ls "$FONT_DIR"/JetBrainsMonoNerd*.ttf &>/dev/null 2>&1; then
        print_ok "JetBrainsMono Nerd Font already installed"
        return
    fi

    mkdir -p "$FONT_DIR"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local zip_file="$tmp_dir/JetBrainsMono.zip"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip"

    print_info "Downloading JetBrainsMono Nerd Font..."
    curl -fsSL "$url" -o "$zip_file"
    unzip -q "$zip_file" -d "$tmp_dir"
    find "$tmp_dir" -name "*.ttf" ! -name "*Windows*" -exec cp {} "$FONT_DIR/" \;
    rm -rf "$tmp_dir"

    is_linux && fc-cache -f "$FONT_DIR"
    print_ok "Font installed to $FONT_DIR"
}

link_configs() {
    mkdir -p "$KITTY_XDG_DIR"
    symlink_with_backup "$CONFIG_DIR/kitty.conf" "$KITTY_XDG_DIR/kitty.conf"
    [[ -f "$CONFIG_DIR/session.conf" ]] && symlink_with_backup "$CONFIG_DIR/session.conf" "$KITTY_XDG_DIR/session.conf"

    # Set default theme (gruvbox-dark) if not already set
    if [[ ! -e "$CONFIG_DIR/current-theme.conf" ]]; then
        ln -sf "themes/gruvbox-dark.conf" "$CONFIG_DIR/current-theme.conf"
        print_ok "Default theme set to gruvbox-dark"
    fi
}

post_install() {
    echo ""
    print_info "Kitty setup complete!"
    echo "  Config: $KITTY_XDG_DIR/kitty.conf"
    echo "  Fonts: $FONT_DIR"
    echo ""
    if is_macos; then
        echo "Reload config: Ctrl+Cmd+,"
    else
        echo "Reload config: Ctrl+Shift+F5"
    fi
}

main() {
    echo "==> Installing $NAME"
    install_kitty
    create_cli_symlinks
    install_font
    link_configs
    post_install
    echo "==> Done"
}

main "$@"
