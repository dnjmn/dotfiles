#!/bin/bash

# Claude Code Configuration Setup
# Symlinks Claude configs from dotfiles to ~/.claude/
#
# Version Controlled:
#   - CLAUDE.md      → User instructions/memory
#   - settings.json  → User settings
#   - agents/        → Custom subagents
#   - commands/      → Custom slash commands
#   - skills/        → Custom skills
#   - rules/         → Path-scoped rules
#   - hooks/         → Hook scripts
#
# NOT Version Controlled (in ~/.claude/):
#   - .credentials.json, history.jsonl, projects/, debug/, etc.
#   - MCP servers (stored in ~/.claude.json, use ./mcp-install.sh)
#
# For MCP servers: run ./mcp-install.sh after this script

set -euo pipefail

echo "======================================"
echo "Claude Code Setup"
echo "======================================"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

print_info "Source: $SCRIPT_DIR"
print_info "Target: $CLAUDE_HOME"
echo ""

# Check Claude Code installation
print_step "Checking Claude Code..."
if command -v claude &>/dev/null; then
    print_info "Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
    print_warn "Claude Code not found - install from: https://claude.ai/download"
fi

# Create ~/.claude if needed
mkdir -p "$CLAUDE_HOME"

# Backup existing files/dirs that aren't symlinks
backup_if_needed() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        print_warn "Backed up: $target → $backup"
    fi
}

# Symlink a file
link_file() {
    local src="$1"
    local dest="$2"
    [ -f "$src" ] || return 0
    backup_if_needed "$dest"
    ln -sf "$src" "$dest"
    print_info "Linked: $(basename "$dest")"
}

# Symlink a directory
link_dir() {
    local src="$1"
    local dest="$2"
    # Only link if source dir exists
    [ -d "$src" ] || return 0
    backup_if_needed "$dest"
    rm -f "$dest" 2>/dev/null || true  # Remove existing symlink
    ln -sf "$src" "$dest"
    print_info "Linked: $(basename "$dest")/"
}

# Link configurations
print_step "Linking configurations..."

# Core config files
link_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
link_file "$SCRIPT_DIR/settings.json" "$CLAUDE_HOME/settings.json"

# Directories
link_dir "$SCRIPT_DIR/agents" "$CLAUDE_HOME/agents"
link_dir "$SCRIPT_DIR/commands" "$CLAUDE_HOME/commands"
link_dir "$SCRIPT_DIR/skills" "$CLAUDE_HOME/skills"
link_dir "$SCRIPT_DIR/rules" "$CLAUDE_HOME/rules"
link_dir "$SCRIPT_DIR/hooks" "$CLAUDE_HOME/hooks"

# Summary
echo ""
echo "======================================"
print_info "Claude Code setup complete!"
echo "======================================"
echo ""
echo "Linked configs:"
[ -L "$CLAUDE_HOME/CLAUDE.md" ] && echo "  - CLAUDE.md (user instructions)"
[ -L "$CLAUDE_HOME/settings.json" ] && echo "  - settings.json (user settings)"
[ -L "$CLAUDE_HOME/agents" ] && echo "  - agents/ (custom subagents)"
[ -L "$CLAUDE_HOME/commands" ] && echo "  - commands/ (slash commands)"
[ -L "$CLAUDE_HOME/skills" ] && echo "  - skills/ (custom skills)"
[ -L "$CLAUDE_HOME/rules" ] && echo "  - rules/ (path-scoped rules)"
[ -L "$CLAUDE_HOME/hooks" ] && echo "  - hooks/ (hook scripts)"
echo ""
print_info "For MCP servers, run: ./mcp-install.sh"
