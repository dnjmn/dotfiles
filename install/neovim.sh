#!/bin/bash
# install/neovim.sh - Neovim with LazyVim configuration

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="neovim"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly DEPS=(ripgrep fd git curl unzip neovim)
readonly NVIM_XDG_DIR="$XDG_CONFIG_HOME/nvim"
readonly NVIM_DATA_DIR="$XDG_DATA_HOME/nvim"

install_deps() {
    ensure_homebrew
    for dep in "${DEPS[@]}"; do
        pkg_install "$dep"
    done
}

setup_dirs() {
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$NVIM_DATA_DIR"
    mkdir -p "$XDG_STATE_HOME/nvim"
    mkdir -p "$XDG_CACHE_HOME/nvim"
}

link_configs() {
    # Symlink entire config directory
    symlink_with_backup "$CONFIG_DIR" "$NVIM_XDG_DIR"
}

install_lazy() {
    local lazy_dir="$NVIM_DATA_DIR/lazy/lazy.nvim"
    if [[ -d "$lazy_dir" ]]; then
        print_ok "lazy.nvim already installed"
        return
    fi
    git clone --filter=blob:none --branch=stable \
        https://github.com/folke/lazy.nvim.git "$lazy_dir"
    print_ok "lazy.nvim installed"
}

sync_plugins() {
    print_info "Syncing plugins..."
    nvim --headless "+Lazy! sync" +qa 2>&1 || print_warn "Run ':Lazy sync' manually if needed"
}

post_install() {
    echo ""
    print_info "Neovim setup complete!"
    echo "  Config: $NVIM_XDG_DIR"
    echo "  Plugins: $NVIM_DATA_DIR/lazy/"
    echo ""
    echo "Run 'nvim' then ':checkhealth' to verify"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    setup_dirs
    link_configs
    install_lazy
    sync_plugins
    post_install
    echo "==> Done"
}

main "$@"
