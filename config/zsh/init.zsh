export DOTFILES="$HOME/Github/dnjmn/private/dotfiles"
export CREDFILES="$HOME/Github/dnjmn/private/credfiles"

#-- XDG Paths --------------------------------------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"
# export XDG_RUNTIME_DIR ??

#-- zsh --------------------------------------------------------------------------------------
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
source $ZDOTDIR/.zshenv
