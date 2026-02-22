# Software Development Philosophies Index

This directory contains detailed documentation for each software development philosophy, grounded in how it applies to the Cambium codebase.

## Quick Reference

| Status      | Meaning                                 |
| ----------- | --------------------------------------- |
| COMMITTED   | Explicitly adopted, continue practicing |
| STRONG      | Naturally aligned, good compliance      |
| PARTIAL     | Some alignment, selective adoption      |
| MINIMAL     | Little alignment, low priority          |
| NOT ADOPTED | Explicitly not using, by design         |

---

## Process Philosophies

| Philosophy                        | Summary                                                  | Status      |
| --------------------------------- | -------------------------------------------------------- | ----------- |
| [Agile](agile.md)                 | Iterative development with flexibility and collaboration | PARTIAL     |
| [Lean](lean.md)                   | Eliminate waste, optimize flow, deliver fast             | PARTIAL     |
| [XP (Extreme Programming)](xp.md) | Engineering practices: TDD, pair programming, CI         | PARTIAL     |
| [Shape Up](shape-up.md)           | 6-week cycles with shaped pitches and appetites          | MINIMAL     |
| [Waterfall](waterfall.md)         | Sequential phases with formal sign-offs                  | NOT ADOPTED |

---

## Architecture Philosophies

| Philosophy                                                | Summary                                                 | Status      |
| --------------------------------------------------------- | ------------------------------------------------------- | ----------- |
| [Hexagonal Architecture](hexagonal-architecture.md)       | Ports and adapters isolating domain from infrastructure | COMMITTED   |
| [Clean Architecture](clean-architecture.md)               | Dependencies pointing inward, domain at center          | STRONG      |
| [Modular Monolith](modular-monolith.md)                   | Single deployment with well-defined module boundaries   | COMMITTED   |
| [Event-Driven Architecture](event-driven-architecture.md) | Components communicate through events                   | PARTIAL     |
| [CQRS](cqrs.md)                                           | Separate read and write models                          | PARTIAL     |
| [Event Sourcing](event-sourcing.md)                       | State as sequence of immutable events                   | NOT ADOPTED |
| [Microservices](microservices.md)                         | Independent services with own databases                 | NOT ADOPTED |
| [Serverless](serverless.md)                               | Functions as a service, no server management            | NOT ADOPTED |

---

## Design Philosophies

| Philosophy                                  | Summary                                                    | Status      |
| ------------------------------------------- | ---------------------------------------------------------- | ----------- |
| [DDD (Domain-Driven Design)](ddd.md)        | Design centered on business domain and ubiquitous language | PARTIAL     |
| [TDD (Test-Driven Development)](tdd.md)     | Write tests before code, red-green-refactor                | MINIMAL     |
| [BDD (Behavior-Driven Development)](bdd.md) | Tests in business language, Given-When-Then                | NOT ADOPTED |
| [API-First](api-first.md)                   | Design API contract before implementation                  | PARTIAL     |

---

## Coding Principles

| Philosophy                                                      | Summary                                           | Status  |
| --------------------------------------------------------------- | ------------------------------------------------- | ------- |
| [SOLID](solid.md)                                               | Five OO principles for maintainable code          | STRONG  |
| [DRY](dry.md)                                                   | Dont Repeat Yourself - single source of truth     | STRONG  |
| [YAGNI](yagni.md)                                               | You Arent Gonna Need It - no speculative features | STRONG  |
| [KISS](kiss.md)                                                 | Keep It Simple - avoid unnecessary complexity     | STRONG  |
| [Separation of Concerns](separation-of-concerns.md)             | Divide code by distinct responsibilities          | STRONG  |
| [Law of Demeter](law-of-demeter.md)                             | Only talk to immediate friends, avoid chains      | PARTIAL |
| [Composition over Inheritance](composition-over-inheritance.md) | Assemble from parts vs inheritance hierarchies    | STRONG  |
| [Functional Programming](functional-programming.md)             | Pure functions, immutability, declarative style   | PARTIAL |
| [Reactive Programming](reactive-programming.md)                 | Data streams and propagation of change            | PARTIAL |

---

## Delivery Philosophies

| Philosophy                                          | Summary                                               | Status      |
| --------------------------------------------------- | ----------------------------------------------------- | ----------- |
| [DevOps](devops.md)                                 | Unify development and operations, automate everything | STRONG      |
| [GitOps](gitops.md)                                 | Git as source of truth for infrastructure             | PARTIAL     |
| [CI/CD](ci-cd.md)                                   | Continuous Integration and Deployment                 | STRONG      |
| [Infrastructure as Code](infrastructure-as-code.md) | Version-controlled, reproducible infrastructure       | MINIMAL     |
| [SRE (Site Reliability Engineering)](sre.md)        | Software engineering approach to operations           | MINIMAL     |
| [Shift Left](shift-left.md)                         | Move testing and security earlier in lifecycle        | PARTIAL     |
| [Chaos Engineering](chaos-engineering.md)           | Test resilience by introducing controlled failures    | NOT ADOPTED |

---

## Emerging Philosophies

| Philosophy                                            | Summary                                        | Status    |
| ----------------------------------------------------- | ---------------------------------------------- | --------- |
| [AI-Assisted Development](ai-assisted-development.md) | Use AI tools to augment human developers       | COMMITTED |
| [Trunk-Based Development](trunk-based-development.md) | All developers commit to single branch         | STRONG    |
| [Strangler Fig Pattern](strangler-fig-pattern.md)     | Gradually replace legacy system piece by piece | COMMITTED |

---

## Committed Philosophies (Must Follow)

These philosophies are explicitly adopted and should be enforced:

1. **Hexagonal Architecture** - See `docs/ARCHITECTURE.md`
2. **Modular Monolith** - Modules in `modules/`
3. **AI-Assisted Development** - Claude Code + OpenClaw
4. **Strangler Fig Pattern** - Per `docs/MODULE-MIGRATION-PATTERN.md`

## Strong Alignment (Continue Practicing)

These naturally align and are well-practiced:

- SOLID, DRY, YAGNI, KISS
- Separation of Concerns, Composition over Inheritance
- CI/CD, DevOps, Trunk-Based Development
- Clean Architecture (via hexagonal)

## Not Adopted (By Design)

These are inappropriate for Cambium:

- **Microservices** - Modular monolith is sufficient
- **Serverless** - WebSocket/SignalR requires persistent connections
- **Event Sourcing** - CRUD with audit logs is sufficient
- **Waterfall** - Iterative development preferred
- **BDD** - Unit tests sufficient for current scale
- **Chaos Engineering** - Low priority for single deployment

---

_Generated 2026-02-22 by OpenClaw AI_
