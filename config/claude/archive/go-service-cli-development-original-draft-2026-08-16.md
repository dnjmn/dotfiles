---
name: go-service-cli-development
version: 1.0.0
description: Design, implement, review, refactor, and test production-grade Go services and CLI tools using hexagonal architecture, SOLID principles, explicit configuration, strong boundaries, and pragmatic design patterns.
---

# Go Service / CLI Development Skill

## Mission

Build Go services and CLI tools that are:

- easy to change without rippling changes across the codebase
- testable without real infrastructure
- explicit about dependencies, configuration, and failure modes
- operationally observable
- secure by default
- boring in the good places and sophisticated only where complexity earns its keep

Prefer simple Go over clever Go. Use abstractions to protect boundaries and change points, not to manufacture indirection.

## Non-Negotiable Principles

### 1. Hexagonal Architecture is the default

Use a ports-and-adapters architecture.

- **Domain** contains business concepts and rules.
- **Application/use-case layer** orchestrates business workflows.
- **Ports** define what the application needs and exposes.
- **Adapters** implement ports for HTTP, gRPC, CLI, databases, queues, files, cloud APIs, etc.
- **Infrastructure/bootstrap** wires concrete implementations together.

Dependency direction must point inward:

`adapters/infrastructure -> application -> domain`

The domain and application layers must not depend on concrete infrastructure packages.

Do not let frameworks, SDKs, database models, HTTP request/response types, or CLI libraries leak into domain logic.

### 2. Every implementation must be configurable

Anything likely to vary by environment, deployment, customer, test, or operational choice must be represented through configuration or dependency injection.

Examples:

- ports and listen addresses
- timeouts
- retry policies
- database connection settings
- external API endpoints
- credentials/secret references
- feature flags
- concurrency limits
- queue/topic names
- log level
- telemetry settings
- TLS settings
- file locations

Configuration must:

- be loaded in one predictable place
- be validated before application startup
- have safe defaults where defaults are genuinely safe
- fail fast for invalid required values
- avoid reading environment variables deep inside business logic
- avoid global mutable configuration

Prefer typed configuration structs over scattered strings.

### 3. Strict SOLID

Apply SOLID deliberately:

- **Single Responsibility:** a type should have one coherent reason to change.
- **Open/Closed:** add behavior behind stable interfaces rather than editing unrelated consumers.
- **Liskov Substitution:** implementations must honor the semantic contract of their interfaces.
- **Interface Segregation:** small consumer-owned interfaces beat giant service interfaces.
- **Dependency Inversion:** application/domain depend on abstractions; composition root supplies implementations.

Do not create interfaces merely because an interface feels architecturally correct. Introduce them at consumption boundaries, especially where substitution, testing, or decoupling has real value.

### 4. Prefer design patterns, but only where they clarify change

Patterns are tools, not decorations.

Commonly useful patterns:

- Dependency Injection
- Factory / Abstract Factory
- Strategy
- Adapter
- Decorator
- Command
- Repository
- Unit of Work, when transactional consistency requires it
- Specification, when business predicates become reusable/composable
- Builder, only when construction has substantial optional state
- Chain of Responsibility, for ordered processing pipelines
- State, when behavior changes materially by lifecycle state

Avoid pattern stacking. A 20-line switch can be better than a miniature framework.

## Default Project Shape

Use a structure similar to:

```text
cmd/
  myservice/
    main.go
    command/              # CLI command wiring, if applicable
internal/
  domain/
    entity/
    valueobject/
    service/
    errors.go
  application/
    ports/
      inbound/
      outbound/
    usecase/
  adapters/
    inbound/
      http/
      grpc/
      cli/
    outbound/
      postgres/
      redis/
      github/
      filesystem/
  infrastructure/
    config/
    logging/
    telemetry/
    database/
  app/
    bootstrap.go
pkg/                     # only for intentionally reusable public packages
migrations/
configs/
docs/
```

Do not cargo-cult every directory. Keep the shape proportional to the project.

## Composition Root

Create one explicit composition root where concrete dependencies are assembled.

