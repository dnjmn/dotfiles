# LS/LSD Aliases with Tool Detection

if command -v lsd &>/dev/null; then
  # LSD available - use enhanced listing
  alias ls="lsd"
  alias ll="lsd -l"
  alias la="lsd -la"
  alias l="lsd -F"
  alias lt="lsd -l --timesort"
  alias tree="lsd --tree"
else
  # Fallback to standard ls
  alias ls="ls --color=auto"
  alias ll="ls -lh"
  alias la="ls -lha"
  alias l="ls -CF"
  alias lt="ls -lhtr"
fi
