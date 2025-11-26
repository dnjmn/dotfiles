#!/bin/bash

# Notion Installation Script
# Installs Notion AppImage at user level (no sudo required)
# Date: 2025-11-26

set -euo pipefail

echo "======================================"
echo "Notion Desktop Setup (User-level)"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# XDG directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

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
RELEASE_API="https://api.github.com/repos/notion-enhancer/notion-repackaged/releases/latest"
DOWNLOAD_URL=$(curl -fsSL "$RELEASE_API" | grep -oP '"browser_download_url":\s*"\K[^"]+\.AppImage' | head -1)

if [ -z "$DOWNLOAD_URL" ]; then
    print_error "Could not find AppImage download URL"
    exit 1
fi

print_info "Download URL: $DOWNLOAD_URL"

# Download AppImage
print_step "Downloading Notion AppImage..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "$NOTION_BIN"; then
    print_error "Failed to download Notion"
    exit 1
fi

chmod +x "$NOTION_BIN"
print_info "AppImage saved to $NOTION_BIN"

# Create symlink
ln -sf "$NOTION_BIN" "$BIN_DIR/notion"
print_info "Symlink created: $BIN_DIR/notion"

# Download icon
print_step "Downloading icon..."
curl -fsSL "https://raw.githubusercontent.com/notion-enhancer/notion-repackaged/main/media/colour.svg" \
    -o "$ICON_DIR/notion.svg" 2>/dev/null || true

# Create desktop entry
print_step "Creating desktop entry..."
cat > "$DESKTOP_DIR/notion.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Notion
GenericName=Productivity
Comment=All-in-one workspace
Exec=$NOTION_BIN %U
Icon=$ICON_DIR/notion.svg
Terminal=false
Categories=Office;Productivity;
Keywords=notes;wiki;productivity;
StartupWMClass=Notion
EOF

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

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
