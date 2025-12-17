#!/bin/bash

# LSD (LSDeluxe) Installation Script
# Cross-platform: macOS (Homebrew) and Linux (binary download)
# Modern replacement for ls with icons and colors
# Date: 2025-11-26

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "LSD (LSDeluxe) Setup"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Paths
LSD_BIN_DIR="$HOME/.local/bin"
LSD_CONFIG_DIR="$XDG_CONFIG_HOME/lsd"

# Pinned version (for Linux binary download)
LSD_VERSION="v1.1.5"

mkdir -p "$LSD_BIN_DIR"
mkdir -p "$LSD_CONFIG_DIR"

# Check if already installed
print_step "Checking LSD installation..."
if command -v lsd &>/dev/null; then
    print_warning "LSD already installed ($(lsd --version | head -1))"
else
    if is_macos; then
        # macOS: Use Homebrew
        print_info "Installing LSD via Homebrew..."
        ensure_homebrew
        if ! init_brew; then
            print_warn "Brew not initialized in current session - may need manual setup"
        fi
        pkg_install lsd
    else
        # Linux: Download binary (checksums in release notes, not as separate file)
        print_info "Installing LSD ${LSD_VERSION}..."

        tmp_dir=$(mktemp -d)
        arch=$(detect_arch)

        # Map architecture for lsd binary naming
        case "$arch" in
            x86_64) arch="x86_64" ;;
            arm64)  arch="aarch64" ;;
            *)      print_error "Unsupported architecture: $arch"; exit 1 ;;
        esac

        download_url="https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/lsd-${LSD_VERSION}-${arch}-unknown-linux-gnu.tar.gz"

        download_verified "$download_url" "$tmp_dir/lsd.tar.gz"

        tar -xzf "$tmp_dir/lsd.tar.gz" -C "$tmp_dir"
        cp "$tmp_dir/lsd-${LSD_VERSION}-${arch}-unknown-linux-gnu/lsd" "$LSD_BIN_DIR/lsd"
        chmod +x "$LSD_BIN_DIR/lsd"

        rm -rf "$tmp_dir"
    fi
    print_info "LSD installed"
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
