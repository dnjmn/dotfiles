# File/Directory Helper Functions

# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Quick find (filename search)
f() {
  find . -name "*$1*" 2>/dev/null
}

# Tree aliases with depth limits
alias tree1="tree -L 1"
alias tree2="tree -L 2"
alias tree3="tree -L 3"
