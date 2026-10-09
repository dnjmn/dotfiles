# Architecture

## Dependency direction

```
adapters / infrastructure  ->  application  ->  domain
```

The domain and application layers must not import concrete infrastructure. Frameworks, SDKs, database models, transport request/response types, and command-parsing types do not appear inward of an adapter.

- **Domain** - business concepts, rules, invariants.
- **Application** - orchestrates workflows across domain objects and ports.
- **Ports** - interfaces describing what the application needs (outbound) and offers (inbound).
- **Adapters** - implement ports for transports, stores, queues, files, external APIs.
- **Composition root** - wires concrete implementations together.

## Composition root

Exactly one place assembles concrete dependencies, in this order:

1. load configuration
2. validate configuration
3. initialize logging and telemetry
4. create infrastructure clients
5. construct outbound adapters
6. construct use cases
7. construct inbound adapters
8. register lifecycle and shutdown hooks
9. start

```
Config -> Infrastructure -> Adapters -> Use Cases -> Entrypoints
                         ^
                    dependency injection
```

Business code never selects which concrete implementation to instantiate.

## Dependency injection

Constructor injection by default:

```go
func NewIssueCertificate(certs CertificateStore, ca CertificateAuthority, clock Clock) *IssueCertificate
```

Constructors reject invalid dependencies and configuration immediately. If a dependency has a lifecycle, make it explicit.

Avoid service locators, package-level dependency globals, hidden singletons, and constructors that quietly perform long-running work.

## Project shape

Keep the structure proportional to the project. A small tool does not need every directory.

```text
cmd/<binary>/            # entrypoint, command wiring
internal/
  domain/                # entities, value objects, domain services, domain errors
  application/
    ports/               # inbound and outbound interfaces
    usecase/
  adapters/
    inbound/             # http, grpc, cli
    outbound/            # stores, queues, external APIs, filesystem
  infrastructure/        # config, logging, telemetry, connection setup
  app/                   # bootstrap / composition root
pkg/                     # only for intentionally public, reusable packages
migrations/
configs/
docs/
```

## Domain layer

Framework-independent. Prefer typed IDs, value objects for meaningful concepts, explicit invariants, domain errors with stable semantics, and deterministic logic.

Keep out: ORM annotations, HTTP status codes, serialization tags as a domain concern, command parsing, cloud SDK types, and `context.Context` unless cancellation genuinely belongs to the domain contract.

Do not promote every struct to a domain entity. Use domain modeling where business rules justify it.

## Application layer

Use cases name business actions - `CreateUser`, `IssueCertificate`, `RotateSecret`, `SyncResources` - not transport mechanics.

They accept domain-oriented inputs and return domain-oriented results. Never pass a transport request object, a command object, a database row, a generated message type, or a vendor struct into a use case.

Ports stay minimal and consumer-driven:

```go
type UserReader interface {
    FindByID(ctx context.Context, id UserID) (User, error)
}
```

A port must not expose the storage mechanism's semantics.

## Interfaces

- Declare them where they are consumed, not next to the implementation.
- Keep them small; one method is often right.
- No interfaces for plain data containers.
- Avoid `any` where a useful static type exists.
- Do not create mock-only interfaces speculatively.

## Context

`context.Context` is the first parameter of I/O and cancellable operations.

- Never store it in a struct.
- Never use it as a bag of optional parameters.
- Propagate request-scoped deadlines and cancellation.
- Derive shorter deadlines for expensive downstream calls.
- Honor cancellation in loops and workers.
- Do not invent a context parameter for a pure calculation.

## SOLID, applied

- **Single responsibility** - one coherent reason to change.
- **Open/closed** - extend behind a stable interface rather than editing unrelated consumers.
- **Liskov** - implementations honor the semantic contract, not just the signature.
- **Interface segregation** - small consumer-owned interfaces over broad service interfaces.
- **Dependency inversion** - application and domain depend on abstractions; the composition root supplies implementations.

Do not add an interface because an interface feels architecturally correct. Add it where substitution, testing, or decoupling has real value.

## Patterns

Useful when they clarify a change point: dependency injection, factory, strategy, adapter, decorator, command, repository, unit of work (when transactional consistency demands it), specification (when business predicates become reusable), builder (when construction has substantial optional state), chain of responsibility (ordered pipelines), state (when behavior varies materially by lifecycle).

Avoid pattern stacking. A twenty-line switch often beats a miniature framework.
