# SDD-as-Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port `superpowers:subagent-driven-development` to a `Workflow` script so its discipline-dependent rules (BASE tracking, review loops, one-fixer-per-wave, no re-dispatch of completed tasks) become enforced code.

**Architecture:** A single self-contained JavaScript file at `config/claude/workflows/subagent-driven-development.js` with three phases — preflight triage/gating, a strictly sequential task loop with review and fix cycles, and a parallel final whole-branch review. Human decision points are handled by returning a structured `needs_decision` payload and stopping; the caller answers and resumes via `resumeFromRunId`. A Node test harness loads the script into an `AsyncFunction` with mocked `agent`/`parallel`/`log` globals so the orchestration logic is tested behaviourally without spending a single real agent.

**Tech Stack:** JavaScript (Workflow runtime sandbox), Node.js v26 `node:test` + `node:assert` (zero dependencies), bash + git for the live verification.

## Global Constraints

Every task's requirements implicitly include this section.

- The workflow file MUST be a **single self-contained file**. The Workflow runtime has no filesystem or Node API access, so `import`/`require` are unavailable. Organise by clearly-separated sections within the one file, not by splitting it.
- The workflow file MUST NOT call `Date.now()`, `new Date()` (argless), or `Math.random()` — the runtime throws on all three because they break resume.
- The workflow file MUST begin with `export const meta = {...}` as a **pure literal** — no variables, function calls, spreads, or template interpolation.
- `meta.phases` titles MUST be exactly `Preflight`, `Tasks`, `Final Review`, and every `agent()` call MUST pass a matching `phase` option explicitly (never rely on the global `phase()` state inside `parallel()`).
- The model ladder is exactly `['haiku', 'sonnet', 'opus']`. A task already at `opus` never self-retries.
- `MAX_FIX_ROUNDS = 2`.
- `TASK_WARN_THRESHOLD = 5` — above this, `log()` a warning that the run exceeds the configured `medium` workflow size guideline.
- Commit SHAs passed between agents are **7-character short SHAs**.
- A task's review BASE is `previousTask.headSha ?? preflight.baseSha`. `HEAD~1` MUST NOT appear anywhere in the file.
- Agent labels are exactly: `preflight`, `impl:<n>`, `review:<n>`, `resolve:<n>`, `fix:<n>`, `final:<dimension-key>`, `synthesis`, `final-fix`. Tests dispatch on these.
- Tests are **behavioural**, asserting on the recorded dispatch sequence and the returned payload. Internal helper functions are never imported or called directly — they are not exported, and testing the contract rather than the internals is the intent.
- Run tests with `node --test tests/workflows/`.

---

### Task 1: Test harness and workflow skeleton

Creates the test infrastructure the remaining tasks depend on, plus the workflow file's meta block, constants, and a body that immediately returns. Setup is folded in here because nothing else can be tested without it.

**Files:**
- Create: `tests/workflows/harness.mjs`
- Create: `tests/workflows/sdd.test.mjs`
- Create: `config/claude/workflows/subagent-driven-development.js`

**Interfaces:**
- Consumes: nothing.
- Produces: `runWorkflow(scriptPath, { args, agent, budget }) => Promise<{ result, calls, logs }>` from `harness.mjs`. `calls` is an array of `{ prompt, opts, index, value }` in dispatch order. The `agent` option is a function `(call) => value | Promise<value>` invoked for every `agent()` the script makes. Also produces the constant `SDD_PATH` used by every later test file section.

- [ ] **Step 1: Write the failing test**

Create `tests/workflows/sdd.test.mjs`:

```js
import test from 'node:test'
import assert from 'node:assert/strict'
import { fileURLToPath } from 'node:url'
import { runWorkflow } from './harness.mjs'

export const SDD_PATH = fileURLToPath(
  new URL('../../config/claude/workflows/subagent-driven-development.js', import.meta.url),
)

test('skeleton loads and returns a structured payload', async () => {
  const { result, calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: () => null,
  })
  assert.equal(typeof result, 'object')
  assert.ok(result !== null)
  assert.equal(calls.length, 0)
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `./harness.mjs`.

- [ ] **Step 3: Write the harness**

Create `tests/workflows/harness.mjs`:

```js
import { readFile } from 'node:fs/promises'

const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

const NOOP_BUDGET = { total: null, spent: () => 0, remaining: () => Infinity }

export async function runWorkflow(scriptPath, { args = {}, agent = () => null, budget } = {}) {
  const source = (await readFile(scriptPath, 'utf8')).replace(/^export const meta/m, 'const meta')

  const calls = []
  const logs = []

  const agentFn = async (prompt, opts = {}) => {
    const call = { prompt, opts, index: calls.length }
    calls.push(call)
    call.value = await agent(call)
    return call.value
  }

  const settle = async (thunk) => {
    try {
      return await thunk()
    } catch {
      return null
    }
  }

  const parallelFn = (thunks) => Promise.all(thunks.map(settle))

  const pipelineFn = (items, ...stages) =>
    Promise.all(
      items.map((item, index) =>
        settle(async () => {
          let acc = item
          for (const stage of stages) acc = await stage(acc, item, index)
          return acc
        }),
      ),
    )

  const body = new AsyncFunction(
    'agent',
    'parallel',
    'pipeline',
    'log',
    'phase',
    'args',
    'budget',
    'workflow',
    source,
  )

  const result = await body(
    agentFn,
    parallelFn,
    pipelineFn,
    (message) => logs.push(message),
    () => {},
    args,
    budget ?? NOOP_BUDGET,
    async () => {
      throw new Error('nested workflow() is not supported in the harness')
    },
  )

  return { result, calls, logs }
}

