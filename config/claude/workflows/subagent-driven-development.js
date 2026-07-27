export const meta = {
  name: 'subagent-driven-development',
  description: 'Execute an implementation plan task-by-task with a fresh implementer and a review gate per task, then a whole-branch review',
  whenToUse: 'When you have an implementation plan with mostly independent tasks and want the SDD review discipline enforced mechanically rather than by hand',
  phases: [
    { title: 'Preflight', detail: 'triage the plan: task list, per-task models, global constraints, conflicts, git state' },
    { title: 'Tasks', detail: 'sequential implementer then reviewer then bounded fix loop, one task at a time' },
    { title: 'Final Review', detail: 'parallel whole-branch review across three dimensions, then synthesis' },
  ],
}

const MODEL_LADDER = ['haiku', 'sonnet', 'opus']
const MAX_FIX_ROUNDS = 2
const TASK_WARN_THRESHOLD = 5
const PROTECTED_BRANCHES = ['main', 'master']

const PREFLIGHT_SCHEMA = {
  type: 'object',
  properties: {
    tasks: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          n: { type: 'number' },
          title: { type: 'string' },
          complexity: { type: 'string', enum: ['mechanical', 'integration', 'architecture'] },
          implementerModel: { type: 'string', enum: ['haiku', 'sonnet', 'opus'] },
          implementerEffort: { type: 'string', enum: ['low', 'medium', 'high'] },
          reviewerModel: { type: 'string', enum: ['haiku', 'sonnet', 'opus'] },
        },
        required: ['n', 'title', 'complexity', 'implementerModel', 'implementerEffort', 'reviewerModel'],
      },
    },
    globalConstraints: { type: 'string' },
    conflicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          taskRef: { type: 'string' },
          planText: { type: 'string' },
          rubricRule: { type: 'string' },
          question: { type: 'string' },
        },
        required: ['id', 'taskRef', 'planText', 'rubricRule', 'question'],
      },
    },
    baseSha: { type: 'string' },
    mergeBase: { type: 'string' },
    currentBranch: { type: 'string' },
    completedTasks: { type: 'array', items: { type: 'number' } },
    scriptsDir: { type: 'string' },
  },
  required: ['tasks', 'globalConstraints', 'conflicts', 'baseSha', 'mergeBase', 'currentBranch', 'completedTasks', 'scriptsDir'],
}

function preflightPrompt(input) {
  return `You are triaging an implementation plan before subagent-driven execution begins.

## Plan
Read the full plan file: ${input.planPath}
${input.specPath ? `Design spec for cross-checking: ${input.specPath}` : ''}

## Your Jobs

1. **Enumerate the tasks.** For each task heading matching "Task N", record its number and title.

2. **Assign a model and effort per task**, using these signals:
   - Touches 1-2 files with a complete spec, or the plan text already contains the code to write (transcription plus testing) -> implementerModel "haiku", implementerEffort "low"
   - Touches multiple files with integration concerns -> "sonnet", "medium"
   - Requires design judgment or broad codebase understanding -> "opus", "high"
   Set reviewerModel by the diff's likely size, complexity and risk: "sonnet" for ordinary work, "opus" only for subtle concurrency, security, or cross-cutting contract changes. Never assign "haiku" as a reviewerModel.

3. **Copy the global constraints verbatim.** Reproduce the plan's "Global Constraints" section exactly — exact values, exact formats, and stated relationships between components. Do not paraphrase or summarise. If the plan has no such section, use the spec's binding requirements. If neither exists, return an empty string.

4. **Find plan conflicts.** Report anything the plan explicitly mandates that a code review rubric would treat as a defect — a test that asserts nothing, verbatim duplication of a logic block — and any task that contradicts another task or the Global Constraints. For each, give a stable short id (c1, c2, ...), the task it appears in, the mandating plan text quoted exactly, the rubric rule it violates, and the question the human must answer. Report only real conflicts; an empty array is the normal result.

5. **Record git state.** Run:
   git rev-parse --abbrev-ref HEAD
   git rev-parse --short HEAD
   git merge-base main HEAD   (fall back to master, then to the root commit, if main does not exist)
   Return currentBranch, baseSha (short), and mergeBase (short, 7 characters).

6. **Read the progress ledger.** Run:
   cat "$(git rev-parse --show-toplevel)/.superpowers/sdd/progress.md" 2>/dev/null || true
   Return completedTasks as the array of task numbers that file marks complete. Return an empty array if the file is absent.

7. **Locate the SDD scripts directory.** Run:
   ls -d ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/subagent-driven-development/scripts | tail -1
   Return that absolute path as scriptsDir. Later agents run task-brief and review-package from it, so it must be exact.

Your review is read-only. Do not modify the working tree, the index, HEAD, or branch state.`
}

