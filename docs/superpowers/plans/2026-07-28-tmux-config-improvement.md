# Tmux Config Improvement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix stale environment variables in new tmux panes, cut the status bar's
continuous CPU cost, and add tmux 3.2+ ergonomics — without restructuring the config.

**Architecture:** Two config files stay as they are (`tmux.conf` + `statusline.conf`).
A new hermetic bash harness boots a throwaway tmux server on a dedicated socket and
asserts effective options, bindings and environment, giving each task a real red→green
cycle. One new neovim plugin spec supplies the editor half of pane navigation.

**Tech Stack:** tmux 3.6a, zsh, bash (harness), lua/lazy.nvim (neovim), macOS arm64.

**Spec:** `docs/superpowers/specs/2026-07-28-tmux-config-improvement-design.md`

## Global Constraints

- Target tmux **3.6a**. `#{m/ri:...}` regex formats and `display-popup` require 3.1+/3.2+ respectively; both verified present.
- Two config files only: `config/tmux/tmux.conf` and `config/tmux/statusline.conf`. Do **not** split further — `install/tmux.sh:22-26` symlinks them individually and must not need changes.
- Keep unchanged: `C-a` prefix, `|`/`-` splits, gruvbox palette, vi copy-mode, `base-index 1`, resurrect/continuum persistence.
- Do **not** edit `config/zsh/.zshenv`. The environment fix is tmux-side by design (spec: "Stop tmux propagating static config vars").
- Every new binding gets a `-N "description"`.
- The harness must never run TPM. `tmux-continuum` would otherwise save/restore against the real `~/.local/share/tmux/resurrect` directory during tests.
- `config/tmux/tmux.conf` has an **uncommitted local change** in the working tree (`@continuum-save-interval` `15`→`1`). Task 2 reverts it to `15`; do not treat it as a conflict.

---

### Task 1: Verification harness + environment fix

Fixes the reported bug: new panes in long-lived sessions get stale env vars.

**Files:**
- Create: `tests/tmux/verify.sh`
- Modify: `config/tmux/tmux.conf:10-14` (environment block), plugin settings block

**Interfaces:**
- Consumes: nothing.
- Produces: `tests/tmux/verify.sh`, an executable that boots a server on socket
  `dotfiles-tmux-verify`, prints `PASS`/`FAIL` per assertion, and exits non-zero if
  any failed. Later tasks append assertion blocks to it and re-run it unchanged.
  Helper functions later tasks reuse: `contains <desc> <needle> <haystack>`,
  `lacks <desc> <needle> <haystack>`, and `tm <tmux-args...>`.

- [ ] **Step 1: Write the failing test**

Create `tests/tmux/verify.sh`:

```bash
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
```

Make it executable:

```bash
chmod +x tests/tmux/verify.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./tests/tmux/verify.sh`

Expected: FAIL. The five `marked for removal` assertions fail (no `-VAR` entries
exist yet), `SSH_AUTH_SOCK` is absent because `tmux.conf:14` replaced the default
list, `@resurrect-dir` is empty, and the new pane still reports `/STALE/zdot`.

- [ ] **Step 3: Write minimal implementation**

In `config/tmux/tmux.conf`, replace the block at lines 12-14 (the
`update-environment` comment and setting) with:

```tmux
# Static config vars must not be inherited from the server's frozen environment.
# `-r` removes each one before a new process starts, so every pane re-derives it:
# with ZDOTDIR absent, zsh falls back to ~/.zshenv, which re-bootstraps ZDOTDIR and
# re-sources the real config. Without this, .zshenv's `${VAR:-default}` guards
# preserve whatever stale value the server was started with.
# update-environment is deliberately left at its default; it is for per-client vars
# (SSH_AUTH_SOCK, DISPLAY) and fires only on attach, never on pane creation.
set-environment -gr ZDOTDIR
set-environment -gr XDG_CONFIG_HOME
set-environment -gr XDG_DATA_HOME
set-environment -gr XDG_CACHE_HOME
set-environment -gr XDG_STATE_HOME
```

Then, in the plugin settings block, immediately after
`set -g @resurrect-capture-pane-contents 'on'`, add:

