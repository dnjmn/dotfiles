# Oh My Zsh Configuration
# Theme, plugins, and core settings

# Theme (Powerlevel10k)
ZSH_THEME="powerlevel10k/powerlevel10k"

# Update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  z
  fzf
  command-not-found
  sudo
  extract
  colored-man-pages
)

# Create Oh My Zsh cache directory
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# Editor configuration
export EDITOR='nvim'
export VISUAL='nvim'
export LANG=en_US.UTF-8