export function callsByLabel(calls, label) {
  return calls.filter((call) => call.opts.label === label)
}

export function labels(calls) {
  return calls.map((call) => call.opts.label)
}
```

- [ ] **Step 4: Write the workflow skeleton**

Create `config/claude/workflows/subagent-driven-development.js`:

```js
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

return { status: 'complete', ...state, finalReview: null }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: PASS, `1 passing`.

- [ ] **Step 6: Commit**

```bash
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/harness.mjs tests/workflows/sdd.test.mjs config/claude/workflows/subagent-driven-development.js
git commit -m "feat(workflows): add SDD workflow skeleton and node test harness"
```

---

### Task 2: Preflight phase and gates

The preflight agent reads the plan once and returns everything the script needs: task list with per-task models, verbatim global constraints, plan conflicts, git state, the ledger's completed tasks, and the superpowers scripts directory. Then the three gates fire.

`scriptsDir` is discovered by the agent rather than hardcoded because the superpowers plugin path is version-pinned (`.../superpowers/6.1.1/...`) and would break on every plugin upgrade.

**Files:**
- Modify: `config/claude/workflows/subagent-driven-development.js` (replace the `phase('Preflight')` line and the final `return`)
- Modify: `tests/workflows/sdd.test.mjs` (append tests)

**Interfaces:**
- Consumes: `runWorkflow`, `labels`, `SDD_PATH` from Task 1.
- Produces: the preflight result object shape used by every later task —
  `{ tasks: [{ n, title, complexity, implementerModel, implementerEffort, reviewerModel }], globalConstraints, conflicts: [{ id, taskRef, planText, rubricRule, question }], baseSha, mergeBase, currentBranch, completedTasks: [number], scriptsDir }`.
  Also produces the gate kinds `protected_branch`, `plan_conflicts`, and `preflight_failed`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/workflows/sdd.test.mjs`:

```js
export const PREFLIGHT_OK = {
  tasks: [
    { n: 1, title: 'One', complexity: 'mechanical', implementerModel: 'haiku', implementerEffort: 'low', reviewerModel: 'sonnet' },
    { n: 2, title: 'Two', complexity: 'integration', implementerModel: 'sonnet', implementerEffort: 'medium', reviewerModel: 'sonnet' },
  ],
  globalConstraints: 'Timeout is exactly 30s.',
  conflicts: [],
  baseSha: 'aaaaaaa',
  mergeBase: '0000000',
  currentBranch: 'feature/x',
  completedTasks: [],
  scriptsDir: '/skills/subagent-driven-development/scripts',
}

test('preflight dispatches one agent on the most capable model', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: (call) => (call.opts.label === 'preflight' ? { ...PREFLIGHT_OK, tasks: [] } : null),
  })
  assert.equal(calls[0].opts.label, 'preflight')
  assert.equal(calls[0].opts.model, 'opus')
  assert.equal(calls[0].opts.effort, 'high')
  assert.equal(calls[0].opts.phase, 'Preflight')
  assert.match(calls[0].prompt, /plan\.md/)
})

test('protected branch without allowMainBranch returns a gate', async () => {
  const { result, calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: () => ({ ...PREFLIGHT_OK, currentBranch: 'main' }),
  })
  assert.equal(result.status, 'needs_decision')
  assert.equal(result.needsDecision.kind, 'protected_branch')
  assert.equal(calls.length, 1)
})

test('allowMainBranch overrides the protected branch gate', async () => {
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md', allowMainBranch: true },
    agent: (call) =>
      call.opts.label === 'preflight'
        ? { ...PREFLIGHT_OK, currentBranch: 'main', tasks: [] }
        : null,
  })
  assert.notEqual(result.needsDecision?.kind, 'protected_branch')
})

test('unresolved plan conflicts return a gate before any task work', async () => {
  const conflicts = [
    { id: 'c1', taskRef: 'Task 2', planText: 'assert true', rubricRule: 'tests must assert behaviour', question: 'Which governs?' },
  ]
  const { result, calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: () => ({ ...PREFLIGHT_OK, conflicts }),
  })
  assert.equal(result.needsDecision.kind, 'plan_conflicts')
  assert.deepEqual(result.needsDecision.conflicts, conflicts)
  assert.equal(calls.length, 1)
})

test('conflicts answered in args.decisions do not gate', async () => {
  const conflicts = [{ id: 'c1', taskRef: 'Task 2', planText: 'x', rubricRule: 'y', question: 'z' }]
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md', decisions: { c1: 'plan governs' } },
    agent: (call) =>
      call.opts.label === 'preflight' ? { ...PREFLIGHT_OK, conflicts, tasks: [] } : null,
  })
  assert.notEqual(result.needsDecision?.kind, 'plan_conflicts')
})

test('a dead preflight agent returns preflight_failed', async () => {
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: () => null,
  })
  assert.equal(result.needsDecision.kind, 'preflight_failed')
})

test('tasks already in the ledger are never dispatched', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: (call) =>
      call.opts.label === 'preflight' ? { ...PREFLIGHT_OK, completedTasks: [1, 2] } : null,
  })
  assert.equal(labels(calls).filter((label) => label.startsWith('impl:')).length, 0)
})

