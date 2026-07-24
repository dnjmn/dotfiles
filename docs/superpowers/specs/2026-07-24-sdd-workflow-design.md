# Subagent-Driven Development as a Workflow Script

**Date:** 2026-07-24
**Status:** Design approved, pending implementation plan

## Problem

`superpowers:subagent-driven-development` (SDD) is a prose skill that a controller
agent follows by hand. Its correctness depends entirely on the controller's
discipline: remembering to generate a diff package before every review, tracking
the right BASE commit per task, never re-dispatching a completed task, never
skipping a review loop, never dispatching one fixer per finding.

Every one of those is a rule the controller can silently violate. The skill's own
text documents real sessions where controllers did: re-dispatching entire completed
task sequences after compaction, pasting 42k characters of accumulated history into
a dispatch, spending more on a final-review fix wave than on all the tasks combined.

Porting SDD to a `Workflow` script converts those rules from discipline into code.

## Non-Goals

Parallelism is not the motivation. SDD explicitly forbids concurrent implementer
subagents (they conflict in the working tree), so the task loop is a strictly
sequential `for`. Fan-out earns its keep in exactly one place: the final
whole-branch review.

## Constraints Discovered

Facts about the `Workflow` runtime that shape the design:

1. **No human channel.** `agent()` is one-shot; a script cannot ask a question. SDD
   mandates three human decision points (pre-flight plan conflicts, plan-mandated
   findings, unresolvable `BLOCKED`).
2. **No filesystem, no `Date.now()` / `Math.random()`.** `scripts/task-brief` and
   `scripts/review-package` are bash. Only an agent can run them.
3. **The script has no context window.** SDD's file-handoff machinery exists to
   protect the *controller's* context. A JS orchestrator has none, so those handoffs
   become optional plumbing rather than a correctness requirement.
4. **`resumeFromRunId` caches by `(prompt, opts)`.** The longest unchanged prefix of
   `agent()` calls replays instantly. This partially replaces SDD's progress ledger —
   in-session only.
5. **Workflow size guideline is `medium`** (under 15 agents), per `/config`.

## Architecture

Three phases. `args = { planPath, specPath?, decisions?, allowMainBranch? }`.

### Phase 1 — Preflight (1 agent, most capable model, high effort)

One agent reads the plan and spec and runs git. Both of its jobs are the same job —
"characterize this plan" — so they are cohesive in one agent rather than split.

Returns via schema:

| Field | Purpose |
|---|---|
| `tasks[]` | `{n, title, complexity, implementerModel, implementerEffort, reviewerModel}` — SDD's Model Selection applied per task |
| `globalConstraints` | Copied **verbatim** from the plan's Global Constraints / spec. Becomes every reviewer's attention lens. |
| `conflicts[]` | Plan text mandating something the review rubric treats as a defect |
| `baseSha` | `git rev-parse HEAD` — the initial BASE |
| `mergeBase` | `git merge-base main HEAD` — BASE for the final review |
| `currentBranch` | For the main/master guard |
| `completedTasks[]` | Parsed from `.superpowers/sdd/progress.md` |
| `scriptsDir` | Absolute path to the SDD skill's `scripts/` directory, discovered by glob. The superpowers plugin path is version-pinned (`.../superpowers/6.1.1/...`), so hardcoding it would break on every plugin upgrade. |

**Gates.** Non-empty `conflicts` not covered by `args.decisions` → return. Branch is
`main`/`master` without `args.allowMainBranch` → return. Tasks listed in
`completedTasks` are skipped and never re-dispatched.

### Phase 2 — Task loop (strictly sequential)

Per task: **implementer** → **reviewer** → **fix loop**.

**Implementer.** Model and effort come from preflight triage. Step one of its prompt
is `scripts/task-brief PLAN N`, which it runs and reads itself. It implements, tests,
commits, self-reviews, and writes its full report to `task-N-report.md`. It returns
`{status, headSha, commits[], testSummary, concerns[], interfaces}`.

The dispatch carries only: one line of placement, the brief path, accumulated
`interfaces` from prior tasks, `globalConstraints`, and the report path. It carries
**no** accumulated session history — SDD names that as a real, observed failure.

**BASE tracking lives in code:** `base = previousTask.headSha ?? preflight.baseSha`.
`HEAD~1` is structurally impossible to reach. This is the single strongest guarantee
the port buys.

Status handling:

- `DONE` → proceed to review.
- `DONE_WITH_CONCERNS` → the concerns are injected into the reviewer's prompt as
  named risks to verify. The script does not adjudicate them itself.
