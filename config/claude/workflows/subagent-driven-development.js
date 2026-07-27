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
  const review = await agent(
    `Review task ${task.n} over ${baseSha}..${implementer.headSha}. Implementer concerns: ${implementer.concerns.join('; ') || 'none'}.`,
    { label: `review:${task.n}`, phase: 'Tasks', model: task.reviewerModel, schema: null },
  )
  if (!review) return { gate: gate('reviewer_failed', { task: task.n }, state) }
  return { head: implementer.headSha }
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

return { status: 'complete', ...state, head: state.base, finalReview: null }