const IMPLEMENTER_SCHEMA = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['DONE', 'DONE_WITH_CONCERNS', 'BLOCKED', 'NEEDS_CONTEXT'] },
    headSha: { type: 'string' },
    commits: { type: 'array', items: { type: 'string' } },
    testSummary: { type: 'string' },
    concerns: { type: 'array', items: { type: 'string' } },
    interfaces: { type: 'string' },
    reportPath: { type: 'string' },
  },
  required: ['status', 'headSha', 'commits', 'testSummary', 'concerns', 'interfaces', 'reportPath'],
}

const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['Critical', 'Important', 'Minor'] },
    location: { type: 'string' },
    what: { type: 'string' },
    why: { type: 'string' },
    fix: { type: 'string' },
  },
  required: ['severity', 'location', 'what', 'why', 'fix'],
}

const PLAN_MANDATED_SCHEMA = {
  type: 'object',
  properties: {
    severity: { type: 'string' },
    location: { type: 'string' },
    what: { type: 'string' },
    why: { type: 'string' },
    fix: { type: 'string' },
    planText: { type: 'string' },
  },
  required: ['severity', 'location', 'what', 'why', 'fix', 'planText'],
}

const REVIEWER_SCHEMA = {
  type: 'object',
  properties: {
    specVerdict: { type: 'string', enum: ['pass', 'fail'] },
    specIssues: { type: 'array', items: { type: 'string' } },
    cannotVerify: { type: 'array', items: { type: 'string' } },
    strengths: { type: 'string' },
    critical: { type: 'array', items: FINDING_SCHEMA },
    important: { type: 'array', items: FINDING_SCHEMA },
    minor: { type: 'array', items: FINDING_SCHEMA },
    planMandated: { type: 'array', items: PLAN_MANDATED_SCHEMA },
    qualityVerdict: { type: 'string', enum: ['approved', 'needs_fixes'] },
  },
  required: ['specVerdict', 'specIssues', 'cannotVerify', 'strengths', 'critical', 'important', 'minor', 'planMandated', 'qualityVerdict'],
}

const RESOLVER_SCHEMA = {
  type: 'object',
  properties: {
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string' },
          verdict: { type: 'string', enum: ['satisfied', 'real_gap'] },
          evidence: { type: 'string' },
        },
        required: ['item', 'verdict', 'evidence'],
      },
    },
  },
  required: ['items'],
}

const FIX_SCHEMA = {
  type: 'object',
  properties: {
    headSha: { type: 'string' },
    fixesApplied: { type: 'array', items: { type: 'string' } },
    testsRun: { type: 'array', items: { type: 'string' } },
    command: { type: 'string' },
    output: { type: 'string' },
  },
  required: ['headSha', 'fixesApplied', 'testsRun', 'command', 'output'],
}

function fixEvidenceComplete(fix) {
  return Boolean(
    fix &&
      Array.isArray(fix.testsRun) &&
      fix.testsRun.length > 0 &&
      typeof fix.command === 'string' &&
      fix.command.trim() !== '' &&
      typeof fix.output === 'string' &&
      fix.output.trim() !== '',
  )
}

function describeFindings(findings) {
  return findings
    .map((finding, index) => `${index + 1}. [${finding.severity}] ${finding.location} — ${finding.what}. Why it matters: ${finding.why}. Suggested fix: ${finding.fix}`)
    .join('\n')
}