Responsibilities:

1. load configuration
2. validate configuration
3. initialize logging and telemetry
4. create infrastructure clients
5. construct repositories/adapters
6. construct use cases
7. construct inbound adapters
8. register lifecycle/shutdown hooks
9. start the application

Business code must never decide which concrete implementation to instantiate.

A useful mental model:

```text
Config -> Infrastructure -> Adapters -> Use Cases -> Entrypoints
                         ^
                    dependency injection
```

## Domain Layer Rules

The domain should be framework-independent.

Prefer:

- typed IDs
- value objects for meaningful concepts
- explicit domain invariants
- domain errors with stable semantics
- deterministic business logic

Avoid:

- ORM annotations when they are not required by the domain
- HTTP status codes
- JSON tags as a domain concern
- CLI command parsing
- cloud SDK types
- `context.Context` unless cancellation is genuinely part of the domain contract

Do not turn every struct into a "domain entity." Use domain modeling where business rules justify it.

## Application Layer Rules

Use cases should describe business actions, not transport mechanics.

Examples:

- `CreateUser`
- `IssueCertificate`
- `RotateSecret`
- `SyncResources`
- `DeleteObject`

Use-case methods should accept domain-oriented inputs and return domain/application-oriented results.

Never pass HTTP request objects, Cobra command objects, SQL rows, protobuf messages, or vendor SDK structs into use cases.

Application ports should be minimal and consumer-driven.

Example:

```go
type UserReader interface {
    FindByID(ctx context.Context, id UserID) (User, error)
}
```

Do not expose repository internals such as SQL semantics through the port.

## Go Interfaces

Rules:

- Define interfaces where they are consumed.
- Keep interfaces small.
- Prefer one-method interfaces when that naturally expresses the dependency.
- Avoid interfaces for plain data containers.
- Avoid `interface{}` / `any` when a useful static type exists.
- Do not create mock-only interfaces prematurely.

Example:

```go
type TokenIssuer interface {
    Issue(ctx context.Context, subject string) (Token, error)
}
```

## Context

`context.Context` belongs as the first parameter of I/O and cancellable operations.

Rules:

- never store context in structs
- never use context as a bag of optional parameters
- propagate request-scoped deadlines and cancellation
- derive shorter deadlines for expensive downstream operations when appropriate
- honor cancellation in loops and workers

Do not invent a fake context requirement for pure domain calculations.

## Error Handling

Errors are part of the architecture.

Use:

- sentinel errors for stable categories where appropriate
- typed errors when callers need structured behavior
- `%w` wrapping to preserve causes
- `errors.Is` / `errors.As` for classification
- domain errors at domain boundaries
- translation of errors at adapter boundaries

Do not:

- compare error strings for control flow
- log the same error repeatedly at every layer
- discard the underlying cause
- expose internal infrastructure details to API clients

Map errors at the boundary:

```text
repository error -> application/domain error -> HTTP/CLI representation
```

Keep user-facing error messages actionable and safe.

## Configuration

Create a typed configuration model, for example:

```go
type Config struct {
    Server ServerConfig
    DB     DBConfig
    Auth   AuthConfig
    Telemetry TelemetryConfig
}
```

Prefer explicit loading functions:

```go
func Load() (Config, error)
func (c Config) Validate() error
```

Configuration precedence should be deterministic. Document it when multiple sources exist, such as:

`defaults < config file < environment < CLI flags`

Secrets must not be committed, logged, printed in error messages, or serialized accidentally.

## HTTP Services

Keep the HTTP adapter thin.

Responsibilities:

- decode and validate transport input
- authenticate/authorize
- map transport types to application inputs
- call the use case
- map application results/errors to HTTP responses
- add request metadata to logs/traces

The handler should not contain business rules, SQL, retry loops, or cloud SDK calls.

Use explicit timeouts and graceful shutdown.

Treat request body size, headers, status codes, and serialization behavior as deliberate design decisions.

## gRPC Services

Keep protobuf-generated types at the adapter boundary.

