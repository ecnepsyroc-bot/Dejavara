# Serverless

## What It Is

Serverless computing runs code in response to events without managing servers. Functions execute on-demand, scale automatically, and you only pay for execution time. AWS Lambda, Azure Functions, and Cloudflare Workers are common platforms.

## Core Principles (Non-Negotiables)

- **No server management** — Platform handles infrastructure
- **Event-driven execution** — Functions triggered by events (HTTP, queue, schedule)
- **Auto-scaling** — Scale to zero when idle, scale up under load
- **Pay-per-execution** — Billed by invocation and duration
- **Stateless functions** — No local state between invocations

## How It Applies to Cambium

### Where We Align

Minimal — Cambium runs as a traditional server application.

### Where We Dont (NOT ADOPTED)

- **Railway hosting**: Long-running server, not functions
- **Stateful application**: EF DbContext, in-memory caches, SignalR connections
- **Monolithic deployment**: Single container, not individual functions

### Compliance Desirable?

**No for core application.** Serverless is inappropriate because:

- **WebSocket requirement**: SignalR needs persistent connections
- **Cold start latency**: Functions have startup delay
- **Database connections**: Connection pooling problematic with functions
- **Complexity**: Would need to decompose into hundreds of functions

**Consider for specific use cases**:

- Background jobs (PDF generation) could be Lambda/Functions
- Scheduled tasks could be serverless cron triggers

## Key Terms

| Term                    | Definition                                         |
| ----------------------- | -------------------------------------------------- |
| Function                | Single-purpose code unit triggered by events       |
| Cold Start              | Latency when function container initializes        |
| Warm Start              | Fast execution when container already running      |
| Trigger                 | Event that invokes a function (HTTP, queue, timer) |
| FaaS                    | Function as a Service (Lambda, Functions, Workers) |
| BaaS                    | Backend as a Service (Firebase, Supabase)          |
| Provisioned Concurrency | Pre-warmed instances to avoid cold starts          |