function implementerPrompt(task, context) {
  return `You are implementing Task ${task.n}: ${task.title}

## Task Description

Run this first, then read the file it names — it is your requirements, and you must use its exact values verbatim:

  ${context.scriptsDir}/task-brief ${context.planPath} ${task.n}

## Context

This is task ${task.n} of ${context.totalTasks} in an implementation plan being executed one task at a time.

Global constraints binding every task:
${context.globalConstraints || '(none stated)'}
${context.interfaces ? `\nInterfaces produced by earlier tasks that your brief cannot know:\n${context.interfaces}` : ''}
${context.escalation ? `\nA previous attempt at this task reported BLOCKED with: ${context.escalation}. You are the escalated retry — approach it differently.` : ''}

## Your Job

1. Implement exactly what the brief specifies — nothing more, nothing less
2. Write tests, following TDD if the brief says to
3. Verify the implementation works
4. Commit your work
5. Self-review, then report

While iterating, run the focused test for what you are changing. Run the full suite once before committing, not after every edit.

## Code Organization

Follow the file structure the brief defines. Each file should have one clear responsibility with a well-defined interface. If a file you are creating grows beyond the brief's intent, stop and report DONE_WITH_CONCERNS rather than splitting it yourself. In an existing codebase, follow established patterns and improve code you touch the way a good developer would, without restructuring anything outside your task.

## When You Are in Over Your Head

It is always OK to stop and say this is too hard. Bad work is worse than no work, and you will not be penalized for escalating. Stop and escalate when the task needs architectural decisions with several valid answers, when you cannot find clarity after reading file after file, or when you are simply unsure your approach is right.

There is no interactive channel here: you cannot ask a question and wait. If you need information you were not given, report NEEDS_CONTEXT with your exact questions in "concerns" and stop. If you are stuck for any other reason, report BLOCKED with what you tried in "concerns".

## Before Reporting: Self-Review

Review your work with fresh eyes. Did you implement every requirement, and no requirement you were not given? Are names accurate? Did you avoid overbuilding? Do the tests verify real behaviour rather than mocks, and is the test output pristine, with no stray warnings? Fix anything you find before reporting.

## Report

Write your full report to ${context.reportPath}: what you implemented, what you tested and the results, TDD evidence (the RED command and failing output, then the GREEN command and passing output) if the brief required TDD, files changed, self-review findings, and any concerns.

Then return:
- status: DONE, DONE_WITH_CONCERNS, BLOCKED, or NEEDS_CONTEXT
- headSha: the 7-character short SHA of HEAD after your commits — run "git rev-parse --short HEAD". If you made no commits, return the SHA you started from.
- commits: each commit you created, as "shortsha subject"
- testSummary: one line, for example "14/14 passing, output pristine"
- concerns: your concerns, or your exact questions if NEEDS_CONTEXT, or what blocked you if BLOCKED
- interfaces: the exact signatures and names later tasks will consume from your work, at most 10 lines. Later implementers see only this — not your report.
- reportPath: ${context.reportPath}

Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness. Never silently produce work you are unsure about.`
}

