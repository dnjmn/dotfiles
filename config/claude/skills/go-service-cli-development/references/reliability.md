# Reliability

## Concurrency

Every goroutine answers: **who stops me, and where do my errors go?**

- Bounded parallelism. A worker pool or bounded group, never one goroutine per item of an unbounded set.
- No fire-and-forget. A function that spawns work and returns before it finishes has discarded its errors.
- No unbounded channels or queues.
- Protect shared mutable state deliberately; document who owns it.
- Prefer immutable values and message passing.
- Honor cancellation inside loops and workers.

A function that starts background work either waits for it or returns a handle the caller can wait on.

## External integrations

Wrap third-party SDKs behind an interface the consumer declares. The rest of the application never depends on vendor types.

Define all of these per integration, explicitly:

- timeout
- retry policy, and whether the operation is safe to retry
- idempotency behavior, including idempotency keys where the API supports them
- backoff with jitter
- rate-limit handling
- error mapping into application errors
- metrics and tracing
- authentication and credential rotation
- circuit breaking or bulkheading, when justified

Retries are selective. Blind retry of a non-idempotent operation duplicates work - charges, emails, records.

Drain and close response bodies so connections can be reused.

## Persistence

Repositories express application needs. They are not a mirror of the table layout.

Keep persistence models separate from domain models when the schema and the domain change for different reasons.

- explicit transactions with clear scope
- bounded query timeouts
- pagination for unbounded result sets, with deterministic ordering
- no N+1 queries
- versioned, reviewable migrations
- indexes justified by an actual access pattern
- uniqueness and conflict errors handled explicitly, mapped to domain errors

Never pass a transaction handle deep into arbitrary domain code.

## Lifecycle

**Startup**

1. load and validate configuration
2. initialize dependencies
3. verify required connectivity
4. register handlers
5. start serving

**Shutdown**

1. stop accepting new work
2. cancel in-flight work where appropriate
3. drain workers and connections
4. flush telemetry and logs
5. close resources
6. exit with the correct status

Use context cancellation and a bounded shutdown deadline.

## Operational resilience

For anything networked, reason explicitly about: timeout budgets, retries with backoff, idempotency, rate limits, partial failure, dependency unavailability, startup failure, graceful degradation, and overload behavior.

Do not bury resilience policy inside a generic helper where its operational behavior stops being visible.

## Time and randomness

Inject non-determinism that affects correctness or testing:

```go
type Clock interface {
    Now() time.Time
}
```

The same applies to ID generation and randomness at meaningful boundaries. Do not abstract everything - abstract what makes behavior untestable.
