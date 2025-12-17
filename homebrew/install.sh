#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper (provides print_*, ensure_homebrew, etc.)
source "$REPO_DIR/lib/platform.sh"

# Print platform info
print_platform_info

# macOS prerequisite: Xcode CLI tools
if is_macos; then
    ensure_xcode_cli
fi

# Install Homebrew/Linuxbrew
ensure_homebrew
init_brew || true

# Install all packages from Brewfile
print_step "Installing packages from Brewfile..."
if is_macos; then
    brew bundle --file="$SCRIPT_DIR/Brewfile"
else
    # Linux: Skip casks, install only brews
    brew bundle --file="$SCRIPT_DIR/Brewfile" --no-cask
fi

print_ok "Homebrew setup complete!"
brew --version
