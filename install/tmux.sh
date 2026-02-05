#!/bin/bash
# install/tmux.sh - Terminal multiplexer with TPM plugin manager

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="tmux"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly DEPS=(tmux)
readonly TMUX_XDG_DIR="$XDG_CONFIG_HOME/tmux"
readonly TPM_DIR="$XDG_DATA_HOME/tmux/plugins/tpm"

install_deps() {
    ensure_homebrew
    for dep in "${DEPS[@]}"; do
        pkg_install "$dep"
    done
}

link_configs() {
    mkdir -p "$TMUX_XDG_DIR"
    symlink_with_backup "$CONFIG_DIR/tmux.conf" "$TMUX_XDG_DIR/tmux.conf"
    symlink_with_backup "$CONFIG_DIR/statusline.conf" "$TMUX_XDG_DIR/statusline.conf"
}

install_tpm() {
    if [[ -d "$TPM_DIR" ]]; then
        print_ok "TPM already installed"
        return
    fi
    mkdir -p "$(dirname "$TPM_DIR")"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    print_ok "TPM installed to $TPM_DIR"
}

post_install() {
    echo ""
    print_info "Tmux setup complete!"
    echo "  Config: $TMUX_XDG_DIR/tmux.conf"
    echo "  Plugins: $XDG_DATA_HOME/tmux/plugins"
    echo ""
    echo "Next: Start tmux, press Prefix+I to install plugins"
    echo "Prefix is Ctrl+a"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    link_configs
    install_tpm
    post_install
    echo "==> Done"
}

main "$@"
