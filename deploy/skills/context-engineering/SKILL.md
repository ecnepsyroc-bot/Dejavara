---
name: context-engineering
description: "The art of curating what an AI knows to get quality output. Includes memory banks, specification files, progressive disclosure, and structured prompting. Use when setting up projects for AI collaboration, creating CLAUDE.md files, designing skill architectures, or optimizing AI context windows. Triggers include memory banks, context windows, specification-driven development, AI prompting strategies, or discussions of how to structure information for AI."
---

# Context Engineering

The art of curating what an AI "knows" to get quality output.

## Core Distinction

| Concept | Definition |
|---------|------------|
| **Prompt Engineering** | *What you say* to the AI |
| **Context Engineering** | *What the AI knows* when you say it |

## Context Window Management

The context window is a **public good**. Everything competes for space:
- System prompt
- Conversation history
- Loaded files
- Your current request

### Progressive Disclosure

Load information in layers:

```
Level 1: Metadata (~100 words)
   ↓ triggers
Level 2: Core instructions (<5k words)
   ↓ as needed
Level 3: Reference files (unlimited via execution)
```

## Memory Bank Structure

```
project/
├── CLAUDE.md              # Always-loaded context
├── memory-bank/
│   ├── projectBrief.md    # Vision, goals, constraints
│   ├── activeContext.md   # Current sprint, focus
│   ├── architecture.md    # Technical decisions
│   └── decisions.md       # Decision log
└── .claude/
    └── commands/          # Custom slash commands
```

## CLAUDE.md Template

```markdown
# Project Name

## Overview
[One sentence description]

## Tech Stack
- Language: [C#, TypeScript, etc.]
- Framework: [ASP.NET Core, React, etc.]
- Database: [PostgreSQL, SQL Server, etc.]

## Architecture
[Key patterns: hexagonal architecture, etc.]

## Shell Commands
\`\`\`bash
# Build
[command]

# Test
[command]

# Run
[command]
\`\`\`

## Key Constants
[Important values, magic numbers]

## Gotchas
- [Known issues]
- [Workarounds]

## Current Focus
[Active task]
```

## Specification-Driven Development

Use specs as source of truth, not just prompts.

### Feature Specification

```json
{
  "id": "F001",
  "category": "functional",
  "description": "User can create new factory order",
  "steps": [
    "Navigate to job page",
    "Click 'New Factory Order'",
    "Fill required fields",
    "Submit form",
    "Verify FO appears in list"
  ],
  "passes": false
}
```

### Rules for Agents

1. **One feature at a time** — prevents scope creep
2. **Leave clean state** — always buildable
3. **Update specs with code** — keep in sync
4. **Test end-to-end** — not just unit tests
5. **Commit with context** — clear messages

## Effective Prompting Patterns

### Plan-Then-Execute

```
1. "Think about how to implement X"
2. "Create a plan with specific steps"
3. "Review the plan, identify risks"
4. "Execute step 1"
5. "Verify step 1, then continue"
```

### Scope Control

```markdown
SCOPE: Only modify files in src/Managers/
TOUCH: BadgeManager.cs, BadgeDto.cs
NO-TOUCH: Controllers, Database, Tests
```

### Few-Shot Examples

```markdown
## Example Input/Output

Input: "Create badge PL1 for finish"
Output: Badge { Code: "PL1", Category: "FINISH", Shape: "Ellipse" }

Input: "Create badge SS1 for fixture"
Output: Badge { Code: "SS1", Category: "FIXTURE", Shape: "Diamond" }
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Dumping entire codebase | Wastes context | Load only relevant files |
| No architecture docs | AI guesses structure | Create CLAUDE.md |
| Vague prompts | Inconsistent results | Be specific, give examples |
| No cleanup protocol | Broken state between sessions | Require clean commits |
| Over-explaining basics | Wastes tokens | Trust AI's knowledge |

## Context Window Budget

Rough allocation for a 100k token window:

```
System prompt:     5-10k
CLAUDE.md:         1-2k
Conversation:      20-40k
Current files:     20-40k
Working space:     20-30k
```

## Cursor Rules / Project Rules

Create `.cursorrules` or `.claude/rules/`:

```markdown
# Architecture Rules

## Hexagonal Architecture
- Domain modules never import from other domain modules
- All cross-domain communication through adapters
- Port files are declarative only

## Code Style
- Use async/await, not callbacks
- Prefer composition over inheritance
- Always use explicit types (no var for complex types)

## Testing
- Every public method needs a test
- Use xUnit with FluentAssertions
- Mock external dependencies
```

## Session Recovery

When starting new session:

```
1. Read CLAUDE.md
2. Check git log (last 10 commits)
3. Read claude-progress.txt
4. Run smoke test
5. Pick up from documented state
```

## Key Insight

> **Default assumption: Claude is already very smart.**
> Only add context Claude doesn't already have.
> Challenge each piece: "Does this justify its token cost?"