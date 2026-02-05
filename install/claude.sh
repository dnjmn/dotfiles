#!/bin/bash
# install/claude.sh - Claude Code CLI configuration

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="claude"
readonly CONFIG_DIR="$REPO_ROOT/config/$NAME"
readonly CLAUDE_HOME="$HOME/.claude"

check_installation() {
    if command -v claude &>/dev/null; then
        print_ok "Claude Code installed"
    else
        print_warn "Claude Code not found - install from: https://claude.ai/download"
    fi
}

link_configs() {
    symlink_with_backup "$CONFIG_DIR" "$CLAUDE_HOME"
}

post_install() {
    echo ""
    print_info "Claude Code setup complete!"
    echo "  Config: $CLAUDE_HOME -> $CONFIG_DIR"
    echo ""
    echo "Custom plugins in: $CONFIG_DIR/plugins/local/"
}

main() {
    echo "==> Installing $NAME"
    check_installation
    link_configs
    post_install
    echo "==> Done"
}

main "$@"
