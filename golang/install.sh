#!/bin/bash

# Go Installation Script with XDG Base Directory Support
# Cross-platform: macOS and Linux (via Homebrew/Linuxbrew)
# Installs Go toolchain and common development tools

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Go Setup Script (XDG Compliant)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Go directories (fully XDG-compliant)
# GOPATH: XDG_DATA_HOME/go for full XDG compliance
# GOBIN: ~/.local/bin so binaries are in PATH
# GOCACHE/GOMODCACHE: XDG cache locations
GO_PATH="$XDG_DATA_HOME/go"
GO_BIN="$HOME/.local/bin"
GO_CACHE="$XDG_CACHE_HOME/go-build"
GO_MOD_CACHE="$XDG_CACHE_HOME/go/mod"
GO_ENV="$XDG_CONFIG_HOME/go/env"

print_info "Using directory structure:"
echo "  • GOPATH:     $GO_PATH"
echo "  • GOBIN:      $GO_BIN"
echo "  • GOCACHE:    $GO_CACHE"
echo "  • GOMODCACHE: $GO_MOD_CACHE"
echo "  • GOENV:      $GO_ENV"
echo ""

# Ensure Homebrew is available
print_info "Ensuring Homebrew is available..."
ensure_homebrew
if ! init_brew; then
    print_warn "Brew not initialized in current session - may need manual setup"
fi

# Create necessary directories
print_step "Creating directory structure..."
mkdir -p "$GO_PATH"/{bin,pkg,src}
mkdir -p "$GO_BIN"
mkdir -p "$GO_CACHE"
mkdir -p "$GO_MOD_CACHE"
mkdir -p "$(dirname "$GO_ENV")"
print_ok "Directories created"

# 1. Install Go
print_step "Installing Go..."
if command -v go &>/dev/null; then
    print_warn "Go is already installed ($(go version | cut -d' ' -f3))"
else
    pkg_install go
    print_ok "Go installed"
fi

# Initialize Go environment for this session
export GOPATH="$GO_PATH"
export GOBIN="$GO_BIN"
export GOCACHE="$GO_CACHE"
export GOMODCACHE="$GO_MOD_CACHE"
export PATH="$GO_BIN:$GOPATH/bin:$PATH"

# 2. Create Go environment file
print_step "Creating Go environment file..."
cat > "$GO_ENV" << 'EOF'
# Go environment - managed by dotfiles
# Fully XDG-compliant paths
GOPATH=$HOME/.local/share/go
GOBIN=$HOME/.local/bin
GOCACHE=$HOME/.cache/go-build
GOMODCACHE=$HOME/.cache/go/mod
EOF
print_ok "Created $GO_ENV"

# 3. Install common Go tools
print_step "Installing Go development tools..."

GO_TOOLS=(
    "golang.org/x/tools/gopls@latest"           # Language server
    "github.com/go-delve/delve/cmd/dlv@latest"  # Debugger
    "golang.org/x/tools/cmd/goimports@latest"   # Import formatter
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"  # Linter
    "github.com/fatih/gomodifytags@latest"      # Struct tag modifier
    "github.com/josharian/impl@latest"          # Interface implementation generator
    "github.com/cweill/gotests/gotests@latest"  # Test generator
)

for tool in "${GO_TOOLS[@]}"; do
    tool_name=$(basename "${tool%@*}")
    if command -v "$tool_name" &>/dev/null; then
        print_ok "$tool_name already installed"
    else
        print_info "Installing $tool_name..."
        if go install "$tool" 2>/dev/null; then
            print_ok "$tool_name installed"
        else
            print_warn "Failed to install $tool_name (non-critical)"
        fi
    fi
done

# 4. Link zsh config if it exists
ZSH_CONFIG_DIR="$XDG_CONFIG_HOME/zsh/config"
if [[ -d "$ZSH_CONFIG_DIR" && -f "$SCRIPT_DIR/../zsh/config/golang.zsh" ]]; then
    print_step "Linking zsh Go configuration..."
    # The zsh installer handles this, but ensure the file is in place
    if [[ -f "$ZSH_CONFIG_DIR/golang.zsh" ]]; then
        print_ok "Go zsh config already exists"
    else
        symlink_with_backup "$REPO_DIR/zsh/config/golang.zsh" "$ZSH_CONFIG_DIR/golang.zsh"
    fi
fi

# 5. Summary
echo ""
echo "======================================"
print_ok "Go setup complete!"
echo "======================================"
echo ""
print_info "Installed components:"
echo "  • Go: $(go version | cut -d' ' -f3)"
echo "  • gopls (LSP)"
echo "  • dlv (debugger)"
echo "  • goimports"
echo "  • golangci-lint"
echo "  • gomodifytags"
echo "  • impl"
echo "  • gotests"
echo ""
print_info "Directory structure:"
echo "  • GOPATH:     $GO_PATH"
echo "  • GOBIN:      $GO_BIN (binaries here)"
echo "  • Modules:    $GO_MOD_CACHE"
echo "  • Cache:      $GO_CACHE"
echo ""
print_info "Next steps:"
echo "  1. Restart shell or: source ~/.config/zsh/.zshrc"
echo "  2. Verify: go version"
echo "  3. Create project: mkdir -p ~/.local/share/go/src/myproject && cd \$_ && go mod init"
echo ""
print_info "Useful commands:"
echo "  • gomod      - Initialize Go module"
echo "  • gotest     - Run tests with coverage"
echo "  • gobuild    - Build current package"
echo "  • golint     - Run golangci-lint"
echo ""
