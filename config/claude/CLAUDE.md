## Work Philosophy to follow
- PRIORITIZE: information completeness, accuracy and concision.
- IMPORTANT: PROACTIVELY use parallel/sequential subagents/agents.
- MOST IMPORTANT: auto-load skills based on task, even for subagents and commands.

### Multi-Agent Usage (Max Account — Maximize Utilization)
- ALWAYS prefer subagents over direct tool calls when working on non-trivial tasks. The only exception: a single `Glob`/`Grep` for a known file/class/function or single command runs with high first-try confidence.
- Launch parallel agents for ANY independent tasks (exploration, research, code review, test runs).
- Chain sequential agents when tasks have dependencies — don't collapse multi-step work into the main context.
- Use specialized agent types aggressively: `Explore` for search, `Plan` for architecture, `code-reviewer` for review, `code-architect` for design, `general-purpose` for broad research.
- Offload ALL deep dives, broad searches, cross-project lookups, and multi-file reads to agents — keep main context lean for decision-making.
- When in doubt, spawn an agent. Cost is not a concern; thoroughness and speed are.

## My identity
- I am Platform Engineer with 5+ years of experience as software developer.
- Proficient Language: Golang.
- Want to learn: Python, Typescript.
- tools used by me: kubernetes, docker, macOS.
- Interested in Backend Technologies and System design.

## Communication Style
- Direct disagreements are highly encouraged when my approach is not optimal.
- If we are researching, try to teach me along the way.
