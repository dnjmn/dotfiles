# session-journal — Design Spec

**Date:** 2026-07-16
**Status:** Approved for planning

## Purpose

A local Obsidian vault that automatically documents the what/when/where/how/why of
daily engineering work, captured from (1) Claude Code sessions and (2) interactive
zsh commands, with zero manual effort. Queryable in natural language from any Claude
Code session via a `/journal` skill ("what did I do yesterday?", "when did I change
the gateway config and why?", "which cluster did I run that migration on?").

## Requirements

### Functional

- **FR1 — Session capture.** When a Claude Code session ends (`/clear`, exit,
  before `--resume`), record metadata (project, cwd, git branch, start/end time,
  model, end reason) and produce a narrative note: what was asked, what was done
  (files changed, commands run), key decisions and why, and outcome
  (done / in-progress / blocked, plus where work left off).
- **FR2 — Shell capture.** Log every interactive zsh command with timestamp, cwd,
  exit code, and duration. Commands matching `kubectl|helm|k9s|stern` additionally
  record the active kube context. Surfaced through `/journal` queries.
- **FR3 — Journal everything.** Every session gets a note; trivial sessions get a
  compact note rather than being skipped.
- **FR4 — Daily note.** One note per day linking all session notes with one-line
  summaries. Updated live (pending line at session end, replaced when the summary
  lands).
- **FR5 — Retrieval skill.** `/journal` answers natural-language questions over the
  vault; `/journal sync` recovers unjournaled sessions.
- **FR6 — Vault bootstrap.** Installer creates the vault (folder layout, templates,
  project MOC stubs) and wires all hooks/config.
- **FR7 — Crash resilience.** Sessions that end without a hook firing (crash,
  SIGKILL, sleep) are recovered by `/journal sync`, which sweeps
  `~/.claude/projects/` for unprocessed transcripts.

### Non-functional

- **NFR1 — Never block.** SessionEnd hook does file appends only (<1s); the
  summarizer runs as a detached process. `/clear` must not feel slower.
- **NFR2 — Cost-bounded.** Summarization model is a single config value
  (`JOURNAL_MODEL`, default `sonnet`; ~$0.20/session estimated vs ~$1/session for
  opus). Recursion guarded: `claude -p` runs with `--bare` (no hooks loaded) plus a
  `JOURNAL_SUMMARIZING=1` env check in the capture hook.
- **NFR3 — Local-only.** Vault lives on this machine; no secret redaction in v1.
  Revisit before ever syncing the vault.
- **NFR4 — Survive Claude Code updates.** The transcript JSONL schema is
  documented as unstable. Narrative generation uses the documented interface
  (`claude -p --resume`); direct JSONL parsing is best-effort stats only and
  degrades gracefully (omitted frontmatter fields, never fatal).
- **NFR5 — Idempotent.** Reprocessing a session never duplicates notes or daily
  lines. Keyed by `session_id` + transcript mtime; daily-note lines carry a hidden
  `<!-- sid:… -->` marker for in-place replacement.
- **NFR6 — Shell-safe.** The zsh module must never break the shell: no
  subprocesses in the hot path, every function failure-proofed (`|| true`).

### Out of scope (v1)

Multi-machine sync, secret redaction, browser/calendar capture, Obsidian plugin
development, scheduled jobs (no launchd). **v1.1 candidates:** `/journal standup`
(yesterday/today/blockers), weekly rollups, skill evals like `document-learning`.

## Decisions log

| Decision | Choice | Rationale |
|---|---|---|
| Capture scope | Claude sessions + zsh history | Full "what did I do" picture; shell layer is cheap and deterministic |
| Vault | New, `~/Journal` (configurable) | No existing vault; design conventions from scratch |
| Privacy | Local-only, no redaction | Vault treated like `~/.claude` itself |
| Noise filter | Journal everything | User preference; compact notes for trivial sessions |
| Summarization timing | Real-time at SessionEnd (detached), no nightly digest | User preference; `/journal sync` replaces the digest's sweep role; rollups are generated lazily on query |
| Model | `sonnet` default, configurable | Opus estimated $5–15/day at journal-everything volume; one-line switch if richer summaries prove worth it |
| Config location | `~/.config/session-journal/config` (XDG, repo-managed) | Matches dotfiles conventions; vault `.journal/` holds only state/data |

## Architecture

Four runtime components plus an installer. One writer owns the vault (the
summarizer); capture components only append to inbox/log files.

```
Claude session ends ──▶ session-capture (SessionEnd hook, bash)
                          appends inbox record + daily pending line,
                          setsid-detaches summarizer (skip when reason=resume)
zsh command ──────────▶ shell-capture (zsh preexec/precmd)
                          one JSON line per command
hook (detached) ──────▶ journal-summarize <session_id> <transcript_path>
/journal sync ────────▶   stats → claude -p (sonnet) → session note,
                          daily-note marker replace, processed.json
"what did I do…?" ────▶ journal skill (/journal)
                          searches vault + shell logs; sync = sweep + summarize
one-time ─────────────▶ install/session-journal.sh
```

### Repo layout (dotfiles)

```
config/claude/journal/session-capture.sh      # SessionEnd hook
config/claude/journal/journal-summarize.sh    # single vault writer
config/claude/journal/summarize-prompt.md     # fixed summarization prompt
config/claude/skills/journal/SKILL.md         # /journal skill
config/claude/settings.json                   # + hooks.SessionEnd registration
config/session-journal/config                 # KEY=VALUE, symlinked to ~/.config/session-journal/
config/zsh/…                                  # shell-capture module (follow config/zsh/CLAUDE.md conventions)
install/session-journal.sh                    # bootstrap (standard install-script pattern)
```

`config/claude/` is live as `~/.claude` via symlink, so hook paths in settings.json
reference `~/.claude/journal/…`.

### Hook registration (settings.json)

```json
"hooks": {
  "SessionEnd": [
    { "hooks": [ { "type": "command",
                   "command": "~/.claude/journal/session-capture.sh",
                   "timeout": 10 } ] }
  ]
}
```

No matcher — the script branches on `reason` itself (all reasons update the inbox;
`resume` skips summarization because the session isn't over).

## Vault design

```
~/Journal/
├── daily/2026/07/2026-07-16.md
├── sessions/2026/07/2026-07-16-1030-dotfiles-fix-zsh-aliases.md
├── projects/dotfiles.md            # MOC stub, created once, self-maintaining
└── .journal/                       # dot-folder: hidden from Obsidian
    ├── inbox.jsonl                 # session-end events
    ├── processed.json              # session_id → {mtime, note, summarized_at}
    ├── shell/2026-07-16.jsonl
    └── log/summarize.log
```

### Session note

Filename: `YYYY-MM-DD-HHMM-<project>-<slug>.md` (unique, wikilink-friendly).

```markdown
---
type: session
date: 2026-07-16
time: "10:30"
session_id: <uuid>
project: "[[dotfiles]]"
cwd: /Users/…/dotfiles/config/claude
branch: mac
duration_min: 47
model: claude-fable-5
end_reason: clear
files_modified: [config/claude/settings.json]
tags: [session]
---
# <Title>

**TL;DR** — one paragraph.

## What happened
## Decisions & why
## Commands of note        ← kubectl/helm/git worth remembering, cluster context when visible
## Outcome & handoff       ← done/in-progress/blocked + exactly where work left off

---
Transcript: ~/.claude/projects/…/<session_id>.jsonl
```

Frontmatter fields are chosen so Obsidian Bases/Dataview can filter by project,
date, model, and files without plugins being required for basic use. Stats fields
(`duration_min`, `files_modified`) are best-effort and omitted if extraction fails.

### Daily note

```markdown
---
type: daily
date: 2026-07-16
tags: [daily]
---
# 2026-07-16

## Sessions
- 10:30 [[2026-07-16-1030-dotfiles-fix-zsh-aliases|Fix zsh aliases]] (dotfiles, 47m) — one-liner <!-- sid:<uuid> -->
- 16:26 ⏳ dotfiles — summarizing… <!-- sid:<uuid> -->
```

The capture hook appends the ⏳ line; the summarizer replaces the line bearing the
matching `sid` marker. A surviving ⏳ line is the visible signal that a summary
failed and `/journal sync` should be run.

### Project MOCs

`projects/<name>.md` is a stub created on first sight of a project, containing a
Bases/Dataview query over `project` frontmatter. Session notes link to it via
`project: "[[name]]"`, so backlinks and the embedded query keep it current with no
writer process. Project name = terminal path component of the repo root (fallback:
of cwd).

## Component details

### session-capture.sh (SessionEnd hook)

1. Exit 0 immediately if `JOURNAL_SUMMARIZING=1` (recursion guard) or vault absent
   (pre-bootstrap; log to stderr).
2. Read hook JSON from stdin: `session_id`, `transcript_path`, `cwd`, `reason`.
3. Append event to `.journal/inbox.jsonl`.
4. Ensure today's daily note exists (from template); append ⏳ pending line with
   `sid` marker under `flock`.
5. If `reason != resume`: `setsid journal-summarize.sh <session_id> <transcript_path> >>log 2>&1 &`.

File appends only; no LLM, no network. Total <1s.

### journal-summarize.sh (single vault writer)

1. Per-session lockdir (`.journal/lock/<session_id>/`) — hook spawn and sync sweep
   never double-run; stale locks older than 1h are reclaimed.
2. Skip if `processed.json[session_id].mtime` equals current transcript mtime.
3. Best-effort stats via `jq`: start/end timestamps, files modified, git branch.
   Any failure → omit fields, continue.
4. `JOURNAL_SUMMARIZING=1 claude -p --resume <session_id> --fork-session --bare
   --model $JOURNAL_MODEL --output-format json < summarize-prompt.md`.
   `--fork-session` keeps the summary turn out of the original transcript; `--bare`
   loads no hooks/skills/MCP.
5. Parse result; write session note atomically (tmp + `mv`). Compact note for
   trivial sessions is the prompt's responsibility (template instructs scaling).
6. Replace daily-note ⏳ line by `sid` marker under `flock`; create project MOC
   stub if missing.
7. On success only: update `processed.json`. Always: log one structured line to
   `.journal/log/summarize.log`.
8. A resumed-then-ended session has a new mtime → re-summarized → note overwritten
   in place (path looked up from `processed.json`).

### shell-capture (zsh module)

- `preexec`: capture command text + epoch ms. `precmd`: exit code + duration;
  append one JSON line to `.journal/shell/YYYY-MM-DD.jsonl`.
- Kube context only for commands matching `^(kubectl|helm|k9s|stern)`: parse
  `current-context:` from `$KUBECONFIG`/`~/.kube/config` with zsh built-ins/awk —
  no `kubectl` invocation in the hot path.
- Non-interactive shells don't fire `preexec`, so commands Claude runs via its
  Bash tool are not double-captured (they're covered by session notes).
- Record shape: `{ts, cwd, cmd, exit, dur_ms, kube_ctx?}`.

### /journal skill

Teaches Claude the vault layout and query strategy:

- "what did I do on/since X" → read daily notes for the range.
- project/file questions → grep session-note frontmatter (`project`,
  `files_modified`), then read matching notes.
- command/cluster questions → search `.journal/shell/*.jsonl` and session notes'
  "Commands of note".
- Rollups ("summarize my week") → lazy synthesis over daily notes + TL;DRs.
- `/journal sync` → list transcripts under `~/.claude/projects/*/*.jsonl` with
  mtime newer than their `processed.json` entry (or absent), run
  `journal-summarize.sh` for each, report recovered sessions.

### install/session-journal.sh

Standard install-script pattern (`REPO_ROOT`, `platform.sh`, `install_deps` →
`link_configs` → `post_install`): dependency check (`jq`, `claude`), create vault
tree + templates, symlink config to `~/.config/session-journal/`, wire zsh module,
verify hook registration in settings.json (settings.json edit is committed in the
repo, not done by the installer). Idempotent re-runs.

## Error handling

| Failure | Behavior | Recovery |
|---|---|---|
| Summarizer/`claude -p` fails or offline | ⏳ line stays in daily note; not marked processed; logged | `/journal sync` retries |
| Session crash / SIGKILL (no hook) | No inbox event | `/journal sync` sweep finds transcript by mtime |
| Transcript schema drift | Stats extraction degrades; `--resume` path unaffected | Omitted frontmatter fields only |
| Concurrent session ends | `flock` on daily note; per-session lockdirs | — |
| Vault missing / pre-bootstrap | Hooks no-op with a log line | Run installer |
| zsh module error | Swallowed (`|| true`); shell unaffected | Fix at leisure |

Nothing fails silently into data loss: the transcript remains the source of truth
until `processed.json` says otherwise, and the ⏳ marker makes failure visible in
the vault itself.

## Testing

- **bats/sh tests** (fixtures, no network):
  - capture: fixture stdin JSON → inbox line + ⏳ daily line; `resume` reason → no
    summarizer spawn; recursion-guard env → no-op.
  - summarizer: stub `claude` binary prepended to PATH → note
    written with correct frontmatter, marker replaced, `processed.json` updated;
    second run is a no-op; failing stub → not marked processed, ⏳ survives.
  - sweep: fixture transcript dir with one unprocessed file → exactly one
    summarizer invocation.
  - shell module: interactive `zsh -i` fixture run → correct JSONL record;
    `kubectl` command → `kube_ctx` present.
- **Manual acceptance:** real session → `/clear` → note appears in Obsidian within
  ~1 min; `kill -9` a session mid-flight → `/journal sync` recovers it; `/journal
  what did I do today` answers correctly.

## References

- Hooks: https://code.claude.com/docs/en/hooks.md, hooks-guide.md, headless.md
  (SessionEnd payload/reasons, fire-and-forget semantics, `--bare`, recursion env
  vars, transcript-schema instability warning)
- Prior art: FlorianBruniaux/claude-code-ultimate-guide `session-summary.sh`
  (section analytics), wiggitywhitney/commit-story (narrative journal structure),
  simonwillison claude-code-transcripts, Obsidian daily-note/Dataview/Bases
  conventions (frontmatter-driven filtering)