test('a plan above the size threshold logs a warning', async () => {
  const many = Array.from({ length: 6 }, (_, i) => ({
    n: i + 1, title: `T${i + 1}`, complexity: 'mechanical',
    implementerModel: 'haiku', implementerEffort: 'low', reviewerModel: 'sonnet',
  }))
  const { logs } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: (call) =>
      call.opts.label === 'preflight'
        ? { ...PREFLIGHT_OK, tasks: many, completedTasks: many.map((t) => t.n) }
        : null,
  })
  assert.ok(logs.some((line) => /6 tasks/.test(line)))
})
```

Update the harness import line at the top of the file to include `labels`:

```js
import { runWorkflow, labels } from './harness.mjs'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: FAIL — `calls[0]` is `undefined` because the skeleton dispatches nothing.

- [ ] **Step 3: Add the preflight schema and prompt**

In `config/claude/workflows/subagent-driven-development.js`, insert after the `PROTECTED_BRANCHES` constant:

```js
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
```

- [ ] **Step 4: Replace the script body with the preflight phase and gates**

Replace the trailing `phase('Preflight')` and `return` lines with:

```js
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: PASS, `9 passing`.

- [ ] **Step 6: Commit**

```bash
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/sdd.test.mjs config/claude/workflows/subagent-driven-development.js
git commit -m "feat(workflows): add SDD preflight triage phase and its three gates"
```

---

### Task 3: Task loop with implementer dispatch and BASE tracking

Adds the sequential loop. This task delivers implementer dispatch, the model ladder escalation, status handling, and the BASE-tracking invariant. Review is stubbed as an always-clean pass so this task is independently testable; Task 4 replaces the stub.

**Files:**
- Modify: `config/claude/workflows/subagent-driven-development.js`
- Modify: `tests/workflows/sdd.test.mjs`

**Interfaces:**
- Consumes: `PREFLIGHT_OK` and the preflight result shape from Task 2.
- Produces: the implementer result shape `{ status, headSha, commits: [string], testSummary, concerns: [string], interfaces, reportPath }` where `status` is one of `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`. Produces gate kinds `implementer_failed`, `blocked`, `needs_context`, `no_commits`. Produces `reviewTask(task, base, head, review)` as the extension point Task 4 fills in.

- [ ] **Step 1: Write the failing tests**

Append to `tests/workflows/sdd.test.mjs`:

```js
const DONE = (headSha) => ({
  status: 'DONE',
  headSha,
  commits: [`${headSha} feat: work`],
  testSummary: '3/3 passing, output pristine',
  concerns: [],
  interfaces: 'exports doThing(x: string): number',
  reportPath: '/w/task-report.md',
})

const CLEAN_REVIEW = {
  specVerdict: 'pass',
  specIssues: [],
  cannotVerify: [],
  strengths: 'tidy',
  critical: [],
  important: [],
  minor: [],
  planMandated: [],
  qualityVerdict: 'approved',
}

function scripted(handlers) {
  return (call) => {
    const handler = handlers[call.opts.label]
    if (typeof handler === 'function') return handler(call)
    if (handler === undefined) return null
    return handler
  }
}

test('tasks run sequentially with per-task models from preflight', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: PREFLIGHT_OK,
      'impl:1': DONE('bbbbbbb'),
      'impl:2': DONE('ccccccc'),
      'review:1': CLEAN_REVIEW,
      'review:2': CLEAN_REVIEW,
    }),
  })
  const taskPhase = labels(calls).filter((label) => !label.startsWith('final') && label !== 'synthesis')
  assert.deepEqual(taskPhase, ['preflight', 'impl:1', 'review:1', 'impl:2', 'review:2'])
  assert.equal(callsByLabel(calls, 'impl:1')[0].opts.model, 'haiku')
  assert.equal(callsByLabel(calls, 'impl:1')[0].opts.effort, 'low')
  assert.equal(callsByLabel(calls, 'impl:2')[0].opts.model, 'sonnet')
  assert.equal(callsByLabel(calls, 'impl:1')[0].opts.phase, 'Tasks')
})

test('BASE advances by reported head sha and never uses HEAD~1', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: PREFLIGHT_OK,
      'impl:1': DONE('bbbbbbb'),
      'impl:2': DONE('ccccccc'),
      'review:1': CLEAN_REVIEW,
      'review:2': CLEAN_REVIEW,
    }),
  })
  assert.match(callsByLabel(calls, 'review:1')[0].prompt, /aaaaaaa\.\.bbbbbbb/)
  assert.match(callsByLabel(calls, 'review:2')[0].prompt, /bbbbbbb\.\.ccccccc/)
  for (const call of calls) assert.doesNotMatch(call.prompt, /HEAD~1/)
  assert.equal(result.head, 'ccccccc')
})

test('the implementer prompt carries the brief command and prior interfaces only', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: PREFLIGHT_OK,
      'impl:1': DONE('bbbbbbb'),
      'impl:2': DONE('ccccccc'),
      'review:1': CLEAN_REVIEW,
      'review:2': CLEAN_REVIEW,
    }),
  })
  const first = callsByLabel(calls, 'impl:1')[0].prompt
  const second = callsByLabel(calls, 'impl:2')[0].prompt
  assert.match(first, /task-brief.*plan\.md 1/)
  assert.match(first, /Timeout is exactly 30s\./)
  assert.match(second, /exports doThing\(x: string\): number/)
  assert.doesNotMatch(second, /3\/3 passing/)
})

