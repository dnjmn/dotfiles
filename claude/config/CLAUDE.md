## Work Philosophy to follow
- PRIORITIZE: , information completeness and accuracy, concision
- BLEND: out-of-box thinking + best practices + industry standards
- use Multi-Agent Orchestration (see below) PROACTIVELY for complex tasks

## My identity
- I am Platform Engineer with 5+ years of experience as software developer.
- Proficient Language: Golang
- Tools: kubernetes, docker, macOS
- currently working on Creating Backstage Developer portal for my company.

## Communication Style

- Skip basic explanations
- Lead with code, follow with brief rationale only if non-obvious
- No hedging phrases ("I think", "perhaps", "you might want to")
- Direct disagreement welcome when my approach is suboptimal

## Code Preferences

### General
- Production-ready by default (error handling, logging, edge cases)
- Prefer stdlib over dependencies unless there's clear benefit
- Tests: table-driven (Go), pytest parametrize (Python)
- Comments only for "why", never "what"



## Commands Reference

### Git Workflow
| Command | Purpose | When |
|---------|---------|------|
| `/commit` | Create commit | After changes |
| `/commit-push-pr` | Commit + push + PR | Feature complete |
| `/clean_gone` | Remove stale branches | Maintenance |

### Code Review
| Command | Purpose | When |
|---------|---------|------|
| `/code-review` | Review PR on GitHub | After PR created (posts comment) |
| `/review-pr [aspects]` | Review local changes | Before commit (aspects: code, tests, errors, types, comments, simplify) |

### Development
| Command | Purpose | When |
|---------|---------|------|
| `/orchestrate` | 6-phase multi-agent workflow | Complex features (50+ lines, 3+ files) |
| `/feature-dev` | 7-phase guided workflow | Complex features |
| `/ralph-loop` | Iterative completion | Tasks with clear success criteria |
| `/frontend-design` | Production UI | Web components |
| `/create-plugin` | Plugin scaffold | Building plugins |

### Notion
| Command | Purpose |
|---------|---------|
| `/notion-search` | Search workspace |
| `/notion-create-page` | Create page |
| `/notion-database-query` | Query database |
| `/notion-create-task` | Create task |
| `/notion-find` | Quick title search |

### Atlassian (auto-triggered)
| Skill | Triggers On |
|-------|-------------|
| `triage-issue` | Bug reports, errors |
| `capture-tasks-from-meeting-notes` | Meeting notes |
| `generate-status-report` | Status requests |
| `search-company-knowledge` | Internal docs lookup |
| `spec-to-backlog` | Spec → Jira tickets |

## Auto-Triggered Agents

| Agent | Triggers When | Plugin |
|-------|---------------|--------|
| `code-reviewer` | Significant code changes* | pr-review-toolkit |
| `silent-failure-hunter` | Error handling modified | pr-review-toolkit |
| `type-design-analyzer` | New types added | pr-review-toolkit |
| `comment-analyzer` | Docs/comments added | pr-review-toolkit |
| `pr-test-analyzer` | Test files changed | pr-review-toolkit |
| `code-simplifier` | After review passes | pr-review-toolkit |
| `code-explorer` | Codebase exploration | feature-dev |
| `code-architect` | Architecture design | feature-dev |

*Significant = new feature, architecture changes, bug fixes, auth/security, 50+ lines complex logic

### Skip Auto-Review (ASK first)
Typos, comments, formatting, single-line fixes, docs, README

## Multi-Agent Orchestration

**Command**: `/dnjmn-workflows:orchestrate <feature-description>`

Enforces 6-phase workflow with parallel agent execution. Use for complex features.

### Workflow Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLEX FEATURE WORKFLOW                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐                                               │
│  │   TRIGGER?   │  50+ lines │ 3+ files │ arch decisions        │
│  └──────┬───────┘                                               │
│         │ yes                                                    │
│         ▼                                                        │
│  ┌──────────────────────────────────────┐                       │
│  │     PHASE 1: EXPLORE (Parallel)      │                       │
│  │  ┌────────────┐  ┌────────────┐      │                       │
│  │  │ explorer-1 │  │ explorer-2 │ ...  │  1-3 agents           │
│  │  └────────────┘  └────────────┘      │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 2: ARCHITECT (Sequential)     │                       │
│  │  code-architect → implementation plan │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 3: IMPLEMENT (Sequential)     │                       │
│  │  Write code per architect blueprint   │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │     PHASE 4: REVIEW (Parallel)       │                       │
│  │  ┌──────────┐ ┌──────────┐ ┌───────┐ │                       │
│  │  │code-revwr│ │silent-err│ │type-da│ │  All applicable       │
│  │  └──────────┘ └──────────┘ └───────┘ │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 5: POLISH (Sequential)        │                       │
│  │  code-simplifier → final cleanup      │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                            │
│                     ▼                                            │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 6: COMMIT                     │                       │
│  │  /commit or /commit-push-pr          │                       │
│  └──────────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### Trigger Criteria (Always-On)
Automatically use when ANY:
- New feature ≥50 lines
- Touching ≥3 files
- Architecture decisions required
- Error handling modified
- New types/interfaces introduced

### Phase Details

| Phase | Agent(s) | Execution | Input |
|-------|----------|-----------|-------|
| 1. Explore | `code-explorer` ×1-3 | **Parallel** | Feature description |
| 2. Architect | `code-architect` | Sequential | Explorer findings |
| 3. Implement | (me) | Sequential | Architecture plan |
| 4. Review | `code-reviewer` + applicable | **Parallel** | Code changes |
| 5. Polish | `code-simplifier` | Sequential | Review feedback |
| 6. Commit | `/commit` skill | Sequential | Polished code |

### Review Phase Agents
Launch ALL that apply (parallel):
- `code-reviewer` → always for significant changes
- `silent-failure-hunter` → if error handling touched
- `type-design-analyzer` → if new types added
- `pr-test-analyzer` → if tests changed

### Execution Rules
1. **Parallel** = Multiple Task calls in ONE message
2. **Sequential** = Wait for previous phase
3. **TodoWrite** = Track every phase transition
4. **Context chain** = Feed previous output to next agent

## Plugin Skills (context-aware)

| Skill | Plugin | Triggers On |
|-------|--------|-------------|
| `frontend-design` | frontend-design | UI requests |
| `hook-development` | plugin-dev | Event hooks |
| `mcp-integration` | plugin-dev | MCP config |
| `plugin-structure` | plugin-dev | Plugin scaffold |
| `command-development` | plugin-dev | Slash commands |
| `agent-development` | plugin-dev | Agent creation |
| `skill-development` | plugin-dev | Skill creation |

## Workflows

### When I paste code/errors

- Identify root cause
- Provide fix
- Mention related issues only if critical

### When I describe a feature

- Clarify ambiguity with targeted questions if needed
- Propose architecture briefly
- Implement incrementally

**Standard Dev:**
```
1. /feature-dev OR code directly
2. /review-pr code errors
3. /commit
4. /commit-push-pr
5. /code-review (on PR)
```

**Local Review:**
```
/review-pr              # All aspects
/review-pr tests errors # Specific
/review-pr simplify     # Polish
```

**Iterative:**
```
/ralph-loop "make tests pass" --completion-promise "All tests passing"
```

