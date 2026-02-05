#!/bin/bash
# install/zsh.sh - Zsh shell with Oh My Zsh, Powerlevel10k, and plugins

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="zsh"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly DEPS=(zsh fzf fd bat tree)

# Oh My Zsh and plugin locations
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

install_deps() {
    ensure_homebrew
    for dep in "${DEPS[@]}"; do
        pkg_install "$dep"
    done
}

setup_xdg_dirs() {
    mkdir -p "$XDG_CONFIG_HOME/zsh"
    mkdir -p "$XDG_CACHE_HOME/zsh"
    mkdir -p "$XDG_CACHE_HOME/oh-my-zsh"
    mkdir -p "$XDG_STATE_HOME/zsh"
}

setup_zdotdir() {
    # ~/.zshenv points ZDOTDIR to our config
    if [[ -f "$CONFIG_DIR/home-zshenv" ]]; then
        if [[ -f "$HOME/.zshenv" ]] && cmp -s "$CONFIG_DIR/home-zshenv" "$HOME/.zshenv"; then
            print_ok "~/.zshenv already configured"
        else
            [[ -f "$HOME/.zshenv" ]] && mv "$HOME/.zshenv" "$HOME/.zshenv.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CONFIG_DIR/home-zshenv" "$HOME/.zshenv"
            print_ok "Created ~/.zshenv (ZDOTDIR=$CONFIG_DIR)"
        fi
    fi
}

setup_secrets_template() {
    local secrets_file="$XDG_CONFIG_HOME/zsh/env.zsh"
    if [[ ! -f "$secrets_file" && -f "$CONFIG_DIR/xdg-env-template.zsh" ]]; then
        cp "$CONFIG_DIR/xdg-env-template.zsh" "$secrets_file"
        print_ok "Created secrets template: $secrets_file"
    fi
}

install_ohmyzsh() {
    if [[ -d "$ZSH" ]]; then
        print_ok "Oh My Zsh already installed"
        return
    fi
    RUNZSH=no ZSH="$ZSH" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_ok "Oh My Zsh installed to $ZSH"
}

install_plugins() {
    local plugins=(
        "powerlevel10k|https://github.com/romkatv/powerlevel10k.git|themes/powerlevel10k"
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions|plugins/zsh-autosuggestions"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git|plugins/zsh-syntax-highlighting"
        "zsh-completions|https://github.com/zsh-users/zsh-completions|plugins/zsh-completions"
        "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search|plugins/zsh-history-substring-search"
    )

    for plugin in "${plugins[@]}"; do
        IFS='|' read -r name url path <<< "$plugin"
        local target="$ZSH_CUSTOM/$path"
        if [[ -d "$target" ]]; then
            print_ok "$name already installed"
        else
            git clone --depth=1 "$url" "$target"
            print_ok "$name installed"
        fi
    done
}

set_default_shell() {
    if [[ "$SHELL" == *zsh ]]; then
        print_ok "zsh is already default shell"
        return
    fi
    if chsh -s "$(which zsh)" 2>/dev/null; then
        print_ok "Default shell changed to zsh"
    else
        print_warn "Run manually: chsh -s $(which zsh)"
    fi
}

post_install() {
    echo ""
    print_info "Zsh setup complete!"
    echo "  ZDOTDIR:  $CONFIG_DIR"
    echo "  Oh My Zsh: $ZSH"
    echo "  Secrets:  $XDG_CONFIG_HOME/zsh/env.zsh"
    echo ""
    echo "Next: Log out/in or run 'exec zsh'"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    setup_xdg_dirs
    setup_zdotdir
    setup_secrets_template
    install_ohmyzsh
    install_plugins
    set_default_shell
    post_install
    echo "==> Done"
}

main "$@"
