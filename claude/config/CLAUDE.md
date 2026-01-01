## Work Philosophy to follow
- PRIORITIZE: information completeness, accuracy and concision
- IMPORTANT: PROACTIVELY use multiple agents wherever.
- MOST IMPORTANT: auto-load skills based on task, even for subagents and commands

## My identity
- I am Platform Engineer with 5+ years of experience as software developer.
- Proficient Language: Golang
- tools used by me: kubernetes, docker, macOS
- currently working on Creating Backstage Developer portal for my company.

## Communication Style
- Skip basic explanations
- Lead with code, follow with brief rationale only if non-obvious
- Direct disagreement welcome when my approach is not optimal

## Workflows

### When I paste code/errors

- Identify root cause
- Provide fix
- Mention related issues only if critical

### When I describe a feature

- Clarify ambiguity with targeted questions
- Propose architecture briefly (using skilled subagent)
- Implement incrementally with tracking in the project

## Code Preferences

### General
- Production-ready by default
- Prefer stdlib over dependencies unless there's clear benefit
- Tests: table-driven (Go), pytest parametrize (Python)
- Comments: only for "why", never "what"

## plugin references

- feature development:
| `/feature-dev` | 7-phase guided workflow | Complex features |
| `/ralph-loop` | Iterative completion | Tasks with clear success criteria |
| `/frontend-design` | Production UI | Web components |
| `/create-plugin` | Plugin scaffold | Building plugins |
- code review: `/pr-review-toolkit`
- plugin or skill (review or development): `/plugin-dev`

## Multi-Agent Orchestration
- use skilled Multi-Agent Orchestration (see below) PROACTIVELY.
- this should be auto-invoked for new big features or projects

Enforces 6-phase workflow with parallel agent execution. Use for complex features.

### Workflow Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLEX FEATURE WORKFLOW                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐                                               │
│  │   TRIGGER?   │  50+ lines │ 3+ files │ arch decisions        │
│  └──────┬───────┘                                               │
│         │ yes                                                   │
│         ▼                                                       │
│  ┌──────────────────────────────────────┐                       │
│  │     PHASE 1: EXPLORE (Parallel)      │                       │
│  │   should be done via /feature-dev:code-explorer              │ 
│  │  ┌────────────┐  ┌────────────┐      │                       │
│  │  │ explorer-1 │  │ explorer-2 │ ...  │  1-3 agents           │
│  │  └────────────┘  └────────────┘      │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 2: ARCHITECT (parallel)       │                       │
│  │  via /feature-dev:code-architect     │                       │
│  │  ┌────────────┐  ┌────────────┐      │                       │
│  │  │ arch-1     │  │ arch-2     │ ...  │  1-3 agents           │
│  │  └────────────┘  └────────────┘      │                       │
│  │ store this info in a task file with todos                    │
|  | rest of the phases will run for each todo until marked complete
│  └──────────────────┬───────────────────┘                       │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 3: IMPLEMENT (Sequential)     │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────────┐                   │
│  │     PHASE 4: REVIEW (Sequential)         │                   │
│  │                                          │                   │
│  │ run command: /pr-review-toolkit:review-pr│  All applicable   │
│  │                                          │      agents       │
│  └──────────────────┬───────────────────────┘                   │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 5: POLISH (Sequential)        │                       │
│  │  code-simplifier → final cleanup     │                       │
│  └──────────────────┬───────────────────┘                       │
│                     │                                           │
│                     ▼                                           │
│  ┌──────────────────────────────────────┐                       │
│  │  PHASE 6: COMMIT                     │                       │
│  │  update todo file with discription   │                       │
│  └──────────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

