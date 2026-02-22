# Test-Driven Development (TDD)

## What It Is

TDD is a development practice where you write a failing test before writing the code that makes it pass. The cycle is: Red (write failing test), Green (make it pass), Refactor (improve code). Tests drive the design.

## Core Principles (Non-Negotiables)

- **Test first** — Write the test before the implementation
- **Red-Green-Refactor** — Failing test -> passing test -> clean code
- **Small steps** — One test at a time, minimal code to pass
- **Tests as documentation** — Tests describe expected behavior
- **Continuous refactoring** — Improve design after each green

## How It Applies to Cambium

### Where We Align

- **Tests exist**: `tests/Cambium.Tests.Unit/` with folders for Controllers, EventHandlers, Events, Managers, Services, UseCases
- **Refactoring active**: Module migration improves structure continuously

**Evidence**:

```
tests/Cambium.Tests.Unit/
+-- Controllers/
+-- EventHandlers/
+-- Events/
+-- Managers/
+-- Services/
+-- UseCases/
```

### Where We Dont (NOT PRACTICED)

- **Tests written after**: Code first, tests follow (when written)
- **No coverage metrics**: No coverage gates in CI
- **No TDD discipline**: Red-green-refactor cycle not followed

### Compliance Desirable?

**Yes for new development.** Benefits:

- Catches regressions immediately
- Forces testable design (dependency injection, interfaces)
- Tests serve as documentation

**Recommendation**: Adopt TDD for new module development. Retrofitting existing code is lower priority.

## Key Terms

| Term               | Definition                                                 |
| ------------------ | ---------------------------------------------------------- |
| Red                | Write a failing test                                       |
| Green              | Write minimal code to pass the test                        |
| Refactor           | Improve code structure without changing behavior           |
| Unit Test          | Test of a single unit in isolation                         |
| Test Double        | Fake, mock, or stub replacing a dependency                 |
| Arrange-Act-Assert | Test structure pattern                                     |
| Code Coverage      | Percentage of code exercised by tests                      |
| Test Pyramid       | More unit tests, fewer integration tests, fewest E2E tests |
