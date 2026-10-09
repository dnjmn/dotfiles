# Operations

## Configuration

A typed model, loaded and validated in one place:

```go
type Config struct {
    Server    ServerConfig
    DB        DBConfig
    Auth      AuthConfig
    Telemetry TelemetryConfig
}

func Load() (Config, error)
func (c Config) Validate() error
```

Everything that varies by environment, deployment, customer, test, or operational choice is a field: listen addresses, timeouts, retry budgets, connection settings, external endpoints, secret references, feature flags, concurrency limits, queue and topic names, log level, telemetry settings, TLS settings, file locations.

Rules:

- loaded in one predictable place, validated before startup
- required values fail fast; defaults exist only where a default is genuinely safe
- no environment reads inside business logic
- no global mutable configuration
- deterministic, documented precedence when multiple sources exist, for example `defaults < file < environment < flags`

Secrets are never committed, logged, printed in errors, or serialized by accident. Give secret types a `String()`/`MarshalJSON` that redacts, so accidental logging cannot leak them.

## Observability

Part of the change, not a follow-up ticket.

Structured logs carrying correlation fields: request ID, trace ID, operation or use-case name, safe resource identifiers, duration, outcome.

Log an error once, where it is handled - not at every layer on the way up.

Metrics answer: how often, how long, how many failures, how saturated.

Tracing follows meaningful cross-service boundaries, not every function.

Never log secrets, credentials, tokens, private keys, or sensitive payloads.

## Security

Secure defaults are mandatory. Work through: authentication, authorization, least privilege, input limits, secret handling, TLS validation, SSRF risk on user-controlled URLs, path traversal, command injection, unsafe deserialization, query injection, dependency vulnerabilities, and sensitive data in logs.

Never disable TLS verification to make development work. If a local environment genuinely needs different trust, it goes in an explicit, isolated development configuration that cannot be selected in production.

## Dependencies

Prefer the standard library. Add a third-party dependency when it provides clear value.

Evaluate: maintenance health, security history, license, transitive cost, API stability, and whether the standard library already suffices.

Keep upgrades deliberate.

## Documentation

For non-trivial projects keep current: README, architecture overview, local development instructions, configuration reference, API and CLI examples, an operational runbook where production deployment is involved, and ADRs for significant decisions.

Documentation explains decisions and constraints. It does not restate the code.
