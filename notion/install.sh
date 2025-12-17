#!/bin/bash

# Notion Installation Script
# Cross-platform: macOS (Homebrew Cask) and Linux (AppImage)
# Date: 2025-11-26

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Notion Desktop Setup"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# macOS: Use Homebrew Cask
if is_macos; then
    print_step "Installing Notion via Homebrew Cask..."
    ensure_homebrew
    if ! init_brew; then
        print_warn "Brew not initialized in current session - may need manual setup"
    fi
    pkg_install_cask notion

    echo ""
    echo "======================================"
    print_info "Notion setup complete!"
    echo "======================================"
    echo ""
    print_info "Launch: Open from Applications folder or Spotlight"
    echo ""
    exit 0
fi

# Linux: AppImage installation
# Paths
NOTION_DIR="$XDG_DATA_HOME/notion"
NOTION_BIN="$NOTION_DIR/notion.AppImage"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$XDG_DATA_HOME/applications"
ICON_DIR="$XDG_DATA_HOME/icons"

# Create directories
mkdir -p "$NOTION_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"

# Check if already installed
print_step "Checking Notion installation..."
if [ -f "$NOTION_BIN" ]; then
    print_warning "Notion AppImage already exists at $NOTION_BIN"
    print_info "Use --force to reinstall"
    if [ "${1:-}" != "--force" ]; then
        exit 0
    fi
fi

# Get latest release from notion-repackaged
print_step "Fetching latest Notion release..."
if ! DOWNLOAD_URL=$(get_github_release_url "notion-enhancer/notion-repackaged" "\.AppImage$"); then
    print_error "Could not find AppImage download URL"
    exit 1
fi

print_info "Download URL: $DOWNLOAD_URL"

# Download AppImage (no checksum available for this third-party repo)
print_step "Downloading Notion AppImage..."
download_verified "$DOWNLOAD_URL" "$NOTION_BIN"

chmod +x "$NOTION_BIN"
print_info "AppImage saved to $NOTION_BIN"

# Create symlink
ln -sf "$NOTION_BIN" "$BIN_DIR/notion"
print_info "Symlink created: $BIN_DIR/notion"

# Download icon (non-critical)
print_step "Downloading icon..."
ICON_PATH="$ICON_DIR/notion.svg"
if ! curl -fsSL "https://raw.githubusercontent.com/notion-enhancer/notion-repackaged/main/media/colour.svg" -o "$ICON_PATH"; then
    print_warn "Icon download failed (non-critical)"
    ICON_PATH=""
fi

# Create desktop entry
print_step "Creating desktop entry..."
create_desktop_entry "Notion" "$NOTION_BIN" "$ICON_PATH" "Office;Productivity"

# Summary
echo ""
echo "======================================"
print_info "Notion setup complete!"
echo "======================================"
echo ""
print_info "Launch:"
echo "  notion         # From terminal"
echo "  Or find 'Notion' in application menu"
echo ""
