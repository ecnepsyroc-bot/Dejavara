# Skill Template

Copy and customize for new skills.

```markdown
---
name: <skill-name>
description: <1-2 sentences: what it does AND when to trigger it>
---

# <Skill Title>

## Prerequisites

- [ ] Required credential: `~/.openclaw/secrets/<token-name>`
- [ ] Required tool: `<tool-name>` installed
- [ ] Required access: <service/API access>

## Quick Reference

```bash
# Most common operation
<command>

# Second most common
<command>
```

## Workflow: <Primary Task Name>

### Step 1: <First Step>

```bash
<exact command>
```

Expected output:
```
<what success looks like>
```

### Step 2: <Second Step>

<instructions or commands>

### Step 3: Verify

```bash
<verification command>
```

## Workflow: <Secondary Task> (if applicable)

<steps>

## Common Issues

### Issue: <Problem Description>

**Symptoms:** <what you see>

**Cause:** <why it happens>

**Fix:**
```bash
<solution command or steps>
```

### Issue: <Another Problem>

<same format>

## Stored Credentials

| Item | Location | Notes |
|------|----------|-------|
| API Token | `~/.openclaw/secrets/<name>` | Permissions: X, Y, Z |
| Config | `<path>` | Created during setup |

## Configuration Files

### <config-name>

Location: `<path>`

```yaml
# or json, toml, etc.
<config contents>
```

## API Reference (if applicable)

See [references/api-examples.md](references/api-examples.md)

## External Docs

- Official docs: <url>
- API reference: <url>
```

## Frontmatter Tips

**Good description:**
> Set up and manage Cloudflare tunnels for exposing local services. Use when: (1) Adding domains to Cloudflare, (2) Creating tunnels for NAT/firewall traversal, (3) Connecting services across networks.

**Bad description:**
> Cloudflare stuff.

The description is how the skill gets triggered — be specific about use cases.

## File Organization

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── scripts/           # Helper scripts (optional)
│   └── helper.sh
└── references/        # Detailed docs (optional)
    ├── api-examples.md
    └── config-templates.md
```

Keep SKILL.md under 500 lines. Move details to references/.
