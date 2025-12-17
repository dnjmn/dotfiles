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
    if ! init_brew; then
        print_warn "Brew not initialized in current session - may need manual setup"
    fi
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
if ! LATEST_VERSION=$(get_github_release_version "obsidianmd/obsidian-releases"); then
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

# Download AppImage with checksum verification
print_step "Downloading Obsidian $LATEST_VERSION..."
DOWNLOAD_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/Obsidian-${LATEST_VERSION}.AppImage"
CHECKSUM_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/SHA-256.txt"

# Fetch checksum for verification
print_info "Fetching checksum..."
if EXPECTED_CHECKSUM=$(curl -fsSL "$CHECKSUM_URL" 2>/dev/null | grep "Obsidian-${LATEST_VERSION}.AppImage" | cut -d' ' -f1); then
    download_verified "$DOWNLOAD_URL" "$APPIMAGE_PATH" "$EXPECTED_CHECKSUM"
else
    print_warn "Could not fetch checksum - downloading without verification"
    download_verified "$DOWNLOAD_URL" "$APPIMAGE_PATH"
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
create_desktop_entry "Obsidian" "$APPIMAGE_PATH" "$ICON_PATH" "Office;TextEditor"

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