```tmux
# Pin explicitly. resurrect derives this from ${XDG_DATA_HOME:-$HOME/.local/share}
# (scripts/helpers.sh:4), and XDG_DATA_HOME is now removed from the environment.
# Same path as before, but stated rather than inferred — if it were ever inferred
# differently, saved sessions would silently relocate.
set -g @resurrect-dir "$HOME/.local/share/tmux/resurrect"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./tests/tmux/verify.sh`

Expected: PASS, `failed: 0`. Confirm the behavioural assertion in particular —
the new pane must report an empty `ZDOTDIR`, not `/STALE/zdot`.

- [ ] **Step 5: Confirm saved sessions did not move**

Run: `ls ~/.local/share/tmux/resurrect/ | tail -3`

Expected: the existing `tmux_resurrect_*.txt` files are still listed. If this
directory is empty or missing, stop — `@resurrect-dir` resolved somewhere new.

- [ ] **Step 6: Commit**

```bash
git add tests/tmux/verify.sh config/tmux/tmux.conf
git commit -m "fix(tmux): stop propagating stale static config vars to new panes"
```

---

### Task 2: Remove obsolete plugins, absorb tmux-sensible

**Files:**
- Modify: `config/tmux/tmux.conf` (plugin list and plugin settings), general settings block
- Modify: `tests/tmux/verify.sh` (append assertions)

**Interfaces:**
- Consumes: `contains`, `lacks`, `tm`, `REPO_ROOT` from Task 1.
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

Append to `tests/tmux/verify.sh`, immediately before the final `echo` /
`passed:` summary lines:

```bash
echo "== plugins and absorbed settings =="
TC="$REPO_ROOT/config/tmux/tmux.conf"
conf_lacks "tmux-copycat removed"   "tmux-copycat"    "$TC"
conf_lacks "tmux-sensible removed"  "tmux-sensible"   "$TC"
conf_lacks "yank_selection removed" "@yank_selection" "$TC"
contains "status-keys absorbed"       "status-keys emacs"    "$(tm show-options -g status-keys)"
contains "aggressive-resize absorbed" "aggressive-resize on" "$(tm show-options -gw aggressive-resize)"
contains "continuum save interval 15" "save-interval 15"     "$(tm show-options -g @continuum-save-interval)"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./tests/tmux/verify.sh`

