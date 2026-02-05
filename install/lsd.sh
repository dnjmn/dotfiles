#!/bin/bash
# install/lsd.sh - Modern ls replacement with icons and colors

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="lsd"
readonly DEPS=(lsd)
readonly LSD_CONFIG_DIR="$XDG_CONFIG_HOME/lsd"

install_deps() {
    ensure_homebrew

    if command -v lsd &>/dev/null; then
        print_ok "lsd already installed"
        return
    fi

    if is_macos; then
        pkg_install lsd
    else
        # Linux: try brew first, fallback to binary
        if pkg_install lsd 2>/dev/null; then
            return
        fi

        local version="v1.1.5"
        local arch=$(detect_arch)
        [[ "$arch" == "arm64" ]] && arch="aarch64"

        local url="https://github.com/lsd-rs/lsd/releases/download/${version}/lsd-${version}-${arch}-unknown-linux-gnu.tar.gz"
        local tmp_dir=$(mktemp -d)

        download_verified "$url" "$tmp_dir/lsd.tar.gz"
        tar -xzf "$tmp_dir/lsd.tar.gz" -C "$tmp_dir"
        cp "$tmp_dir"/lsd-*/lsd "$HOME/.local/bin/lsd"
        chmod +x "$HOME/.local/bin/lsd"
        rm -rf "$tmp_dir"
    fi
}

setup_config() {
    mkdir -p "$LSD_CONFIG_DIR"
    [[ -f "$LSD_CONFIG_DIR/config.yaml" ]] && return

    cat > "$LSD_CONFIG_DIR/config.yaml" << 'EOF'
color:
  theme: default
icons:
  when: auto
  theme: fancy
sorting:
  dir-grouping: first
EOF
    print_ok "Created config"
}

post_install() {
    echo ""
    print_info "LSD setup complete!"
    echo "  Config: $LSD_CONFIG_DIR/config.yaml"
    echo "  Usage: lsd, lsd -la, lsd --tree"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    setup_config
    post_install
    echo "==> Done"
}

main "$@"
