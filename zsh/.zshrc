# .zshrc - Zsh Configuration
# Generated: 2025-11-07
# Located in: ZDOTDIR (ubuntu-setup/zsh/)
# This configuration uses Oh My Zsh with Powerlevel10k theme

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===== OH MY ZSH CONFIGURATION =====

# Set theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Update behavior
zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13   # check for updates every 13 days

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Enable command auto-correction.
# ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment if you want to disable marking untracked files under VCS as dirty.
# This makes repository status check for large repositories much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS      # Don't record duplicate entries
setopt HIST_FIND_NO_DUPS         # Don't display duplicates when searching
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt SHARE_HISTORY             # Share history between sessions

# Create necessary directories
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# ===== PLUGINS =====

plugins=(
  # Git integration
  git

  # Auto-suggestions (suggests commands as you type based on history)
  zsh-autosuggestions

  # Syntax highlighting (highlights commands green if valid, red if invalid)
  zsh-syntax-highlighting

  # Additional completions
  zsh-completions

  # z - jump to frequently used directories
  z

  # fzf - fuzzy finder integration
  fzf

  # Common utilities
  command-not-found
  sudo
  extract
  colored-man-pages
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ===== USER CONFIGURATION =====

# Preferred editor
export EDITOR='vim'
export VISUAL='vim'

# Language environment
export LANG=en_US.UTF-8

# ===== ALIASES =====

# Zsh configuration
alias zshconfig="$EDITOR $ZDOTDIR/.zshrc"
alias zshenv="$EDITOR $ZDOTDIR/.zshenv"
alias zshenvsecret="$EDITOR $XDG_CONFIG_HOME/zsh/env.zsh"
alias zshreload="source $ZDOTDIR/.zshrc"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# ls aliases (with colors)
alias ls="ls --color=auto"
alias ll="ls -lh"
alias la="ls -lha"
alias l="ls -CF"
alias lt="ls -lhtr"  # Sort by time

# Git aliases (additional to oh-my-zsh git plugin)
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate --all"
alias gst="git stash"
alias gstp="git stash pop"

# Safety aliases
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ln="ln -i"

# Directory shortcuts
alias dev="cd ~/Developer"
alias repos="cd ~/Developer/repos"
alias dotfiles="cd ~/Developer/repos/dnjmn/ubuntu-setup"

# System
alias update="sudo apt update && sudo apt upgrade -y"
alias install="sudo apt install"
alias remove="sudo apt remove"
alias search="apt search"
alias cleanup="sudo apt autoremove && sudo apt autoclean"

# Kubernetes (from user's global CLAUDE.md)
alias k="kubectl --context kind-llmariner-demo"
alias kgp="kubectl --context kind-llmariner-demo get pods"
alias kgs="kubectl --context kind-llmariner-demo get svc"
alias kgd="kubectl --context kind-llmariner-demo get deployments"
alias kgn="kubectl --context kind-llmariner-demo get nodes"
alias kd="kubectl --context kind-llmariner-demo describe"
alias kl="kubectl --context kind-llmariner-demo logs"
alias ke="kubectl --context kind-llmariner-demo exec -it"

# Docker
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias di="docker images"
alias dlog="docker logs"
alias dexec="docker exec -it"
alias dstop="docker stop"
alias drm="docker rm"
alias drmi="docker rmi"
alias dprune="docker system prune -af"

# Utilities
alias weather="curl wttr.in"
alias myip="curl ifconfig.me"
alias localip="ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"
alias ports="netstat -tulanp"
alias listening="lsof -i -P -n | grep LISTEN"

# Common typos
alias claer="clear"
alias celar="clear"
alias clar="clear"

# ===== FZF CONFIGURATION =====

# Set fzf default options with Gruvbox colors
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --color=bg+:#3c3836,bg:#282828,spinner:#fb4934,hl:#928374
  --color=fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934
  --color=marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934
"

# Use fd or find for fzf
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# fzf keybindings
# Ctrl+T - Paste selected files/dirs onto command line
# Ctrl+R - Paste selected command from history onto command line
# Alt+C - cd into selected directory

# ===== ZSH-AUTOSUGGESTIONS CONFIGURATION =====

# Color for suggestions (greyish to match Gruvbox theme)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#928374"

# Accept suggestion with Ctrl+Space or End key
bindkey '^ ' autosuggest-accept
bindkey '^[[F' autosuggest-accept  # End key

# ===== CUSTOM FUNCTIONS =====

# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Quick find
f() {
  find . -name "*$1*" 2>/dev/null
}

# Grep with color
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Quick git commit
qc() {
  git add -A && git commit -m "$*"
}

# Quick git push
qp() {
  git add -A && git commit -m "$*" && git push
}

# Better diff with delta if available
if command -v delta &> /dev/null; then
  alias diff="delta"
fi

# Better cat with bat if available
if command -v bat &> /dev/null; then
  alias cat="bat --style=plain"
  alias ccat="/bin/cat"  # original cat
fi

# Tree with depth limit
alias tree1="tree -L 1"
alias tree2="tree -L 2"
alias tree3="tree -L 3"

# Disk usage
alias du1="du -h --max-depth=1 | sort -h"
alias duf="df -h | grep -v tmpfs | grep -v udev"

# ===== PATH CONFIGURATION =====

# Add local bin to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Add custom scripts directory if it exists
if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

# Add NPM global bin to PATH if it exists
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

# ===== COMPLETION CONFIGURATION =====

# Enable completion cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection for completion
zstyle ':completion:*' menu select

# Color completion menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ===== POWERLEVEL10K =====

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# Store p10k config in ZDOTDIR
if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
  source "$ZDOTDIR/.p10k.zsh"
fi

# ===== FINAL TOUCHES =====

# Load fzf keybindings if available
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# Load local overrides if they exist (not version controlled)
if [[ -f "$ZDOTDIR/local.zsh" ]]; then
  source "$ZDOTDIR/local.zsh"
fi

# Welcome message (comment out if you prefer clean startup)
# echo "Welcome to Zsh with Oh My Zsh and Powerlevel10k!"

alias claude="/home/dhananjay-meena/.claude/local/claude"
