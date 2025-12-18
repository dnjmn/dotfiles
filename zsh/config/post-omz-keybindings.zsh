# History Substring Search Configuration
# Fish-like history search with up/down arrows
# Searches history for commands containing the current input

# Bind up/down arrows to history substring search
# These bindings work after oh-my-zsh is loaded
bindkey '^[[A' history-substring-search-up    # Up arrow
bindkey '^[[B' history-substring-search-down  # Down arrow

# Alternative bindings for different terminal emulators
bindkey '^[OA' history-substring-search-up    # Up arrow (alternate)
bindkey '^[OB' history-substring-search-down  # Down arrow (alternate)

# Vi mode bindings (if using vi mode)
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Emacs mode bindings
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# Highlight style for matches (gruvbox yellow)
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#504945,fg=#fabd2f,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#3c3836,fg=#fb4934,bold'

# Ensure unique matches (no duplicates)
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Fuzzy matching (optional - comment out for exact prefix matching)
HISTORY_SUBSTRING_SEARCH_FUZZY=1