Expected: FAIL on all six. The plugins are still listed, `status-keys` is `vi`
(tmux's default, since tmux-sensible is not running under the stripped config),
`aggressive-resize` is `off`, and the save interval is `1`.

- [ ] **Step 3: Write minimal implementation**

In `config/tmux/tmux.conf`, delete these three plugin lines:

```tmux
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-copycat'
```

and this setting:

```tmux
set -g @yank_selection 'primary'
```

Change the continuum interval back to the upstream default:

```tmux
set -g @continuum-save-interval '15'
```

In the General Settings block, after `set -g mouse on`, add the two settings
tmux-sensible was providing:

```tmux
# Absorbed from tmux-sensible, which is no longer used. That plugin applied these
# only when it judged the current value "unchanged" (sensible.tmux:82-112), which
# made effective settings depend on plugin heuristics resolved after this file ran.
set -g status-keys emacs
setw -g aggressive-resize on
```

Keep `@yank_selection_mouse 'clipboard'` — only the `primary` line is removed.

- [ ] **Step 4: Run test to verify it passes**

Run: `./tests/tmux/verify.sh`

Expected: PASS, `failed: 0`.

- [ ] **Step 5: Remove the now-unused plugin directories**

```bash
rm -rf ~/.local/share/tmux/plugins/tmux-sensible ~/.local/share/tmux/plugins/tmux-copycat
```

- [ ] **Step 6: Commit**

```bash
git add config/tmux/tmux.conf tests/tmux/verify.sh
git commit -m "refactor(tmux): drop tmux-sensible and tmux-copycat, absorb their settings"
```

---

### Task 3: Trim the status bar

**Files:**
- Modify: `config/tmux/statusline.conf:22` (interval), `:25` (length), `:42-56` (status-right)
- Modify: `config/tmux/tmux.conf:46-47` (delete the duplicate `status-interval`)
- Modify: `tests/tmux/verify.sh` (append assertions)

**Interfaces:**
- Consumes: `contains`, `lacks`, `tm`, `REPO_ROOT` from Task 1.
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

Append to `tests/tmux/verify.sh` before the summary lines:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./tests/tmux/verify.sh`

Expected: FAIL. Interval is `2`, and all four expensive segments are present.

- [ ] **Step 3: Write minimal implementation**

In `config/tmux/statusline.conf`, set the interval on line 22:

```tmux
set -g status-interval 5
```

In `config/tmux/tmux.conf`, delete lines 46-47 — the duplicate that
`statusline.conf` already overrides. The fact gets one home:

```tmux
# Refresh status bar every 5 seconds
set -g status-interval 5
```

Set the length on line 25:

```tmux
set -g status-right-length 60
```

Replace the whole `status-right` assignment (lines 42-56) with:

```tmux
# git branch + dirty flag, battery, clock. One git process replaces the previous
# four-call chain (rev-parse + branch + diff + diff --cached); measured 56 ms vs
# 116 ms. `git -C` replaces the `cd` subshell.
set -g status-right "\
#[fg=#504945,bg=#282828]\
#[fg=#b8bb26,bg=#504945] #(git -C '#{pane_current_path}' status --porcelain=v2 --branch 2>/dev/null | awk '/^# branch.head/{b=$3} /^[12u?]/{d=\"*\"} END{if(b!=\"\")printf \"%s%s\",b,d; else printf \"󰊢\"}') \
#[fg=#3c3836,bg=#504945]\
#[fg=#fabd2f,bg=#3c3836] #(pmset -g batt | awk 'match($0,/[0-9]+%/){print substr($0,RSTART,RLENGTH)}') \
#[fg=#b8bb26,bg=#3c3836]\
#[fg=#282828,bg=#b8bb26,bold]  %H:%M "
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./tests/tmux/verify.sh`

Expected: PASS, `failed: 0`.

- [ ] **Step 5: Verify the shell pipelines standalone**

The assertions above check the *configuration*, not the rendered output. Confirm
each pipeline independently:

```bash
sh -c "git -C \"$PWD\" status --porcelain=v2 --branch 2>/dev/null | awk '/^# branch.head/{b=\$3} /^[12u?]/{d=\"*\"} END{if(b!=\"\")printf \"%s%s\",b,d; else printf \"-\"}'"
sh -c "pmset -g batt | awk 'match(\$0,/[0-9]+%/){print substr(\$0,RSTART,RLENGTH)}'"
```

Expected: a branch name with `*` when dirty (e.g. `mac*`), and a percentage
(e.g. `95%`).

- [ ] **Step 6: Verify rendering live — this cannot be done headlessly**

`#()` jobs only run when a client is attached, so a detached test server always
renders these segments blank. Reload in a real session and look at the bar:

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

Expected: the right side shows branch + dirty marker, battery percentage and
clock, with gruvbox separators and no gaps. Wait up to 5 seconds for the first
refresh. If a segment is blank, run the Step 5 commands to isolate which one.

- [ ] **Step 7: Re-measure the cost**

```bash
tmux display -p '#{status-interval}'
for c in "git -C $PWD status --porcelain=v2 --branch" "pmset -g batt"; do
  s=$(python3 -c 'import time;print(time.time())'); eval "$c" >/dev/null 2>&1
  e=$(python3 -c 'import time;print(time.time())')
  python3 -c "print(f'{($e-$s)*1000:7.0f} ms  $c')"
done
```

Expected: interval `5`, and the two commands summing to roughly 90 ms — versus
the 590 ms per 2 s baseline recorded in the spec. Record the real numbers; the
spec's "after" column was a projection, not a measurement.

- [ ] **Step 8: Commit**

```bash
git add config/tmux/statusline.conf tests/tmux/verify.sh
git commit -m "perf(tmux): trim status bar to git, battery and clock"
```

---

### Task 4: Vim-aware pane navigation

Ships the tmux and neovim halves together — `C-hjkl` half-works if either is missing.

**Files:**
- Create: `config/neovim/lua/plugins/tmux.lua`
- Modify: `config/tmux/tmux.conf:97-98` (replace window-nav binds)
- Modify: `tests/tmux/verify.sh` (append assertions)

**Interfaces:**
- Consumes: `contains`, `lacks`, `tm`, `ok`, `bad`, `REPO_ROOT` from Task 1.
- Produces: root-table bindings `C-h`, `C-j`, `C-k`, `C-l`; prefix bindings
  `C-l` (shell clear), `n`, `p`. Task 5 must not rebind any of these.

- [ ] **Step 1: Write the failing test**

Append to `tests/tmux/verify.sh` before the summary lines:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./tests/tmux/verify.sh`

Expected: FAIL on all nine — no root-table bindings exist, `prefix C-h` is still
`select-window`, and the neovim spec file is absent.

- [ ] **Step 3: Write minimal implementation — tmux half**

In `config/tmux/tmux.conf`, delete these two lines (currently at `:97-98`):

```tmux
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+
```

Replace them with:

```tmux
# Window navigation. tmux binds prefix n/p by default; this only adds repeat.
bind -N "next window"     -r n next-window
bind -N "previous window" -r p previous-window

# Vim-aware pane navigation. The match runs inside tmux's format engine, so unlike
# the canonical `ps | grep` snippet this forks nothing per keypress. `#{E:...}`
# expands the stored format a second time, so the pattern is defined once.
set -g @is_vim "#{m/ri:^(g?(view|l?n?vim?x?)(diff)?|fzf|lazygit)$,#{pane_current_command}}"
bind -N "pane left (vim-aware)"  -n C-h if -F "#{E:#{@is_vim}}" 'send-keys C-h' 'select-pane -L'
bind -N "pane down (vim-aware)"  -n C-j if -F "#{E:#{@is_vim}}" 'send-keys C-j' 'select-pane -D'
bind -N "pane up (vim-aware)"    -n C-k if -F "#{E:#{@is_vim}}" 'send-keys C-k' 'select-pane -U'
bind -N "pane right (vim-aware)" -n C-l if -F "#{E:#{@is_vim}}" 'send-keys C-l' 'select-pane -R'

# Root-table C-l now steers panes, so shell clear-screen moves under the prefix.
bind -N "clear screen" C-l send-keys 'C-l'
```

- [ ] **Step 4: Write minimal implementation — neovim half**

Create `config/neovim/lua/plugins/tmux.lua`:

```lua
-- Seamless navigation between neovim splits and tmux panes.
-- The tmux half lives in config/tmux/tmux.conf (root-table C-h/j/k/l).
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left pane" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower pane" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper pane" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right pane" },
  },
}
```

No install-script change is needed: `install/neovim.sh:31` symlinks the whole
`config/neovim` directory.

- [ ] **Step 5: Run test to verify it passes**

Run: `./tests/tmux/verify.sh`

Expected: PASS, `failed: 0`.

- [ ] **Step 6: Install the neovim plugin and verify live**

```bash
nvim --headless "+Lazy! sync" +qa
```

Then, in a real tmux session with a horizontal split and neovim open in one pane:

- `C-h` / `C-l` move between neovim splits, then cross into the adjacent tmux pane
  without a prefix.
- `C-l` in a shell pane moves right rather than clearing.
- `prefix C-l` clears the shell.
- `prefix n` / `prefix p` change window, and repeat without re-pressing the prefix.

- [ ] **Step 7: Commit**

```bash
git add config/tmux/tmux.conf config/neovim/lua/plugins/tmux.lua tests/tmux/verify.sh
git commit -m "feat(tmux): vim-aware pane navigation with zero-fork detection"
```

---

### Task 5: Popups, key descriptions, terminal capabilities

**Files:**
- Modify: `config/tmux/tmux.conf` (general settings, key bindings)
- Modify: `tests/tmux/verify.sh` (append assertions)

**Interfaces:**
- Consumes: `contains`, `lacks`, `tm`, `ok`, `bad` from Task 1.
- Produces: prefix bindings `g`, `s`, `C-t`. Must not rebind `C-l`, `n`, `p`
  from Task 4.

- [ ] **Step 1: Write the failing test**

Append to `tests/tmux/verify.sh` before the summary lines:

```bash
echo "== popups, options, descriptions =="
contains "lazygit popup"    "lazygit"       "$(tm list-keys -T prefix g 2>/dev/null)"
contains "fzf session popup" "fzf"          "$(tm list-keys -T prefix s 2>/dev/null)"
contains "scratch popup"    "display-popup" "$(tm list-keys -T prefix C-t 2>/dev/null)"
contains "clipboard on"          "set-clipboard on"      "$(tm show-options -g set-clipboard)"
contains "detach-on-destroy off" "detach-on-destroy off" "$(tm show-options -g detach-on-destroy)"
contains "default-terminal is a server option" "tmux-256color" "$(tm show-options -s default-terminal)"
contains "undercurl capability" "Smulx"       "$(tm show-options -g terminal-overrides)"

