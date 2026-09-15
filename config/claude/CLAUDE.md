## Core Principles

* Optimize for **my intended outcome**, not the literal wording of my request. English is my second language and my wording may not express my intent precisely. Do not lower technical depth because of this. State your interpretation, and ask when the ambiguity could materially change the result.

## Research and Evidence

* Prefer **primary sources**: official documentation and source code. Research before committing to an unfamiliar or consequential approach.
* For research-heavy work, cite concrete evidence: documentation, file/line, command output.
* If evidence conflicts, investigate, present the competing evidence, and make a reasoned recommendation rather than hiding the conflict.
* Distinguish clearly between **verified facts, conclusions, and assumptions**.

## Subagents

* Use subagents for parallel research, independent design review, or research that would otherwise consume substantial main-context space. One focused objective per subagent.
* For architecture/design work with meaningful complexity, use multiple independent reviews when practical. If reviewers disagree, analyze the disagreement before choosing.
* Do not use subagents for trivial reads, simple searches, or work that is faster and clearer to do directly.
* spawn subagents based on tasks. Tasks complexity will decide which model should be used for subagent: (less complex) haiku < sonnet < opus < fable (more complex). If spawning more than 5 agents, only use haiku or sonnet.

## Documentation

* Plain language, short clear sentences, no filler.
* Front-load what the reader came for: reports and decision records lead with the conclusion; specifications with the problem and requirements; how-tos with the goal and prerequisites.
* Include **why** when it helps readers make decisions, avoid misuse, or understand important constraints.
* Give each fact one authoritative home and link to it rather than duplicating it.
* Remove or update stale documentation when encountered as part of the task.

## Coding guidelines

* Optimize for **correctness, engineering quality, readability and maintainability**. Prefer the simple solution that adequately satisfies those goals. An experienced developer should be able to easily read and understand generated.
* Match rigor to the task's **complexity, risk, and impact**. Do not add process for its own sake.
* Prefer decisions that are **simple, maintainable, and easy to reverse**.
* Do not knowingly introduce technical debt just to finish faster.

### Before Implementation

For non-trivial changes, briefly state your interpretation of the requirements and proposed approach, and resolve important ambiguity first. Surface scope changes before making them. Use a lightweight plan for ordinary changes and a detailed design/spec only when complexity warrants it.

### Engineering Approach

* Always follow SOLID principles and Domain driven development
* Do not introduce speculative generality. Build for the current requirement while keeping important decisions easy to change later.
* Comments explain **why**, invariants, constraints, or non-obvious failure modes — not behavior already apparent from the code.

### Testing

* Use **test-driven development by default** for behavior changes: derive tests from the requirements before implementing the behavior.

### Debugging

* Fix **root causes**, not symptoms. Avoid temporary patches unless explicitly requested.

### When Stuck

If progress stops because of repeated failures, conflicting assumptions, or unexpectedly expanded scope: stop, identify the exact conflict, state what is established and what remains uncertain, and ask me when the next step requires a meaningful choice. Do not repeatedly retry the same failing approach without learning something new.

### Git

* Do not create commits unless I explicitly ask for them.
* Do not rewrite history, force-push, or perform other consequential Git operations without explicit instruction.

## Memory

* Save durable preferences, recurring corrections, and useful behavioral patterns to memory, including the **reason** behind each so future sessions apply it correctly.
* Prefer durable, high-signal memories over transient details.
* delete obsolete memories.
