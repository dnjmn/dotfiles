#!/bin/bash

# Zsh Installation Script with XDG Base Directory Support
# Cross-platform: macOS and Linux (via Homebrew/Linuxbrew)
# This script installs and configures zsh with Oh My Zsh, Powerlevel10k, and useful plugins
# Everything follows XDG Base Directory specification to keep home directory clean
# Date: 2025-11-07

set -euo pipefail  # Fail fast: exit on error, undefined vars, pipe failures

# Get script directory (where this install.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Zsh Setup Script (XDG Compliant)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Set Oh My Zsh install location to XDG_DATA_HOME
export ZSH="$XDG_DATA_HOME/oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

print_info "Using XDG directory structure:"
echo "  • XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
echo "  • XDG_DATA_HOME: $XDG_DATA_HOME"
echo "  • XDG_CACHE_HOME: $XDG_CACHE_HOME"
echo "  • XDG_STATE_HOME: $XDG_STATE_HOME"
echo "  • Oh My Zsh: $ZSH"
echo "  • ZDOTDIR: $SCRIPT_DIR"
echo ""

# Ensure Homebrew is available
print_info "Ensuring Homebrew is available..."
ensure_homebrew
if ! init_brew; then
    print_warn "Brew not initialized in current session - may need manual setup"
fi

# Create necessary XDG directories
print_step "Creating XDG directory structure..."
mkdir -p "$XDG_CONFIG_HOME/zsh"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$XDG_CACHE_HOME/oh-my-zsh"
mkdir -p "$XDG_STATE_HOME/zsh"
print_info "XDG directories created"

# 1. Install zsh
print_step "Installing zsh package..."
if command -v zsh &> /dev/null; then
    print_warning "zsh is already installed ($(zsh --version))"
else
    pkg_install zsh
    print_info "zsh installed: $(zsh --version)"
fi

# 2. Set up ZDOTDIR by creating ~/.zshenv
print_step "Setting up ZDOTDIR..."
if [ -f "$SCRIPT_DIR/home-zshenv" ]; then
    if [ -f "$HOME/.zshenv" ] && cmp -s "$SCRIPT_DIR/home-zshenv" "$HOME/.zshenv"; then
        print_warning "~/.zshenv is already up to date"
    else
        # Backup existing .zshenv if it exists and differs
        if [ -f "$HOME/.zshenv" ]; then
            cp "$HOME/.zshenv" "$HOME/.zshenv.backup.$(date +%Y%m%d_%H%M%S)"
            print_warning "Backed up existing ~/.zshenv"
        fi
        cp "$SCRIPT_DIR/home-zshenv" "$HOME/.zshenv"
        print_info "Created ~/.zshenv (sets ZDOTDIR to $SCRIPT_DIR)"
    fi
else
    print_error "home-zshenv template not found in $SCRIPT_DIR"
    exit 1
fi

# 3. Create XDG secret env file if it doesn't exist
print_step "Setting up secret environment variables file..."
if [ ! -f "$XDG_CONFIG_HOME/zsh/env.zsh" ]; then
    if [ -f "$SCRIPT_DIR/xdg-env-template.zsh" ]; then
        cp "$SCRIPT_DIR/xdg-env-template.zsh" "$XDG_CONFIG_HOME/zsh/env.zsh"
        print_info "Created $XDG_CONFIG_HOME/zsh/env.zsh (for secrets)"
        print_warning "Add your API keys and secrets to: $XDG_CONFIG_HOME/zsh/env.zsh"
    else
        print_warning "xdg-env-template.zsh not found, skipping"
    fi
else
    print_warning "Secret env file already exists at $XDG_CONFIG_HOME/zsh/env.zsh"
fi

# 4. Install Oh My Zsh to XDG_DATA_HOME
print_step "Installing Oh My Zsh to $ZSH..."
if [ -d "$ZSH" ]; then
    print_warning "Oh My Zsh is already installed at $ZSH"
else
    # Install Oh My Zsh non-interactively to custom location
    RUNZSH=no ZSH="$ZSH" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_info "Oh My Zsh installed to $ZSH"
fi

# 5. Install Powerlevel10k theme
print_step "Installing Powerlevel10k theme..."
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    print_warning "Powerlevel10k already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    print_info "Powerlevel10k installed"
fi

