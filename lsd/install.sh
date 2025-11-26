#!/bin/bash

# LSD (LSDeluxe) Installation Script
# Modern replacement for ls with icons and colors
# Date: 2025-11-26

set -euo pipefail

echo "======================================"
echo "LSD (LSDeluxe) Setup"
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Paths
LSD_BIN_DIR="$HOME/.local/bin"
LSD_CONFIG_DIR="$XDG_CONFIG_HOME/lsd"

# Pinned version
LSD_VERSION="v1.1.5"

mkdir -p "$LSD_BIN_DIR"
mkdir -p "$LSD_CONFIG_DIR"

# Check if already installed
print_step "Checking LSD installation..."
if command -v lsd &>/dev/null; then
    print_warning "LSD already installed ($(lsd --version | head -1))"
else
    print_info "Installing LSD ${LSD_VERSION}..."

    tmp_dir=$(mktemp -d)
    arch=$(dpkg --print-architecture)

    # Map architecture
    case "$arch" in
        amd64) arch="x86_64" ;;
        arm64) arch="aarch64" ;;
        *) print_error "Unsupported architecture: $arch"; exit 1 ;;
    esac

    download_url="https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/lsd-${LSD_VERSION}-${arch}-unknown-linux-gnu.tar.gz"

    if ! curl -fsSL "$download_url" -o "$tmp_dir/lsd.tar.gz"; then
        print_error "Failed to download LSD"
        rm -rf "$tmp_dir"
        exit 1
    fi

    tar -xzf "$tmp_dir/lsd.tar.gz" -C "$tmp_dir"
    cp "$tmp_dir/lsd-${LSD_VERSION}-${arch}-unknown-linux-gnu/lsd" "$LSD_BIN_DIR/lsd"
    chmod +x "$LSD_BIN_DIR/lsd"

    rm -rf "$tmp_dir"
    print_info "LSD installed to $LSD_BIN_DIR/lsd"
fi

# Create config if not exists
print_step "Setting up configuration..."
if [ ! -f "$LSD_CONFIG_DIR/config.yaml" ]; then
    cat > "$LSD_CONFIG_DIR/config.yaml" << 'EOF'
# LSD Configuration
color:
  theme: default
icons:
  when: auto
  theme: fancy
sorting:
  dir-grouping: first
EOF
    print_info "Created default config at $LSD_CONFIG_DIR/config.yaml"
else
    print_warning "Config already exists"
fi

# Summary
echo ""
echo "======================================"
print_info "LSD setup complete!"
echo "======================================"
echo ""
print_info "Usage:"
echo "  lsd          # Basic listing"
echo "  lsd -l       # Long format"
echo "  lsd -la      # With hidden files"
echo "  lsd --tree   # Tree view"
echo ""
print_info "Note: Aliases are configured in zsh/.zshrc"
echo ""
