#!/bin/bash

# Neovim Installation Script with LazyVim Configuration
# Installs Neovim, dependencies, and configures LazyVim setup
# Date: 2025-11-26

set -euo pipefail

echo "======================================"
echo "Neovim Setup (LazyVim + XDG Compliant)"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Paths
NVIM_CONFIG_DIR="$XDG_CONFIG_HOME/nvim"
NVIM_DATA_DIR="$XDG_DATA_HOME/nvim"
NVIM_BIN_DIR="$HOME/.local/bin"

print_info "Using XDG directory structure:"
echo "  • Config: $NVIM_CONFIG_DIR"
echo "  • Data: $NVIM_DATA_DIR"
echo "  • Binary: $NVIM_BIN_DIR"
echo ""

# Create directories
print_step "Creating directories..."
mkdir -p "$NVIM_BIN_DIR"
mkdir -p "$NVIM_DATA_DIR"
mkdir -p "$XDG_STATE_HOME/nvim"
mkdir -p "$XDG_CACHE_HOME/nvim"

# 1. Install Neovim dependencies
print_step "Installing dependencies..."
DEPS="ripgrep fd-find git curl unzip"
for dep in $DEPS; do
    if ! dpkg -l | grep -q "^ii  $dep "; then
        print_info "Installing $dep..."
        sudo apt-get install -y "$dep" >/dev/null 2>&1
    fi
done
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
    version=$(nvim --version | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    if [ -z "$version" ]; then
        return 1
    fi
    # Simple version comparison (works for x.y.z format)
    printf '%s\n%s\n' "$MIN_VERSION" "$version" | sort -V | head -1 | grep -q "$MIN_VERSION"
}

if check_nvim_version; then
    print_warning "Neovim already installed ($(nvim --version | head -1))"
else
    print_info "Installing Neovim via AppImage..."

    # Download latest stable AppImage
    NVIM_APPIMAGE="$NVIM_BIN_DIR/nvim.appimage"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage" -o "$NVIM_APPIMAGE"
    chmod +x "$NVIM_APPIMAGE"

    # Create symlink
    ln -sf "$NVIM_APPIMAGE" "$NVIM_BIN_DIR/nvim"

    print_info "Neovim installed: $($NVIM_BIN_DIR/nvim --version | head -1)"
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
