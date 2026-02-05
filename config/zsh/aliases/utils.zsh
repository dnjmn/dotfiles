# Utility Aliases - Networking, Weather, Typos

# === NETWORKING ===
alias weather="curl wttr.in"
alias myip="curl ifconfig.me"
alias ports="netstat -tulanp 2>/dev/null || lsof -i -P -n"
alias listening="lsof -i -P -n | grep LISTEN"

# Local IP (cross-platform)
if [[ "$(uname)" == "Darwin" ]]; then
  alias localip="ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'No IP found'"
else
  alias localip="hostname -I 2>/dev/null | awk '{print \$1}' || ip -4 addr show | grep -oE 'inet [0-9.]+' | grep -v '127.0.0.1' | awk '{print \$2}' | head -1"
fi

# === GREP (colorized) ===
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# === TYPO FIXES ===
alias claer="clear"
alias celar="clear"
alias clar="clear"