# Every binding in every table must carry a description. Bare `list-keys -N`
# covers root and prefix but silently omits copy-mode-vi, so check each table.
for table in root prefix copy-mode-vi; do
  total=$(tm list-keys -T "$table" 2>/dev/null | wc -l | tr -d ' ')
  noted=$(tm list-keys -T "$table" -N 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$total" -eq "$noted" ]]; then ok "all $table bindings described ($noted/$total)"
  else bad "all $table bindings described" "$total" "$noted"; fi
done
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./tests/tmux/verify.sh`

Expected: FAIL. No popup bindings exist, `set-clipboard` is `external`,
`detach-on-destroy` is `on`, `terminal-overrides` has no `Smulx`, and the
described-bindings counts do not match.

- [ ] **Step 3: Write minimal implementation — options**

In `config/tmux/tmux.conf`, change line 20 from `set -g` to `set -s`
(`default-terminal` has been a server option since tmux 3.2):

```tmux
set -s default-terminal "tmux-256color"
```

After the existing `terminal-features` lines, add:

```tmux
# Undercurl and coloured underlines, used by neovim LSP diagnostics.
# config/neovim/lua/plugins/colorscheme.lua enables undercurl in gruvbox.
set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}/%d::%p1%{256}/%{256}/%%d::%p1%{256}%%d%;m'
```

In the General Settings block, after `set -g focus-events on`, add:

```tmux
# OSC 52, so copying works over SSH.
set -g set-clipboard on

