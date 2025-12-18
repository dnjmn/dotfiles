#!/bin/bash

# Claude Code Configuration Setup
# Symlinks Claude configs from dotfiles to ~/.claude/
# Date: 2025-11-27

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_HOME="$HOME/.claude"

# Source platform helper for symlink_with_backup
source "$REPO_DIR/lib/platform.sh"

# Additional print function not in platform.sh
print_step() { echo -e "\e[34m[STEP]\e[0m $1"; }

echo "======================================"
echo "Claude Code Setup"
echo "======================================"
echo ""

print_info "Source: $SCRIPT_DIR"
print_info "Target: $CLAUDE_HOME"
echo ""

# Check Claude Code installation
print_step "Checking Claude Code..."
if command -v claude &>/dev/null; then
    print_info "Claude Code installed"
else
    print_warn "Claude Code not found - install from: https://claude.ai/download"
fi

# Create ~/.claude if needed
mkdir -p "$CLAUDE_HOME"

# Link if source exists (uses symlink_with_backup from platform.sh)
link_if_exists() {
    local src="$1"
    local dest="$2"
    if [ -e "$src" ]; then
        symlink_with_backup "$src" "$dest"
    fi
}

# Link configs
print_step "Linking configurations..."

link_if_exists "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
link_if_exists "$SCRIPT_DIR/settings.json" "$CLAUDE_HOME/settings.json"
link_if_exists "$SCRIPT_DIR/statusline.sh" "$CLAUDE_HOME/statusline.sh"
link_if_exists "$SCRIPT_DIR/agents" "$CLAUDE_HOME/agents"
link_if_exists "$SCRIPT_DIR/commands" "$CLAUDE_HOME/commands"
link_if_exists "$SCRIPT_DIR/skills" "$CLAUDE_HOME/skills"
link_if_exists "$SCRIPT_DIR/output-styles" "$CLAUDE_HOME/output-styles"

# Link custom plugins
print_step "Linking custom plugins..."
mkdir -p "$CLAUDE_HOME/plugins/local"
link_if_exists "$SCRIPT_DIR/plugins/dnjmn-workflows" "$CLAUDE_HOME/plugins/local/dnjmn-workflows"

# Summary
echo ""
echo "======================================"
print_info "Claude Code setup complete!"
echo "======================================"
echo ""
print_info "Linked:"
[ -L "$CLAUDE_HOME/CLAUDE.md" ] && echo "  - CLAUDE.md"
[ -L "$CLAUDE_HOME/settings.json" ] && echo "  - settings.json"
[ -L "$CLAUDE_HOME/statusline.sh" ] && echo "  - statusline.sh"
[ -L "$CLAUDE_HOME/agents" ] && echo "  - agents/"
[ -L "$CLAUDE_HOME/commands" ] && echo "  - commands/"
[ -L "$CLAUDE_HOME/skills" ] && echo "  - skills/"
[ -L "$CLAUDE_HOME/output-styles" ] && echo "  - output-styles/"
[ -L "$CLAUDE_HOME/plugins/local/dnjmn-workflows" ] && echo "  - plugins/local/dnjmn-workflows/"
echo ""
