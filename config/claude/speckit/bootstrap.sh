#!/usr/bin/env bash
# Materialize spec-kit's per-project runtime at <project>/.specify.
#
# The speckit-* skills are global (~/.claude/skills/), but every one of them
# resolves scripts and templates against <project>/.specify — common.sh's
# find_specify_root() walks up for that directory and hard-fails without it,
# and resolve_template() reads only "$repo_root/.specify/templates". There is no
# env var to point either at a global location, so each project needs this once.
set -euo pipefail

SEED="${SPECKIT_SEED:-$HOME/.claude/speckit/seed}"

# How the global seed becomes <project>/.specify. Copying keeps the project
# self-contained and committable, so teammates and CI need no dotfiles.
materialize() {
  cp -R "$1" "$2"
}

main() {
  local start="${1:-$PWD}" root target
  [[ -d "$SEED" ]] || { echo "ERROR: seed not found: $SEED" >&2; return 1; }

  root="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null)" || root="$start"
  target="$root/.specify"

  # Idempotent: never clobber a constitution or template overrides already there.
  if [[ -d "$target" ]]; then
    echo "already initialized: $target"
    return 0
  fi

  materialize "$SEED" "$target"
  chmod +x "$target"/scripts/bash/*.sh

  echo "initialized: $target"
  echo "next: /speckit-constitution, then /speckit-specify"
}

main "$@"
