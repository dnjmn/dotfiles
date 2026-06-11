---
name: document-learning
description: Persist a completed /learn session into ~/Developer/repo/dnjmn/learn/<topic>/notes.md. Use this whenever the user asks to "document this learning session", "save these notes", "persist this learn session", types /document-learning, or when a /learn Socratic session reaches Phase 3 (Graduation) and needs to be captured for future reference. Also use when the user mentions writing up or archiving what they just learned in a Claude session.
---

# Document Learning Session

Persist the current `/learn` Socratic-tutor session into the user's learning workspace at `~/Developer/repo/dnjmn/learn/<topic>/notes.md` so future sessions can pick up where they left off without re-covering material.

## When this skill runs

You arrive after a `/learn` session has finished (or nearly finished). The conversation history contains:

- A topic (e.g. "react-query", "python-asyncio", "rust-ownership")
- A roadmap of concepts the tutor built
- Explain-back exchanges where the user put concepts in their own words
- Source URLs the tutor fetched during research (Context7, official docs, blog posts)
- Usually a Phase 3 "Session Handoff" block

Your job is to extract that material faithfully and write it to disk. **You are an archivist, not an author.** Do not invent content, re-teach, or paraphrase the user's explain-backs. If something is missing from the conversation, note it as missing rather than filling it in from training data.

## The workspace

The user keeps learning notes in `~/Developer/repo/dnjmn/learn/`. That repo has its own `CLAUDE.md` defining the convention:

```
learn/
  <topic>/              # lowercase, hyphenated
    notes.md            # key concepts, mental models, "aha" moments, Go analogues
    examples/           # (optional) runnable code
    exercises/          # (optional) practice
    projects/           # (optional) mini-projects
```

You only create `notes.md`. Leave the sibling dirs alone unless the user asks.

## Procedure

### 1. Identify the topic

Pick the topic slug from the conversation. Rules:

- lowercase, hyphen-separated (`react-query`, not `React Query` or `react_query`)
- match what the `/learn` command was invoked with, if visible
- if ambiguous, ask the user once before writing — don't guess between plausible slugs

### 2. Check for an existing notes file

Read `~/Developer/repo/dnjmn/learn/<topic>/notes.md` if it exists. There are three cases:

- **No directory** → create `~/Developer/repo/dnjmn/learn/<topic>/` and write a fresh `notes.md`
- **File exists, new session covers new concepts** → append a new dated session section; do not rewrite prior content
- **File exists, new session revisits old concepts** → append a new dated section noting "revisit" and what was reinforced or corrected

Never overwrite prior sessions. The learning workspace is cumulative by design.

### 3. Extract the material faithfully

Pull these from the conversation, in priority order:

1. **The `/learn` Phase 3 Session Handoff block** if it exists — copy it verbatim into a "Session Handoff" subsection. This is the canonical artifact the learn command produces and the user explicitly wants it preserved.
2. **User's explain-back quotes** — the actual words the user used when validating each concept. These are the highest-signal content in the entire session because they reflect how the user actually thinks about the topic. Preserve them verbatim in quotes, not paraphrased.
3. **Source URLs** — every link the tutor fetched (Context7, WebSearch, WebFetch). Group them by concept. Drop any that weren't actually fetched this session.
4. **Gotchas** — the pitfalls surfaced during research, verbatim.
5. **Go/K8s analogy bridges** — if the tutor mapped concepts to the user's existing stack, capture those mappings.

If the session never reached Phase 3 (user stopped early), capture whatever concepts did get validated and mark the rest as "not covered in this session".

### 4. Write notes.md using this template

```markdown
---
topic: <topic-slug>
last_updated: <YYYY-MM-DD>
sessions:
  - date: <YYYY-MM-DD>
    concepts_validated: [<concept-1>, <concept-2>, ...]
    status: <complete | partial>
---

# <Topic in Title Case>

<One-sentence framing of what this technology is and why the user cared enough to learn it. Pull from conversation — don't invent.>

## Session — <YYYY-MM-DD>

### Concepts validated
- **<concept-1>** — <one-line summary from the tutor's teaching>
- **<concept-2>** — <one-line summary>
- ...

### In my own words
<The user's explain-back quotes, one per concept, verbatim. Format as:>

**<concept-1>:**
> <exact words the user said>

**<concept-2>:**
> <exact words the user said>

### Mental model
<From the Phase 3 handoff if present, else synthesized from user's explain-backs. 2-3 sentences max.>

### Go / K8s bridges
| You already know | <Topic> equivalent |
|---|---|
| <Go or K8s pattern> | <topic pattern> |
| ... | ... |

(Omit this section if the tutor didn't draw analogies.)

### Gotchas
- <gotcha from research, verbatim>
- ...

### Sources verified this session
- **<concept-1>:** [<title>](<url>)
- **<concept-2>:** [<title>](<url>)
- ...

### Session Handoff (verbatim from /learn Phase 3)
<Paste the entire Phase 3 handoff block the /learn command produced, unedited. Wrap in a fenced code block if it makes formatting cleaner.>
```

For a **revisit** session, append a new `## Session — <date>` block below the existing ones rather than editing prior sections.

### 5. Confirm and show the user

After writing, report:

- The full path written to
- Whether it was a new file or appended session
- A one-line summary of what was captured (e.g. "5 concepts, 7 source URLs, user explain-backs preserved")

Do not paste the full notes back into the chat — the file is the artifact, and re-dumping it wastes the user's context.

## What NOT to do

- **Don't invent sources.** If a URL wasn't in the conversation, don't add it. A made-up link is worse than a missing one.
- **Don't paraphrase explain-backs.** The user's exact words are the point. If you smooth them out you lose the signal of how they actually think.
- **Don't re-teach.** This skill archives; it does not instruct. If a concept seems under-explained in the transcript, leave it as-is — the gap itself is data.
- **Don't overwrite.** Always append new sessions to existing `notes.md` files.
- **Don't write to the current repo.** The destination is always `~/Developer/repo/dnjmn/learn/`, regardless of where the session was invoked from.
- **Don't create `examples/`, `exercises/`, or `projects/` directories.** Those are for the user's own code; this skill only produces `notes.md`.

## Why this matters

The user runs `/learn` sessions to build durable understanding of new technologies. Without persistence, every session's hard-won explain-backs and verified sources evaporate when the conversation ends. By archiving faithfully — especially the user's *own words* from explain-backs — future sessions can calibrate the user as "already fluent in X" instead of re-probing from scratch. That's the whole point of the `learn/` workspace.