- convert protobuf requests into application inputs
- convert application results into protobuf responses
- translate domain/application errors into appropriate gRPC status codes
- preserve structured error details where useful

Do not make generated protobuf types your domain model.

## CLI Tools

A CLI is an inbound adapter.

Recommended flow:

```text
command parsing -> validation -> application use case -> output formatting
```

Rules:

- command definitions should be thin
- business logic must live outside Cobra/urfave/flag handlers
- separate machine-readable output from human-readable output
- support `--output` / structured output when useful
- send diagnostic/error output to stderr
- return meaningful exit codes
- honor cancellation and timeouts
- avoid hidden network calls during argument parsing
- make destructive commands explicit
- provide dry-run support for risky bulk operations when practical

Keep output formatting separate from use-case execution so the same operation can be reused by another interface.

## Dependency Injection

Use constructor injection by default.

```go
func NewUserService(repo UserRepository, clock Clock, logger Logger) *UserService
```

Constructors should reject invalid dependencies/configuration early.

Avoid:

- service locators
- package-level dependency globals
- hidden singleton state
- constructors that perform long-running work unexpectedly

If a dependency has a lifecycle, make that lifecycle explicit.

## Time, Randomness, and UUIDs

Do not scatter direct calls to wall-clock time or randomness through business logic when deterministic testing matters.

Create small abstractions such as:

```go
type Clock interface {
    Now() time.Time
}
```

Similarly consider interfaces for UUID generation or randomness at meaningful boundaries.

Avoid abstracting everything. Abstract non-determinism when it affects correctness or testing.

## Concurrency

Prefer structured concurrency and bounded parallelism.

Rules:

- every goroutine needs a clear owner and shutdown path
- avoid fire-and-forget goroutines
- use `errgroup` where appropriate
- bound worker pools
- avoid unbounded channels/queues
- protect shared mutable state deliberately
- document ownership of mutable data
- prefer immutable values and message passing where practical

Every goroutine should have an answer to: "Who stops me?"

## External Integrations

Wrap third-party SDKs behind adapters.

Never let the rest of the application depend directly on vendor types when a stable internal contract is more appropriate.

For each integration define:

- timeout
- retry policy
- idempotency behavior
- rate-limit handling
- error mapping
- metrics
- logging/tracing
- authentication
- circuit-breaking or bulkheading when justified

Retries must be selective. Do not blindly retry non-idempotent operations.

## Database / Persistence

Repositories should express application needs, not duplicate tables as an API.

Keep persistence models separate when the database schema and domain model have different responsibilities.

Rules:

- explicit transactions
- bounded query timeouts
- pagination for unbounded datasets
- deterministic ordering when pagination matters
- no N+1 queries
- migrations are versioned and reviewable
- indexes are justified by access patterns
- handle uniqueness/conflict errors explicitly

Never pass a database transaction object deep into arbitrary domain code.

## Serialization Boundaries

Define explicit mapping between:

- transport DTOs
- application inputs/outputs
- domain models
- persistence models

Do not rely on accidental structural compatibility between unrelated representations.

Explicit mapping is preferred when boundaries encode meaning.

## Validation

Use layered validation.

- transport validation: shape, required fields, syntax
- application validation: use-case preconditions
- domain validation: business invariants
- infrastructure validation: connectivity/configuration constraints

Never rely on only one layer.

## Logging and Observability

Observability is part of the architecture, not decoration.

Use structured logs.

Include useful correlation fields such as:

- request ID
- trace ID
- operation/use-case name
- resource identifiers that are safe to log
- duration
- outcome

Never log secrets, credentials, tokens, private keys, or sensitive payloads.

Metrics should answer:

- how often
- how long
- how many failures
- how saturated

Tracing should follow meaningful cross-service boundaries rather than wrapping every line of code.

## Security

Secure defaults are mandatory.

Consider:

- authentication
- authorization
- least privilege
- input limits
- secret handling
- TLS validation
- SSRF risks for user-controlled URLs
- command/file path traversal
- unsafe deserialization
- injection risks
- dependency vulnerabilities
- sensitive logging

