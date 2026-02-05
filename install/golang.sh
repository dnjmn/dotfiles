#!/bin/bash
# install/golang.sh - Go toolchain with development tools

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="golang"
readonly DEPS=(go)

# XDG-compliant Go paths
readonly GO_PATH="$XDG_DATA_HOME/go"
readonly GO_BIN="$HOME/.local/bin"
readonly GO_CACHE="$XDG_CACHE_HOME/go-build"
readonly GO_MOD_CACHE="$XDG_CACHE_HOME/go/mod"
readonly GO_ENV="$XDG_CONFIG_HOME/go/env"

install_deps() {
    ensure_homebrew
    for dep in "${DEPS[@]}"; do
        pkg_install "$dep"
    done
}

setup_dirs() {
    mkdir -p "$GO_PATH"/{bin,pkg,src}
    mkdir -p "$GO_BIN"
    mkdir -p "$GO_CACHE"
    mkdir -p "$GO_MOD_CACHE"
    mkdir -p "$(dirname "$GO_ENV")"
}

create_env_file() {
    cat > "$GO_ENV" << 'EOF'
GOPATH=$HOME/.local/share/go
GOBIN=$HOME/.local/bin
GOCACHE=$HOME/.cache/go-build
GOMODCACHE=$HOME/.cache/go/mod
EOF
    print_ok "Created $GO_ENV"
}

install_tools() {
    export GOPATH="$GO_PATH" GOBIN="$GO_BIN" GOCACHE="$GO_CACHE" GOMODCACHE="$GO_MOD_CACHE"
    export PATH="$GO_BIN:$PATH"

    local tools=(
        "golang.org/x/tools/gopls@latest"
        "github.com/go-delve/delve/cmd/dlv@latest"
        "golang.org/x/tools/cmd/goimports@latest"
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    )

    for tool in "${tools[@]}"; do
        local name=$(basename "${tool%@*}")
        if command -v "$name" &>/dev/null; then
            print_ok "$name installed"
        else
            go install "$tool" 2>/dev/null && print_ok "$name installed" || print_warn "Failed: $name"
        fi
    done
}

post_install() {
    echo ""
    print_info "Go setup complete!"
    echo "  GOPATH: $GO_PATH"
    echo "  GOBIN:  $GO_BIN"
    echo ""
    echo "Restart shell or: source ~/.config/zsh/.zshrc"
}

main() {
    echo "==> Installing $NAME"
    install_deps
    setup_dirs
    create_env_file
    install_tools
    post_install
    echo "==> Done"
}

main "$@"
