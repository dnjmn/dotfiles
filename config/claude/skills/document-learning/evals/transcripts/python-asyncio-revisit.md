# Simulated /learn session — python-asyncio REVISIT (notes.md already exists)

This scenario tests the "append to existing notes.md" case. A prior notes.md already exists at ~/Developer/repo/dnjmn/learn/python-asyncio/notes.md (the partial session from yesterday). Today the user resumed and finished the remaining 3 concepts.

---

**User:** /learn python-asyncio — picking up where we left off yesterday

**Assistant:** Welcome back. You validated event loop and coroutines + await. Remaining:

```
[✓] event loop
[✓] coroutines + await
[ ] tasks — scheduling coroutines concurrently
[ ] asyncio.gather / TaskGroup — structured concurrency
[ ] cancellation + timeouts
```

Ready to continue?

**User:** yes

**Assistant:** **Concept 3: tasks.** Why it exists: when you `await some_coroutine()`, you run it sequentially. To get concurrency you need to schedule multiple coroutines on the loop *at the same time*, then await their collective completion. `asyncio.create_task(coro)` wraps the coroutine in a Task object and hands it to the loop; from that moment it's running concurrently with whoever created it.

[Source: Python Docs — asyncio.create_task](https://docs.python.org/3/library/asyncio-task.html#asyncio.create_task)

```python
task1 = asyncio.create_task(fetch_user(session, 1))
task2 = asyncio.create_task(fetch_user(session, 2))
user1 = await task1
user2 = await task2
```

Gotcha: if you create a task and never await it, exceptions raised inside it are silently swallowed. Python will warn on garbage collection but by then the damage is done.

In your own words: when would you use `create_task` vs just `await`?

**User:** Plain `await` is sequential — I use it when I need the result before doing the next thing. `create_task` is for when I want two or more coroutines running concurrently and I'll collect their results later. Like `go foo()` vs calling `foo()` directly in Go. The gotcha about swallowed exceptions is nasty — it means I have to be disciplined about either awaiting every task I create or wiring up a done-callback that logs errors.

**Assistant:** Correct. In practice you almost always use `gather` or `TaskGroup` instead of raw `create_task` for this reason — they handle the awaiting discipline for you.

**Concept 4: gather / TaskGroup.** Why it exists: raw `create_task` leaves error handling and lifetime management to you, and people get it wrong. Structured concurrency says "all tasks spawned in a scope must finish before the scope exits, and if any one fails all siblings are cancelled". `asyncio.gather(*coros)` is the older API; `asyncio.TaskGroup` (3.11+) is the modern structured-concurrency version and should be preferred.

[Source: Python Docs — asyncio.TaskGroup](https://docs.python.org/3/library/asyncio-task.html#task-groups)
[Source: PEP 654 — Exception Groups](https://peps.python.org/pep-0654/)

```python
async with asyncio.TaskGroup() as tg:
    tg.create_task(fetch_user(session, 1))
    tg.create_task(fetch_user(session, 2))
# By the time the `async with` exits, all tasks are done.
# If any raised, you get an ExceptionGroup with all failures.
```

Gotcha: `gather(return_exceptions=False)` (the default) cancels siblings on first failure but *returns* the exception wrapped in the result list if you pass `return_exceptions=True`. TaskGroup always cancels siblings and raises. These are different contracts and people conflate them.

In your own words: why prefer TaskGroup over gather?

**User:** TaskGroup enforces structured concurrency — the lifetime of all spawned tasks is bounded by the `async with` block, and if any fail the rest get cancelled automatically. gather predates this and has looser semantics: with return_exceptions=True you can actually leak failures because the call returns successfully with exceptions buried in the result list. TaskGroup's contract is stricter and maps more cleanly to errgroup in Go.

**Assistant:** Correct. The errgroup analogy is perfect — both enforce "all siblings cancel on first error" and both make exception handling explicit at the group level.

**Concept 5: cancellation + timeouts.** Why it exists: long-running tasks need to be cancellable (user navigated away, timeout hit, parent task failed). asyncio cancellation works by raising `CancelledError` inside the coroutine at its next `await` point — cooperative, not preemptive. `asyncio.timeout(5)` is a context manager that cancels the enclosed coroutine if it exceeds the deadline.

[Source: Python Docs — asyncio.timeout](https://docs.python.org/3/library/asyncio-task.html#asyncio.timeout)

```python
async with asyncio.timeout(5):
    result = await long_running_operation()
```

Gotcha: `CancelledError` is a `BaseException` in Python 3.8+, not `Exception`. If you write `except Exception:` you won't catch it — which is usually what you want, because catching and swallowing cancellation breaks the whole cooperative model.

In your own words: how does asyncio cancellation compare to Go's context?

**User:** In Go, context.Context propagates deadline and cancellation down through function calls; goroutines check ctx.Done() at checkpoints and return early. asyncio is similar but implicit — cancellation is delivered by raising CancelledError at the next await, so the "checkpoints" are every await in the coroutine. You don't need to pass a ctx around because the loop tracks task lineage. The BaseException thing is the Python-specific detail: it means "do NOT silently absorb this with a bare except" because you'd break cooperative cancellation.

**Assistant:** Correct on all counts, especially the last point. Treating CancelledError as catchable is the #1 way people break asyncio lifecycles.

[Launches graduation agent]

## You're Ready

You've validated all 5 concepts for python-asyncio.

### Session Handoff Prompt
Copy this into a new Claude Code session when you're ready to build:

---
I've completed a learning session on python-asyncio. Here's my context:

**What I know:**
- Event loop is a single-threaded scheduler that multiplexes coroutines onto epoll/kqueue — same pattern as Go's runtime but explicit. Single-threaded by design so CPU-bound work starves the loop
- Coroutines are inert objects until scheduled; `async def foo(); foo()` returns a coroutine, not a running task. `await` is the suspension point
- `asyncio.create_task` wraps a coroutine and hands it to the loop for concurrent execution, but unawaited tasks swallow exceptions — use gather or TaskGroup instead
- TaskGroup (3.11+) enforces structured concurrency: all tasks bounded to the `async with` scope, any failure cancels siblings and raises ExceptionGroup. Maps cleanly to Go errgroup
- Cancellation is cooperative and delivered via `CancelledError` at the next await; it's a BaseException in 3.8+ specifically so a bare `except Exception` won't swallow it

**My mental model:**
asyncio is Go's runtime with the loop made explicit. Every concept maps to something I know — goroutines ↔ tasks, channels ↔ queues, context.Context ↔ CancelledError propagation, errgroup ↔ TaskGroup. The main mental shift is that suspension points are explicit (`await`) rather than hidden in runtime IO interception.

**Gotchas I should remember:**
- Calling an async function without await returns a coroutine object — it does not run
- Orphan tasks (created but never awaited) silently swallow exceptions
- gather(return_exceptions=True) can leak failures into the result list — prefer TaskGroup
- CancelledError is a BaseException in 3.8+ — never catch it with bare `except Exception` unless you re-raise
- Event loop is single-threaded — CPU-bound work starves IO; use run_in_executor for CPU hot paths

**I'm building:** [describe your task here]
---

### Further Reading
- event loop: [Python Docs — asyncio Event Loop](https://docs.python.org/3/library/asyncio-eventloop.html)
- coroutines: [Python Docs — Coroutines and Tasks](https://docs.python.org/3/library/asyncio-task.html)
- tasks: [Python Docs — asyncio.create_task](https://docs.python.org/3/library/asyncio-task.html#asyncio.create_task)
- TaskGroup: [Python Docs — asyncio.TaskGroup](https://docs.python.org/3/library/asyncio-task.html#task-groups)
- PEP 654: [PEP 654 — Exception Groups](https://peps.python.org/pep-0654/)
- timeout: [Python Docs — asyncio.timeout](https://docs.python.org/3/library/asyncio-task.html#asyncio.timeout)

### Quick Reference Card

**Core APIs/Patterns:**
- `asyncio.run(main())` — entrypoint
- `async with asyncio.TaskGroup() as tg: tg.create_task(...)` — structured concurrency
- `async with asyncio.timeout(n): ...` — deadline
- `await coro` — sequential
- `tg.create_task(coro)` — concurrent

**Analogy Bridge (what you already know → asyncio):**
| You Know | asyncio Equivalent |
|---|---|
| goroutine | Task |
| `go foo()` | `tg.create_task(foo())` |
| channel | asyncio.Queue |
| errgroup.Group | asyncio.TaskGroup |
| context.Context | implicit, via CancelledError |
| ctx.Done() check | any `await` point |

**Concept Dependencies:**
event loop → coroutines+await → tasks → TaskGroup → cancellation