test('BLOCKED escalates one model tier exactly once', async () => {
  let attempts = 0
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] },
      'impl:1': () => {
        attempts += 1
        return { ...DONE('bbbbbbb'), status: 'BLOCKED', concerns: ['cannot infer schema'] }
      },
    }),
  })
  assert.equal(attempts, 2)
  assert.equal(callsByLabel(calls, 'impl:1')[0].opts.model, 'haiku')
  assert.equal(callsByLabel(calls, 'impl:1')[1].opts.model, 'sonnet')
  assert.equal(result.needsDecision.kind, 'blocked')
})

test('a task already at opus does not self-retry when BLOCKED', async () => {
  const opusTask = { ...PREFLIGHT_OK.tasks[0], implementerModel: 'opus', implementerEffort: 'high' }
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [opusTask] },
      'impl:1': { ...DONE('bbbbbbb'), status: 'BLOCKED' },
    }),
  })
  assert.equal(callsByLabel(calls, 'impl:1').length, 1)
  assert.equal(result.needsDecision.kind, 'blocked')
})

test('NEEDS_CONTEXT gates immediately without escalating', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] },
      'impl:1': { ...DONE('bbbbbbb'), status: 'NEEDS_CONTEXT', concerns: ['which port?'] },
    }),
  })
  assert.equal(callsByLabel(calls, 'impl:1').length, 1)
  assert.equal(result.needsDecision.kind, 'needs_context')
  assert.deepEqual(result.needsDecision.questions, ['which port?'])
})

test('an unchanged head sha is treated as failure, not success', async () => {
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] },
      'impl:1': DONE('aaaaaaa'),
    }),
  })
  assert.equal(result.needsDecision.kind, 'no_commits')
})

test('DONE_WITH_CONCERNS proceeds to review with the concerns injected', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] },
      'impl:1': { ...DONE('bbbbbbb'), status: 'DONE_WITH_CONCERNS', concerns: ['retry loop may spin'] },
      'review:1': CLEAN_REVIEW,
    }),
  })
  assert.match(callsByLabel(calls, 'review:1')[0].prompt, /retry loop may spin/)
})

test('a completed task appends a ledger line', async () => {
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] },
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
    }),
  })
  assert.deepEqual(result.completed, [1])
  assert.deepEqual(result.ledgerLines, ['Task 1: complete (commits aaaaaaa..bbbbbbb, review clean)'])
})
```

Update the harness import line to include `callsByLabel`:

```js
import { runWorkflow, labels, callsByLabel } from './harness.mjs'
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: FAIL — `labels(calls)` is `['preflight']`; no implementer is dispatched.

- [ ] **Step 3: Add the implementer schema and prompt**

Insert after `preflightPrompt` in `config/claude/workflows/subagent-driven-development.js`:

```js
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
```

- [ ] **Step 4: Add the task loop**

Replace the trailing `phase('Tasks')` and `return` lines with:

```js
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
```

Task 5 replaces this `return`. The two label-ordering assertions in this task's tests deliberately filter out `final:*` and `synthesis`, because Task 5 appends those calls to every successful run.

- [ ] **Step 5: Add the review stub**

Insert immediately before `phase('Preflight')` (function declarations hoist, so placement above the call site is not required, but keeping it with the other functions is clearer):

```js
async function reviewTask(task, baseSha, implementer, preflight, state) {
  const review = await agent(
    `Review task ${task.n} over ${baseSha}..${implementer.headSha}. Implementer concerns: ${implementer.concerns.join('; ') || 'none'}.`,
    { label: `review:${task.n}`, phase: 'Tasks', model: task.reviewerModel, schema: null },
  )
  if (!review) return { gate: gate('reviewer_failed', { task: task.n }, state) }
  return { head: implementer.headSha }
}
```

This stub is replaced wholesale in Task 4. It exists so the loop is testable now.

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: PASS, `18 passing`.

- [ ] **Step 7: Commit**

```bash
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/sdd.test.mjs config/claude/workflows/subagent-driven-development.js
git commit -m "feat(workflows): add SDD task loop with BASE tracking and model escalation"
```

---

### Task 4: Review gate, resolver, and bounded fix loop

Replaces the Task 3 stub with the real review gate: the reviewer generates its own review package, plan-mandated findings gate to the human, unverifiable requirements go to a resolver agent, and blocking findings go to exactly one fix agent whose test evidence is validated before re-review.

**Files:**
- Modify: `config/claude/workflows/subagent-driven-development.js` (replace the `reviewTask` stub)
- Modify: `tests/workflows/sdd.test.mjs`

**Interfaces:**
- Consumes: `reviewTask(task, baseSha, implementer, preflight, state)` from Task 3, and `CLEAN_REVIEW` / `scripted` / `DONE` from Task 3's tests.
- Produces: the reviewer result shape `{ specVerdict, specIssues, cannotVerify, strengths, critical, important, minor, planMandated, qualityVerdict }`, the resolver shape `{ items: [{ item, verdict, evidence }] }` with `verdict` one of `satisfied | real_gap`, and the fix shape `{ headSha, fixesApplied: [string], testsRun: [string], command, output }`. Produces gate kinds `plan_mandated`, `review_stuck`, `fix_evidence_missing`, `reviewer_failed`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/workflows/sdd.test.mjs`:

```js
const FINDING = (id) => ({ severity: 'Important', location: `src/a.ts:${id}`, what: `wrong ${id}`, why: 'breaks', fix: 'do it right' })

