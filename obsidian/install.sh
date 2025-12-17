#!/bin/bash

# Obsidian Installation Script
# Cross-platform: macOS (Homebrew Cask) and Linux (AppImage)
# Date: 2025-11-26

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Obsidian Setup Script"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# macOS: Use Homebrew Cask
if is_macos; then
    print_step "Installing Obsidian via Homebrew Cask..."
    ensure_homebrew
    init_brew || true
    pkg_install_cask obsidian

    echo ""
    echo "======================================"
    print_info "Obsidian setup complete!"
    echo "======================================"
    echo ""
    print_info "Launch: Open from Applications folder or Spotlight"
    print_info "Vaults: Create anywhere, typically ~/Documents/Obsidian/"
    echo ""
    exit 0
fi

# Linux: AppImage installation
LOCAL_BIN="$HOME/.local/bin"

# Obsidian paths
OBSIDIAN_DIR="$XDG_DATA_HOME/obsidian"
APPIMAGE_PATH="$OBSIDIAN_DIR/Obsidian.AppImage"
DESKTOP_FILE="$XDG_DATA_HOME/applications/obsidian.desktop"
ICON_PATH="$XDG_DATA_HOME/icons/obsidian.png"

print_info "Installation paths:"
echo "  • AppImage: $APPIMAGE_PATH"
echo "  • Desktop: $DESKTOP_FILE"
echo "  • Config: $XDG_CONFIG_HOME/obsidian/"
echo ""

# Check dependencies
print_step "Checking dependencies..."
pkg_install curl jq

# Create directories
print_step "Creating directories..."
mkdir -p "$OBSIDIAN_DIR"
mkdir -p "$LOCAL_BIN"
mkdir -p "$XDG_DATA_HOME/applications"
mkdir -p "$XDG_DATA_HOME/icons"
mkdir -p "$XDG_CONFIG_HOME/obsidian"

# Get latest version from GitHub API
print_step "Fetching latest Obsidian version..."
LATEST_VERSION=$(curl -sL "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" | jq -r '.tag_name' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    print_error "Failed to fetch latest version"
    exit 1
fi
print_info "Latest version: $LATEST_VERSION"

# Check if already installed with same version
if [ -f "$APPIMAGE_PATH" ]; then
    CURRENT_VERSION=$("$APPIMAGE_PATH" --version 2>/dev/null | sed 's/.*\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/' || echo "unknown")
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        print_warning "Obsidian $LATEST_VERSION already installed"
        print_info "Run with --force to reinstall"
        [ "${1:-}" != "--force" ] && exit 0
    else
        print_info "Upgrading from $CURRENT_VERSION to $LATEST_VERSION"
    fi
fi

# Download AppImage
print_step "Downloading Obsidian $LATEST_VERSION..."
DOWNLOAD_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/Obsidian-${LATEST_VERSION}.AppImage"

if ! curl -L --progress-bar -o "$APPIMAGE_PATH" "$DOWNLOAD_URL"; then
    print_error "Download failed"
    exit 1
fi

chmod +x "$APPIMAGE_PATH"
print_info "AppImage downloaded and made executable"

# Create symlink in PATH
print_step "Creating symlink..."
ln -sf "$APPIMAGE_PATH" "$LOCAL_BIN/obsidian"
print_info "Symlink created: $LOCAL_BIN/obsidian"

# Download icon
print_step "Downloading icon..."
ICON_URL="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/obsidian.png"
if curl -sL -o "$ICON_PATH" "$ICON_URL" 2>/dev/null; then
    print_info "Icon downloaded"
else
    print_warning "Icon download failed (non-critical)"
fi

# Create desktop entry
print_step "Creating desktop entry..."
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Obsidian
Comment=Knowledge base and note-taking
Exec=$APPIMAGE_PATH %U
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Office;TextEditor;
MimeType=x-scheme-handler/obsidian;
StartupWMClass=obsidian
EOF

# Update desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$XDG_DATA_HOME/applications" 2>/dev/null || true
fi

print_info "Desktop entry created"

# Summary
echo ""
echo "======================================"
print_info "Obsidian setup complete!"
echo "======================================"
echo ""
print_info "Installed:"
echo "  • Version: $LATEST_VERSION"
echo "  • AppImage: $APPIMAGE_PATH"
echo "  • Command: obsidian (in PATH)"
echo ""
print_info "Launch methods:"
echo "  • Terminal: obsidian"
echo "  • App menu: Search 'Obsidian'"
echo ""
print_info "Config location: $XDG_CONFIG_HOME/obsidian/"
print_info "Vaults: Create anywhere, typically ~/Documents/Obsidian/"
echo ""
