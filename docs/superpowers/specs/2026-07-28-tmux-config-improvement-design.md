# Tmux Config: Cost Reduction and 3.6 Ergonomics

**Date:** 2026-07-28
**Status:** Design approved, pending implementation plan
**Files:** `config/tmux/tmux.conf`, `config/tmux/statusline.conf`,
`config/neovim/lua/plugins/tmux.lua` (new), `docs/tmux-setup.md`

## Problem

The config works, but three things are measurably wrong on this machine
(tmux 3.6a, macOS arm64, kitty):

**1. The status bar burns CPU continuously.** `statusline.conf:22` sets
`status-interval 2`, silently overriding `tmux.conf:47`. Each refresh forks ~23
processes across six `#()` jobs. Measured wall time per command:

| command | time |
|---|---|
| `top -l 1 -n 0` | 274 ms |
| `docker ps -q` | 144 ms |
| `kubectl config current-context` | 54 ms |
| git branch + dirty (4 git calls) | 116 ms |
| `pmset -g batt` | 35 ms |
| `memory_pressure` | 30 ms |

That is ~590 ms of subprocess work every 2 s — a 29% duty cycle, roughly 41,000
processes per hour, on a laptop. `#()` runs asynchronously so the UI never
blocks; the cost is battery and CPU, not latency.

**2. Two settings are inert or obsolete.** `tmux-copycat` (`tmux.conf:152`) is
superseded by native regex search — its own README says so for tmux 3.1+.
`@yank_selection 'primary'` (`tmux.conf:164`) is an X11 concept and does nothing
on macOS.

**3. Effective settings are decided by a plugin, not by the file.**
`tmux-sensible` applies `escape-time`, `history-limit`, `display-time` and
`focus-events` only when it judges the value "unchanged", by string-comparing
against tmux's compiled-in default (`sensible.tmux:82-112`). It runs from
`run tpm` at the bottom of the file, i.e. after everything above it. The config
sets all four explicitly anyway, so the plugin's arbitration is invisible
coupling with no benefit.

Separately, the setup misses ergonomics that tmux 3.2+ makes cheap: no popups,
no fuzzy session switching despite `fzf` being installed, no seamless
nvim-to-tmux pane navigation despite nvim being the editor, no key
descriptions, no undercurl for LSP diagnostics.

## Non-Goals

No structural rewrite. The two-file split (`tmux.conf` + `statusline.conf`)
stays, which also means `install/tmux.sh:22-26` needs no change. The gruvbox
theme, `C-a` prefix, `|`/`-` splits, vi copy-mode, and resurrect/continuum
persistence are all deliberate and are kept.

Not adopting a curated plugin pack. The only plugin change is removals.

## Decisions

### Drop `tmux-sensible`; make every setting explicit

Rejected alternative: keep the plugin and delete the four duplicated lines.
That is a shorter file but leaves the effective config dependent on plugin
heuristics resolved after the file is read.

Dropping it loses exactly two settings, absorbed directly:

```tmux
set -g status-keys emacs
setw -g aggressive-resize on
```

Its remaining contributions are already bound in the file: prefix passthrough
(`tmux.conf:64`), reload (`:67`), window nav (`:97-98`).

**What would change this answer:** if a future tmux release adds several new
sensible defaults worth tracking upstream, re-adopting the plugin becomes
cheaper than maintaining them by hand.

### Trim the status bar rather than caching it

Rejected alternative: keep all six segments, backed by a background script
writing a cache file on a slower schedule. That preserves the k8s/docker
readout but adds a script, a cache path, and a staleness question, to display
information that is rarely load-bearing while coding.

Right side becomes git + battery + clock. `status-left` stays `""`.

| | before | after |
|---|---|---|
| interval | 2 s | 5 s |
| processes per refresh | ~23 | ~5 |
| subprocess wall time | 590 ms / 2 s (29%) | ~90 ms / 5 s (1.8%) |

The git segment collapses from four processes to one. Verified against this
repo: `git status --porcelain=v2 --branch` takes 56 ms versus 116 ms for the
current `rev-parse` + `branch` + `diff` + `diff --cached` chain, and parses to
branch-plus-dirty-flag in a single `awk`. `git -C` replaces the `cd` subshell.

### Detect vim by format match, not by `ps`

The canonical `vim-tmux-navigator` tmux snippet forks a `ps | grep` pipeline on
every `C-h/j/k/l` press. tmux 3.1+ can do the same test inside a format string,
forking nothing:

