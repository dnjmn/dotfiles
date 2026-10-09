---
name: go-service-cli-development
description: Use when writing, reviewing, or refactoring Go services, APIs, or CLI tools - adding an endpoint or command, wiring a third-party client or SDK, handling configuration and secrets, adding concurrency or retries, or checking Go code before it ships.
---

# Go Service & CLI Development

## Overview

Dependencies point inward. Anything that varies is injected. Everything here follows from those two rules.

Apply these checks **while writing**, not as a review pass afterwards. Measured baseline: Go code written under normal delivery pressure comes out idiomatic and well-named, and consistently omits the boundary, configuration, and failure-mode decisions below - the same omissions that get correctly flagged when reviewing someone else's code. Knowing the rule is not the gap. Applying it while producing code is.

## 1. The flow goes in a use case, not the handler

An inbound handler - HTTP, gRPC, or CLI command - does exactly five things:

1. decode and validate transport input
2. authenticate and authorize
3. convert transport types into application inputs
4. call **one** use-case method
5. map the result or error to a transport response

A handler that performs a second business step - look up, then record, then notify - is holding a workflow that belongs in a use case.

**Test:** could an HTTP endpoint and a CLI command both invoke this operation without duplicating logic? If no, it is in the wrong place.

## 2. Own the interface; wrapping the SDK is not a boundary

Putting a vendor SDK in its own package is packaging. The boundary is the **interface**, and the consumer declares it:

```go
// application layer - declares what it needs
type NoticeSender interface {
    SendDunningNotice(ctx context.Context, to Email, id AccountID) error
}
```

The adapter package imports the SDK and satisfies that interface. The application never names the concrete type.

If a struct field reads `*email.Client` or `*s3.Client` instead of an interface you declared, you have a wrapper, not a boundary - and no way to exercise the caller without real credentials.

Keep the interface to the methods this consumer actually calls.

## 3. Configuration is typed, validated, and loaded once

Reading env vars only in `main` is necessary, not sufficient. Required:

```go
type Config struct {
    Server    ServerConfig
    DB        DBConfig
    Notifier  NotifierConfig
}

func Load() (Config, error)
func (c Config) Validate() error   // called before anything starts
```

- Every value that varies by environment is a field: addresses, timeouts, retry budgets, concurrency limits, endpoints, credentials, feature flags, log level.
- A missing required secret fails at startup, not on the first request that needs it.
- Inline literals at the composition root (`"billing@acme.example"`, `10`, `30*time.Second`) are configuration that has not been named yet.
- Document precedence when there are multiple sources: `defaults < file < environment < flags`.

## 4. Every outbound call has a deadline and a deliberate retry policy

For each call leaving the process, decide and write down all four:

| Decision | Default if you skip it |
|---|---|
| Timeout | none - hangs until the caller gives up |
| Retry: yes/no | none, or blind retry |
| Safe to retry? | assumed yes, usually wrong |
| Backoff | fixed sleep, synchronized retry storms |

Retry only what is idempotent. A `POST` that creates something is not retryable without an idempotency key.

Backoff is exponential with jitter. A fixed `time.Sleep` between attempts synchronizes every caller into the same retry wave and turns a slow dependency into an outage.

Inheriting the request context is a deadline for the *request*, not a budget for *this dependency* - derive a shorter one.

**Context is a parameter, never a struct field.** A `ctx` stored on a struct is the wrong fix for a missing deadline: it captures one caller's cancellation and silently applies it to every later call. Pass `ctx` as the first argument to each method that performs I/O.

## 5. Map errors at the boundary; keep the cause

- Wrap with `%w` at every layer that adds context. Classify with `errors.Is` / `errors.As`.
- Each layer translates: infrastructure error → domain/application error → transport representation.
- Distinguish not-found from failure. Mapping every error to 404, or every error to 500, is not error handling.

**A persistence error type must not reach the transport layer.** The recipe, all three steps:

1. the repository translates the driver's not-found into a domain error (`ErrAccountNotFound`)
2. the use case returns that domain error unchanged, or wraps it with `%w`
3. the handler checks `errors.Is(err, domain.ErrAccountNotFound)`

`errors.Is(err, sql.ErrNoRows)` inside a handler means `database/sql` is imported by your transport package. Step 1 is the missing step; adding it costs one line in the repository.
- Never return an internal message to the caller; never drop the cause internally.

## 6. CLI: stdout is data, stderr is everything else