function reviewerPrompt(task, baseSha, headSha, context) {
  return `You are reviewing one task's implementation: first whether it matches its requirements, then whether it is well-built. This is a task-scoped gate, not a merge review — a broad whole-branch review happens separately after all tasks are complete.

## What Was Requested

Run this, then read the file it names — it is the task's requirements:

  ${context.scriptsDir}/task-brief ${context.planPath} ${task.n}

Global constraints from the spec that bind this task:
${context.globalConstraints || '(none stated)'}

## What the Implementer Claims They Built

Read the implementer's report: ${context.reportPath}
${context.concerns ? `\nThe implementer flagged these doubts. Verify each specifically and say what you found:\n${context.concerns}` : ''}

## Diff Under Review

Run this, then read the file it names — it holds the commit list, the stat summary, and the full diff with context:

  ${context.scriptsDir}/review-package ${baseSha} ${headSha}

Base: ${baseSha}
Head: ${headSha}
Range: ${baseSha}..${headSha}

The diff's context lines ARE the changed files: do not Read a changed file separately unless a hunk you must judge is cut off mid-function, and say so if you do. Do not crawl the broader codebase. Inspect code outside the diff only to evaluate a concrete risk you can name — one focused check per named risk, naming both the risk and what you checked. Cross-cutting changes are legitimate named risks: if the diff changes lock ordering, a function or API contract, or shared mutable state, checking the call sites is the right method.

Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state in any way.

## Do Not Trust the Report

Treat the report as unverified claims. Verify them against the diff. Design rationales are claims too: "left it per YAGNI" or "kept it simple deliberately" is the implementer grading their own work. A stated rationale never downgrades a finding's severity.

## Tests

The implementer already ran the tests and reported results for exactly this code. Do not re-run the suite to confirm their report. Run a test only when reading the code raises a specific doubt no existing run answers, and then a focused test — never a package-wide suite, race detector run, or high-count loop. If heavy validation seems warranted, recommend it instead of running it. Warnings or other noise in the reported test output are findings: test output should be pristine.

## Part 1: Spec Compliance

Compare the diff against what was requested. Report what is Missing (requirements skipped, or claimed without being implemented), Extra (anything not requested, over-engineering), and Misunderstood (right feature built the wrong way). If a requirement cannot be verified from this diff alone because it lives in unchanged code or spans tasks, put it in cannotVerify instead of broadening your search.

## Part 2: Code Quality

Judge separation of concerns, error handling, DRY without premature abstraction, and edge cases. Judge whether the new and changed tests verify real behaviour rather than mocks, and whether the task's edge cases are covered. Judge whether each file has one clear responsibility, whether units can be understood and tested independently, and whether this change created files that are already large or significantly grew existing ones. Do not flag pre-existing file sizes — only what this change contributed.

Every finding needs a file:line reference.

## Calibration

Categorize by actual severity. Not everything is Critical. Important means the task cannot be trusted until it is fixed: incorrect or fragile behaviour, a missed requirement, or maintainability damage you would block a merge over — verbatim duplication of a logic block, swallowed errors, tests that assert nothing. "Coverage could be broader" and polish are Minor.

If the plan or brief explicitly mandates something this rubric calls a defect, that IS a finding: put it in planMandated with the mandating plan text quoted exactly. The plan's authorship does not grade its own work; the human decides. Do not also list it under critical or important.

Acknowledge what was done well in strengths before listing issues.`
}

function resolverPrompt(task, items, context) {
  return `A task reviewer could not verify these requirements from task ${task.n}'s diff alone, because they live in unchanged code or span several tasks:

${items.map((item, index) => `${index + 1}. ${item}`).join('\n')}

You hold what the reviewer lacked: the whole plan and the whole repository.

For each item, determine whether the requirement is actually satisfied somewhere in the current tree, or is a real gap. Read the plan at ${context.planPath} for cross-task context, and inspect the repository as needed.

Global constraints that bind this work:
${context.globalConstraints || '(none stated)'}

Answer each item with verdict "satisfied" or "real_gap" and cite concrete evidence — a file:line where the requirement is met, or a specific statement of what you searched and did not find. Default to "real_gap" only when you have genuinely looked and it is absent; do not guess in either direction.

Your review is read-only. Do not modify the working tree, the index, HEAD, or branch state.`
}

