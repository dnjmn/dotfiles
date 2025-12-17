# Tool Detection Wrappers
# Provides enhanced versions if tools are available

# Better diff with delta
if command -v delta &>/dev/null; then
  alias diff="delta"
fi

# Better cat with bat
if command -v bat &>/dev/null; then
  alias cat="bat --style=plain"
  alias ccat="/bin/cat"  # original cat preserved
fi

# Disk usage helpers (cross-platform)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS du uses -d for depth
  alias du1="du -h -d 1 | sort -h"
else
  # GNU du uses --max-depth
  alias du1="du -h --max-depth=1 | sort -h"
fi

# df without tmpfs noise
alias duf="df -h | grep -v tmpfs | grep -v udev | grep -v devfs"
