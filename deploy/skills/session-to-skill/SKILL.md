---
name: session-to-skill
description: Meta-skill for capturing technical sessions and converting them into reusable skills. Use when: (1) Working through a new setup or integration, (2) Debugging a complex problem, (3) User says "document this" or "make this a skill", (4) A successful workflow should be preserved for future use.
---

# Session to Skill

Convert live troubleshooting sessions into documented, reusable skills.

## When to Activate

- Setting up new infrastructure (hosting, tunnels, CI/CD)
- Integrating new services or APIs
- Debugging complex multi-step problems
- Any workflow that took significant effort to figure out

## During the Session

### 1. Track as You Go

While working, mentally note:
- **Commands that worked** (exact syntax)
- **Commands that failed** and why
- **API responses** (save key examples)
- **Config files** created
- **Credentials/tokens** and where stored
- **Common gotchas** discovered

### 2. Capture Failure Points

Document what went wrong:
```
## Failed Attempts
- Tried X → failed because Y
- SDK version mismatch: required 9.0, had 8.0
- Submodules not initialized by CI
```

These become the "Common Issues" section.

### 3. Note the Working Solution

When something finally works:
```
## Working Solution
1. Step one (exact command)
2. Step two (config file contents)
3. Verification step
```

## After the Session

### Generate the Skill

1. **Create skill structure:**
```bash
python3 /app/skills/skill-creator/scripts/init_skill.py <skill-name> \
  --path /home/node/.openclaw/workspace/skills \
  --resources scripts,references
```

2. **Write SKILL.md with:**
   - Prerequisites (tokens, tools, access)
   - Quick reference (most common commands)
   - Full workflow (step-by-step)
   - Common issues (what we learned the hard way)
   - Stored credentials (where tokens live)

3. **Add resources:**
   - `scripts/` — Helper scripts for common operations
   - `references/` — API examples, config templates

4. **Update registry:**
   - Add to `skills/SKILLS-REGISTRY.md`
   - Set review date (monthly)

## Skill Template

```markdown
---
name: <skill-name>
description: <what it does and when to use it>
---

# <Skill Title>

## Prerequisites
- Required tokens/credentials
- Required tools

## Quick Reference
<Most common commands>

## Workflow: <Main Task>
1. Step one
2. Step two
3. Verification

## Common Issues

### Issue: <problem>
- Cause: <why>
- Fix: <solution>

## Stored Credentials
| Item | Location |
|------|----------|
| Token | `~/.openclaw/secrets/...` |
```

## Quality Checklist

Before finalizing a skill:
- [ ] Can someone follow the workflow cold?
- [ ] Are exact commands included (not paraphrased)?
- [ ] Are common failures documented?
- [ ] Are credentials/paths noted?
- [ ] Is there a verification step?
- [ ] Added to SKILLS-REGISTRY.md?

## See Also

- [references/skill-template.md](references/skill-template.md) - Full template
- `/app/skills/skill-creator/SKILL.md` - Skill creation guide
