#!/bin/bash
# install/obsidian.sh - Knowledge base and note-taking app

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="obsidian"

install_obsidian() {
    ensure_homebrew

    if is_macos; then
        pkg_install_cask obsidian
        return
    fi

    # Linux: AppImage
    local obsidian_dir="$XDG_DATA_HOME/obsidian"
    local appimage="$obsidian_dir/Obsidian.AppImage"
    local bin_dir="$HOME/.local/bin"

    mkdir -p "$obsidian_dir" "$bin_dir"

    if [[ -f "$appimage" ]]; then
        print_ok "Obsidian already installed"
        return
    fi

    pkg_install curl jq

    local version
    version=$(get_github_release_version "obsidianmd/obsidian-releases") || {
        print_error "Failed to fetch version"
        exit 1
    }

    local url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage"
    download_verified "$url" "$appimage"
    chmod +x "$appimage"
    ln -sf "$appimage" "$bin_dir/obsidian"

    create_desktop_entry "Obsidian" "$appimage" "obsidian" "Office;TextEditor"
    print_ok "Obsidian $version installed"
}

post_install() {
    echo ""
    print_info "Obsidian setup complete!"
    if is_macos; then
        echo "  Launch from Applications or Spotlight"
    else
        echo "  Run: obsidian"
    fi
}

main() {
    echo "==> Installing $NAME"
    install_obsidian
    post_install
    echo "==> Done"
}

main "$@"