const FIX_OK = (headSha) => ({
  headSha,
  fixesApplied: ['corrected the guard'],
  testsRun: ['tests/a.test.ts'],
  command: 'npm test -- tests/a.test.ts',
  output: '2/2 passing',
})

const ONE_TASK = { ...PREFLIGHT_OK, tasks: [PREFLIGHT_OK.tasks[0]] }

test('the reviewer generates its own review package and gets the constraints verbatim', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({ preflight: ONE_TASK, 'impl:1': DONE('bbbbbbb'), 'review:1': CLEAN_REVIEW }),
  })
  const prompt = callsByLabel(calls, 'review:1')[0].prompt
  assert.match(prompt, /review-package aaaaaaa bbbbbbb/)
  assert.match(prompt, /Timeout is exactly 30s\./)
  assert.match(prompt, /task-brief.*plan\.md 1/)
  assert.match(prompt, /\.superpowers\/sdd\/task-1-report\.md/)
  assert.equal(callsByLabel(calls, 'review:1')[0].opts.model, 'sonnet')
})

test('plan-mandated findings gate to the human without dispatching a fixer', async () => {
  const planMandated = [{ severity: 'Important', location: 'src/a.ts:9', what: 'test asserts nothing', why: 'no coverage', fix: 'assert behaviour', planText: 'assert true' }]
  const { result, calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, planMandated },
    }),
  })
  assert.equal(result.needsDecision.kind, 'plan_mandated')
  assert.deepEqual(result.needsDecision.findings, planMandated)
  assert.equal(callsByLabel(calls, 'fix:1').length, 0)
})

test('cannotVerify items go to a resolver and satisfied ones do not trigger a fix', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, cannotVerify: ['timeout applied at call site'] },
      'resolve:1': { items: [{ item: 'timeout applied at call site', verdict: 'satisfied', evidence: 'src/b.ts:14 sets 30s' }] },
    }),
  })
  assert.equal(callsByLabel(calls, 'resolve:1').length, 1)
  assert.equal(callsByLabel(calls, 'fix:1').length, 0)
  assert.equal(result.status, 'complete')
})

test('a resolver real_gap becomes a blocking finding and triggers one fix', async () => {
  let reviews = 0
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': () => {
        reviews += 1
        return reviews === 1 ? { ...CLEAN_REVIEW, cannotVerify: ['timeout applied'] } : CLEAN_REVIEW
      },
      'resolve:1': { items: [{ item: 'timeout applied', verdict: 'real_gap', evidence: 'no call site sets it' }] },
      'fix:1': FIX_OK('ddddddd'),
    }),
  })
  assert.equal(callsByLabel(calls, 'fix:1').length, 1)
  assert.equal(reviews, 2)
  assert.equal(result.status, 'complete')
  assert.deepEqual(result.ledgerLines, ['Task 1: complete (commits aaaaaaa..ddddddd, review clean)'])
})

test('all blocking findings go to exactly one fixer, not one per finding', async () => {
  let reviews = 0
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': () => {
        reviews += 1
        return reviews === 1
          ? { ...CLEAN_REVIEW, specVerdict: 'fail', qualityVerdict: 'needs_fixes', critical: [FINDING(1)], important: [FINDING(2), FINDING(3)] }
          : CLEAN_REVIEW
      },
      'fix:1': FIX_OK('ddddddd'),
    }),
  })
  assert.equal(callsByLabel(calls, 'fix:1').length, 1)
  const prompt = callsByLabel(calls, 'fix:1')[0].prompt
  for (const id of [1, 2, 3]) assert.match(prompt, new RegExp(`wrong ${id}`))
})

test('re-review runs against the fixer new head', async () => {
  let reviews = 0
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': () => {
        reviews += 1
        return reviews === 1 ? { ...CLEAN_REVIEW, qualityVerdict: 'needs_fixes', important: [FINDING(1)] } : CLEAN_REVIEW
      },
      'fix:1': FIX_OK('ddddddd'),
    }),
  })
  assert.match(callsByLabel(calls, 'review:1')[1].prompt, /review-package aaaaaaa ddddddd/)
})

test('a fix report missing test evidence is re-dispatched once then gates', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, qualityVerdict: 'needs_fixes', important: [FINDING(1)] },
      'fix:1': { ...FIX_OK('ddddddd'), output: '' },
    }),
  })
  assert.equal(callsByLabel(calls, 'fix:1').length, 2)
  assert.match(callsByLabel(calls, 'fix:1')[1].prompt, /did not include/)
  assert.equal(result.needsDecision.kind, 'fix_evidence_missing')
})

test('the fix loop is bounded at two rounds', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, qualityVerdict: 'needs_fixes', important: [FINDING(1)] },
      'fix:1': FIX_OK('ddddddd'),
    }),
  })
  assert.equal(callsByLabel(calls, 'fix:1').length, 2)
  assert.equal(callsByLabel(calls, 'review:1').length, 3)
  assert.equal(result.needsDecision.kind, 'review_stuck')
})

test('minor findings accumulate rather than being discarded', async () => {
  const minor = [{ severity: 'Minor', location: 'src/a.ts:2', what: 'naming', why: 'clarity', fix: 'rename' }]
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, minor },
    }),
  })
  assert.equal(result.minorLedger.length, 1)
  assert.equal(result.minorLedger[0].task, 1)
  assert.equal(result.minorLedger[0].what, 'naming')
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: FAIL — the stub reviewer's prompt has no `review-package` text and no fix agent is ever dispatched.

