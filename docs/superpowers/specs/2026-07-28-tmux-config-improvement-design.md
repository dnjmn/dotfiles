# Tmux Config: Environment Correctness, Cost Reduction, 3.6 Ergonomics

**Date:** 2026-07-28
**Status:** Design approved, pending implementation plan
**Files:** `config/tmux/tmux.conf`, `config/tmux/statusline.conf`,
`config/neovim/lua/plugins/tmux.lua` (new), `docs/tmux-setup.md`

## Problem

The config works, but four things are measurably wrong on this machine
(tmux 3.6a, macOS arm64, kitty). Item 4 is the user-reported bug; items 1-3
were found while investigating it.

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

**4. New panes in long-lived sessions get stale environment variables.**
Reported symptom: editing `.zshenv` does not affect new panes in resurrected
sessions. Root cause established by reproduction (see below), not inspection.

New panes *do* re-source `.zshenv`. The failure is that `.zshenv:6-9` uses the
`${VAR:-default}` idiom, which by design yields to an inherited value — and
tmux hands down a copy of the environment frozen when the *server* started.
Reproduction on a scratch socket, server started holding `XDG_DATA_HOME=STALE_OLD`
and `.zshenv` then edited:

| variable | form | result |
|---|---|---|
| `XDG_DATA_HOME` | `${VAR:-default}` | `STALE_OLD` — stale |
| `DERIVED` | unconditional, derived from XDG | `STALE_OLD/oh-my-zsh` — poisoned |
| `UNCONDITIONAL` | plain export | updated correctly |
| `NEWVAR` | newly added | appeared correctly |

This is why the bug looks inconsistent: plain exports (`EDITOR`, `GOPATH`,
`CLAUDE_CODE_SUBAGENT_MODEL`) update fine, while the four XDG vars and roughly
fifteen values computed from them (`HISTFILE:13`, `ZSH:20`, `ZSH_CUSTOM:26`,
`NPM_CONFIG_*:30-31`, `AWS_*:40-41`, `SECRETS:84`, the Homebrew branch at `:57`)
silently do not.

Two findings fell out of the investigation:

- **`ZDOTDIR` cannot be repaired from the shell side.** zsh reads
  `$ZDOTDIR/.zshenv` *instead of* `~/.zshenv` when `ZDOTDIR` is already set, so
  a stale value means the file that would fix it never loads. Reproduced: stale
  `ZDOTDIR` yielded `BOOTSTRAPPED=<EMPTY>`, i.e. no config at all.
- **`tmux.conf:14` silently dropped nine defaults.** `set -g update-environment`
  *replaces* the list rather than extending it, discarding `SSH_AUTH_SOCK`,
  `SSH_AGENT_PID`, `SSH_CONNECTION`, `DISPLAY` and five more. Since the git
  remote is `git@github.com:` and macOS assigns ssh-agent a new socket path per
  login, reattaching an old session after a reboot leaves `SSH_AUTH_SOCK`
  pointing at a dead socket and `git push` fails with a publickey error.

`update-environment` was also the wrong tool for the reported symptom: it fires
only on client **attach**, never on pane creation.

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

Its remaining contributions are already covered: prefix passthrough
(`tmux.conf:64`) and reload (`:67`) are bound in the file, and its `C-p`/`C-n`
window nav is superseded by the `bind -r n`/`p` introduced below.

**What would change this answer:** if a future tmux release adds several new
sensible defaults worth tracking upstream, re-adopting the plugin becomes
cheaper than maintaining them by hand.

### Trim the status bar rather than caching it

Rejected alternative: keep all six segments, backed by a background script
writing a cache file on a slower schedule. That preserves the k8s/docker
readout but adds a script, a cache path, and a staleness question, to display
information that is rarely load-bearing while coding.

Right side becomes git + battery + clock. `status-left` stays `""`.

| | before (measured) | after (projected) |
|---|---|---|
| interval | 2 s | 5 s |
| processes per refresh | ~23 | ~5 |
| subprocess wall time | 590 ms / 2 s (29%) | ~90 ms / 5 s (1.8%) |

The "before" column is measured. The "after" column is a projection from the
same per-command timings (git 56 ms + `pmset` 35 ms) and must be re-measured
against the real status line during verification, not assumed.

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

### Stop tmux propagating static config vars; fix it in tmux, not in `.zshenv`

The five static config variables are removed from tmux's inheritance so every
new pane re-derives them:

```tmux
set-environment -gr ZDOTDIR
set-environment -gr XDG_CONFIG_HOME
set-environment -gr XDG_DATA_HOME
set-environment -gr XDG_CACHE_HOME
set-environment -gr XDG_STATE_HOME
```

`-r` marks a variable for removal from the environment before a new process
starts. Verified: with tmux's env still holding `STALE_OLD`, a new pane resolved
`DEFAULT_FRESH`, derived variables followed, and a brand-new session inherited
the behaviour. For `ZDOTDIR` specifically, removal makes zsh fall back to
`~/.zshenv`, which sets `ZDOTDIR` unconditionally (`~/.zshenv:6`) and re-sources
the real config — self-healing on every pane.

