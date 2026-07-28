#!/usr/bin/env bash
# Assert config/tmux/tmux.conf produces its intended effective state.
#
# Hermetic by design — this script deliberately does NOT source lib/platform.sh:
#   * platform.sh:5 runs `set -euo pipefail` at top level, which would abort the
#     run on the first failed assertion instead of reporting every failure.
#   * platform.sh:296-299 exports XDG_* using the same ${VAR:-default} idiom under
#     test here, which would contaminate the environment assertions below.
#
# The TPM loader is stripped before booting: tmux-continuum would otherwise
# save/restore against the real ~/.local/share/tmux/resurrect directory.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOCKET="dotfiles-tmux-verify"
WORK="$(mktemp -d)"
CONF="$WORK/tmux.conf"
PASS=0
FAIL=0

cleanup() { tmux -L "$SOCKET" kill-server 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

ok()  { printf '\033[32m  PASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '\033[31m  FAIL\033[0m %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"; FAIL=$((FAIL + 1)); }
contains() { case "$3" in *"$2"*) ok "$1" ;; *) bad "$1" "contains '$2'" "$3" ;; esac; }
lacks()    { case "$3" in *"$2"*) bad "$1" "does NOT contain '$2'" "$3" ;; *) ok "$1" ;; esac; }
tm() { tmux -L "$SOCKET" "$@"; }

# Assert a whole line exists in tmux's global environment WITHOUT ever echoing
# that environment. It contains secrets — ~/.config/zsh/env.zsh is sourced by
# .zshenv:84 and exports API tokens. Never pass `show-environment` output to
# contains()/lacks(), which print the haystack on failure.
env_has_line() { # env_has_line <description> <exact-line>
  if tm show-environment -g 2>/dev/null | grep -qxF -- "$2"; then ok "$1"
  else bad "$1" "a line reading '$2'" "absent"; fi
}

# Assert a pattern is absent from a config file, printing only matching lines.
conf_lacks() { # conf_lacks <description> <pattern> <file>
  if grep -q -- "$2" "$3"; then bad "$1" "no match for '$2'" "$(grep -n -- "$2" "$3" | head -3)"
  else ok "$1"; fi
}

# statusline.conf is pulled in via the installed symlink path.
[[ -L "$HOME/.config/tmux/statusline.conf" ]] || {
  echo "run install/tmux.sh first — config symlinks are missing"; exit 1; }

grep -v "plugins/tpm/tpm" "$REPO_ROOT/config/tmux/tmux.conf" >"$CONF"

# Boot holding deliberately stale values, mimicking a weeks-old server.
tm kill-server 2>/dev/null
env XDG_DATA_HOME=/STALE/data ZDOTDIR=/STALE/zdot \
  tmux -L "$SOCKET" -f "$CONF" new-session -d -s verify 2>"$WORK/err" || {
    echo "config failed to parse:"; cat "$WORK/err"; exit 1; }
sleep 1

echo "== environment =="
for v in ZDOTDIR XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME; do
  env_has_line "$v marked for removal" "-$v"
done
contains "update-environment restores SSH_AUTH_SOCK" "SSH_AUTH_SOCK" "$(tm show-options -g update-environment)"
contains "@resurrect-dir pinned explicitly" "tmux/resurrect" "$(tm show-options -g @resurrect-dir 2>/dev/null)"

# Behavioural: a new pane must not receive the stale value.
tm split-window -t verify -d "sh -c 'printf %s \"\${ZDOTDIR-}\" > $WORK/zdotdir.out'"
sleep 2
lacks "new pane does not inherit stale ZDOTDIR" "/STALE/zdot" "$(cat "$WORK/zdotdir.out" 2>/dev/null)"

echo
echo "passed: $PASS   failed: $FAIL"
[[ $FAIL -eq 0 ]]
