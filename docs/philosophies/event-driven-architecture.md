# Event-Driven Architecture

## What It Is

Event-Driven Architecture (EDA) structures applications around the production, detection, and reaction to events. Components communicate by publishing events that other components subscribe to, enabling loose coupling and reactive behavior.

## Core Principles (Non-Negotiables)

- **Events as first-class citizens** — State changes represented as events
- **Publish-subscribe** — Publishers dont know who consumes events
- **Loose coupling** — Components interact through events, not direct calls
- **Eventual consistency** — Accept that state synchronizes asynchronously
- **Event immutability** — Events are facts that happened, never modified

## How It Applies to Cambium

### Where We Align

- **Event contracts defined**: `event-schema/Cambium.EventSchema.Contracts/`
- **Module events documented**: MODULE.md files list events emitted/consumed
- **Orchestrators react to events**: `adapters/` coordinate cross-module responses

**Evidence**:

- `modules/Cambium.Module.Jobs/MODULE.md` — Documents "Events Emitted" section

### Internal Event Bus (Domain Events)

Cambium has two distinct event layers. The internal event bus handles domain events between modules:

- **Outbound port**: `src/Cambium.Core/Events/IEventBus.cs` — defines `PublishAsync<TEvent>()` and `Subscribe<TEvent>()`
- **Implementation**: `src/Cambium.Core/Events/InMemoryEventBus.cs` — in-memory, sequential handler execution, no queuing or retry
- **Placement note**: `InMemoryEventBus` is a concrete infrastructure class co-located in `Cambium.Core` (application layer). Clean Architecture would place it in `Cambium.Api` or a dedicated infrastructure project. The `IEventBus` interface is correctly placed.

**Wired events (4 total — all Job lifecycle)**:

- `JobCreated` — published by `CreateJobUseCase`, consumed by `JobToChat` adapter
- `JobRenamed` — published by `RenameJobUseCase`
- `JobArchived` — published by `ArchiveJobUseCase`
- `JobDeleted` — published by `DeleteJobUseCase`

**Unwired contracts**: 9 event record files exist in `EventSchema.Contracts/Events/` (Chat, Courier, Document, Job, Master, Parse, Pdf, Production, Specification), but only the Job events above are published via `IEventBus`. The remaining are Phase 1: contracts defined, not yet emitted.

### Real-Time Broadcast Layer (SignalR)

SignalR is a separate layer from the internal event bus. It pushes UI notifications to connected browser clients:

- `src/Cambium.Api/Hubs/` — SignalR hubs for real-time client communication
- SignalR events are **UI delivery**, not domain events — they notify frontends of state changes
- The `JobToChat` adapter bridges the two layers: it subscribes to `IEventBus` domain events and triggers chat/SignalR broadcasts

### Where We Dont

- **No event store**: Domain events are in-memory only — lost on restart, not persisted for replay
- **No event sourcing**: State is mutable, not derived from event log
- **Narrow adoption**: Only 4 of 9+ event types are actually wired; the dominant code path (Gen 1 managers) uses direct method calls, not events
- **Sequential dispatch**: `InMemoryEventBus` executes handlers one-by-one in subscription order — functionally synchronous despite `async/await` signatures

### Compliance Desirable?

Partial. The event bus pattern is proven for Job lifecycle events but not yet adopted broadly. SignalR provides real-time UX. Full event sourcing would add complexity without proportional benefit for this domain. Expanding `IEventBus` adoption to more modules (as events are wired during Gen 1 -> Gen 2 migration) is the natural next step.

## Cambium Architectural Context

Two generations of code coexist (see `docs/architecture/CLEAN-ARCHITECTURE-AUDIT.md`):

- **Gen 2 (target)**: Use cases like `CreateJobUseCase` publish domain events via `IEventBus` after persistence succeeds. The `JobToChat` adapter subscribes to these events and bridges them to the chat/SignalR layer. This is genuine event-driven architecture.
- **Gen 1 (dominant)**: ~44 managers in `Cambium.Core/Managers/` use direct method calls — no events, no pub/sub. Cross-module coordination happens via manager-to-manager calls, not event bus.

The "Where We Align" content above describes the Gen 2 event-driven path. Gen 1 has no event-driven behavior at all. As managers migrate to modules, each will gain event publication via `IEventBus`, and the corresponding event contracts in `EventSchema.Contracts/` will move from Phase 1 (defined) to Phase 2 (emitted).

## Key Terms

| Term                 | Definition                                                  |
| -------------------- | ----------------------------------------------------------- |
| Event                | Immutable record of something that happened                 |
| Publisher            | Component that emits events                                 |
| Subscriber           | Component that reacts to events                             |
| Event Bus            | Infrastructure for routing events                           |
| Event Store          | Persistent log of all events                                |
| Command              | Request to do something (vs event: record of what happened) |
| Saga                 | Long-running process coordinating multiple events           |
| Eventual Consistency | State converges over time, not immediately                  |
