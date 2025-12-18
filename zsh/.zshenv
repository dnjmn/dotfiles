# .zshenv - Environment variables
# This file is sourced on all shell invocations
# Located in: ZDOTDIR (dotfiles/zsh/)

# ===== XDG BASE DIRECTORY SPECIFICATION =====
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ===== ZSH CONFIGURATION =====
# History file location (using XDG)
export HISTFILE="$XDG_STATE_HOME/zsh/history"

# Zsh completion cache
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# ===== OH MY ZSH CONFIGURATION =====
# Install Oh My Zsh in XDG_DATA_HOME instead of ~/.oh-my-zsh
export ZSH="$XDG_DATA_HOME/oh-my-zsh"

# Oh My Zsh cache directory
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/oh-my-zsh"

# Custom plugins/themes location
export ZSH_CUSTOM="$ZSH/custom"

# ===== APPLICATION DIRECTORIES (XDG compliance) =====
# NPM
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

# Node REPL history
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Kubernetes
export KUBECONFIG="$XDG_CONFIG_HOME/kube/config.yaml"

# AWS
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"

# Less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# ===== DEFAULT EDITORS =====
export EDITOR="nvim"
export VISUAL="nvim"

# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# ===== PATH CONFIGURATION =====

# Homebrew - Cross-platform detection (XDG first, then system locations)
# User-level XDG location (priority)
if [[ -x "$XDG_DATA_HOME/homebrew/bin/brew" ]]; then
  eval "$("$XDG_DATA_HOME/homebrew/bin/brew" shellenv)"
# macOS Apple Silicon
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
# macOS Intel
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
# Linux (Linuxbrew)
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Go
export GOPATH="$HOME/go"
export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"

# Cargo (Rust)
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# ===== LOAD SECRET ENVIRONMENT VARIABLES =====
# Source secret env vars from XDG config (not version controlled)
if [[ -f "$XDG_CONFIG_HOME/zsh/env.zsh" ]]; then
  source "$XDG_CONFIG_HOME/zsh/env.zsh"
fi
