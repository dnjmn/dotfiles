# Core Aliases - Navigation, Safety, Zsh Config

# === ZSH CONFIGURATION ===
alias zshconfig="$EDITOR $ZDOTDIR/.zshrc"
alias zshenv="$EDITOR $ZDOTDIR/.zshenv"
alias zshenvsecret="$EDITOR $XDG_CONFIG_HOME/zsh/env.zsh"
alias zshreload="source $ZDOTDIR/.zshrc"

# === NAVIGATION ===
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# === SAFETY ALIASES ===
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ln="ln -i"

# === DIRECTORY SHORTCUTS ===
alias dev="cd ~/Developer"
alias repos="cd ~/Developer/repos"
alias dotfiles="cd ~/Developer/repos/dnjmn/dotfiles"

