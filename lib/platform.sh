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
print_warning() { echo -e "\e[33m[WARN]\e[0m $1"; }
print_step() { echo -e "\e[36m[STEP]\e[0m $1"; }

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
    local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"

    # User-level XDG location (priority)
    if [[ -d "$xdg_data/homebrew" ]]; then
        echo "$xdg_data/homebrew"
        return
    fi

    # Fall back to system locations
    if is_macos; then
        if is_arm64 && [[ -d "/opt/homebrew" ]]; then
            echo "/opt/homebrew"
        elif [[ -d "/usr/local/Homebrew" ]]; then
            echo "/usr/local"
        else
            echo "$xdg_data/homebrew"
        fi
    else
        # Linux - Linuxbrew
        if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
            echo "/home/linuxbrew/.linuxbrew"
        else
            echo "$xdg_data/homebrew"
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
    local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
    local brew_prefix="$xdg_data/homebrew"
    local brew_bin="$brew_prefix/bin/brew"

    # Already in PATH?
    if command -v brew &>/dev/null; then
        print_ok "Homebrew already available at $(brew --prefix)"
        return 0
    fi

    # Already installed at XDG location?
    if [[ -x "$brew_bin" ]]; then
        print_ok "Homebrew installed at $brew_prefix"
        eval "$("$brew_bin" shellenv)"
        return 0
    fi

    # Check system locations (macOS)
    if is_macos; then
        if is_arm64 && [[ -x "/opt/homebrew/bin/brew" ]]; then
            print_ok "Using system Homebrew at /opt/homebrew"
            eval "$(/opt/homebrew/bin/brew shellenv)"
            return 0
        elif [[ -x "/usr/local/bin/brew" ]]; then
            print_ok "Using system Homebrew at /usr/local"
            eval "$(/usr/local/bin/brew shellenv)"
            return 0
        fi
    fi

    # Install to XDG location (user-level, no sudo)
    print_info "Installing Homebrew to $brew_prefix (user-level)..."
    mkdir -p "$xdg_data"
    git clone https://github.com/Homebrew/brew.git "$brew_prefix"

    eval "$("$brew_bin" shellenv)"
    brew update --force --quiet

    print_ok "Homebrew installed to $brew_prefix"
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

# =============================================================================
# File Operations - Defensive Shell Programming
# =============================================================================

# Symlink with backup - replaces duplicate implementations across scripts
# Usage: symlink_with_backup "/path/to/source" "/path/to/target"
symlink_with_backup() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        print_error "Source does not exist: $source"
        return 1
    fi

    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        print_warn "Backed up: $target → $backup"
    elif [[ -L "$target" ]]; then
        rm "$target"
    fi

    ln -sf "$source" "$target"
    print_ok "Linked: $target → $source"
}

# =============================================================================
# Download Operations - Trust but Verify
# =============================================================================

# Verified download with optional checksum
# Usage: download_verified "url" "dest" ["sha256_checksum"]
download_verified() {
    local url="$1"
    local dest="$2"
    local checksum="${3:-}"  # Optional SHA256

    print_info "Downloading: $url"
    if ! curl -fsSL --progress-bar -o "$dest" "$url"; then
        print_error "Download failed: $url"
        return 1
    fi

    if [[ -n "$checksum" ]]; then
        local actual
        if is_macos; then
            actual=$(shasum -a 256 "$dest" | cut -d' ' -f1)
        else
            actual=$(sha256sum "$dest" | cut -d' ' -f1)
        fi

        if [[ "$actual" != "$checksum" ]]; then
            print_error "Checksum mismatch!"
            print_error "Expected: $checksum"
            print_error "Actual:   $actual"
            rm -f "$dest"
            return 1
        fi
        print_ok "Checksum verified"
    else
        print_warn "No checksum provided - download unverified"
    fi
}

# Fetch latest GitHub release download URL
# Usage: get_github_release_url "owner/repo" "pattern"
# Example: get_github_release_url "neovim/neovim" "\.appimage$"
get_github_release_url() {
    local repo="$1"
    local pattern="$2"  # Regex pattern for asset name

    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local response

    if ! response=$(curl -fsSL "$api_url"); then
        print_error "Failed to fetch GitHub API: $api_url"
        return 1
    fi

    local url
    if command -v jq &>/dev/null; then
        url=$(echo "$response" | jq -r ".assets[] | select(.name | test(\"$pattern\"; \"i\")) | .browser_download_url" | head -1)
    else
        # Fallback without jq
        url=$(echo "$response" | grep -E "\"browser_download_url\".*$pattern" | \
            sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/' | head -1)
    fi

    if [[ -z "$url" ]]; then
        print_error "No asset matching '$pattern' found in $repo"
        return 1
    fi

    echo "$url"
}

# Get latest version tag from GitHub releases
# Usage: get_github_release_version "owner/repo"
get_github_release_version() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local response

    if ! response=$(curl -fsSL "$api_url"); then
        print_error "Failed to fetch GitHub API: $api_url"
        return 1
    fi

    local version
    if command -v jq &>/dev/null; then
        version=$(echo "$response" | jq -r '.tag_name' | sed 's/^v//')
    else
        version=$(echo "$response" | grep -E '"tag_name"' | \
            sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' | sed 's/^v//')
    fi

    if [[ -z "$version" || "$version" == "null" ]]; then
        print_error "Could not determine version from $repo"
        return 1
    fi

    echo "$version"
}

# =============================================================================
# Desktop Integration (Linux only)
# =============================================================================

# Create desktop entry for Linux applications
# Usage: create_desktop_entry "Name" "/path/to/exec" "/path/to/icon" ["categories"]
create_desktop_entry() {
    local name="$1"
    local exec="$2"
    local icon="$3"
    local categories="${4:-Utility}"

    if ! is_linux; then
        return 0  # Skip silently on macOS
    fi

    mkdir -p "$XDG_DATA_HOME/applications"

    # Convert name to lowercase for filename
    local filename
    filename=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    local desktop_file="$XDG_DATA_HOME/applications/${filename}.desktop"

    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$exec %U
Icon=$icon
Terminal=false
Categories=$categories;
StartupWMClass=$name
EOF

    # Update desktop database (non-critical)
    if command -v update-desktop-database &>/dev/null; then
        if ! update-desktop-database "$XDG_DATA_HOME/applications" 2>/dev/null; then
            print_warn "Desktop database update failed (non-critical)"
        fi
    fi

    print_ok "Desktop entry created: $desktop_file"
}
