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
- **Real-time events via SignalR**: Hubs broadcast state changes to connected clients
- **Module events documented**: MODULE.md files list events emitted/consumed
  - Example: Jobs module emits `JobCreated`, `JobRenamed`, `JobArchived`, `JobDeleted`
- **Orchestrators react to events**: `adapters/` coordinate cross-module responses

**Evidence**:

- `src/Cambium.Api/Hubs/` — SignalR hubs for real-time communication
- `modules/Cambium.Module.Jobs/MODULE.md` — Documents "Events Emitted" section

### Where We Dont

- **No event store**: Events not persisted for replay
- **No event sourcing**: State is mutable, not derived from event log
- **Synchronous coordination**: Some orchestrators use direct calls, not async events

### Compliance Desirable?

Partial. Current level (SignalR real-time updates, event contracts) is sufficient. Full event sourcing would add complexity without proportional benefit for this domain.

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
