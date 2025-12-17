#!/bin/bash

# Neovim Installation Script with LazyVim Configuration
# Cross-platform: macOS and Linux (via Homebrew/Linuxbrew)
# Installs Neovim, dependencies, and configures LazyVim setup
# Date: 2025-11-26

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Neovim Setup (LazyVim + XDG Compliant)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Paths
NVIM_CONFIG_DIR="$XDG_CONFIG_HOME/nvim"
NVIM_DATA_DIR="$XDG_DATA_HOME/nvim"
NVIM_BIN_DIR="$HOME/.local/bin"

print_info "Using XDG directory structure:"
echo "  • Config: $NVIM_CONFIG_DIR"
echo "  • Data: $NVIM_DATA_DIR"
echo "  • Binary: $NVIM_BIN_DIR"
echo ""

# Ensure Homebrew is available
print_info "Ensuring Homebrew is available..."
ensure_homebrew
init_brew || true

# Create directories
print_step "Creating directories..."
mkdir -p "$NVIM_BIN_DIR"
mkdir -p "$NVIM_DATA_DIR"
mkdir -p "$XDG_STATE_HOME/nvim"
mkdir -p "$XDG_CACHE_HOME/nvim"

# 1. Install Neovim dependencies
print_step "Installing dependencies..."
pkg_install ripgrep fd git curl unzip
print_info "Dependencies installed"

# 2. Install Neovim
print_step "Checking Neovim installation..."

# Minimum version required for LazyVim
MIN_VERSION="0.9.0"

check_nvim_version() {
    if ! command -v nvim &>/dev/null; then
        return 1
    fi
    local version
    # Cross-platform version extraction (works on both macOS and Linux)
    version=$(nvim --version | head -1 | sed 's/.*v\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
    if [ -z "$version" ]; then
        return 1
    fi
    # Simple version comparison (works for x.y.z format)
    printf '%s\n%s\n' "$MIN_VERSION" "$version" | sort -V | head -1 | grep -q "$MIN_VERSION"
}

if check_nvim_version; then
    print_warning "Neovim already installed ($(nvim --version | head -1))"
else
    if is_macos; then
        # macOS: Use Homebrew
        print_info "Installing Neovim via Homebrew..."
        pkg_install neovim
    else
        # Linux: Use AppImage for latest version
        print_info "Installing Neovim via AppImage..."
        NVIM_APPIMAGE="$NVIM_BIN_DIR/nvim.appimage"
        curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage" -o "$NVIM_APPIMAGE"
        chmod +x "$NVIM_APPIMAGE"
        ln -sf "$NVIM_APPIMAGE" "$NVIM_BIN_DIR/nvim"
    fi
    print_info "Neovim installed: $(nvim --version | head -1)"
fi

# 3. Link configuration from repo
print_step "Linking configuration..."

if [ -d "$NVIM_CONFIG_DIR" ]; then
    if [ -L "$NVIM_CONFIG_DIR" ]; then
        print_warning "Config is already a symlink, updating..."
        rm "$NVIM_CONFIG_DIR"
    else
        # Backup existing config
        backup_dir="$NVIM_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$NVIM_CONFIG_DIR" "$backup_dir"
        print_warning "Backed up existing config to $backup_dir"
    fi
fi

ln -sf "$SCRIPT_DIR" "$NVIM_CONFIG_DIR"
print_info "Config linked: $NVIM_CONFIG_DIR -> $SCRIPT_DIR"

# 4. Bootstrap lazy.nvim (plugin manager)
print_step "Bootstrapping lazy.nvim..."
LAZY_DIR="$NVIM_DATA_DIR/lazy/lazy.nvim"
if [ -d "$LAZY_DIR" ]; then
    print_warning "lazy.nvim already installed"
else
    git clone --filter=blob:none --branch=stable \
        https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
    print_info "lazy.nvim installed"
fi

# 5. Install plugins headlessly
print_step "Installing plugins (this may take a moment)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
print_info "Plugins synchronized"

# Summary
echo ""
echo "======================================"
print_info "Neovim setup complete!"
echo "======================================"
echo ""
print_info "Installed:"
echo "  • Neovim: $(nvim --version 2>/dev/null | head -1)"
echo "  • Config: $NVIM_CONFIG_DIR (symlinked)"
echo "  • Plugins: $NVIM_DATA_DIR/lazy/"
echo ""
print_info "Key shortcuts (LazyVim):"
echo "  • Leader key: Space"
echo "  • Find files: Space f f"
echo "  • Search text: Space /"
echo "  • File explorer: Space e"
echo "  • Terminal: Ctrl+/"
echo ""
print_info "First run:"
echo "  Run 'nvim' - plugins will install automatically"
echo "  Run ':checkhealth' to verify setup"
echo ""
