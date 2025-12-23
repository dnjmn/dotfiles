#!/bin/bash

# MCP Server Installation for Claude Code
# Run this after `install.sh` to add user-level MCP servers
#
# Note: User-level MCP servers are stored in ~/.claude.json
# This file contains sensitive data (sessions, caches) - NOT version controlled
# This script uses `claude mcp add --scope user` to add servers

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Claude Code
if ! command -v claude &>/dev/null; then
    print_error "Claude Code not installed"
    exit 1
fi

echo "======================================"
echo "MCP Server Setup (User Scope)"
echo "======================================"
echo ""

# Add MCP servers (user scope - available in all projects)
# Modify this section to add your preferred MCP servers

print_info "Adding Notion MCP server..."
claude mcp add notion --scope user --transport sse https://mcp.notion.com/sse 2>/dev/null || print_warn "Notion MCP already exists or failed"

print_info "Adding Playwright MCP server..."
claude mcp add playwright --scope user -- npx @anthropic-ai/mcp-server-playwright 2>/dev/null || print_warn "Playwright MCP already exists or failed"

# Uncomment to add more servers:
# print_info "Adding GitHub MCP server..."
# claude mcp add github --scope user --transport http https://api.githubcopilot.com/mcp/

# print_info "Adding filesystem MCP server..."
# claude mcp add filesystem --scope user -- npx -y @anthropic-ai/mcp-server-filesystem ~/Documents

echo ""
print_info "MCP servers configured. Run 'claude mcp list' to verify."
print_info "Use '/mcp' in Claude Code to authenticate servers that need it."