Rejected alternative: make `.zshenv:6-9` unconditional exports. Also verified
working, but it cannot fix `ZDOTDIR` (chicken-and-egg), it costs XDG-spec
compliance and portability to systems that legitimately set these, and it leaves
the actual mechanism — tmux propagating a frozen copy of static config — in
place. The `:-` guards are correct code being fed a stale value; the value is
the defect, not the guard.

Rejected alternative: force each new pane to source `~/.zshenv`, e.g. via
`set -g default-command 'source ~/.zshenv; exec zsh'`. This does not work.
`$ZDOTDIR/.zshenv` is already sourced by every new pane — verified, since newly
added and unconditional variables do update — and re-sourcing cannot overcome a
stale value, because `${VAR:-default}` substitutes only when `VAR` is unset.
Measured with `XDG_DATA_HOME=STALE` present: sourcing once, twice and three
times all yield `STALE`; removing the variable first yields `FRESH_DEFAULT`.
The approach also adds a shell layer and interferes with tmux-resurrect's
restored pane commands.

The valid part of that idea is delivered by the chosen fix. zsh reads
`$ZDOTDIR/.zshenv` *instead of* `~/.zshenv`, so the bootstrap file never runs
inside tmux today (verified both ways). Removing `ZDOTDIR` restores it, giving
a full re-bootstrap per pane — by removal rather than by adding a source
command.

Scope confirmed with the user: only newly created panes need correct values.
Already-running panes keep what they have, which is inherent — a running
process's environment cannot be changed externally.

Consequence accepted: every process tmux starts without a shell — including
`run-shell` plugin scripts — receives no XDG vars. Harmless here because all
four values equal the XDG spec defaults, so a program falling back to its own
default resolves the same path.

The load-bearing instance is tmux-resurrect, which computes its save directory
with the *same* idiom at `scripts/helpers.sh:4`:

```sh
default_resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}"/tmux/resurrect
```

Verified both ways — with `XDG_DATA_HOME` set and unset, the path is identically
`~/.local/share/tmux/resurrect`, where the existing saves already live.
`~/.tmux/resurrect` does not exist, so the legacy branch at `helpers.sh:1`
stays inactive, and `@resurrect-dir` is not overridden in the config.

**Implementation must not treat this as incidental.** If `XDG_DATA_HOME` ever
diverges from `$HOME/.local/share`, resurrect silently begins saving to a new
directory and existing session history appears to vanish. Guard: set
`@resurrect-dir` explicitly rather than relying on the default.

`tmux.conf:14` is deleted, restoring tmux's nine `update-environment` defaults —
the per-client variables the option exists for.

**What would change this answer:** if XDG values ever diverge from the spec
defaults, non-shell panes would need `default-command` or an explicit wrapper.

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

Remove: `update-environment` override at `:14` (restores tmux's nine defaults,
fixing `SSH_AUTH_SOCK`); `status-interval` at `:47` (single home for the fact is
`statusline.conf`); `@plugin tmux-copycat`; `@plugin tmux-sensible`;
`@yank_selection 'primary'`; window-nav binds at `:97-98`.

Add: the five `set-environment -gr` lines, `status-keys emacs`,
`aggressive-resize on`, `set-clipboard on` (OSC-52 copy over SSH),
`detach-on-destroy off` (killing a session's last window lands in another
session instead of ejecting to the shell), undercurl `terminal-overrides` so
nvim LSP diagnostics render in kitty, root-table `C-hjkl` navigation,
`prefix + C-l` shell-clear, `bind -r n`/`p`.

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
3. Assert every binding has a description, checking **each key table
   explicitly**: `list-keys -T root -N`, `-T prefix -N`, `-T copy-mode-vi -N`.
   Bare `list-keys -N` is not sufficient — verified that it covers the root and
   prefix tables but silently omits `copy-mode-vi`. Since `prefix + ?` is bound
   to plain `list-keys -N`, copy-mode bindings will not appear there; that is
   tmux behaviour, not a defect to fix.
4. Re-measure fork rate over 60 s of idle; expect ~1 fork/s against a ~11.5
   fork/s baseline.
5. Live check: `C-h`/`C-l` crosses an nvim split boundary into a tmux pane and
   back; `prefix + C-l` clears the shell; `prefix + g` opens lazygit;
   `prefix + s` fuzzy-switches sessions.
6. Confirm the status bar renders branch, dirty marker, battery and clock with
   correct gruvbox separators.
7. Environment fix, against a **long-lived** session (not a fresh server, which
   would mask the bug):
   - `tmux show-environment -g | grep -E '^-?(ZDOTDIR|XDG_)'` shows each of the
     five prefixed with `-`, marking it for removal.
   - In a pane opened *after* the change: `echo $ZDOTDIR` resolves correctly and
     `echo $XDG_DATA_HOME` matches the current `.zshenv`, while
     `tmux show-environment` may still report the old value — that divergence is
     the fix working.
   - Regression guard: edit an XDG default in `.zshenv`, open a new pane in an
     existing session, confirm the new value and a derived variable
     (for example `$ZSH`) both follow.
   - Already-open panes are expected to keep their old values.
8. `tmux show-options -g update-environment` lists tmux's nine defaults,
   including `SSH_AUTH_SOCK`. Confirm `ssh-add -l` succeeds in a pane after
   detach/reattach.
