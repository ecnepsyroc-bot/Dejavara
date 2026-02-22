# CQRS (Command Query Responsibility Segregation)

## What It Is

CQRS separates read operations (queries) from write operations (commands) into distinct models. Instead of one model for both reading and writing, you have optimized models for each purpose, potentially using different data stores.

## Core Principles (Non-Negotiables)

- **Separate read and write models** — Different objects for queries vs commands
- **Command handlers** — Process commands, modify state, return success/failure
- **Query handlers** — Read state, return data, no side effects
- **Optimized for purpose** — Read model denormalized, write model normalized

## How It Applies to Cambium

### Where We Align (Partial)

- **Conceptual separation**: Inbound ports separate query vs command methods

```csharp
// In IJobService (module port)
// Queries
Task<List<Job>> GetAllJobsAsync(bool includeArchived);
Task<Job?> GetJobByIdAsync(int jobId);

// Commands
Task<Job> CreateJobAsync(CreateJobRequest request);
Task RenameJobAsync(int jobId, string newName);
```

### Where We Dont

- **Single model**: Same EF entities for read and write
- **Single DbContext**: No separate read database
- **No command/query objects**: Methods, not message objects

### Compliance Desirable?

Not fully. Current approach (method separation) provides most benefits without complexity. Full CQRS (separate databases, event-sourced write side) is overkill for this scale.

## Key Terms

| Term                 | Definition                                     |
| -------------------- | ---------------------------------------------- |
| Command              | Request to change state (CreateJob, RenameJob) |
| Query                | Request for data with no side effects          |
| Command Handler      | Processes a command, updates state             |
| Query Handler        | Executes query, returns data                   |
| Read Model           | Denormalized view optimized for queries        |
| Write Model          | Normalized model for maintaining consistency   |
| Eventual Consistency | Read model may lag behind write model          |