function fixPrompt(task, findings, context) {
  return `You are fixing review findings on Task ${task.n}: ${task.title}

${context.evidenceGap ? `Your previous fix report ${context.evidenceGap}. Apply the fixes if you have not already, then re-run the covering tests and report the command and its real output this time.\n` : ''}
## Findings to Fix

Fix all of these in one pass:

${describeFindings(findings)}

## Requirements

Run this, then read the file it names — it holds the task's requirements and the exact values you must use:

  ${context.scriptsDir}/task-brief ${context.planPath} ${task.n}

Global constraints binding this task:
${context.globalConstraints || '(none stated)'}

## Your Job

1. Fix every finding above. Do not fix anything else, and do not add features.
2. Re-run the tests covering the code you amended. These are the covering tests: ${context.coveringTests}. A targeted fix does not need the whole suite.
3. Append your fix report — what you changed, and the test command with its output — to ${context.reportPath}.
4. Commit your work.

Then return: headSha (the 7-character short SHA of HEAD after your commits, from "git rev-parse --short HEAD"), fixesApplied, testsRun (the test files you actually ran), command (the exact command), and output (its real output). All five are required, and the re-review will not proceed without genuine test evidence.`
}

const DIMENSIONS = [
  {
    key: 'plan-alignment',
    focus: `Does the implementation match the plan and requirements across the whole branch? Is all planned functionality present? Are deviations justified improvements or problematic departures? Do the tasks compose into one coherent change, or did later tasks undo or contradict earlier ones? If you find problems with the plan itself rather than the implementation, say so explicitly.`,
  },
  {
    key: 'quality-architecture',
    focus: `Are the design decisions sound? Judge separation of concerns, error handling, type safety where applicable, DRY without premature abstraction, and edge cases. Judge scalability and performance where they matter, security concerns, and whether the change integrates cleanly with the surrounding code. Look for duplication and drifting abstractions introduced across task boundaries, which per-task reviews structurally cannot see.`,
  },
  {
    key: 'testing-production',
    focus: `Do the tests verify real behaviour rather than mocks? Are edge cases covered, and are there integration tests where they matter? Then judge production readiness: migration strategy if a schema changed, backward compatibility, documentation completeness, and any obvious bug.`,
  },
]

const DIMENSION_SCHEMA = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: FINDING_SCHEMA },
    notes: { type: 'string' },
  },
  required: ['findings', 'notes'],
}

const SYNTHESIS_SCHEMA = {
  type: 'object',
  properties: {
    readyToMerge: { type: 'string', enum: ['yes', 'no', 'with-fixes'] },
    summary: { type: 'string' },
    blocking: { type: 'array', items: FINDING_SCHEMA },
    recommendations: { type: 'array', items: { type: 'string' } },
    minorTriage: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          what: { type: 'string' },
          decision: { type: 'string', enum: ['fix-before-merge', 'defer'] },
          reason: { type: 'string' },
        },
        required: ['what', 'decision', 'reason'],
      },
    },
  },
  required: ['readyToMerge', 'summary', 'blocking', 'recommendations', 'minorTriage'],
}

function dimensionPrompt(dimension, mergeBase, head, context) {
  return `You are a Senior Code Reviewer examining a completed feature branch before merge. You own one dimension of that review.

## Your Dimension: ${dimension.key}

${dimension.focus}

Review only this dimension. Other reviewers are covering the others in parallel, and a synthesis step merges your reports.

## What Was Built

The branch implements the plan at ${context.planPath}. Read it for the requirements.

Global constraints binding the whole branch:
${context.globalConstraints || '(none stated)'}

## Diff Under Review

Run this, then read the file it names — it holds the commit list, the stat summary, and the full branch diff with context:

  ${context.scriptsDir}/review-package ${mergeBase} ${head} .superpowers/sdd/review-final-${dimension.key}.diff

Base: ${mergeBase}
Head: ${head}

Write to that exact path — each dimension has its own file so parallel reviewers never collide.

## Read-Only Review

Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state. Use git show, git diff, and git log to inspect history. If you need a working copy of another revision, add a separate temporary worktree — never move HEAD on this checkout.

## Calibration

Categorize by actual severity. Not everything is Critical. Critical means bugs, security issues, data loss risks, or broken functionality. Important means architecture problems, missing features, poor error handling, or test gaps. Minor means style, optimization, or documentation polish.

Each finding needs a file:line reference, what is wrong, why it matters, and how to fix it if that is not obvious. Do not say "looks good" without checking, do not mark nitpicks as Critical, and do not give feedback on code you did not actually read. Put anything worth saying that is not a finding in notes, including what was done well.`
}

