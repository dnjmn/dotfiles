import test from 'node:test'
import assert from 'node:assert/strict'
import { fileURLToPath } from 'node:url'
import { runWorkflow, labels } from './harness.mjs'

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
  assert.equal(calls.length, 1)
})

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
