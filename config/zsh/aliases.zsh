#source $ZDOTDIR/kbaliases
#source $ZDOTDIR/kbenv
## SYSTEM WIDE
# listing
alias l='lsd'
alias ll='lsd -l'
alias la='lsd -la'
alias lt='lsd --tree'

alias cdd='cd $DOTFILES'
alias cdc='cd $CREDFILES'
alias cdi='cd /Users/metalhead/Projects/developer/languages/golang/playground/interview'


## GIT
# git add
alias ga='git add'
alias gaa='git add --all'
# git status / *f -> full 
alias gs='git status -sb'
alias gsf='git status'
# commit
alias gc='git commit -m'
# log
alias gl='git log --oneline'
alias glf='git log'
alias gll='git log -1 HEAD --stat'
# diff
alias gd='git diff'
# difftool
alias gdt='git difftool'
# config
alias gcon='git config --list'

## TERMINAL
alias c='clear'

## SSH
alias sshp14sn='ssh p14s -t tmux new -s p14s'
alias sshp14s='ssh p14s -t tmux a -t p14s'

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias v='~/./nvim.appimage'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    alias v='~/.local/bin/lvim'
fi
