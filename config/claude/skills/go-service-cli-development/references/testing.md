# Testing and change management

## Strategy

Tests mirror architectural boundaries.

**Unit** - domain rules, use-case behavior, deterministic transformations, error mapping. Fake only the boundaries that matter.

**Integration** - real or realistic infrastructure for store behavior, queues, external adapter semantics, migrations, serialization compatibility.

**End-to-end** - selectively, for high-value workflows. Not a substitute for a strong unit and integration suite.

## Quality rules

- table-driven where it improves readability
- test behavior, not private implementation details
- cover error paths and cancellation, not just the happy path
- test configuration validation - a missing required secret should fail a test, not production
- test concurrency-sensitive behavior deliberately, with the race detector
- inject deterministic clocks and randomness
- synchronize rather than sleep

## Test doubles

Prefer the lightest useful double:

1. the real implementation
2. an in-memory fake
3. a stub
4. a mock

Mocks verify a meaningful interaction contract. Do not generate one per interface by reflex.

Consumer-owned interfaces exist so the caller can be tested without real infrastructure. If testing a use case requires credentials or a network, the boundary is in the wrong place.

## Quality gates

Where applicable:

```text
gofmt -l .
go vet ./...
go test ./...
go test -race ./...     # anything concurrent
```

Plus whatever linters and static analysis the project configures.

## Backward compatibility

Public contracts are expensive to change. Before changing a public API or a CLI command:

- identify consumers
- preserve compatibility when practical
- add new fields and commands before removing old ones
- document breaking changes
- update examples and tests

For CLI tools, stdout format, stderr format, and exit codes are part of the contract. Changing them breaks scripts.

## Refactoring

1. understand current behavior
2. identify the architectural boundary being changed
3. preserve behavior unless the change is intentional
4. improve the boundary rather than layering another workaround
5. keep changes cohesive
6. add regression tests before risky refactors

Never silently delete data, configuration, migrations, or operational knowledge. Preserve it in code, documentation, a migration, or another durable artifact.

## ADRs

Record a decision when it carries a meaningful trade-off: changing storage technology, introducing queues or event-driven workflows, selecting an authentication model, adopting a major framework, moving a service boundary, or introducing a complex concurrency model.

Capture context, decision, alternatives considered, and consequences.

## Architecture drift check

After a change, ask:

- Did infrastructure leak inward?
- Did a handler or command gain business logic?
- Did an interface grow beyond its consumer's needs?
- Did configuration become hidden or global?
- Did a dependency become hard to substitute?
- Did concurrency gain an unmanaged goroutine?
- Did error semantics become transport-specific?

Fix drift before finishing.
