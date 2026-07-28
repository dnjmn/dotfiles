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

echo "== plugins and absorbed settings =="
TC="$REPO_ROOT/config/tmux/tmux.conf"
conf_lacks "tmux-copycat removed"   "@plugin 'tmux-plugins/tmux-copycat'"    "$TC"
conf_lacks "tmux-sensible removed"  "@plugin 'tmux-plugins/tmux-sensible'"   "$TC"
conf_lacks "yank_selection removed" "@yank_selection '" "$TC"
contains "status-keys absorbed"       "status-keys emacs"    "$(tm show-options -g status-keys)"
contains "aggressive-resize absorbed" "aggressive-resize on" "$(tm show-options -gw aggressive-resize)"
contains "continuum save interval 15" "save-interval 15"     "$(tm show-options -g @continuum-save-interval)"

echo "== status bar =="
SR="$(tm show-options -g status-right)"
contains "status-interval is 5" "status-interval 5" "$(tm show-options -g status-interval)"
conf_lacks "status-interval not duplicated in tmux.conf" "status-interval" "$REPO_ROOT/config/tmux/tmux.conf"
lacks "no docker segment"   "docker"          "$SR"
lacks "no k8s segment"      "kubectl"         "$SR"
lacks "no cpu segment"      "top -l"          "$SR"
lacks "no memory segment"   "memory_pressure" "$SR"
contains "single git call"  "porcelain=v2"    "$SR"
lacks "no cd subshell"      "cd #{pane_current_path}" "$SR"

echo "== navigation =="
contains "root C-h is vim-aware" "@is_vim" "$(tm list-keys -T root C-h 2>/dev/null)"
contains "vim matcher defined once" "pane_current_command" "$(tm show-options -gv @is_vim 2>/dev/null)"
# The matcher must evaluate to 0 in this shell pane; 1 would mean it matches everything.
contains "vim matcher evaluates" "0" "$(tm display -p -t verify '#{E:#{@is_vim}}' 2>/dev/null)"
contains "root C-j bound"        "select-pane -D"       "$(tm list-keys -T root C-j 2>/dev/null)"
contains "root C-k bound"        "select-pane -U"       "$(tm list-keys -T root C-k 2>/dev/null)"
contains "root C-l bound"        "select-pane -R"       "$(tm list-keys -T root C-l 2>/dev/null)"
contains "prefix C-l clears shell" "send-keys"          "$(tm list-keys -T prefix C-l 2>/dev/null)"
contains "prefix n repeats"      "-r"                   "$(tm list-keys -T prefix n 2>/dev/null)"
contains "prefix p repeats"      "-r"                   "$(tm list-keys -T prefix p 2>/dev/null)"
lacks "old window-nav bind gone" "select-window"        "$(tm list-keys -T prefix C-h 2>/dev/null)"
[[ -f "$REPO_ROOT/config/neovim/lua/plugins/tmux.lua" ]] \
  && ok "neovim navigator spec exists" \
  || bad "neovim navigator spec exists" "config/neovim/lua/plugins/tmux.lua" "missing"

echo "== popups, options, descriptions =="
contains "lazygit popup"    "lazygit"       "$(tm list-keys -T prefix g 2>/dev/null)"
contains "fzf session popup" "fzf"          "$(tm list-keys -T prefix s 2>/dev/null)"
contains "scratch popup"    "display-popup" "$(tm list-keys -T prefix C-t 2>/dev/null)"
contains "clipboard on"          "set-clipboard on"      "$(tm show-options -g set-clipboard)"
contains "detach-on-destroy off" "detach-on-destroy off" "$(tm show-options -g detach-on-destroy)"
contains "default-terminal is a server option" "tmux-256color" "$(tm show-options -s default-terminal)"
contains "undercurl capability" "Smulx"       "$(tm show-options -g terminal-overrides)"

# Assert OUR bindings carry a -N description. Do not compare per-table totals:
# tmux ships 19 undescribed root bindings (mouse) and ~87 undescribed copy-mode-vi
# bindings, so `total == described` is unsatisfiable and annotating them is out of
# scope. `list-keys -T <table> -N <key>` prints the note, or "unknown key: <key>"
# when the key has none — that distinction is the test.
described() { # described <table> <key>
  out="$(tm list-keys -T "$1" -N "$2" 2>&1)"
  case "$out" in
    *"unknown key"*) bad "described: $1 $2" "a -N note" "$out" ;;
    *)               ok "described: $1 $2" ;;
  esac
}
for k in r '|' - c N P h j k l H J K L o T b Enter n p C-l g s C-t; do
  described prefix "$k"
done
for k in C-h C-j C-k C-l;  do described root "$k"; done
for k in v y C-v;           do described copy-mode-vi "$k"; done

echo
echo "passed: $PASS   failed: $FAIL"
[[ $FAIL -eq 0 ]]