- **stdout** carries result records and nothing else - no headers, no column labels, no blank lines, no `"Files to upload:"`, no trailing summary. Everything a human reads but a script would have to strip is stderr.
- **stderr** carries progress, spinners, status lines, warnings, and errors. Always - they corrupt a pipe otherwise.
- Records on stdout are parseable without a flag: one record per line, fields delimited.
- Exit codes are named constants covering at least: success, usage error, runtime failure, and interrupted (`130`). Returning only `0` and `1` means a caller cannot distinguish "your arguments were wrong" from "the upload failed" from "you pressed Ctrl-C".
- Destructive and bulk operations get explicit confirmation or a dry-run mode.
- Changing stdout, stderr, or exit codes breaks scripts. Treat it as a breaking change.

## 7. Concurrency: every goroutine answers "who stops me?"

Bound the parallelism, propagate errors out, honor cancellation, and give every goroutine a shutdown path. Never fire-and-forget: a function that spawns work and returns before it completes has silently discarded every error.

## 8. Observability is part of the change, not a follow-up

A new use case ships with at least: a structured log line carrying the outcome, the operation name, a correlation ID, and duration. Never log secrets, tokens, or credentials.

## 9. Write the test

Consumer-owned interfaces (check 2) exist so the use case can be tested with a fake. Having them is not the deliverable; using them is.

The minimum for a new use case: one test that drives it through its interfaces with fakes, covering the success path and the one failure path that matters most. That test needs no credentials, no network, and no database - if it does, the boundary is wrong, and the test is what tells you.

Scale up from there with risk. Do not scale down to zero and record it as a known gap.

## Red flags - stop and fix

- A handler or command function with more than one business step in it
- A struct field holding a concrete third-party type
- A string or number literal at the composition root
- An outbound call with no explicit timeout
- `fmt.Errorf` without `%w`
- `sql.` , `redis.` , or any driver identifier appearing in a transport or application package
- A retry loop you did not decide was safe
- A fixed `time.Sleep` between retry attempts
- `ctx` as a struct field
- `go func()` with no owner tracking it
- Progress, headers, or labels written to stdout
- Naming a boundary violation in your summary instead of fixing it
- Finishing a feature having written no test

## Under pressure

| Thought | Reality |
|---|---|
| "It's a demo in 90 minutes" | Checks 1-5 cost minutes now. Unpicking them costs days. |
| "I'll add the interface when I write tests" | You will not write tests, because there is no interface. |
| "The request context is the timeout" | That is the caller's budget, not this dependency's. |
| "I'll parameterize it later" | The literal is already config. Name it now. |
| "Wrapping the SDK in its own package is the boundary" | The interface is the boundary. Packaging is not. |
| "It's obviously safe to retry" | Write down why. Most POSTs are not. |
| "Structured logging is a follow-up ticket" | The first incident is what makes it urgent, and too late. |
| "It works, it just leaks a storage concern into transport" | You have located the defect precisely. That is the expensive half. Fixing it is one line in the repository. |
| "I'll note the deviation in my summary" | A noted violation is still a violation, and the note is not in the code. Fix it or leave a `TODO` at the site. |
| "The interfaces are in place, so it's testable" | Testable is not tested. Write the one test that proves the boundary works. |
| "0 and 1 are enough exit codes" | Then a script cannot tell a bad flag from a failed upload from Ctrl-C. |

## When reviewing Go code

Line-level defects are the easy half and get found reliably. Ask the structural questions **first**, because they do not surface on their own:

1. What are the boundaries in this file, and does it hold more than one?
2. Which types cross a boundary that should not - SDK types, driver errors, persistence tags on a transport struct?
3. What varies by environment but is written as a literal?
4. For each outbound call: timeout, retry safety, backoff, idempotency?
5. For each goroutine: who owns it, who stops it, where do its errors go?
6. What is unobservable when this fails at 3am?

Then review the lines.

## Decision heuristics

When two designs are both defensible, prefer the one that keeps dependencies pointing inward, makes configuration explicit, makes failure behavior obvious, is deterministically testable, and introduces the fewest new concepts.

## References

The checks above are self-contained; reviewing code needs nothing further. Read the relevant reference before *designing* something new - a new service, a new adapter, a new integration, or a refactor that moves a boundary.

- `references/architecture.md` - layer rules, composition root, project shape, domain modeling
- `references/adapters.md` - HTTP, gRPC, and CLI boundary rules; serialization and validation
- `references/reliability.md` - concurrency, external integrations, persistence, lifecycle, shutdown
- `references/operations.md` - configuration, observability, security, dependency management
- `references/testing.md` - test strategy, doubles, compatibility, ADRs, refactoring
