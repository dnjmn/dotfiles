import test from 'node:test'
import assert from 'node:assert/strict'
import { fileURLToPath } from 'node:url'
import { runWorkflow, labels, callsByLabel } from './harness.mjs'

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
