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
# External plugins (installed via git clone to $ZSH_CUSTOM/plugins/)
# Built-in plugins (come with Oh My Zsh)
plugins=(
  # External plugins
  zsh-autosuggestions           # Fish-like autosuggestions
  zsh-syntax-highlighting       # Command syntax highlighting (must be last external)
  zsh-completions               # Additional completions
  zsh-history-substring-search  # Fish-like history search with up/down arrows

  # Git
  git                           # Git aliases and functions

  # Navigation & productivity
  z                             # Jump to frecent directories
  fzf                           # Fuzzy finder integration
  dirhistory                    # Alt+Left/Right for directory navigation
  copypath                      # Copy current directory path to clipboard

  # Utility
  sudo                          # ESC ESC to prefix command with sudo
  extract                       # Smart archive extraction
  command-not-found             # Suggest packages for missing commands
  colored-man-pages             # Colorized man pages
  aliases                       # List aliases with 'als' command
  jsontools                     # JSON utilities (pp_json, is_json, urlencode_json)
)

# Create Oh My Zsh cache directory
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# Editor configuration
export EDITOR='nvim'
export VISUAL='nvim'
export LANG=en_US.UTF-8