function synthesisPrompt(reports, minorLedger, context) {
  return `Three reviewers examined this feature branch in parallel, each on one dimension. Merge their reports into one verdict.

## Dimension Reports

${reports.map((report) => `### ${report.key}\n\nNotes: ${report.notes}\n\nFindings:\n${report.findings.length ? describeFindings(report.findings) : '(none)'}`).join('\n\n')}

## Minor Findings Deferred From Per-Task Reviews

These were raised during per-task reviews, judged Minor at the time, and deferred to you. Triage each one: does it need fixing before merge, or can it be deferred? A roll-up nobody reads is a silent discard, so give every entry a decision and a reason.

${minorLedger.length ? minorLedger.map((entry) => `- Task ${entry.task}: ${entry.location} — ${entry.what} (${entry.why})`).join('\n') : '(none)'}

## Requirements

The branch implements the plan at ${context.planPath}.

Global constraints binding the whole branch:
${context.globalConstraints || '(none stated)'}

## Your Job

De-duplicate findings that several dimensions raised. Drop any finding another report's evidence refutes, and say so in your summary. Promote a Minor to blocking only if you can justify it. Return the blocking set — everything that must be fixed before merge — plus recommendations that are worth doing but not blocking, and your triage of every deferred minor finding.

Give a clear verdict in readyToMerge: "yes", "no", or "with-fixes". Do not avoid the verdict.

Your review is read-only. Do not modify the working tree, the index, HEAD, or branch state.`
}

function nextModel(model) {
  const index = MODEL_LADDER.indexOf(model)
  if (index === -1 || index === MODEL_LADDER.length - 1) return null
  return MODEL_LADDER[index + 1]
}

function isProtectedBranch(branch) {
  return PROTECTED_BRANCHES.includes(branch)
}

function gate(kind, detail, state) {
  return {
    status: 'needs_decision',
    needsDecision: { kind, ...detail },
    completed: state.completed,
    ledgerLines: state.ledgerLines,
    minorLedger: state.minorLedger,
    head: state.base,
  }
}

const state = {
  completed: [],
  ledgerLines: [],
  minorLedger: [],
  base: null,
}

async function reviewTask(task, baseSha, implementer, preflight, state) {
  const context = {
    planPath: args.planPath,
    scriptsDir: preflight.scriptsDir,
    globalConstraints: preflight.globalConstraints,
    reportPath: `.superpowers/sdd/task-${task.n}-report.md`,
    concerns: implementer.concerns.join('\n'),
    coveringTests: 'the test files touched by this task',
    evidenceGap: null,
  }

  let head = implementer.headSha
  let round = 0

  while (true) {
    const review = await agent(reviewerPrompt(task, baseSha, head, context), {
      label: `review:${task.n}`,
      phase: 'Tasks',
      model: task.reviewerModel,
      schema: REVIEWER_SCHEMA,
    })

    if (!review) {
      return { gate: gate('reviewer_failed', { task: task.n, message: `The reviewer for task ${task.n} returned no result.` }, state) }
    }

    if (review.planMandated.length > 0) {
      return {
        gate: gate('plan_mandated', {
          task: task.n,
          findings: review.planMandated,
          message: `Task ${task.n}'s review found defects the plan itself mandates. Decide which governs — the plan or the rubric — then resume.`,
        }, state),
      }
    }

    let gaps = []
    if (review.cannotVerify.length > 0) {
      const resolved = await agent(resolverPrompt(task, review.cannotVerify, context), {
        label: `resolve:${task.n}`,
        phase: 'Tasks',
        model: task.implementerModel,
        schema: RESOLVER_SCHEMA,
      })
      gaps = (resolved ? resolved.items : [])
        .filter((entry) => entry.verdict === 'real_gap')
        .map((entry) => ({
          severity: 'Important',
          location: 'unverified requirement',
          what: entry.item,
          why: 'The reviewer could not verify it from the diff and a resolver confirmed it is absent.',
          fix: entry.evidence,
        }))
    }

    const blocking = [...review.critical, ...review.important, ...gaps]
    const clean = blocking.length === 0 && review.specVerdict === 'pass' && review.qualityVerdict === 'approved'

    if (clean) {
      for (const finding of review.minor) state.minorLedger.push({ task: task.n, ...finding })
      return { head }
    }

    if (round >= MAX_FIX_ROUNDS) {
      return {
        gate: gate('review_stuck', {
          task: task.n,
          rounds: round,
          findings: blocking,
          specIssues: review.specIssues,
          message: `Task ${task.n} still fails review after ${round} fix rounds. The plan or the approach likely needs to change.`,
        }, state),
      }
    }

    round += 1
    let fix = await agent(fixPrompt(task, blocking, context), {
      label: `fix:${task.n}`,
      phase: 'Tasks',
      model: task.implementerModel,
      effort: task.implementerEffort,
      schema: FIX_SCHEMA,
    })

    if (!fixEvidenceComplete(fix)) {
      fix = await agent(
        fixPrompt(task, blocking, { ...context, evidenceGap: 'did not include the covering tests, the command run, and its output' }),
        { label: `fix:${task.n}`, phase: 'Tasks', model: task.implementerModel, effort: task.implementerEffort, schema: FIX_SCHEMA },
      )
    }

    if (!fixEvidenceComplete(fix)) {
      return {
        gate: gate('fix_evidence_missing', {
          task: task.n,
          message: `The fixer for task ${task.n} twice failed to report covering tests, the command run, and its output. Re-review cannot proceed without test evidence.`,
        }, state),
      }
    }

    head = fix.headSha
  }
}

