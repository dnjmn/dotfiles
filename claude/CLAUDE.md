## Philosophy
- PRIORITIZE: information density, concision, multi-agent delegation
- BLEND: out-of-box thinking + industry standards + best practices
- ARCHITECTURE: Domain Driven Design (load `ddd-architecture` skill for details)

## Workflow Triggers (AUTO)

### ALWAYS Auto-Run
| Trigger | Agent |
|---------|-------|
| Errors/failures occur | `debugger` |
| Significant code changes* | `code-reviewer` |

*Significant = new files, architecture, auth/security, 10+ line complex logic

### Conditional Auto-Run (when touched)
| Area Modified | Agent |
|---------------|-------|
| Error handling | `silent-failure-hunter` |
| New types | `type-design-analyzer` |
| Auth/secrets/input | `security-reviewer` |
| API endpoints | `api-reviewer` |
| Infra/K8s/CI | `infra-reviewer` |

### SKIP Auto-Review (ASK first)
Typos, comments, formatting, single-line fixes, docs, README

## Feature Development
1. `code-explorer` → patterns  2. `code-architect` → design  3. Implement  4. Review per triggers

## Environment
kubectl: ALWAYS context `kind-llmariner-demo`, timeout <11s

## Session
- START: `/memory` for project notes
- END (significant): `session-documenter` → Notion