```tmux
bind -n C-h if -F '#{m/ri:^(g?(view|l?n?vim?x?)(diff)?|fzf|lazygit)$,#{pane_current_command}}' \
  'send-keys C-h' 'select-pane -L'
```

Verified on 3.6a: the binding is accepted and the format evaluates to `0`
against a `zsh` pane.

The nvim half is `christoomey/vim-tmux-navigator` in a new
`config/neovim/lua/plugins/tmux.lua`. `install/neovim.sh:31` symlinks the whole
`config/neovim` directory, so no install-script change is needed.

Two consequences, both handled:

- tmux swallows `C-l`, so shell-clear moves to `prefix + C-l`.
- Root-table `C-hjkl` now means *panes*, which conflicts conceptually with
  `prefix + C-h`/`C-l` meaning *windows* (`tmux.conf:97-98`). Those two lines
  are replaced by `bind -r n next-window` / `bind -r p previous-window` — tmux
  binds `prefix n`/`p` by default, so this only adds repeat.

`prefix + h/j/k/l` is kept as a fallback for when a full-screen TUI captures
`C-hjkl`.

### Persistence tuning

`@continuum-save-interval` returns to `15`, the upstream default. Note this
reverts an uncommitted local change to `1` present in the working tree at design
time. Auto-restore and pane-content capture are unchanged. Worst case on a
crash is losing 15 minutes of *layout* changes, not shell history.

## Changes

### `config/tmux/tmux.conf`

Keep unchanged: `history-limit`, `display-time`, `focus-events`, `escape-time`.
These stay exactly as written; dropping `tmux-sensible` is what makes them
authoritative rather than contested.

Remove: `status-interval` at `:47` (single home for the fact is
`statusline.conf`); `@plugin tmux-copycat`; `@plugin tmux-sensible`;
`@yank_selection 'primary'`; window-nav binds at `:97-98`.

Add: `status-keys emacs`, `aggressive-resize on`, `set-clipboard on` (OSC-52
copy over SSH), `detach-on-destroy off` (killing a session's last window lands
in another session instead of ejecting to the shell), undercurl
`terminal-overrides` so nvim LSP diagnostics render in kitty, root-table
`C-hjkl` navigation, `prefix + C-l` shell-clear, `bind -r n`/`p`.

Change: `default-terminal` from `set -g` to `set -s` — it has been a server
option since 3.2; `show-options -s` confirms it currently lands there anyway.

Popups:

```tmux
bind g   display-popup -E -w 90% -h 90% -d "#{pane_current_path}" lazygit
bind C-t display-popup -E -d "#{pane_current_path}"
bind s   display-popup -E -w 40% -h 40% \
  "tmux list-sessions -F '#{session_name}' | fzf --reverse --header='switch session' \
   | xargs -I{} tmux switch-client -t {}"
```

`xargs -I{}` rather than `-r`: `-r` works on this machine but is absent from the
macOS `xargs` man page, while `-I{}` is documented and also skips execution on
empty input. Verified: the `prefix + s` binding parses from a config file with
`#{session_name}` intact and registers its `-N` description.

`prefix + s` replaces `choose-tree`; `choose-tree` remains on `prefix + w`.

Every binding gets a `-N` description, making `prefix + ?` self-documenting.

### `config/tmux/statusline.conf`

`status-interval` 2 to 5. `status-right-length` 200 to ~60. `status-right`
reduced to git, battery, clock. Window formats, mode/message styles, and clock
config unchanged.

### `config/neovim/lua/plugins/tmux.lua` (new)

`christoomey/vim-tmux-navigator`, lazy-loaded on its `TmuxNavigate*` commands
and `<C-h/j/k/l>` keys, following the existing `lua/plugins/` spec style.

### `docs/tmux-setup.md`

Keybinding tables and plugin list updated to match.

## Verification

1. Boot a throwaway server against the new config
   (`tmux -f <conf> new-session -d -s verify`); confirm no parse errors.
2. Diff `show-options -g` and `show-options -s` against a baseline captured
   from the current config; every difference must be intentional per this spec.
3. Assert `list-keys -N` reports no binding with an empty description.
4. Re-measure fork rate over 60 s of idle; expect ~1 fork/s against a ~11.5
   fork/s baseline.
5. Live check: `C-h`/`C-l` crosses an nvim split boundary into a tmux pane and
   back; `prefix + C-l` clears the shell; `prefix + g` opens lazygit;
   `prefix + s` fuzzy-switches sessions.
6. Confirm the status bar renders branch, dirty marker, battery and clock with
   correct gruvbox separators.
