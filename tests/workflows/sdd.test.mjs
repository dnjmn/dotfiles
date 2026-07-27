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