# 6. Install zsh-autosuggestions plugin
print_step "Installing zsh-autosuggestions..."
AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
    print_warning "zsh-autosuggestions already installed"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR"
    print_info "zsh-autosuggestions installed"
fi

# 7. Install zsh-syntax-highlighting plugin
print_step "Installing zsh-syntax-highlighting..."
SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    print_warning "zsh-syntax-highlighting already installed"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR"
    print_info "zsh-syntax-highlighting installed"
fi

# 8. Install zsh-completions plugin
print_step "Installing zsh-completions..."
COMPLETIONS_DIR="$ZSH_CUSTOM/plugins/zsh-completions"
if [ -d "$COMPLETIONS_DIR" ]; then
    print_warning "zsh-completions already installed"
else
    git clone https://github.com/zsh-users/zsh-completions "$COMPLETIONS_DIR"
    print_info "zsh-completions installed"
fi

# 9. Install zsh-history-substring-search plugin
print_step "Installing zsh-history-substring-search..."
HISTORY_SEARCH_DIR="$ZSH_CUSTOM/plugins/zsh-history-substring-search"
if [ -d "$HISTORY_SEARCH_DIR" ]; then
    print_warning "zsh-history-substring-search already installed"
else
    git clone https://github.com/zsh-users/zsh-history-substring-search "$HISTORY_SEARCH_DIR"
    print_info "zsh-history-substring-search installed"
fi

# 10. Install fzf (fuzzy finder)
print_step "Installing fzf..."
pkg_install fzf

# 11. Install optional tools (fd, bat, tree)
print_step "Installing optional tools (fd, bat, tree)..."
pkg_install fd bat tree

# Note: On Linux with apt, fd is called fd-find and bat is called batcat
# Homebrew/Linuxbrew uses the correct names, so no symlinks needed
# If using apt on Linux, create symlinks for compatibility
if is_linux && command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
    print_info "Created symlink: fd -> fdfind"
fi

if is_linux && command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    print_info "Created symlink: bat -> batcat"
fi

# 12. Set zsh as default shell
print_step "Setting zsh as default shell..."
# Check if current shell is any zsh (handles different paths like /bin/zsh vs homebrew zsh)
if [[ "$SHELL" == *zsh ]]; then
    print_warning "zsh is already the default shell ($SHELL)"
else
    if chsh -s "$(which zsh)" 2>/dev/null; then
        print_info "Default shell changed to zsh"
        print_warning "You need to log out and log back in for the shell change to take effect"
    else
        print_warning "Could not change default shell (may require password). Run manually: chsh -s $(which zsh)"
    fi
fi

# 13. Summary
echo ""
echo "======================================"
print_info "Zsh setup complete!"
echo "======================================"
echo ""
print_info "Directory Structure:"
echo "  • ZDOTDIR: $SCRIPT_DIR"
echo "  • Config modules: $SCRIPT_DIR/config/"
echo "  • Alias modules: $SCRIPT_DIR/aliases/"
echo "  • Function modules: $SCRIPT_DIR/functions/"
echo "  • Secrets: $XDG_CONFIG_HOME/zsh/env.zsh"
echo "  • Oh My Zsh: $ZSH"
echo "  • History: $XDG_STATE_HOME/zsh/history"
echo "  • Cache: $XDG_CACHE_HOME/zsh/"
echo ""
print_info "Installed components:"
echo "  • Zsh: $(zsh --version)"
echo "  • Oh My Zsh (XDG compliant)"
echo "  • Powerlevel10k theme"
echo "  • Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search"
echo "  • OMZ plugins: git, z, fzf, sudo, extract, colored-man-pages, copypath, dirhistory, jsontools, aliases"
echo "  • Tools: fzf, fd, bat, tree"
echo ""
print_info "Next steps:"
echo "  1. Log out and log back in (or run: exec zsh)"
echo "  2. On first launch, Powerlevel10k configuration wizard will run"
echo "  3. Follow the prompts to customize your prompt (or skip and use defaults)"
echo "  4. Add secrets to: $XDG_CONFIG_HOME/zsh/env.zsh"
echo "  5. Customize config in: $SCRIPT_DIR/.zshrc"
echo ""
print_warning "Note: Only ~/.zshenv is in your home directory. All other configs are in ZDOTDIR or XDG directories!"
echo ""