Never disable TLS verification merely to make development "work" without an explicit, isolated development configuration.

## Testing Strategy

Tests should mirror architectural boundaries.

### Unit tests

Use for:

- domain rules
- application/use-case behavior
- deterministic transformations
- error mapping

Mock/fake only the boundaries that matter.

### Integration tests

Use real or realistic infrastructure for:

- database behavior
- queues
- external adapter semantics
- migrations
- serialization compatibility

### End-to-end tests

Use selectively for high-value workflows.

Avoid using end-to-end tests as a substitute for a strong unit/integration test suite.

### Test quality rules

- table-driven tests where they improve readability
- test behavior, not private implementation details
- cover error paths and cancellation
- test configuration validation
- test concurrency-sensitive behavior deliberately
- use deterministic clocks/randomness where needed
- avoid sleeping in tests when synchronization is possible

## Test Doubles

Prefer the lightest useful double:

1. real implementation
2. in-memory fake
3. stub
4. mock

Use mocks mainly to verify a meaningful interaction contract. Do not generate a forest of mocks for every interface.

## API and CLI Backward Compatibility

Treat public contracts as expensive to change.

Before changing a public API or CLI command:

- identify consumers
- preserve compatibility when practical
- add new fields/commands before removing old ones
- document breaking changes
- update examples and tests

For CLI tools, changing stdout/stderr or exit codes can be a breaking change for scripts.

## Dependency Management

Prefer the standard library.

Add third-party dependencies only when they provide clear value.

For every dependency, consider:

- maintenance health
- security history
- license compatibility
- transitive dependency cost
- API stability
- whether the standard library is sufficient

Pin dependencies through normal Go module tooling and keep dependency upgrades deliberate.

## Code Quality

Write idiomatic Go.

Prefer:

- small cohesive functions
- early returns
- explicit control flow
- meaningful names
- narrow types
- package-level documentation for non-obvious packages
- comments that explain decisions, not syntax

Avoid:

- needless abstractions
- giant manager/service types
- boolean parameter soup
- deeply nested control flow
- reflection unless justified
- premature generics
- global mutable state
- init-time magic

Use generics when they make a reusable abstraction clearer, not merely because they are available.

## Naming

Names should communicate intent and layer responsibility.

Prefer:

- `UserRepository`
- `IssueCertificate`
- `CloudflareCertificateClient`
- `ConfigLoader`

Avoid vague names:

- `Manager`
- `Helper`
- `Util`
- `Processor`
- `Common`

unless the name genuinely describes a coherent responsibility.

## Lifecycle and Shutdown

Every long-running process must have an explicit lifecycle.

Startup:

1. load and validate config
2. initialize dependencies
3. establish required connectivity
4. register handlers
5. start serving

Shutdown:

1. stop accepting new work
2. cancel in-flight work where appropriate
3. drain workers/connections
4. flush telemetry/logging
5. close resources
6. exit with the correct status

Use context cancellation and bounded shutdown deadlines.

## Operational Resilience

For networked services, explicitly reason about:

- timeout budgets
- retries with backoff
- idempotency
- rate limits
- partial failure
- dependency unavailability
- startup failure
- graceful degradation
- overload behavior

Do not hide resilience policies inside generic helpers where their operational behavior becomes hard to see.

## CLI UX Rules

Commands should be discoverable and predictable.

Use:

- clear command names
- explicit destructive-action confirmation where appropriate
- `--help` that explains examples
- stable exit codes
- machine-readable output for automation
- human-readable output by default

For long-running commands, show progress without corrupting machine-readable stdout.

## Documentation Expectations

For non-trivial projects, keep these current:

- README
- architecture overview
- local development instructions
- configuration reference
- API/CLI examples
- operational runbook when production deployment is involved
- ADRs for important architectural decisions

Documentation should explain decisions and constraints, not restate obvious code.

## ADR / Design Decision Rule

Create an ADR for decisions involving meaningful trade-offs, such as:

- switching storage technology
- introducing queues/event-driven workflows
- selecting an authentication model
- choosing a major framework/library
- changing service boundaries
- introducing a complex concurrency model

