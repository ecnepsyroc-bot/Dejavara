# Behavior-Driven Development (BDD)

## What It Is

BDD extends TDD by writing tests in natural language that describe behavior from the users perspective. Specifications are written in Given-When-Then format (Gherkin) and serve as living documentation that non-technical stakeholders can read.

## Core Principles (Non-Negotiables)

- **Ubiquitous language** — Specifications use business terminology
- **Given-When-Then** — Scenario format: precondition, action, outcome
- **Living documentation** — Specs are executable and always current
- **Collaboration** — Three Amigos: dev, QA, product define scenarios together
- **Outside-in development** — Start with user-facing behavior

## How It Applies to Cambium

### Where We Align

Minimal — BDD not practiced.

### Where We Dont (NOT ADOPTED)

- **No Gherkin specs**: No `.feature` files in codebase
- **No BDD framework**: No SpecFlow, Cucumber, or similar
- **Unit tests are technical**: Tests describe implementation, not behavior

### Compliance Desirable?

**Low priority.** BDD shines when:

- Non-technical stakeholders need to understand specs
- QA team participates in specification
- Complex business rules need documentation

For solo/small team with technical owner, unit tests are sufficient.

## Key Terms

| Term                 | Definition                                            |
| -------------------- | ----------------------------------------------------- |
| Gherkin              | Language for writing specifications (Given/When/Then) |
| Feature File         | `.feature` file containing scenarios                  |
| Scenario             | Single test case in Given-When-Then format            |
| Step Definition      | Code that executes a Gherkin step                     |
| Three Amigos         | Dev, QA, Product collaborate on scenarios             |
| Living Documentation | Specs that execute and stay current                   |
| SpecFlow             | BDD framework for .NET                                |
| Cucumber             | BDD framework (Ruby, Java, JS)                        |
