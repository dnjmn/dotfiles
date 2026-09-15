---
name: document-learning
description: Persist a completed /learn session into ~/Developer/repo/dnjmn/learn/<topic>/notes.md. Use this whenever the user asks to "document this learning session", "save these notes", "persist this learn session", types /document-learning, or when a /learn session reaches its epilogue and needs to be captured for future reference. Also use when the user mentions writing up or archiving what they just learned in a Claude session.
---

# Document Learning Session

Persist the current `/learn` session into the user's learning workspace at `~/Developer/repo/dnjmn/learn/<topic>/notes.md` so future sessions can pick up where they left off without re-covering material.

## When this skill runs

You arrive after a `/learn` session has finished (or nearly finished). The conversation history contains:

- A topic (e.g. "envoy", "python-asyncio", "rust-ownership"), optionally with a task the user wants to build
- A table of contents: chapters phrased as questions, each covering one design decision
- Chapters told as a story: situation → obvious fix → *your turn* → why it broke → what they built → the price → cliffhanger
- *Your turn* exchanges where the user predicted a design before the reveal
- Source URLs in each chapter's footnotes (Context7, official docs, origin posts)
- Usually an epilogue with a "story → official name → docs" table

Your job is to extract that material faithfully and write it to disk. **You are an archivist, not an author.** Do not invent content, re-teach, or paraphrase the user's *your turn* predictions. If something is missing from the conversation, note it as missing rather than filling it in from training data.

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

1. **The chapter arc** — for each chapter: its title-question, the problem, why the obvious fix broke, and what was built. Compress each chapter to 3–5 sentences that keep the *causal chain*; the chain is what makes the concept memorable, so don't reduce it to a definition.
2. **User's *your turn* predictions** — the actual words the user used when predicting a design, and the one-line comparison with what really happened. Preserve the user's words verbatim in quotes.
3. **The epilogue table** (story → official name → docs) verbatim, if it exists.
4. **Source URLs** — every link from chapter footnotes. Group them by chapter. Drop any that weren't actually fetched this session.
5. **The price / gotchas** — one per chapter, verbatim.
6. **Task pointers** — if the user named a task and the epilogue mapped chapters to it, capture that.

If the session never reached the epilogue (user stopped early), capture the chapters that were read and list the remaining table-of-contents entries as "not read this session".

### 4. Write notes.md using this template

```markdown
---
topic: <topic-slug>
last_updated: <YYYY-MM-DD>
sessions:
  - date: <YYYY-MM-DD>
    chapters_read: [<chapter-1-short-title>, <chapter-2-short-title>, ...]
    status: <complete | partial>
---

# <Topic in Title Case>

<One-sentence framing of what this technology is and why the user cared enough to learn it. Pull from conversation — don't invent.>

## Session — <YYYY-MM-DD>

### The story, chapter by chapter
**1. <chapter title-question>**
<3–5 sentences: the problem → why the obvious fix broke → what they built (now named) → what it costs.>

**2. <chapter title-question>**
<...>

### What I predicted
<The user's *your turn* answers, verbatim, with the one-line comparison. Format as:>

**Ch 1 — <title>:**
> <exact words the user said>

<one line: how it compared with what was actually built>

### Story → vocabulary
| In the story | Official name | Docs |
|---|---|---|
| <plot point> | <term> | [link](<url>) |

(Verbatim from the epilogue if present; omit if the session ended early.)

### Go / K8s bridges
| You already know | <Topic> equivalent |
|---|---|
| <Go or K8s pattern> | <topic pattern> |
| ... | ... |

(Omit this section if the tutor didn't draw analogies.)

### The price
- **Ch N:** <gotcha/cost from research, verbatim>
- ...

### Sources by chapter
- **Ch 1:** [<title>](<url>) · [<title>](<url>)
- **Ch 2:** [<title>](<url>)
- ...

### If I'm building <task>
<From the epilogue: which chapters matter, in what order, and the starting snippet. Omit if no task was given.>
```

For a **revisit** session, append a new `## Session — <date>` block below the existing ones rather than editing prior sections.

### 5. Confirm and show the user

After writing, report:

- The full path written to
- Whether it was a new file or appended session
- A one-line summary of what was captured (e.g. "6 chapters, 9 source URLs, 4 predictions preserved")

Do not paste the full notes back into the chat — the file is the artifact, and re-dumping it wastes the user's context.

## What NOT to do

- **Don't invent sources.** If a URL wasn't in the conversation, don't add it. A made-up link is worse than a missing one.
- **Don't paraphrase the user's predictions.** Their exact words are the point. If you smooth them out you lose the signal of how they actually think.
- **Don't flatten chapters into definitions.** Keep the problem → broke → built chain; a glossary is what the user was trying to avoid.
- **Don't re-teach.** This skill archives; it does not instruct. If a concept seems under-explained in the transcript, leave it as-is — the gap itself is data.
- **Don't overwrite.** Always append new sessions to existing `notes.md` files.
- **Don't write to the current repo.** The destination is always `~/Developer/repo/dnjmn/learn/`, regardless of where the session was invoked from.
- **Don't create `examples/`, `exercises/`, or `projects/` directories.** Those are for the user's own code; this skill only produces `notes.md`.

## Why this matters

The user runs `/learn` sessions to build durable understanding of new technologies. Without persistence, every session's story, predictions, and verified sources evaporate when the conversation ends. By archiving faithfully — the causal chain of each chapter and the user's *own words* from predictions — future sessions can treat the user as "already read the book on X" instead of starting from the prologue. That's the whole point of the `learn/` workspace.