# Killing a session's last window switches to another session instead of
# ejecting the client to the shell.
set -g detach-on-destroy off
```

- [ ] **Step 4: Write minimal implementation — popups**

In the Key Bindings block, add:

```tmux
# `xargs -I{}` rather than `-r`: -r works on macOS but is undocumented there,
# while -I{} is documented and also skips execution on empty input.
bind -N "switch session (fzf)" s display-popup -E -w 40% -h 40% \
  "tmux list-sessions -F '#{session_name}' | fzf --reverse --header='switch session' | xargs -I{} tmux switch-client -t {}"
bind -N "lazygit"        g   display-popup -E -w 90% -h 90% -d "#{pane_current_path}" lazygit
bind -N "scratch shell"  C-t display-popup -E -d "#{pane_current_path}"
```

`prefix s` replaces the default `choose-tree`; it remains available on `prefix w`.

- [ ] **Step 5: Add descriptions to every pre-existing binding**

Add `-N "<description>"` to each binding already in the file. Use exactly these:

```tmux
bind -N "reload config"        r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
bind -N "split horizontally"   | split-window -h -c "#{pane_current_path}"
bind -N "split vertically"     - split-window -v -c "#{pane_current_path}"
bind -N "new window here"      c new-window -c "#{pane_current_path}"
bind -N "new named window"     N command-prompt -p "window name:" "new-window -n '%%' -c '#{pane_current_path}'"
bind -N "rename pane"          P command-prompt -p "pane title:" "select-pane -T '%%'"
bind -N "pane left"            h select-pane -L
bind -N "pane down"            j select-pane -D
bind -N "pane up"              k select-pane -U
bind -N "pane right"           l select-pane -R
bind -N "resize left"       -r H resize-pane -L 5
bind -N "resize down"       -r J resize-pane -D 5
bind -N "resize up"         -r K resize-pane -U 5
bind -N "resize right"      -r L resize-pane -R 5
bind -N "cycle panes"       -r o select-pane -t :.+
bind -N "move window first"    T move-window -t 1
bind -N "break pane out"       b break-pane -d
bind -N "copy mode"        Enter copy-mode
bind -T copy-mode-vi -N "begin selection"  v send -X begin-selection
bind -T copy-mode-vi -N "copy selection"   y send -X copy-selection-and-cancel
bind -T copy-mode-vi -N "rectangle toggle" C-v send -X rectangle-toggle
```

Keep `bind C-a send-prefix` as-is — it is tmux's prefix passthrough and already
carries a built-in description.

- [ ] **Step 6: Run test to verify it passes**

Run: `./tests/tmux/verify.sh`

Expected: PASS, `failed: 0`. If a described-bindings count mismatches, list the
offenders with:

```bash
diff <(tmux -L dotfiles-tmux-verify list-keys -T prefix | sort) \
     <(tmux -L dotfiles-tmux-verify list-keys -T prefix -N | sort)
