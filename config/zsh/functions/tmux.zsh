# Tmux Helpers

# Attach to session or create if doesn't exist
t() {
  [[ -z "$1" ]] && { tmux ls; return; }
  tmux new -A -s "$1"
}
