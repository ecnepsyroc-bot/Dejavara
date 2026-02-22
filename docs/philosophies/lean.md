# Lean Software Development

## What It Is

Lean applies manufacturing principles from Toyota Production System to software development. It focuses on eliminating waste, optimizing the whole system, and delivering value faster by removing anything that doesnt directly contribute to customer outcomes.

## Core Principles (Non-Negotiables)

- **Eliminate waste** — Remove anything that doesnt add customer value
- **Build quality in** — Prevent defects rather than find them later
- **Create knowledge** — Learn continuously through experimentation
- **Defer commitment** — Make decisions at the last responsible moment
- **Deliver fast** — Short cycles, rapid feedback
- **Respect people** — Trust teams to make decisions
- **Optimize the whole** — Avoid local optimizations that hurt the system

## How It Applies to Cambium

### Where We Align

- **Eliminate waste**: YAGNI applied — no speculative features (BOM module is stub until needed)
- **Build quality in**: Architecture patterns (hexagonal) prevent coupling defects
- **Deliver fast**: Railway auto-deploy on push, no manual deployment steps
- **Defer commitment**: Shared DbContext decision deferred migration complexity

### Where We Dont

- **No value stream mapping**: No formal analysis of development pipeline
- **No WIP limits**: No explicit constraints on work in progress
- **No cycle time tracking**: No measurement of lead time from idea to production

### Compliance Desirable?

Principles — yes (already largely followed). Formal practices (value stream mapping, metrics dashboards) — low priority for current scale.

## Key Terms

| Term         | Definition                                                 |
| ------------ | ---------------------------------------------------------- |
| Waste (Muda) | Anything that doesnt add value (waiting, handoffs, rework) |
| Value Stream | End-to-end flow from idea to customer value                |
| Lead Time    | Time from request to delivery                              |
| Cycle Time   | Time actively working on an item                           |
| WIP Limit    | Maximum items in progress simultaneously                   |
| Pull System  | Work pulled when capacity available, not pushed            |
| Kaizen       | Continuous incremental improvement                         |
| Muri         | Waste from overburden/unreasonable demands                 |
| Mura         | Waste from unevenness/inconsistency                        |
