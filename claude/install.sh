#!/bin/bash

# Claude Code Configuration Setup
# Symlinks ~/.claude to config directory in this repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_HOME="$HOME/.claude"
CONFIG_DIR="$SCRIPT_DIR/config"

source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Claude Code Setup"
echo "======================================"
echo ""

# Check Claude Code installation
if command -v claude &>/dev/null; then
    print_info "Claude Code installed"
else
    print_warn "Claude Code not found - install from: https://claude.ai/download"
fi

# Symlink ~/.claude → config/
print_info "Linking $CLAUDE_HOME → $CONFIG_DIR"
symlink_with_backup "$CONFIG_DIR" "$CLAUDE_HOME"

echo ""
print_info "Claude Code setup complete!"
echo ""
