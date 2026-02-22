# Event Sourcing

## What It Is

Event Sourcing persists state as a sequence of events rather than current values. Instead of storing "balance = $100", you store "deposited $50", "deposited $75", "withdrew $25". Current state is derived by replaying events.

## Core Principles (Non-Negotiables)

- **Events are the source of truth** — No mutable state, only event log
- **State derived from events** — Replay events to reconstruct current state
- **Events are immutable** — Never modify or delete events
- **Full audit trail** — Every change is recorded with timestamp and metadata
- **Temporal queries** — Can reconstruct state at any point in time

## How It Applies to Cambium

### Where We Align

- **Audit logging exists**: `audit_logs` table records some changes
- **PO activity log**: `po_activity_log` tracks PO state changes
- **Event contracts defined**: Events documented in MODULE.md files

### Where We Dont (NOT ADOPTED)

- **Mutable state**: Entities are updated in place, not event-sourced
- **No event replay**: Cannot reconstruct past state from events
- **No event store**: Events broadcast via SignalR, not persisted
- **Traditional CRUD**: Standard create/update/delete operations

### Compliance Desirable?

**No for full adoption.** Event sourcing adds significant complexity:

- Requires event versioning strategy
- Complex debugging (must replay to understand state)
- Eventual consistency challenges

**Consider for specific cases**: If audit requirements grow, event source PO or Badge workflows.

## Key Terms

| Term             | Definition                                  |
| ---------------- | ------------------------------------------- |
| Event Store      | Append-only log of all events               |
| Aggregate        | Cluster of entities with event-sourced root |
| Projection       | Read model built by processing events       |
| Snapshot         | Cached state to avoid full replay           |
| Event Versioning | Strategy for evolving event schemas         |
| Replay           | Reconstructing state by processing events   |
| Temporal Query   | Query state as of a specific point in time  |