- [ ] **Step 3: Add the review, resolver, and fix schemas**

Insert after `IMPLEMENTER_SCHEMA` in `config/claude/workflows/subagent-driven-development.js`:

```js
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
```

- [ ] **Step 4: Add the reviewer, resolver, and fix prompts**

Insert after `implementerPrompt`:

```js
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
```

- [ ] **Step 5: Replace the reviewTask stub with the real gate**

Delete the Task 3 `reviewTask` stub entirely and replace it with:

```js
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
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: PASS, `27 passing`.

- [ ] **Step 7: Commit**

```bash
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/sdd.test.mjs config/claude/workflows/subagent-driven-development.js
git commit -m "feat(workflows): add SDD review gate, resolver, and bounded fix loop"
```

---

### Task 5: Final whole-branch review and return contract

Adds the parallel three-dimension whole-branch review, the synthesis agent that also triages the accumulated minor ledger, and the single final fix wave. Completes the return contract.

**Files:**
- Modify: `config/claude/workflows/subagent-driven-development.js`
- Modify: `tests/workflows/sdd.test.mjs`

**Interfaces:**
- Consumes: `state.minorLedger`, `state.base`, `preflight.mergeBase` from Tasks 2-4.
- Produces: the final return payload `{ status: 'complete', completed, ledgerLines, minorLedger, base, finalReview: { readyToMerge, summary, blocking, recommendations, minorTriage }, finalFix }`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/workflows/sdd.test.mjs`:

```js
const SYNTH_OK = {
  readyToMerge: 'yes',
  summary: 'coherent branch',
  blocking: [],
  recommendations: [],
  minorTriage: [],
}

test('the final review fans out across three dimensions in parallel on opus', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
      'final:plan-alignment': { findings: [], notes: 'ok' },
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: SYNTH_OK,
    }),
  })
  const finals = calls.filter((call) => call.opts.label.startsWith('final:'))
  assert.equal(finals.length, 3)
  for (const call of finals) {
    assert.equal(call.opts.model, 'opus')
    assert.equal(call.opts.effort, 'high')
    assert.equal(call.opts.phase, 'Final Review')
  }
})

test('each dimension writes its own review package file so writes cannot race', async () => {
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
      'final:plan-alignment': { findings: [], notes: 'ok' },
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: SYNTH_OK,
    }),
  })
  const outfiles = calls
    .filter((call) => call.opts.label.startsWith('final:'))
    .map((call) => call.prompt.match(/review-final-[a-z-]+\.diff/)[0])
  assert.equal(new Set(outfiles).size, 3)
  for (const call of calls.filter((c) => c.opts.label.startsWith('final:'))) {
    assert.match(call.prompt, /review-package 0000000 bbbbbbb/)
  }
})

test('synthesis receives the accumulated minor ledger for triage', async () => {
  const minor = [{ severity: 'Minor', location: 'src/a.ts:2', what: 'naming', why: 'clarity', fix: 'rename' }]
  const { calls } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': { ...CLEAN_REVIEW, minor },
      'final:plan-alignment': { findings: [], notes: 'ok' },
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: SYNTH_OK,
    }),
  })
  assert.match(callsByLabel(calls, 'synthesis')[0].prompt, /naming/)
})

test('final findings go to exactly one fix agent', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
      'final:plan-alignment': { findings: [], notes: 'ok' },
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: { ...SYNTH_OK, readyToMerge: 'with-fixes', blocking: [FINDING(1), FINDING(2)] },
      'final-fix': FIX_OK('eeeeeee'),
    }),
  })
  assert.equal(callsByLabel(calls, 'final-fix').length, 1)
  assert.match(callsByLabel(calls, 'final-fix')[0].prompt, /wrong 1/)
  assert.match(callsByLabel(calls, 'final-fix')[0].prompt, /wrong 2/)
  assert.equal(result.base, 'eeeeeee')
})

test('a clean synthesis dispatches no final fixer', async () => {
  const { calls, result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
      'final:plan-alignment': { findings: [], notes: 'ok' },
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: SYNTH_OK,
    }),
  })
  assert.equal(callsByLabel(calls, 'final-fix').length, 0)
  assert.equal(result.status, 'complete')
  assert.equal(result.finalReview.readyToMerge, 'yes')
  assert.deepEqual(result.completed, [1])
  assert.equal(result.ledgerLines.length, 1)
})

test('a dead dimension agent does not abort the final review', async () => {
  const { result } = await runWorkflow(SDD_PATH, {
    args: { planPath: 'plan.md' },
    agent: scripted({
      preflight: ONE_TASK,
      'impl:1': DONE('bbbbbbb'),
      'review:1': CLEAN_REVIEW,
      'final:plan-alignment': null,
      'final:quality-architecture': { findings: [], notes: 'ok' },
      'final:testing-production': { findings: [], notes: 'ok' },
      synthesis: SYNTH_OK,
    }),
  })
  assert.equal(result.status, 'complete')
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: FAIL — no `final:*` calls are dispatched.

- [ ] **Step 3: Add the final review dimensions, schemas, and prompts**

Insert after `fixPrompt`:

```js
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
```

- [ ] **Step 4: Add the final review phase**

Replace the trailing `return { status: 'complete', ...state, finalReview: null }` with:

```js
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
```

Note the `fixPrompt` call passes a synthetic task object with `n: 'final'`, so its `task-brief` line reads `task-brief plan.md final`. That command fails harmlessly and the fixer works from the findings and the plan; the findings carry the full context a final fixer needs.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles && node --test tests/workflows/`

