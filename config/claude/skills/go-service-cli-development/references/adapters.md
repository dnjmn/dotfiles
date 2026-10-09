# Adapters

An adapter translates between the outside world and the application. It holds no business rules.

## HTTP

Responsibilities, and nothing beyond them:

- decode and validate transport input
- authenticate and authorize
- map transport types to application inputs
- call one use case
- map results and errors to responses
- attach request metadata to logs and traces

A handler contains no business rules, no queries, no retry loops, no external API calls.

Deliberate decisions, not defaults: request body size limits, read/write/idle timeouts, header handling, status code mapping, serialization behavior, and graceful shutdown.

## gRPC

Generated types stay at the adapter boundary.

- convert requests into application inputs
- convert results into responses
- translate domain and application errors into appropriate status codes
- preserve structured error details where they help the caller

Generated message types are not your domain model.

## CLI

A CLI is an inbound adapter:

```text
parse -> validate -> use case -> format output
```

- Command definitions stay thin; business logic lives outside the command handler.
- Keep output formatting separate from execution, so another interface can reuse the operation.
- Machine-readable output and human-readable output are different code paths, chosen explicitly.
- Diagnostics, progress, and errors go to stderr; results go to stdout.
- Exit codes are stable and meaningful.
- Honor cancellation and timeouts; handle interrupt signals.
- No hidden network calls during argument parsing.
- Destructive commands are explicit; risky bulk operations support dry-run.

## Serialization boundaries

Map explicitly between transport DTOs, application inputs and outputs, domain models, and persistence models.

Do not rely on accidental structural compatibility between representations that mean different things. One struct carrying both transport tags and persistence tags fuses two boundaries that change for different reasons.

## Validation

Layer it, and do not rely on any single layer:

- **transport** - shape, required fields, syntax, size limits
- **application** - use-case preconditions
- **domain** - business invariants
- **infrastructure** - connectivity and configuration constraints

## Error translation

Each boundary translates rather than forwards:

```text
store error -> domain/application error -> transport representation
```

User-facing messages are actionable and safe. Internal detail - driver errors, query text, host names, stack traces - never reaches the caller. The cause is always preserved internally with `%w`.
