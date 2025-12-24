---
description: 6-phase multi-agent workflow for complex features (explore → architect → implement → review → polish → commit)
argument-hint: <feature-description>
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "TodoWrite", "Task", "Skill", "AskUserQuestion"]
---

# Multi-Agent Orchestration Workflow

Execute complex features through 6 coordinated phases with specialized agents. Each phase builds on the previous, with parallel execution where independent and sequential where dependent.

## Core Principles

- **Track progress with TodoWrite** at every phase transition
- **Use specialized agents** via Task tool for exploration, architecture, and review
- **Parallel execution**: Launch multiple agents in ONE message when independent
- **Sequential execution**: Wait for previous phase output before proceeding
- **User checkpoints**: Get approval at architecture and review phases
- **Context chaining**: Feed previous phase outputs to next phase agents

**Feature request:** $ARGUMENTS

---

## Phase 1: EXPLORE (Parallel)

**Goal**: Understand codebase patterns and requirements

**Actions**:

1. Create todo list tracking all 6 phases:
   ```
   - Phase 1: Explore (Parallel) - in_progress
   - Phase 2: Architect (Sequential) - pending
   - Phase 3: Implement (Sequential) - pending
   - Phase 4: Review (Parallel) - pending
   - Phase 5: Polish (Sequential) - pending
   - Phase 6: Commit (Sequential) - pending
   ```

2. Analyze the feature request to determine exploration scope:
   - What areas of codebase are affected?
   - Are there existing similar patterns?
   - Will tests be needed?

3. Launch code-explorer agents in PARALLEL using Task tool:
   - **Explorer 1**: Existing patterns in affected areas
   - **Explorer 2**: Dependencies and interfaces (if scope unclear)
   - **Explorer 3**: Testing patterns (if tests needed)

   Use 1-3 explorers based on scope complexity. Launch all applicable ones in a SINGLE message.

4. Synthesize explorer findings into a summary for the architect phase

**Output**: Exploration summary with:
- Existing patterns discovered
- Key files and interfaces
- Architectural constraints
- Testing approach

---

## Phase 2: ARCHITECT (Sequential)

**Goal**: Design implementation strategy based on exploration

**Actions**:

1. Update todos: Mark Phase 1 complete, Phase 2 in_progress

2. Launch code-architect agent with Task tool, providing:
   - Feature requirements from $ARGUMENTS
   - Exploration findings from Phase 1
   - Request for: files to modify, component structure, implementation sequence

3. The architect produces:
   - Files to create/modify (with paths)
   - Component design
   - Data flows
   - Build sequence (what to implement first)

4. Present architecture blueprint to user

5. **USER CHECKPOINT**: Ask user to approve or adjust the blueprint before proceeding

**Output**: Approved implementation blueprint

---

## Phase 3: IMPLEMENT (Sequential)

**Goal**: Write code following the architect's blueprint

**Actions**:

1. Update todos: Mark Phase 2 complete, Phase 3 in_progress

2. Follow the architect's implementation sequence exactly:
   - Create files in specified order
   - Implement components per design
   - Follow existing codebase patterns from Phase 1

3. Track implementation progress:
   - Update todos as each component completes
   - Show user progress after each significant piece

4. Pause if encountering decisions not covered by blueprint:
   - Ask user for direction
   - Update approach as needed

**Output**: Working implementation ready for review

---

## Phase 4: REVIEW (Parallel)

**Goal**: Multi-angle quality validation

**Actions**:

1. Update todos: Mark Phase 3 complete, Phase 4 in_progress

2. Determine which review agents apply based on changes:
   - `code-reviewer` → ALWAYS for significant code changes
   - `silent-failure-hunter` → if error handling was touched
   - `type-design-analyzer` → if new types/interfaces added
   - `pr-test-analyzer` → if test files were changed

3. Launch ALL applicable review agents in PARALLEL using Task tool:
   - Provide each agent with the list of files changed
   - Each reviews independently

4. Collect and consolidate review feedback:
   - Critical issues (must fix)
   - Warnings (should fix)
   - Suggestions (nice to have)

5. **USER CHECKPOINT**: Present review findings and ask how to proceed:
   - "Fix all issues and continue"
   - "Fix critical only and continue"
   - "Skip fixes and proceed to commit"

**Output**: Consolidated review feedback with user decision

---

## Phase 5: POLISH (Sequential)

**Goal**: Address review feedback and simplify code

**Actions**:

1. Update todos: Mark Phase 4 complete, Phase 5 in_progress

2. If user chose to fix issues:
   - Address critical issues first
   - Apply warnings and suggestions per user preference
   - Re-run specific reviewers if major changes made

3. Launch code-simplifier agent with Task tool:
   - Provide files that were modified
   - Request final cleanup pass
   - Apply simplifications that don't change behavior

4. Present final changes to user

**Output**: Polished, review-approved code

---

## Phase 6: COMMIT (Sequential)

**Goal**: Create atomic commit with clear message

**Actions**:

1. Update todos: Mark Phase 5 complete, Phase 6 in_progress

2. Summarize all changes made:
   - Files created
   - Files modified
   - Key functionality added

3. Use /commit skill to create commit:
   - Generate descriptive commit message
   - Reference the feature from $ARGUMENTS

4. Mark all todos complete

5. Ask user: "Would you like to push and create a PR using /commit-push-pr?"

**Output**: Committed changes (and optionally PR)

---

## Important Notes

### Parallel Execution Pattern

When launching multiple agents in parallel, make multiple Task tool calls in a SINGLE message:

```
Launch code-explorer agents in parallel:
1. Task: "Explore existing auth patterns" → code-explorer
2. Task: "Explore test patterns" → code-explorer
3. Task: "Explore API interfaces" → code-explorer
```

All three run concurrently.

### Sequential Execution Pattern

For dependent phases, wait for previous output:

```
Phase 1 output: [exploration findings]
↓ (feed forward)
Phase 2: Launch architect with findings above
```

### Context Chaining

Each phase should explicitly reference previous phase outputs:

```
"Based on the exploration findings:
- Pattern X was found in src/auth/
- Interface Y is defined in types/
- Tests use framework Z

Design an implementation that follows these patterns..."
```

### User Checkpoints

Never proceed past these points without user confirmation:
1. After Phase 2 (Architecture) - user approves blueprint
2. After Phase 4 (Review) - user decides on fixes

### Trigger Criteria

This workflow is designed for tasks meeting ANY of:
- New feature ≥50 lines of code
- Changes to ≥3 files
- Architecture decisions required
- Error handling modifications
- New types/interfaces introduced

---

## Quick Reference

| Phase | Agents | Execution | Checkpoint |
|-------|--------|-----------|------------|
| 1. Explore | code-explorer ×1-3 | Parallel | No |
| 2. Architect | code-architect | Sequential | **Yes** |
| 3. Implement | (direct) | Sequential | No |
| 4. Review | reviewers ×1-4 | Parallel | **Yes** |
| 5. Polish | code-simplifier | Sequential | No |
| 6. Commit | /commit | Sequential | Optional |

---

**Begin with Phase 1: Create the todo list and analyze the feature scope.**
