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
if command -v kitty &>/dev/null; then
    print_warning "Kitty already installed ($(kitty --version | head -1))"
else
    if is_macos; then
        # macOS: Use Homebrew Cask
        ensure_homebrew
        init_brew || true
        pkg_install_cask kitty
    else
        # Linux: Use installer script
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    fi
    print_info "Kitty installed"
fi

# Create symlinks to ~/.local/bin (Linux only - macOS Homebrew handles this)
if is_linux; then
    print_step "Creating symlinks..."
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
if [ -f "$KITTY_CONFIG_DIR/kitty.conf" ] && [ ! -L "$KITTY_CONFIG_DIR/kitty.conf" ]; then
    cp "$KITTY_CONFIG_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing kitty.conf"
fi
ln -sf "$SCRIPT_DIR/kitty.conf" "$KITTY_CONFIG_DIR/kitty.conf"
print_info "Config linked from repo"

# 4. Create desktop entry (Linux only - macOS uses Applications folder)
if is_linux; then
    print_step "Creating desktop entry..."
    cat > "$DESKTOP_DIR/kitty.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Kitty
GenericName=Terminal Emulator
Comment=Fast, feature-rich, GPU based terminal
Exec=$KITTY_BIN_DIR/kitty
TryExec=$KITTY_BIN_DIR/kitty
Icon=kitty
Terminal=false
Categories=System;TerminalEmulator;
Keywords=terminal;shell;command line;
StartupWMClass=kitty
EOF

    # Copy icon if available
    if [ -f "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" ]; then
        mkdir -p "$XDG_DATA_HOME/icons/hicolor/256x256/apps"
        cp "$KITTY_APP_DIR/share/icons/hicolor/256x256/apps/kitty.png" \
           "$XDG_DATA_HOME/icons/hicolor/256x256/apps/kitty.png"
    fi

    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    print_info "Desktop entry created"
fi

# Summary
echo ""
echo "======================================"
print_info "Kitty setup complete!"
echo "======================================"
echo ""
print_info "Installed:"
echo "  • Kitty: $(kitty --version 2>/dev/null | head -1 || echo 'check PATH')"
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