- `BLOCKED` → escalate one model tier and re-dispatch **once** (SDD sanctions this as
  an autonomous controller action). Still blocked → return. The ladder is
  `haiku → sonnet → opus`; a task already at `opus` returns immediately rather than
  retrying itself. The resolver and fix agents run at the task's own implementer
  model.
- `NEEDS_CONTEXT` → return with the implementer's question.
- `headSha === base` (no commits produced) → treated as a failure, not a pass.

**Reviewer.** Model from triage, scaled to the diff. Step one of its prompt is
`scripts/review-package BASE HEAD`, which it runs and reads itself. Prompt is
`task-reviewer-prompt.md` with the brief path, the report path, and
`globalConstraints` verbatim. Returns `{specVerdict, specIssues[], cannotVerify[],
strengths, critical[], important[], minor[], planMandated[], qualityVerdict}`.

Letting the consumer generate its own input is safe here: both scripts are
deterministic (`awk` extraction and `git diff`), so there is no integrity loss. The
skill's rule that the *controller* generates them is motivated by controller context
cost, which does not exist in a JS script.

**Fix loop**, all rules mechanically enforced:

- `planMandated` non-empty → **return**. SDD is unambiguous that this is the human's
  decision, and the script never overrides it.
- `cannotVerify` non-empty → one cheap **resolver** agent, given the plan and repo
  access, adjudicates each item as `satisfied` or `real_gap`. Real gaps fold into the
  fix list. This is the script's analogue of the controller resolving ⚠️ items with
  cross-task context it holds and the reviewer lacks.
- `critical + important` non-empty → **one** fix agent with the complete list. Never
  one fixer per finding.
- The fix report must contain covering tests, the command run, and the output. The
  script validates all three are present before re-review and re-dispatches the fixer
  once, naming the gap, if any is missing.
- Maximum 2 fix rounds. Still failing → return `review_stuck`.
- `minor` findings accumulate into a ledger handed to the final review for triage, so
  they are not silently discarded.

### Phase 3 — Final whole-branch review (fan-out)

Three dimension reviewers run in `parallel` on the most capable model, grouping
`requesting-code-review/code-reviewer.md`'s five checklist areas into three agents:

1. **Plan alignment** — plan/requirements match across the whole branch, plus whether
   later tasks undid or contradicted earlier ones
2. **Code quality and architecture** — separation of concerns, error handling, DRY,
   edge cases, scalability, security, integration; and duplication or drifting
   abstractions across task boundaries, which per-task reviews structurally cannot see
3. **Testing and production readiness** — real-behaviour tests, edge cases, integration
   tests, migrations, backward compatibility, documentation

Each generates its own review package with an explicit distinct `OUTFILE`
(`review-final-<dimension>.diff`) over `mergeBase..HEAD`, so concurrent writes cannot
race. One synthesis agent merges the three reports and triages the accumulated minor
ledger. Findings → **one** fix agent with the complete list.

## Return Contract and Resume

Every terminal payload — success or gate — carries:

```js
{ status: 'complete' | 'needs_decision',
  completed: [...], ledgerLines: [...], needsDecision?: {...}, finalReview?: {...} }
```

The controller writes the ledger from the main loop and relays any decision to the
user. On answer, the controller resumes with `resumeFromRunId` and augmented `args`.
Preflight's prompt is unchanged, so it replays from cache for free, and the gate
clears because `args.decisions` now covers it. Completed task agents replay from
cache too.

**Known gap, accepted:** if the workflow is killed without returning, the ledger is
never written. In-session this is covered by resume caching; across sessions the
fallback is `git log`, which is SDD's own documented recovery path. Closing it would
cost a bookkeeper agent per task — five agents to cover a hole that already has two
backstops.

## Budget

A four-task plan costs roughly 15 agents: 1 preflight + 8 task agents + ~1 fixer +
3 dimension reviewers + 1 synthesis + ~1 final fixer. That sits at the `medium`
guideline. The script `log()`s a warning when the plan exceeds five tasks so the
truncation risk is visible rather than silent.

## Location

`config/claude/workflows/subagent-driven-development.js`, which is
`~/.claude/workflows/` through the existing whole-directory symlink.

The Claude Code binary references `.claude/workflows/` as a discovery path, but
whether user-level `~/.claude/workflows/` is scanned (as opposed to project-level
only) is **unverified**. If user-level discovery does not work, the workflow is
invoked by `scriptPath` instead, and the file location does not change. This must be
tested empirically during implementation.

## Verification

A dry run against a throwaway two-task plan in a scratch git repository, exercising:

- the happy path through both tasks and the final review
- one deliberately induced review failure, to prove the fix loop and re-review fire
- one deliberately induced plan conflict, to prove the preflight gate returns rather
  than proceeding

The workflow is not considered working until that run is observed end to end.
