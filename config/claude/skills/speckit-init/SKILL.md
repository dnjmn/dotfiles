---
name: "speckit-init"
description: "Set up spec-kit in the current project by creating .specify/ with the scripts, templates and constitution the other speckit-* skills need. Use before the first /speckit-specify in a repo, or when a speckit skill reports a missing .specify directory."
argument-hint: "Optional path to initialize instead of the current repo"
metadata:
  author: "dnjmn-dotfiles"
  source: "config/claude/speckit/bootstrap.sh"
user-invocable: true
disable-model-invocation: false
---

## Goal

Give the current project the `.specify/` runtime that every other `speckit-*`
skill depends on. The skills themselves are installed globally; only this
per-project state is missing.

## Steps

1. Run the bootstrap, passing `$ARGUMENTS` as the starting directory if non-empty:

   ```bash
   ~/.claude/speckit/bootstrap.sh $ARGUMENTS
   ```

2. Report what it printed. `already initialized` means there is nothing to do —
   do **not** delete or overwrite the existing `.specify/`.

3. On success, tell the user the recommended order:
   `/speckit-constitution` → `/speckit-specify` → `/speckit-plan` →
   `/speckit-tasks` → `/speckit-implement`.

## Notes

- `.specify/memory/constitution.md` lands as an unfilled template. It holds the
  project's own principles, so `/speckit-constitution` fills it — never copy one
  project's constitution into another.
- The vendored spec-kit version is recorded in `~/.claude/speckit/VERSION`.
