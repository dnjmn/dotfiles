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