phase('Preflight')

const preflight = await agent(preflightPrompt(args), {
  label: 'preflight',
  phase: 'Preflight',
  model: 'opus',
  effort: 'high',
  schema: PREFLIGHT_SCHEMA,
})

if (!preflight) {
  return gate('preflight_failed', { message: 'The preflight agent returned no result.' }, state)
}

state.base = preflight.baseSha

if (isProtectedBranch(preflight.currentBranch) && !args.allowMainBranch) {
  return gate('protected_branch', {
    branch: preflight.currentBranch,
    message: `Refusing to implement on ${preflight.currentBranch}. Create a branch, or re-run with allowMainBranch: true.`,
  }, state)
}

const decisions = args.decisions || {}
const unresolved = preflight.conflicts.filter((conflict) => !decisions[conflict.id])
if (unresolved.length > 0) {
  return gate('plan_conflicts', {
    conflicts: unresolved,
    message: 'The plan mandates things the review rubric treats as defects. Answer each, then resume with args.decisions keyed by conflict id.',
  }, state)
}

if (preflight.tasks.length > TASK_WARN_THRESHOLD) {
  log(`Plan has ${preflight.tasks.length} tasks, above the ${TASK_WARN_THRESHOLD}-task guideline for medium-size workflows. Expect roughly ${1 + preflight.tasks.length * 2 + 5} agents.`)
}

const pending = preflight.tasks.filter((task) => !preflight.completedTasks.includes(task.n))
if (preflight.completedTasks.length > 0) {
  log(`Ledger marks tasks ${preflight.completedTasks.join(', ')} complete; resuming at task ${pending[0] ? pending[0].n : 'none'}.`)
}

phase('Tasks')

const interfaces = []

