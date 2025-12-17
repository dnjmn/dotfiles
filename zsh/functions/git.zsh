# Git Helper Functions

# Quick commit - stages all and commits with message
qc() {
  git add -A && git commit -m "$*"
}

# Quick push - stages all, commits, and pushes
qp() {
  git add -A && git commit -m "$*" && git push
}
