# Microservices

## What It Is

Microservices architecture decomposes an application into small, independently deployable services. Each service owns its data, runs in its own process, and communicates with others via APIs or messaging. Teams can develop, deploy, and scale services independently.

## Core Principles (Non-Negotiables)

- **Single responsibility** — Each service does one thing well
- **Independent deployment** — Deploy services without coordinating with others
- **Decentralized data** — Each service owns its database
- **API contracts** — Services communicate via well-defined interfaces
- **Failure isolation** — One service failing doesnt crash others
- **Technology diversity** — Each service can use different tech stack

## How It Applies to Cambium

### Where We Align

Minimal — Cambium is explicitly a **modular monolith**, not microservices.

### Where We Dont (BY DESIGN)

- **Single deployable**: One .NET application deployed to Railway
- **Shared database**: All modules use CambiumDbContext (PostgreSQL)
- **In-process communication**: Modules call each other directly or via orchestrators
- **Single tech stack**: .NET 8 + React throughout

### Compliance Desirable?

**No.** Microservices are inappropriate for Cambium because:

- **Team size**: Solo/small team doesnt benefit from independent deployability
- **Operational complexity**: Would need service mesh, distributed tracing, etc.
- **Data relationships**: Strong FK relationships between modules (Job to BadgeCategory)
- **Modular monolith works**: Get 80% of benefits with 20% of complexity

**Future consideration**: If scaling requires, modules are structured to extract as services.

## Key Terms

| Term            | Definition                                           |
| --------------- | ---------------------------------------------------- |
| Service         | Independently deployable unit with own database      |
| API Gateway     | Entry point that routes requests to services         |
| Service Mesh    | Infrastructure for service-to-service communication  |
| Circuit Breaker | Pattern to prevent cascade failures                  |
| Saga            | Pattern for distributed transactions                 |
| Sidecar         | Helper container deployed alongside service          |
| Bounded Context | DDD term for a services domain                       |
| Choreography    | Services react to events without central coordinator |
| Orchestration   | Central service coordinates multi-service workflows  |