Expected: PASS, `33 passing`.

- [ ] **Step 6: Commit**

```bash
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/sdd.test.mjs config/claude/workflows/subagent-driven-development.js
git commit -m "feat(workflows): add SDD final whole-branch review fan-out and return contract"
```

---

### Task 6: Live verification and documentation

Everything so far is proven against mocked agents. This task proves the workflow runs for real: that `meta` is accepted by the Workflow runtime, that user-level workflow discovery works (or does not), and that the gates fire against a real repository.

**Files:**
- Create: `tests/workflows/fixtures/mini-plan.md`
- Create: `tests/workflows/fixtures/conflict-plan.md`
- Modify: `CLAUDE.md`
- Modify: `docs/superpowers/specs/2026-07-24-sdd-workflow-design.md` (record the discovery finding)

**Interfaces:**
- Consumes: the completed workflow from Tasks 1-5.
- Produces: a recorded, observed answer to whether `~/.claude/workflows/` is a discovery path, and fixtures reusable for future regression runs.

**Fence caution:** the three fixtures below are embedded in four-backtick blocks because their bodies contain three-backtick code blocks. `task-brief` toggles its in-fence state on any line starting with three backticks, so each fixture's inner fences must stay balanced — an unbalanced one would invert the parity and silently truncate this task's brief at the first `### Task 1:` inside a fixture. This was verified working against this plan file; re-run the check in Step 4 if you edit a fixture.

- [ ] **Step 1: Create the happy-path fixture plan**

Create `tests/workflows/fixtures/mini-plan.md` with exactly this content. The outer fence below is four backticks so the inner three-backtick code blocks survive; the file itself starts at `# Mini Fixture Plan`.

````markdown
# Mini Fixture Plan

**Goal:** Exercise the SDD workflow end to end against a throwaway repository.

## Global Constraints

- The greeting string is exactly `hello sdd`.
- Every function lives in `src/greet.js`.

---

### Task 1: Greeting function

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
const { greet } = require('../src/greet.js')
assert.equal(greet(), 'hello sdd')
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/greet.test.js`
Expected: FAIL, cannot find module `../src/greet.js`

- [ ] **Step 3: Implement**

```js
function greet() {
  return 'hello sdd'
}
module.exports = { greet }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/greet.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/greet.test.js
git commit -m "feat: add greet"
```

---

### Task 2: Shout function

**Files:**
- Modify: `src/greet.js`
- Test: `test/shout.test.js`

**Interfaces:**
- Consumes: `greet(): string` from Task 1.
- Produces: `shout(): string`.

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
const { shout } = require('../src/greet.js')
assert.equal(shout(), 'HELLO SDD')
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/shout.test.js`
Expected: FAIL, `shout is not a function`

- [ ] **Step 3: Implement**

```js
function shout() {
  return greet().toUpperCase()
}
module.exports = { greet, shout }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/shout.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/shout.test.js
git commit -m "feat: add shout"
```
````

- [ ] **Step 2: Create the conflict fixture plan**

Create `tests/workflows/fixtures/conflict-plan.md` with exactly this content. It is a standalone single-task plan whose Global Constraints mandate a test that asserts nothing — a defect by the review rubric, so preflight must surface it as a conflict rather than executing it.

````markdown
# Conflict Fixture Plan

**Goal:** Force the preflight conflict gate to fire.

## Global Constraints

- The greeting string is exactly `hello sdd`.
- Task 1's test must assert `true` and nothing else. Do not assert on the return value of `greet`.

---