```

- [ ] **Step 7: Verify popups live**

Reload in a real session (`tmux source-file ~/.config/tmux/tmux.conf`), then:

- `prefix g` opens lazygit in a 90% popup, rooted at the current pane's directory.
- `prefix s` opens an fzf list of sessions; selecting one switches to it.
- `prefix C-t` opens a scratch shell popup.
- `prefix ?` lists bindings with descriptions, including root-table `C-h`.

Note: `prefix s` needs at least two sessions to be meaningful, and `switch-client`
requires an attached client — it cannot be verified headlessly.

- [ ] **Step 8: Commit**

```bash
git add config/tmux/tmux.conf tests/tmux/verify.sh
git commit -m "feat(tmux): add popups, key descriptions and terminal capabilities"
```

---

### Task 6: Update documentation

**Files:**
- Modify: `docs/tmux-setup.md` (sections "Pre-configured Plugins", "Vim-Style
  Navigation", "Window Management", "Pane Management", "System")

**Interfaces:**
- Consumes: the final binding set from Tasks 4 and 5.
- Produces: nothing.

- [ ] **Step 1: Regenerate the authoritative binding list**

```bash
for t in root prefix copy-mode-vi; do echo "== $t =="; tmux list-keys -T $t -N; done
```

Use this output as the source of truth — do not transcribe from the plan.

- [ ] **Step 2: Update the plugin list**

In `docs/tmux-setup.md` under "### 3. Pre-configured Plugins", remove the
`tmux-sensible` and `tmux-copycat` entries. Add a line noting that
`vim-tmux-navigator` is installed on the neovim side, not via TPM.

- [ ] **Step 3: Update the keybinding tables**

- "### 3. Vim-Style Navigation" and "### Pane Management": document root-table
  `C-h/j/k/l` as prefix-free and vim-aware; keep `prefix h/j/k/l` listed as the
  fallback for full-screen TUIs.
- "### Window Management": replace `prefix C-h` / `prefix C-l` with
  `prefix n` / `prefix p`.
- "### System": add `prefix C-l` for clear-screen, and note that it moved because
  root `C-l` now steers panes.
- "### Session Management": document `prefix s` as the fzf switcher and `prefix w`
  as `choose-tree`.
- Add the three popups (`prefix g`, `prefix s`, `prefix C-t`).

- [ ] **Step 4: Document the environment behaviour**

Under "## XDG Directory Structure", add a short subsection stating that tmux
removes `ZDOTDIR` and the four `XDG_*` variables from each new process, so every
pane re-derives them from `~/.zshenv`. State the user-visible consequence: newly
created panes pick up `.zshenv` edits; already-open panes keep their old values.

- [ ] **Step 5: Verify the docs match reality**

Cross-check every keybinding in the doc against the Step 1 output. Any binding in
the doc that is not in the output is stale and must be removed.

- [ ] **Step 6: Commit**

```bash
git add docs/tmux-setup.md
git commit -m "docs: update tmux setup for new bindings and environment handling"
```

---

## Final Verification

Run after all tasks, against a **long-lived** session — a freshly started server
masks the environment bug.

- [ ] `./tests/tmux/verify.sh` exits 0 with no failures.
- [ ] Regression check for the reported bug: edit an XDG default in
      `config/zsh/.zshenv`, open a **new pane in an existing session**, and confirm
      both the changed variable and a derived one (`echo $ZDOTDIR $XDG_DATA_HOME $ZSH`)
      reflect the edit. Revert the edit afterwards.
- [ ] Already-open panes still show their old values — expected, not a failure.
- [ ] `ssh-add -l` succeeds in a pane after detach/reattach.
- [ ] `ls ~/.local/share/tmux/resurrect/` still lists the pre-existing saves.
- [ ] Status bar renders branch, dirty marker, battery and clock (needs an
      attached client; blank segments never reproduce headlessly).
- [ ] `git diff main --stat` touches only: `config/tmux/tmux.conf`,
      `config/tmux/statusline.conf`, `config/neovim/lua/plugins/tmux.lua`,
      `tests/tmux/verify.sh`, `docs/tmux-setup.md`, and the two spec/plan docs.
      **`config/zsh/.zshenv` must not appear.**
