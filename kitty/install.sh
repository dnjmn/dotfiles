#!/bin/bash

# Kitty Terminal Installation Script with XDG Base Directory Support
# Cross-platform: macOS (Homebrew Cask) and Linux (installer script)
# Installs Kitty terminal, JetBrainsMono Nerd Font, and configures everything
# Date: 2025-11-26

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Kitty Terminal Setup (XDG Compliant)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Kitty paths
KITTY_APP_DIR="$HOME/.local/kitty.app"
KITTY_BIN_DIR="$HOME/.local/bin"
KITTY_CONFIG_DIR="$XDG_CONFIG_HOME/kitty"
FONT_DIR="$(get_font_dir)"
DESKTOP_DIR="$XDG_DATA_HOME/applications"

print_info "Using directory structure:"
echo "  • Config: $KITTY_CONFIG_DIR"
echo "  • Fonts: $FONT_DIR"
if is_linux; then
    echo "  • App: $KITTY_APP_DIR"
fi
echo ""

# Create directories
print_step "Creating directories..."
mkdir -p "$KITTY_BIN_DIR"
mkdir -p "$KITTY_CONFIG_DIR"
mkdir -p "$FONT_DIR"
if is_linux; then
    mkdir -p "$DESKTOP_DIR"
fi

# 1. Install Kitty
print_step "Installing Kitty terminal..."

# Helper to get kitty binary path
get_kitty_bin() {
    if command -v kitty &>/dev/null; then
        command -v kitty
    elif is_macos && [[ -x "/Applications/kitty.app/Contents/MacOS/kitty" ]]; then
        echo "/Applications/kitty.app/Contents/MacOS/kitty"
    elif [[ -x "$KITTY_APP_DIR/bin/kitty" ]]; then
        echo "$KITTY_APP_DIR/bin/kitty"
    fi
}

KITTY_BIN="$(get_kitty_bin)"

if [[ -n "$KITTY_BIN" ]]; then
    print_warning "Kitty already installed ($("$KITTY_BIN" --version | head -1))"
else
    if is_macos; then
        # macOS: Use Homebrew Cask
        ensure_homebrew
        if ! init_brew; then
            print_warn "Brew not initialized in current session - may need manual setup"
        fi
        pkg_install_cask kitty
    else
        # Linux: Use installer script
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    fi
    KITTY_BIN="$(get_kitty_bin)"
    print_info "Kitty installed"
fi

# Create symlinks to ~/.local/bin for CLI access
print_step "Creating CLI symlinks..."
if is_macos; then
    # macOS: Link from /Applications/kitty.app
    if [[ -x "/Applications/kitty.app/Contents/MacOS/kitty" ]]; then
        ln -sf "/Applications/kitty.app/Contents/MacOS/kitty" "$KITTY_BIN_DIR/kitty"
        ln -sf "/Applications/kitty.app/Contents/MacOS/kitten" "$KITTY_BIN_DIR/kitten"
        print_info "Symlinks created in $KITTY_BIN_DIR"
    fi
else
    # Linux: Link from ~/.local/kitty.app
    ln -sf "$KITTY_APP_DIR/bin/kitty" "$KITTY_BIN_DIR/kitty"
    ln -sf "$KITTY_APP_DIR/bin/kitten" "$KITTY_BIN_DIR/kitten"
    print_info "Symlinks created in $KITTY_BIN_DIR"
fi

# 2. Install JetBrainsMono Nerd Font
print_step "Installing JetBrainsMono Nerd Font..."

# Pinned version for reproducibility - update as needed
NERD_FONT_VERSION="v3.3.0"

install_jetbrains_font() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local zip_file="$tmp_dir/JetBrainsMono.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip"

    print_info "Downloading JetBrainsMono Nerd Font ${NERD_FONT_VERSION}..."
    if ! curl -fsSL "$download_url" -o "$zip_file"; then
        print_error "Failed to download font"
        rm -rf "$tmp_dir"
        return 1
    fi

    print_info "Extracting fonts..."
    if ! unzip -q "$zip_file" -d "$tmp_dir"; then
        print_error "Failed to extract font archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    # Copy only .ttf files (skip Windows-compatible and variable fonts)
    find "$tmp_dir" -name "*.ttf" ! -name "*Windows*" -exec cp {} "$FONT_DIR/" \;

    rm -rf "$tmp_dir"
    print_info "Font files installed to $FONT_DIR"
    return 0
}

# Check if font is already installed
font_installed() {
    if is_macos; then
        # macOS: Check for font file in Library/Fonts
        ls "$FONT_DIR"/JetBrainsMonoNerd*.ttf &>/dev/null 2>&1
    else
        # Linux: Use fc-list
        fc-list | grep -qi "JetBrainsMono Nerd Font"
    fi
}

if font_installed; then
    print_warning "JetBrainsMono Nerd Font already installed"
else
    if install_jetbrains_font; then
        if is_linux; then
            fc-cache -f "$FONT_DIR"
        fi
        print_info "Font installed"
    else
        print_warning "Font installation skipped - install manually from:"
        echo "  https://github.com/ryanoasis/nerd-fonts/releases"
    fi
fi

# 3. Symlink configuration
print_step "Linking configuration..."
symlink_with_backup "$SCRIPT_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"

# 4. Create desktop entry (Linux only - macOS uses Applications folder)
if is_linux; then
    print_step "Creating desktop entry..."

    # Copy icon if available
    ICON_PATH="kitty"  # Use system icon name as default
    if [ -f "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" ]; then
        mkdir -p "$XDG_DATA_HOME/icons/hicolor/256x256/apps"
        cp "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" \
           "$XDG_DATA_HOME/icons/hicolor/256x256/apps/kitty.png"
        ICON_PATH="$XDG_DATA_HOME/icons/hicolor/256x256/apps/kitty.png"
    fi

    create_desktop_entry "Kitty" "$KITTY_BIN_DIR/kitty" "$ICON_PATH" "System;TerminalEmulator"
fi

# Summary
echo ""
echo "======================================"
print_info "Kitty setup complete!"
echo "======================================"
echo ""
print_info "Installed:"
echo "  • Kitty: $("$KITTY_BIN" --version 2>/dev/null | head -1 || echo 'check installation')"
echo "  • Config: $KITTY_CONFIG_DIR/kitty.conf"
echo "  • Fonts: $FONT_DIR"
if is_linux; then
    echo "  • Desktop: $DESKTOP_DIR/kitty.desktop"
fi
echo ""
print_info "Key shortcuts:"
if is_macos; then
    echo "  • New tab: Cmd+T"
    echo "  • New window: Cmd+N"
    echo "  • Reload config: Ctrl+Cmd+,"
else
    echo "  • New tab: Ctrl+Shift+T"
    echo "  • New window: Ctrl+Shift+Enter"
    echo "  • Reload config: Ctrl+Shift+F5"
fi
echo ""
