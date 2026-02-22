# AI-Assisted Development

## What It Is

AI-Assisted Development uses artificial intelligence tools to augment human developers. AI can generate code, explain concepts, review changes, automate testing, and accelerate development. Tools like GitHub Copilot, Claude, and ChatGPT are common examples.

## Core Principles (Non-Negotiables)

- **Human oversight** — AI assists, humans decide
- **Review AI output** — Verify generated code before committing
- **Context is critical** — Better context yields better results
- **Iterative refinement** — Guide AI through conversation
- **Know the tools limits** — AI can hallucinate or be wrong

## How It Applies to Cambium

### Where We Align (ACTIVELY PRACTICING)

**AI tools in use**:

- **Claude Code**: Primary development assistant via OpenClaw
- **CLAUDE.md files**: AI instructions in `clients/laminate-inventory/CLAUDE.md`
- **.claude directory**: `src/Cambium.Api/.claude/` for Claude Code context

**Evidence**:

- Design specs created with AI assistance (Purchasing v2 Design Spec)
- Module migration guided by AI
- Architecture audit performed by AI (this document!)
- Real-time pair programming with AI

### Where We Dont

- **No GitHub Copilot**: Using Claude instead
- **No AI testing**: Not using AI-generated tests

### Compliance Desirable?

**Yes — ALREADY COMMITTED.** Continue and expand:

- Add CLAUDE.md to more projects
- Document AI-friendly patterns
- Maintain context files for AI assistants

## Key Terms

| Term                     | Definition                                     |
| ------------------------ | ---------------------------------------------- |
| Claude Code              | Anthropic CLI tool for AI-assisted development |
| OpenClaw                 | AI assistant platform integrating Claude       |
| GitHub Copilot           | Microsoft/GitHub AI code completion            |
| Context Window           | Amount of text AI can consider at once         |
| Prompt Engineering       | Crafting inputs to get better AI outputs       |
| Hallucination            | AI generating plausible but incorrect output   |
| CLAUDE.md                | Project instructions file for Claude Code      |
| Pair Programming with AI | Human + AI collaborative coding                |
