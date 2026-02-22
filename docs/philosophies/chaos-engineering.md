# Chaos Engineering

## What It Is

Chaos Engineering proactively tests system resilience by introducing controlled failures. By breaking things on purpose in a controlled way, you discover weaknesses before they cause real outages. Netflix popularized it with Chaos Monkey.

## Core Principles (Non-Negotiables)

- **Hypothesize about steady state** — Define what normal looks like
- **Vary real-world events** — Simulate actual failure modes
- **Run experiments in production** — Test where it matters
- **Automate experiments** — Continuously test resilience
- **Minimize blast radius** — Start small, limit impact

## How It Applies to Cambium

### Where We Align

Minimal — Chaos engineering not practiced.

### Where We Dont (NOT ADOPTED)

- **No chaos tools**: No Chaos Monkey, Gremlin, LitmusChaos
- **No failure injection**: Not simulating database failures, network issues
- **No game days**: No scheduled resilience testing
- **Limited redundancy**: Single Railway deployment

### Compliance Desirable?

**Low priority for current scale.** Chaos engineering valuable when:

- High availability requirements
- Distributed system with many failure modes
- Team dedicated to reliability

**Consider lightweight approaches**:

- Test behavior when external APIs fail
- Verify graceful degradation for database issues
- Document known failure modes

## Key Terms

| Term              | Definition                                 |
| ----------------- | ------------------------------------------ |
| Chaos Monkey      | Netflix tool that randomly kills instances |
| Blast Radius      | Scope of impact from failure injection     |
| Game Day          | Scheduled chaos experiment with team       |
| Steady State      | Normal operating behavior                  |
| Failure Injection | Deliberately introducing failures          |
| Resilience        | Ability to recover from failures           |
| Gremlin           | Commercial chaos engineering platform      |
| Circuit Breaker   | Pattern to prevent cascade failures        |
