# Law of Demeter (Principle of Least Knowledge)

## What It Is

The Law of Demeter states that an object should only talk to its immediate friends, not strangers. Dont chain through objects (`a.getB().getC().doThing()`). This reduces coupling and makes code easier to change.

## Core Principles (Non-Negotiables)

- **Talk to friends** — Only call methods on: self, parameters, created objects, direct fields
- **No train wrecks** — Avoid `a.getB().getC().getD()` chains
- **Tell, dont ask** — Objects should do things, not expose their internals
- **Encapsulation** — Hide internal structure

## How It Applies to Cambium

### Where We Align

- **Port interfaces limit reach**: Services expose specific methods, not internal objects
- **DTOs flatten data**: API responses are flat, not nested object graphs

**Good example**:

```csharp
// Service exposes specific method
await _jobService.RenameJobAsync(jobId, newName);

// NOT: jobService.GetJob().SetName().Save()
```

### Where We Dont (PARTIAL COMPLIANCE)

- **EF Include chains**: Some queries navigate deep object graphs
- **Legacy managers**: Some access `entity.Related.Child.Property`

**Violation example**:

```csharp
// Potential violation in managers
var name = context.Jobs
    .Include(j => j.Contacts)
    .First().Contacts.First().Name;  // Train wreck
```

### Compliance Desirable?

**Yes.** Improve during module migration:

- Use DTOs to flatten data
- Create focused query methods
- Avoid exposing internal collections

## Key Terms

| Term          | Definition                              |
| ------------- | --------------------------------------- |
| Train Wreck   | Chain of method calls through objects   |
| Friend        | Object you can directly interact with   |
| Stranger      | Object you reach through another object |
| Tell Dont Ask | Give commands, dont query then decide   |
| Feature Envy  | Method more interested in other class   |