### Task 1: Greeting function

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
require('../src/greet.js')
assert.ok(true)
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/greet.test.js`
Expected: FAIL, cannot find module `../src/greet.js`

- [ ] **Step 3: Implement**

```js
function greet() {
  return 'hello sdd'
}
module.exports = { greet }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/greet.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/greet.test.js
git commit -m "feat: add greet"
```
````

- [ ] **Step 3: Create the induced-defect fixture plan**

Create `tests/workflows/fixtures/defect-plan.md` with exactly this content. Its task text requires a named-greeting behaviour that the shown implementation does not provide and the shown test does not cover. This is an incomplete implementation rather than a mandated rubric defect, so it should pass preflight and be caught by the task reviewer as a Missing requirement — which is what exercises the fix loop and re-review live.

````markdown
# Defect Fixture Plan

**Goal:** Force one task review to fail so the fix loop and re-review run.

## Global Constraints

- The default greeting string is exactly `hello sdd`.
- Every function lives in `src/greet.js`.

---

### Task 1: Greeting function with an optional name

**Requirements:** `greet()` called with no argument returns `hello sdd`. `greet(name)` called with a non-empty string returns `hello ` followed by that name. Both behaviours are required.

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

- [ ] **Step 1: Write the failing test**

```js
const assert = require('node:assert/strict')
const { greet } = require('../src/greet.js')
assert.equal(greet(), 'hello sdd')
console.log('ok')
```

- [ ] **Step 2: Run it and watch it fail**

Run: `node test/greet.test.js`
Expected: FAIL, cannot find module `../src/greet.js`

- [ ] **Step 3: Implement**

```js
function greet(name) {
  return 'hello sdd'
}
module.exports = { greet }
```

- [ ] **Step 4: Run it and watch it pass**

Run: `node test/greet.test.js`
Expected: PASS, prints `ok`

- [ ] **Step 5: Commit**

```bash
git add src/greet.js test/greet.test.js
git commit -m "feat: add greet"
```
````

- [ ] **Step 4: Build the scratch repository**

```bash
SCRATCH=/private/tmp/sdd-verify
rm -rf "$SCRATCH" && mkdir -p "$SCRATCH" && cd "$SCRATCH"
git init -q -b main
mkdir -p src test docs/superpowers/plans
cp /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles/tests/workflows/fixtures/*.md docs/superpowers/plans/
git add -A && git commit -q -m "chore: fixture plans"
git checkout -q -b feature/verify
git log --oneline
ls docs/superpowers/plans/
```

Expected: one commit on branch `feature/verify`, and all three fixture plans present.

Then confirm `task-brief` extracts cleanly from a fixture, since these files are what every implementer will read:

```bash
cd /private/tmp/sdd-verify
SCRIPTS=$(ls -d ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/subagent-driven-development/scripts | tail -1)
"$SCRIPTS/task-brief" docs/superpowers/plans/mini-plan.md 2
cat .superpowers/sdd/task-2-brief.md
```

Expected: the brief contains only Task 2's heading and body — `### Task 2: Shout function` through its commit step — with no Task 1 content.

- [ ] **Step 5: Verify the protected-branch gate fires**

From the scratch repo on `main`:

```bash
cd /private/tmp/sdd-verify && git checkout -q main
```

Invoke the Workflow tool with `scriptPath` set to `/Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles/config/claude/workflows/subagent-driven-development.js` and `args` set to `{"planPath": "docs/superpowers/plans/mini-plan.md"}`.

Expected: returns `status: "needs_decision"` with `needsDecision.kind: "protected_branch"`, after exactly one agent (`preflight`).

- [ ] **Step 6: Verify the plan-conflict gate fires**

```bash
cd /private/tmp/sdd-verify && git checkout -q feature/verify
```

Invoke the Workflow tool with the same `scriptPath` and `args` set to `{"planPath": "docs/superpowers/plans/conflict-plan.md"}`.

Expected: returns `status: "needs_decision"` with `needsDecision.kind: "plan_conflicts"`, and the returned conflict quotes the "must assert `true` and nothing else" mandate. No implementer runs.

- [ ] **Step 7: Verify the happy path end to end**

Invoke the Workflow tool with the same `scriptPath` and `args` set to `{"planPath": "docs/superpowers/plans/mini-plan.md"}`.

Expected: returns `status: "complete"`, `completed: [1, 2]`, two ledger lines whose SHA ranges chain (task 2's base equals task 1's head), and a non-null `finalReview` with a `readyToMerge` verdict. Confirm with:

```bash
cd /private/tmp/sdd-verify && git log --oneline && node test/greet.test.js && node test/shout.test.js
```

Expected: at least two feature commits, and both test files print `ok`.

- [ ] **Step 8: Verify the fix loop and re-review fire live**

Reset the scratch tree so the defect plan starts from a clean base:

```bash
cd /private/tmp/sdd-verify && git checkout -q -B feature/defect main && git status --short
```

Expected: clean tree on `feature/defect`.

Invoke the Workflow tool with the same `scriptPath` and `args` set to `{"planPath": "docs/superpowers/plans/defect-plan.md"}`.

Expected: task 1's first review reports `specVerdict: "fail"` with the named-greeting requirement Missing, exactly one `fix:1` agent runs, a second `review:1` runs against the fixer's new head, and the run then completes. Confirm the fix actually landed:

```bash
cd /private/tmp/sdd-verify && node -e 'const {greet}=require("./src/greet.js"); console.log(greet(), "|", greet("dnjmn"))'
```

Expected: prints `hello sdd | hello dnjmn`.

If instead the first review passes and no fixer runs, that is a real finding about reviewer sensitivity, not something to retry until it passes. Record it in the spec's Verification section and report it rather than papering over it.

- [ ] **Step 9: Test user-level workflow discovery**

Invoke the Workflow tool with `name` set to `subagent-driven-development` (no `scriptPath`) and the same `args`, from the scratch repo.

Record the observed result. If it resolves, user-level `~/.claude/workflows/` discovery works. If it throws an unknown-name error, it does not, and `scriptPath` is the supported invocation.

- [ ] **Step 10: Record the discovery finding in the spec**

In `docs/superpowers/specs/2026-07-24-sdd-workflow-design.md`, replace the "Location" section's unverified paragraph with the observed result — state plainly whether `name` resolution worked, and which invocation form is supported.

- [ ] **Step 11: Document the workflow in the repo guide**

In `CLAUDE.md`, add `config/claude/workflows/` to the architecture notes with a one-line description, and add a line to the "When Editing" section:

```markdown
- Workflow scripts: `node --test tests/workflows/` (logic is tested against mocked agents; no real agents are spent)
```

- [ ] **Step 12: Clean up and commit**

```bash
rm -rf /private/tmp/sdd-verify
cd /Users/Dhananjay.Meena@gruve.ai/Developer/repo/dnjmn/dotfiles
git add tests/workflows/fixtures CLAUDE.md docs/superpowers/specs/2026-07-24-sdd-workflow-design.md
git commit -m "test(workflows): add SDD live verification fixtures and record discovery finding"
```
