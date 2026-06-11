# Simulated prior conversation — a PARTIAL /learn session on python-asyncio

The session stopped before reaching Phase 3 graduation. Only 2 of 5 concepts were validated.

---

**User:** /learn python-asyncio

**Assistant:** [Research agents ran]

Scenario: in Go you'd spin up a goroutine per incoming request and use channels to coordinate. If you had to do the equivalent in Python today — fan out 1000 HTTP calls and collect results — how would you approach it?

**User:** Thread pool probably, concurrent.futures.ThreadPoolExecutor with max_workers=100 or so. I know asyncio exists but I haven't actually used it in anger.

**Assistant:** OK — threadpool is a reasonable fallback but it's the wrong tool for IO-bound fanout at that scale because the GIL and thread overhead hurt you. Roadmap:

```
[ ] event loop — the core scheduler (new)
[ ] coroutines + await — suspending without blocking (new)
[ ] tasks — scheduling coroutines concurrently (new)
[ ] asyncio.gather / TaskGroup — structured concurrency (new)
[ ] cancellation + timeouts — context-like lifecycle (new)
```

Ready?

**User:** yes

**Assistant:** **Concept 1: event loop.** Why it exists: in a single-threaded IO-bound program, most time is spent waiting on syscalls (recv, read). The event loop is a scheduler that multiplexes many waiting operations onto one thread by registering callbacks with the OS (epoll/kqueue) and resuming whichever coroutine is ready. It's exactly the pattern Go's runtime hides from you — Go's scheduler parks goroutines on blocking IO and wakes them when the fd is ready. Python's asyncio exposes the loop as an explicit object.

[Source: Python Docs — asyncio Event Loop](https://docs.python.org/3/library/asyncio-eventloop.html)

Gotcha: only one event loop per thread, and you typically don't create it yourself — `asyncio.run()` manages it for you.

In your own words: why does a single-threaded event loop outperform a thread pool for IO-bound workloads?

**User:** Threads have stack + kernel scheduling overhead, and the GIL means only one runs Python bytecode at a time anyway. The event loop runs one thread but can have thousands of coroutines parked on IO because parking a coroutine is just "save its state, register for the fd, yield to the loop" — way cheaper than a thread context switch. It's basically what Go's runtime does but explicit.

**Assistant:** Correct. One nuance: Go's runtime also multiplexes goroutines onto OS threads so it can use multiple cores for CPU work. asyncio is single-threaded by design — if your workload has CPU-bound segments, the loop starves.

**Concept 2: coroutines + await.** Why it exists: a coroutine is a function that can suspend mid-execution and resume later. `async def` declares one; `await` is the suspension point. When you `await some_io_operation()`, the coroutine's state is saved, control returns to the loop, and the loop resumes it when the IO is ready.

[Source: Python Docs — Coroutines and Tasks](https://docs.python.org/3/library/asyncio-task.html)

```python
async def fetch_user(session, user_id):
    async with session.get(f"/api/users/{user_id}") as resp:
        return await resp.json()
```

Gotcha: calling `fetch_user(session, 1)` without await returns a coroutine object — it doesn't run. This trips up everybody coming from sync Python.

In your own words: what's the difference between a coroutine and a running task?

**User:** A coroutine is like a paused function object — calling `async def foo()` followed by `foo()` just gives you an inert thing. It only actually runs when something schedules it on the event loop. A task is the scheduled wrapper — once you hand the coroutine to the loop (via asyncio.create_task or by awaiting it), it's live and the loop can resume it. Kind of like the distinction between a goroutine function literal and actually `go`-ing it, except in Go there's no intermediate inert object.

**Assistant:** Exactly right, and the Go analogy is precise. In Go, `go foo()` atomically creates-and-schedules — there's no way to hold a "paused goroutine". Python forces you to be explicit.

**User:** I have to drop out, can we pick this up tomorrow?

**Assistant:** Of course. You've validated 2 of 5 concepts (event loop, coroutines + await). When you resume, we'll continue from tasks → gather/TaskGroup → cancellation.

[Session ended here. No Phase 3 handoff was generated.]