for (const task of pending) {
  const baseSha = state.base
  const context = {
    planPath: args.planPath,
    scriptsDir: preflight.scriptsDir,
    globalConstraints: preflight.globalConstraints,
    totalTasks: preflight.tasks.length,
    interfaces: interfaces.join('\n'),
    reportPath: `.superpowers/sdd/task-${task.n}-report.md`,
    escalation: null,
  }

  let model = task.implementerModel
  let effort = task.implementerEffort
  let implementer = await agent(implementerPrompt(task, context), {
    label: `impl:${task.n}`,
    phase: 'Tasks',
    model,
    effort,
    schema: IMPLEMENTER_SCHEMA,
  })

  if (implementer && implementer.status === 'BLOCKED') {
    const escalated = nextModel(model)
    if (escalated) {
      log(`Task ${task.n} reported BLOCKED on ${model}; escalating to ${escalated}.`)
      model = escalated
      effort = 'high'
      implementer = await agent(
        implementerPrompt(task, { ...context, escalation: implementer.concerns.join('; ') }),
        { label: `impl:${task.n}`, phase: 'Tasks', model, effort, schema: IMPLEMENTER_SCHEMA },
      )
    }
  }

  if (!implementer) {
    return gate('implementer_failed', { task: task.n, message: `The implementer for task ${task.n} returned no result.` }, state)
  }

  if (implementer.status === 'NEEDS_CONTEXT') {
    return gate('needs_context', {
      task: task.n,
      questions: implementer.concerns,
      message: `Task ${task.n} needs information the plan did not provide. Answer, then resume with the answers appended to args.decisions.`,
    }, state)
  }

  if (implementer.status === 'BLOCKED') {
    return gate('blocked', {
      task: task.n,
      model,
      reasons: implementer.concerns,
      message: `Task ${task.n} is blocked at model ${model}. Break the task down, fix the plan, or provide context.`,
    }, state)
  }

  if (implementer.headSha === baseSha) {
    return gate('no_commits', {
      task: task.n,
      message: `Task ${task.n} reported ${implementer.status} but HEAD did not move from ${baseSha}. Nothing was committed.`,
    }, state)
  }

  const outcome = await reviewTask(task, baseSha, implementer, preflight, state)
  if (outcome.gate) return outcome.gate

  if (implementer.interfaces) {
    interfaces.push(`Task ${task.n} (${task.title}): ${implementer.interfaces}`)
  }
  state.completed.push(task.n)
  state.ledgerLines.push(`Task ${task.n}: complete (commits ${baseSha}..${outcome.head}, review clean)`)
  state.base = outcome.head
}

phase('Final Review')

const finalContext = {
  planPath: args.planPath,
  scriptsDir: preflight.scriptsDir,
  globalConstraints: preflight.globalConstraints,
}

const dimensionReports = await parallel(
  DIMENSIONS.map((dimension) => () =>
    agent(dimensionPrompt(dimension, preflight.mergeBase, state.base, finalContext), {
      label: `final:${dimension.key}`,
      phase: 'Final Review',
      model: 'opus',
      effort: 'high',
      schema: DIMENSION_SCHEMA,
    }).then((report) => (report ? { key: dimension.key, ...report } : null)),
  ),
)

const reports = dimensionReports.filter(Boolean)
if (reports.length < DIMENSIONS.length) {
  log(`${DIMENSIONS.length - reports.length} of ${DIMENSIONS.length} final review dimensions returned nothing; synthesising from the rest.`)
}

const synthesis = await agent(synthesisPrompt(reports, state.minorLedger, finalContext), {
  label: 'synthesis',
  phase: 'Final Review',
  model: 'opus',
  effort: 'high',
  schema: SYNTHESIS_SCHEMA,
})

let finalFix = null
if (synthesis && synthesis.blocking.length > 0) {
  finalFix = await agent(
    fixPrompt(
      { n: 'final', title: 'whole-branch review findings' },
      synthesis.blocking,
      {
        planPath: args.planPath,
        scriptsDir: preflight.scriptsDir,
        globalConstraints: preflight.globalConstraints,
        reportPath: '.superpowers/sdd/final-review-report.md',
        coveringTests: 'the test files covering each finding you fix',
        evidenceGap: null,
      },
    ),
    { label: 'final-fix', phase: 'Final Review', model: 'opus', effort: 'high', schema: FIX_SCHEMA },
  )
  if (finalFix) state.base = finalFix.headSha
}

return {
  status: 'complete',
  completed: state.completed,
  ledgerLines: state.ledgerLines,
  minorLedger: state.minorLedger,
  base: state.base,
  head: state.base,
  finalReview: synthesis,
  finalFix,
}
