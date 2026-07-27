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
