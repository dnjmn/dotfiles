---
name: no-claude-coauthor
description: Never add Claude as co-author in git commits
metadata:
  type: feedback
---

Do not include "Co-Authored-By: Claude..." in any commit messages.

**Why:** User preference — Claude's contributions should not be attributed as co-authorship in the git history.

**How to apply:** When creating commits via `git commit`, use only the commit message body without the Co-Authored-By trailer. Omit it entirely.
