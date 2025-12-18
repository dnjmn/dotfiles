---
name: ddd-architecture
description: This skill should be used when the user asks about "DDD", "domain driven design", "bounded contexts", "aggregates", "repository pattern", "code architecture", "testing strategy", "system design", mentions domain modeling, discusses complex refactoring, or needs guidance on structuring code with DDD principles.
version: 1.0.0
---

# Domain Driven Design Architecture

## Directory Structure
```
domain/       → Core business logic (entities, value objects, domain services)
application/  → Use cases, orchestration, DTOs
infrastructure/ → External integrations (DB, APIs, messaging, caches)
interfaces/   → API controllers, UI components, CLI handlers
```

## Key Principles

| Principle | Rule |
|-----------|------|
| Ubiquitous Language | Code MUST reflect domain terminology |
| Bounded Contexts | Clear boundaries, each context owns its models |
| Aggregates | Consistency boundaries, one root per transaction |
| Repository Pattern | Abstract data access, domain NEVER knows storage |

## Testing Strategy

| Layer | Type | Dependencies |
|-------|------|--------------|
| domain/ | Unit | Pure functions, NO external deps |
| application/ | Integration | Mock infrastructure |
| interfaces/ | E2E | Playwright for UI flows |

## Extended Thinking (AUTO-ACTIVATE)

AUTOMATICALLY use extended thinking for:
- System architecture decisions
- Complex refactoring strategies
- Security vulnerability analysis
- Cross-domain integration design
- Performance optimization planning
- Multi-step debugging (unclear root cause)
- Trade-off analysis between approaches
