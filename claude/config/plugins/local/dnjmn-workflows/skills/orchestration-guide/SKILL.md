---
name: orchestration-guide
description: This skill should be used when the user asks about "multi-agent workflow", "orchestrate agents", "parallel agent execution", "6-phase workflow", "complex feature workflow", mentions needing coordinated agents, or when implementing features that meet orchestration criteria (50+ lines, 3+ files, architecture decisions).
version: 1.0.0
---

# Multi-Agent Orchestration Guide

Coordinate multiple specialized agents through a 6-phase workflow for complex feature development.

## When to Use Orchestration

Trigger the `/dnjmn-workflows:orchestrate` command when ANY apply:
- New feature ≥50 lines of code
- Changes to ≥3 files
- Architecture decisions required
- Error handling modifications
- New types/interfaces introduced

## The 6-Phase Workflow

```
┌─────────────────────────────────────────────────┐
│  Phase 1: EXPLORE (Parallel)                    │
│  Launch 1-3 code-explorer agents simultaneously │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  Phase 2: ARCHITECT (Sequential)                │
│  code-architect designs based on findings       │
│  ★ USER CHECKPOINT: Approve blueprint           │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  Phase 3: IMPLEMENT (Sequential)                │
│  Write code per architect's blueprint           │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  Phase 4: REVIEW (Parallel)                     │
│  Launch applicable reviewers simultaneously     │
│  ★ USER CHECKPOINT: Decide on fixes             │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  Phase 5: POLISH (Sequential)                   │
│  code-simplifier for final cleanup              │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  Phase 6: COMMIT (Sequential)                   │
│  /commit or /commit-push-pr                     │
└─────────────────────────────────────────────────┘
```

## Parallel vs Sequential Execution

**Parallel** = Multiple Task tool calls in ONE message
- Agents run concurrently
- Use for independent analyses
- Example: Multiple explorers, multiple reviewers

**Sequential** = Wait for previous phase output
- Next phase depends on previous
- Feed output forward as context
- Example: Architect needs explorer findings

## Available Agents

| Agent | Purpose | When |
|-------|---------|------|
| `code-explorer` | Understand patterns | Phase 1 |
| `code-architect` | Design implementation | Phase 2 |
| `code-reviewer` | General quality | Phase 4 |
| `silent-failure-hunter` | Error handling | Phase 4 |
| `type-design-analyzer` | Type safety | Phase 4 |
| `pr-test-analyzer` | Test coverage | Phase 4 |
| `code-simplifier` | Final cleanup | Phase 5 |

## Quick Start

For complex features, run:
```
/dnjmn-workflows:orchestrate "Add user authentication with JWT"
```

The command enforces the workflow, manages TodoWrite tracking, and coordinates agents automatically.

## Manual Orchestration

If not using the command, follow this pattern:

1. **TodoWrite**: Create 6-phase tracker
2. **Phase 1**: Launch explorers with Task tool (parallel)
3. **Phase 2**: Launch architect with findings (sequential)
4. **Checkpoint**: Get user approval
5. **Phase 3**: Implement per blueprint
6. **Phase 4**: Launch reviewers with Task tool (parallel)
7. **Checkpoint**: User decides on fixes
8. **Phase 5**: Launch simplifier
9. **Phase 6**: Run /commit