Record:

- context
- decision
- alternatives considered
- consequences

## Refactoring Rule

When modifying existing code:

1. understand the current behavior
2. identify the architectural boundary being changed
3. preserve behavior unless change is intentional
4. improve the boundary instead of layering another workaround
5. keep commits/changes cohesive
6. add regression tests before risky refactors when feasible

Never silently delete data, configuration, migrations, or operational knowledge. Preserve important information in code, documentation, migration files, or another durable artifact.

## Review Checklist

Before considering an implementation complete, verify:

- [ ] Architecture follows hexagonal boundaries.
- [ ] Concrete infrastructure is injected from the composition root.
- [ ] Domain/application layers are independent of transport/framework details.
- [ ] Configuration is typed, validated, and centrally loaded.
- [ ] SOLID violations are addressed where they create real coupling.
- [ ] Interfaces are consumer-owned and minimal.
- [ ] Errors preserve causes and are mapped at boundaries.
- [ ] Context cancellation and timeouts are handled correctly.
- [ ] Goroutines have explicit lifecycle ownership.
- [ ] External calls have deliberate timeout/retry behavior.
- [ ] Logs and metrics are useful without leaking secrets.
- [ ] Security boundaries are explicit.
- [ ] Unit and integration tests cover important behavior and failure paths.
- [ ] CLI output and exit codes are intentional for automation.
- [ ] Graceful shutdown is implemented for long-running processes.
- [ ] Public contract changes are backward-compatible or explicitly documented.
- [ ] Documentation reflects meaningful operational/architectural decisions.

## Claude Code Operating Procedure

When asked to implement or modify a Go service/CLI:

### Step 1: Inspect before changing

Read the relevant repository structure, module files, existing configuration, entrypoints, tests, and architecture documentation.

Identify:

- current dependency direction
- composition root
- inbound/outbound adapters
- configuration sources
- existing conventions
- test strategy

Do not introduce a new architecture pattern blindly if the repository already has a coherent one. Improve incrementally.

### Step 2: State the boundary

Before coding, identify which layer and boundary the change belongs to.

Examples:

- new business rule -> domain
- new workflow -> application/use case
- new database integration -> outbound adapter
- new HTTP endpoint -> inbound adapter
- new CLI command -> CLI adapter
- new environment setting -> configuration

### Step 3: Design the contract first

Define or adjust:

- input/output types
- interfaces/ports
- error semantics
- configuration
- lifecycle expectations

Only then implement concrete adapters.

### Step 4: Wire through dependency injection

Update the composition root rather than allowing feature code to instantiate its own infrastructure dependencies.

### Step 5: Test behavior

Add or update tests at the narrowest meaningful layer, then integration tests where infrastructure semantics matter.

### Step 6: Run quality gates

At minimum, where applicable:

```text
go test ./...
go vet ./...
gofmt -w .
go test -race ./...       # for concurrency-sensitive projects
```

Also run project-specific linters/static analysis when configured.

### Step 7: Review for architecture drift

Ask:

- Did infrastructure leak inward?
- Did a handler/command gain business logic?
- Did an interface become too broad?
- Did configuration become hidden/global?
- Did a dependency become difficult to substitute?
- Did concurrency gain an unmanaged goroutine?
- Did error semantics become transport-specific?

Fix drift before finalizing.

## Decision Heuristics

When two solutions are both valid, prefer the one that:

1. keeps dependencies pointing inward
2. makes configuration explicit
3. reduces hidden coupling
4. makes failure behavior obvious
5. is easy to test deterministically
6. preserves backward compatibility
7. minimizes third-party dependencies
8. keeps operational behavior visible
9. uses a proven design pattern when it materially improves changeability
10. introduces the fewest concepts necessary to solve the actual problem

## Golden Rule

The architecture should make the right thing easy:

```text
Domain rules stay in the domain.
Workflows stay in use cases.
Infrastructure stays behind ports.
Configuration stays explicit.
Dependencies are injected.
Adapters stay thin.
Failures stay visible.
Tests stay fast and meaningful.
```
