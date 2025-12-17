#!/bin/bash
# Platform detection and package manager abstraction
# Source this file in install scripts: source "$(dirname "$0")/../lib/platform.sh"

set -euo pipefail

# =============================================================================
# Colors (consistent with existing scripts)
# =============================================================================
print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
print_ok() { echo -e "\e[32m[OK]\e[0m $1"; }
print_error() { echo -e "\e[31m[ERROR]\e[0m $1"; }
print_warn() { echo -e "\e[33m[WARN]\e[0m $1"; }

# =============================================================================
# OS Detection
# =============================================================================
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "darwin" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

is_macos() {
    [[ "$(detect_os)" == "darwin" ]]
}

is_linux() {
    [[ "$(detect_os)" == "linux" ]]
}

# =============================================================================
# Architecture Detection
# =============================================================================
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  echo "x86_64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       echo "$arch" ;;
    esac
}

is_arm64() {
    [[ "$(detect_arch)" == "arm64" ]]
}

is_x86_64() {
    [[ "$(detect_arch)" == "x86_64" ]]
}

# =============================================================================
# Homebrew Paths
# =============================================================================
get_brew_prefix() {
    if is_macos; then
        if is_arm64; then
            echo "/opt/homebrew"
        else
            echo "/usr/local"
        fi
    else
        # Linux - Linuxbrew
        if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
            echo "/home/linuxbrew/.linuxbrew"
        else
            echo "$HOME/.linuxbrew"
        fi
    fi
}

get_brew_bin() {
    echo "$(get_brew_prefix)/bin/brew"
}

# =============================================================================
# Homebrew/Linuxbrew Installation
# =============================================================================
ensure_xcode_cli() {
    if ! is_macos; then
        return 0
    fi

    if xcode-select -p &>/dev/null; then
        print_ok "Xcode Command Line Tools already installed"
        return 0
    fi

    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true

    # Wait for installation
    print_info "Waiting for Xcode CLI tools installation to complete..."
    print_info "Please complete the installation dialog if it appears."

    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    print_ok "Xcode Command Line Tools installed"
}

ensure_homebrew() {
    local brew_bin
    brew_bin="$(get_brew_bin)"

    if [[ -x "$brew_bin" ]]; then
        print_ok "Homebrew already installed at $brew_bin"
        return 0
    fi

    print_info "Installing Homebrew..."

    # Homebrew installer works for both macOS and Linux
    # It installs to user-level location (no sudo required on macOS)
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Verify installation
    brew_bin="$(get_brew_bin)"
    if [[ -x "$brew_bin" ]]; then
        print_ok "Homebrew installed successfully"
        # Add to current shell session
        eval "$("$brew_bin" shellenv)"
    else
        print_error "Homebrew installation failed"
        return 1
    fi
}

ensure_linuxbrew() {
    if ! is_linux; then
        return 0
    fi
    ensure_homebrew
}

# Initialize brew in current session if available
init_brew() {
    local brew_bin
    brew_bin="$(get_brew_bin)"
    if [[ -x "$brew_bin" ]]; then
        eval "$("$brew_bin" shellenv)"
        return 0
    fi
    return 1
}

# =============================================================================
# Package Manager Abstraction
# =============================================================================
pkg_update() {
    if ! command -v brew &>/dev/null; then
        if ! init_brew; then
            print_error "Homebrew not found. Run ensure_homebrew first."
            return 1
        fi
    fi
    print_info "Updating Homebrew..."
    brew update
}

pkg_install() {
    if ! command -v brew &>/dev/null; then
        if ! init_brew; then
            print_error "Homebrew not found. Run ensure_homebrew first."
            return 1
        fi
    fi

    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            print_ok "$pkg already installed"
        else
            print_info "Installing $pkg..."
            brew install "$pkg"
        fi
    done
}

pkg_install_cask() {
    if ! is_macos; then
        print_warn "Cask installation only available on macOS"
        return 1
    fi

    if ! command -v brew &>/dev/null; then
        if ! init_brew; then
            print_error "Homebrew not found. Run ensure_homebrew first."
            return 1
        fi
    fi

    local casks=("$@")
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            print_ok "$cask already installed"
        else
            print_info "Installing $cask..."
            brew install --cask "$cask"
        fi
    done
}

has_package() {
    local pkg="$1"
    if command -v brew &>/dev/null || init_brew; then
        brew list "$pkg" &>/dev/null
    else
        return 1
    fi
}

has_cask() {
    local cask="$1"
    if is_macos && (command -v brew &>/dev/null || init_brew); then
        brew list --cask "$cask" &>/dev/null
    else
        return 1
    fi
}

# =============================================================================
# Path Helpers
# =============================================================================
get_font_dir() {
    if is_macos; then
        echo "$HOME/Library/Fonts"
    else
        echo "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    fi
}

get_app_dir() {
    if is_macos; then
        echo "/Applications"
    else
        echo "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    fi
}

get_bin_dir() {
    echo "$HOME/.local/bin"
}

# Ensure user bin directory exists and is in PATH
ensure_bin_dir() {
    local bin_dir
    bin_dir="$(get_bin_dir)"
    mkdir -p "$bin_dir"

    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
    fi
}

# =============================================================================
# XDG Base Directory defaults
# =============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# =============================================================================
# Platform Info Display
# =============================================================================
print_platform_info() {
    local os arch brew_prefix
    os="$(detect_os)"
    arch="$(detect_arch)"
    brew_prefix="$(get_brew_prefix)"

    echo ""
    echo "Platform Information:"
    echo "  OS:           $os"
    echo "  Architecture: $arch"
    echo "  Brew prefix:  $brew_prefix"
    echo ""
}
