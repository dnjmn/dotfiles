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

return { status: 'complete', ...state, finalReview: null }
