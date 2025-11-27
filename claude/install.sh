#!/bin/bash

# Claude Code Configuration Setup
# Symlinks Claude configs from dotfiles to ~/.claude/
# Date: 2025-11-27

set -euo pipefail

echo "======================================"
echo "Claude Code Setup"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

print_info "Source: $SCRIPT_DIR"
print_info "Target: $CLAUDE_HOME"
echo ""

# Check Claude Code installation
print_step "Checking Claude Code..."
if command -v claude &>/dev/null; then
    print_info "Claude Code installed"
else
    print_warning "Claude Code not found - install from: https://claude.ai/download"
fi

# Create ~/.claude if needed
mkdir -p "$CLAUDE_HOME"

# Backup helper
backup_if_needed() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        print_warning "Backed up: $target → $backup"
    fi
}

# Symlink file
link_file() {
    local src="$1"
    local dest="$2"
    [ -f "$src" ] || return 0
    backup_if_needed "$dest"
    ln -sf "$src" "$dest"
    print_info "Linked: $(basename "$dest")"
}

# Symlink directory (entire directory as symlink)
link_dir() {
    local src="$1"
    local dest="$2"
    # Only link if source dir exists and has content
    [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ] || return 0
    backup_if_needed "$dest"
    rm -rf "$dest" 2>/dev/null || true
    ln -sf "$src" "$dest"
    print_info "Linked: $(basename "$dest")/"
}

# Link configs
print_step "Linking configurations..."

link_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
link_file "$SCRIPT_DIR/settings.json" "$CLAUDE_HOME/settings.json"
link_file "$SCRIPT_DIR/mcp.json" "$HOME/.mcp.json"
link_dir "$SCRIPT_DIR/agents" "$CLAUDE_HOME/agents"
link_dir "$SCRIPT_DIR/commands" "$CLAUDE_HOME/commands"
link_dir "$SCRIPT_DIR/skills" "$CLAUDE_HOME/skills"
link_dir "$SCRIPT_DIR/output-styles" "$CLAUDE_HOME/output-styles"

# Summary
echo ""
echo "======================================"
print_info "Claude Code setup complete!"
echo "======================================"
echo ""
print_info "Linked:"
[ -L "$CLAUDE_HOME/CLAUDE.md" ] && echo "  - CLAUDE.md"
[ -L "$CLAUDE_HOME/settings.json" ] && echo "  - settings.json"
[ -L "$HOME/.mcp.json" ] && echo "  - ~/.mcp.json (MCP servers)"
[ -L "$CLAUDE_HOME/agents" ] && echo "  - agents/"
[ -L "$CLAUDE_HOME/commands" ] && echo "  - commands/"
[ -L "$CLAUDE_HOME/skills" ] && echo "  - skills/"
[ -L "$CLAUDE_HOME/output-styles" ] && echo "  - output-styles/"
echo ""
