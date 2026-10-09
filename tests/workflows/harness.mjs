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
