# Design: Improve `/learn` Command Prompt Engineering

**Date:** 2026-04-06
**Scope:** Rewrite `config/claude/commands/learn.md` to get better LLM output through stronger prompt engineering
**Approach:** Restructure around LLM strengths — strong guardrails, flexible execution, agent-driven research

---

## 1. Iron Law & Anti-Rationalization

### Iron Law

> "Never confirm understanding the user hasn't demonstrated. Teaching is not explaining — it's verifying that the explanation landed."

### Red Flags Table

The prompt must include a rationalization table to prevent common LLM teaching failures:

| LLM Instinct | Why It's Bad | Rule |
|---|---|---|
| "Great explanation!" after a mediocre answer | Flattery teaches wrong things | Only say "correct" when user demonstrates they can *apply* the concept |
| Dumping 5 concepts because they're related | Overwhelms, prevents deep understanding | One concept. Finish it. Then next. |
| Showing a big code example immediately | Code without mental model is memorization | Mental model first. Code illustrates, never leads. |
| Skipping explain-back because user "seems to get it" | Seeming ≠ knowing | Every concept gets validated. No exceptions. |
| Saying "this is similar to X" without explaining *how* | Vague analogies create false confidence | Analogies must map specific mechanics |
| Moving on after a partial answer | Gaps compound into misunderstandings | Partial = re-teach the gap, then re-validate |

---

## 2. Adaptive Assessment (Replacing Rigid Phase 0)

Instead of asking "what do you know about X?", the LLM should:

1. **Research first** — Use Context7/WebSearch to build the concept map *before* talking to the user
2. **Probe with a scenario** — Instead of "what do you know about React Query?", ask: "If you needed to fetch user data on component mount and keep it fresh, how would you approach it today?" Reveals actual understanding vs. vocabulary familiarity.
3. **Calibrate from the answer:**
   - What they reach for (current mental model)
   - What vocabulary they use naturally (depth)
   - What they skip or hand-wave (gaps)
4. **Present roadmap with reasoning** — Show why each concept is tagged known/partial/new, so the user can correct miscalibrations

**Key shift:** Infer knowledge level from demonstrated thinking, not self-reported familiarity.

---

## 3. Analogy Construction Framework

### Structured Analogy Mapping

1. **Map the mechanism, not the name** — Don't say "X is like Redis." Say "X solves the same problem as Redis TTL — stale data vs. fetch cost — but the eviction trigger is [different mechanism]."

2. **Anchor to user's stack:**
   - Concurrency/lifecycle → Go goroutines, context, channels
   - State management → Kubernetes reconciliation loop, desired vs. actual state
   - Caching/invalidation → Redis, HTTP cache headers
   - Error handling → Go's explicit error returns vs. try/catch
   - Dependency injection → Go interfaces, K8s service abstraction
   - Build/deploy pipeline → Docker layers, K8s rolling updates

3. **Three-part structure:**
   - "In Go/K8s, you solve [problem] with [mechanism]"
   - "This technology solves the same problem with [different mechanism]"
   - "The key difference is [what makes this approach distinct]"

4. **Know when NOT to analogize** — If there's no good parallel, say so. Bad analogies are worse than no analogy.

---

## 4. Agent-Driven Research at Every Phase

Research agents are launched **before** each teaching step, not all upfront.

| Phase | What agents research | Why |
|---|---|---|
| **Assessment** | Concept map of technology, prerequisites, typical learning paths | Build good probing scenario, calibrate accurately |
| **Per-concept teaching** | Official docs for the specific concept, common misconceptions, real-world usage patterns | Teach with current, accurate info — not training data |
| **Analogy construction** | How concept maps to Go/K8s patterns, community comparisons | Build precise analogies |
| **Explain-back evaluation** | Verify user's mental model against actual behavior, edge cases | Catch subtle misunderstandings |
| **Graduation** | Current best practices, production pitfalls, latest API changes | Accurate handoff and cheat sheet |

**Execution pattern:**
- Context7 first, fall back to WebSearch + WebFetch
- One agent per concern, parallel where possible
- Teaching agent consumes results, never raw-dumps on user

---

## 5. Evidence-Based Teaching & Reference Links

### Iron Rule Addition

> "Never teach from training data alone. Every concept taught must be backed by a source fetched this session. If you can't find a source, tell the user and search harder — don't guess."

### Every concept explanation must include:
- The core teaching (mental model + mechanics)
- 1-2 reference links: `[Source: Official Docs — Topic](url)`

### Source hierarchy:
1. Official documentation (Context7 or direct fetch)
2. Official blog posts / release notes
3. Well-known community resources (Go blog, K8s docs)
4. Never: random blog posts, StackOverflow, or LLM paraphrasing without source

### If a source can't be found:
- Don't teach from memory
- Tell user: "I couldn't find a current source for [X]. Let me try a different search."
- Escalate: "I can't verify this — want me to teach what I know with the caveat it may be outdated?"

---

## 6. Concrete Explain-Back Rubric

### PASS requires ALL of:
- User can state *what problem* the concept solves (not just what it does)
- User can describe *when they'd use it* vs. alternatives
- User uses their own words/analogies, not parroting

### PARTIAL — any of:
- Can describe what it does but not why it exists
- Uses right vocabulary but can't connect to a concrete scenario
- Gets happy path but misses error/edge behavior

### MISS — any of:
- Confuses this concept with something else
- Can't explain without re-reading the teaching
- Applies it to a wrong scenario

### Evaluation behavior:
- **PASS:** One sentence + one practical nuance/gotcha. Move on.
- **PARTIAL:** Name the specific gap. Re-teach *only that gap* from different angle. Re-validate with narrower question.
- **MISS:** Different analogy or approach entirely. If two attempts miss, ask the user what's confusing.

### Anti-flattery:
- Never "Great explanation!" or "Exactly right!"
- Instead: "Correct. One thing to watch for: [nuance]." or just "That's right. Next concept."

---

## 7. Graduation & Handoff

### Improvements over current:

1. **Handoff uses user's own words** — "What I know" bullets use analogies/explanations the user gave during explain-backs, not the LLM's teaching
2. **Further Reading section** — All reference links from session, organized by concept, verified accessible
3. **Quick Reference Card additions:**
   - Go/K8s analogy mapping for each concept (bridge between known and learned)
   - Concept dependency graph

### Kept from current design:
- Session summary prompt structure
- "Copy this into a new session" handoff format
- `[describe your task here]` placeholder

---

## What Stays the Same

- Command format (`.md` in `commands/`)
- Frontmatter: `allowed-tools` (updated to include `Agent` for subagent research), `model: opus`, `argument-hint`
- Overall flow: Assess → Research → Teach → Graduate
- One concept at a time pacing
- Progress tracking visualization
- No implementation code rule

## What Changes

- Rigid phases → flexible guardrails with iron laws
- Single upfront research → continuous agent-driven research per concept
- Self-reported knowledge → scenario-based probing
- Vague analogies → structured 3-part analogy framework
- Vibes-based evaluation → concrete PASS/PARTIAL/MISS rubric
- Teaching from training data → evidence-based with reference links
- Scripted LLM responses → constraint-based natural teaching
