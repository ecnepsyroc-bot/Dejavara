# Extreme Programming (XP)

## What It Is

XP is an agile methodology that emphasizes technical excellence and tight feedback loops. It prescribes specific engineering practices (pair programming, TDD, continuous integration) designed to produce high-quality software while remaining responsive to changing requirements.

## Core Principles (Non-Negotiables)

- **Test-Driven Development (TDD)** — Write tests before code
- **Pair Programming** — Two developers, one keyboard
- **Continuous Integration** — Integrate and test multiple times per day
- **Refactoring** — Continuously improve code structure
- **Simple Design** — Do the simplest thing that works
- **Collective Code Ownership** — Anyone can change any code
- **Coding Standards** — Consistent style across codebase
- **Sustainable Pace** — No death marches

## How It Applies to Cambium

### Where We Align

- **Continuous Integration**: Railway auto-deploys on every push to main
- **Refactoring**: Active module migration (Core managers to hexagonal modules)
- **Simple Design**: KISS principle evident — direct EF Core, no over-abstraction
- **Coding Standards**: Prettier, lint-staged enforce consistency
- **Collective Ownership**: Single codebase, no code silos

### Where We Dont

- **TDD not practiced**: Tests exist (`tests/Cambium.Tests.Unit/`) but written after code
- **No pair programming**: Solo development context
- **Test coverage unknown**: No coverage metrics or gates

### Compliance Desirable?

Selective adoption recommended:

- **TDD for new modules**: Yes — catches regressions early
- **Pair programming**: Not applicable (solo context)
- **Refactoring**: Already doing this well

## Key Terms

| Term               | Definition                                        |
| ------------------ | ------------------------------------------------- |
| Red-Green-Refactor | TDD cycle: failing test, make it pass, clean up   |
| Spike              | Time-boxed exploration to reduce uncertainty      |
| Planning Game      | Collaborative estimation and planning session     |
| User Story         | Small unit of functionality from user perspective |
| Iteration          | Short development cycle (1-2 weeks in XP)         |
| On-Site Customer   | Stakeholder available for immediate feedback      |
| Metaphor           | Shared vocabulary/mental model for the system     |
