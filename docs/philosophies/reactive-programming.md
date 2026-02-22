# Reactive Programming

## What It Is

Reactive programming is a paradigm oriented around data streams and propagation of change. When data changes, dependent computations automatically update. Its particularly useful for UIs and real-time systems.

## Core Principles (Non-Negotiables)

- **Data streams** — Everything is a stream of events over time
- **Observers** — Components subscribe to streams
- **Automatic propagation** — Changes flow through the system
- **Backpressure** — Handle producers faster than consumers
- **Declarative composition** — Combine streams with operators

## How It Applies to Cambium

### Where We Align

- **SignalR for real-time**: Server pushes updates to clients
- **React state management**: UI reacts to state changes

**Evidence**:

- `src/Cambium.Api/Hubs/` — SignalR hubs push events
- React SPAs update when state changes

### Where We Dont

- **No Rx.NET**: Not using System.Reactive
- **Imperative event handling**: Most event handlers are procedural
- **No stream operators**: Not composing event streams

### Compliance Desirable?

**Low priority.** Current approach (SignalR + React) provides reactive UX without formal reactive programming framework.

**Consider if**:

- Complex event stream processing needed
- Multiple event sources need coordination
- Backpressure becomes an issue

## Key Terms

| Term            | Definition                                 |
| --------------- | ------------------------------------------ |
| Observable      | Stream of events over time                 |
| Observer        | Subscriber that reacts to events           |
| Subscription    | Connection between observable and observer |
| Operator        | Function that transforms/combines streams  |
| Backpressure    | Mechanism to handle slow consumers         |
| Hot Observable  | Emits regardless of subscribers            |
| Cold Observable | Emits only when subscribed                 |
| Rx              | Reactive Extensions library                |
