#!/bin/bash
# install/notion.sh - Notion desktop app

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="notion"

install_notion() {
    ensure_homebrew

    if is_macos; then
        pkg_install_cask notion
        return
    fi

    # Linux: AppImage from notion-repackaged
    local notion_dir="$XDG_DATA_HOME/notion"
    local appimage="$notion_dir/notion.AppImage"
    local bin_dir="$HOME/.local/bin"

    mkdir -p "$notion_dir" "$bin_dir"

    if [[ -f "$appimage" ]]; then
        print_ok "Notion already installed"
        return
    fi

    local url
    url=$(get_github_release_url "notion-enhancer/notion-repackaged" "\.AppImage$") || {
        print_error "Failed to fetch download URL"
        exit 1
    }

    download_verified "$url" "$appimage"
    chmod +x "$appimage"
    ln -sf "$appimage" "$bin_dir/notion"

    create_desktop_entry "Notion" "$appimage" "notion" "Office;Productivity"
    print_ok "Notion installed"
}

post_install() {
    echo ""
    print_info "Notion setup complete!"
    if is_macos; then
        echo "  Launch from Applications or Spotlight"
    else
        echo "  Run: notion"
    fi
}

main() {
    echo "==> Installing $NAME"
    install_notion
    post_install
    echo "==> Done"
}

main "$@"
