# Skills Research & Recommendations

## Analysis Date: 2026-02-08

Based on bundled OpenClaw skills and our work patterns.

---

## Agentic Coding Skills

### Patterns from `coding-agent` Skill

| Pattern | Description | Our Use Case |
|---------|-------------|--------------|
| PTY mode | Interactive terminal apps need `pty:true` | AutoCAD tools, .NET CLI |
| Background + monitor | Long tasks in background, poll for progress | Builds, migrations |
| Git worktrees | Parallel work on multiple branches/issues | Multiple FOs, PR reviews |
| Wake notifications | Alert when background task completes | Build completion |
| Progress updates | Keep user informed during long tasks | Railway deploys |

### Recommended Skill: `dotnet-dev`

```
Purpose: .NET development patterns for Cambium
Contents:
- Build commands (dotnet build/publish/test)
- SDK version management (global.json)
- Dockerfile patterns for .NET
- EF Core migrations
- Common gotchas (SDK mismatch, submodules)
```

### Recommended Skill: `sub-agent-orchestration`

```
Purpose: Spawn and coordinate sub-agents for complex tasks
Contents:
- When to spawn vs do inline
- sessions_spawn patterns
- Progress tracking across agents
- Result aggregation
- Error handling
```

---

## Workflow Skills

### Recommended Skill: `git-workflow`

```
Purpose: Git patterns for our mono-repo setup
Contents:
- Branching strategy (feature/, fix/, refactor/)
- Commit message conventions
- PR workflow
- Worktree patterns for parallel work
- Submodule handling
```

### Recommended Skill: `cambium-dev`

```
Purpose: Cambium-specific development patterns
Contents:
- Solution structure (Root.sln, subfolders)
- Module architecture (hexagonal terms)
- Client apps (React/Vite)
- Local dev setup
- Test patterns
```

---

## Infrastructure Skills

### Already Created

| Skill | Status | Purpose |
|-------|--------|---------|
| cloudflare-tunnel | ✅ v1.0.0 | Tunnel & DNS management |
| session-to-skill | ✅ v1.0.0 | Convert sessions to skills |

### Recommended Skill: `railway-deploy`

```
Purpose: Railway deployment (once we solve the build)
Contents:
- Project setup
- PostgreSQL provisioning
- Dockerfile for mono-repos
- Environment variables
- Domain/SSL setup
- Database migration
- Common failures (SDK, submodules)
```

### Recommended Skill: `pi-infrastructure`

```
Purpose: Raspberry Pi management for OpenClaw
Contents:
- Docker container management
- cloudflared service
- Monitoring/health checks
- Backup patterns
- Network troubleshooting
```

---

## Domain Skills (Feature Millwork)

### Recommended Skill: `feature-millwork-docs`

```
Purpose: V5.1 Documentation Standards
Contents:
- Folder structure (00-11)
- File naming conventions
- Sheet numbering
- FO workflow
- Project/new-fo scripts
```

### Recommended Skill: `autocad-tools`

```
Purpose: AutoCAD integration via Luxify
Contents:
- Command bridge (named pipe)
- Badge insertion
- Title block management
- Drawing conventions
```

---

## Meta Skills

### Recommended Skill: `skill-revision`

```
Purpose: Keep skills up to date
Contents:
- Monthly review checklist
- Version tracking
- Changelog patterns
- Deprecation handling
- Testing workflows
```

---

## Priority Order

### Tier 1 - Build Now (High Value, Ready)
1. `feature-millwork-docs` — V5.1 is fresh, document it
2. `git-workflow` — Use constantly
3. `railway-deploy` — Once we solve the build

### Tier 2 - Build Soon (Medium Value)
4. `dotnet-dev` — .NET patterns
5. `cambium-dev` — Project-specific
6. `pi-infrastructure` — Our always-on gateway

### Tier 3 - Build Later (Nice to Have)
7. `sub-agent-orchestration` — Complex task coordination
8. `autocad-tools` — When we revisit Luxify
9. `skill-revision` — Formalize review process

---

## Revision Schedule

| Frequency | Action |
|-----------|--------|
| Monthly | Review all active skills for accuracy |
| On Failure | Update skill when documented workflow fails |
| On Success | Capture new patterns that worked |
| Quarterly | Audit skill coverage vs actual work |

---

## Software Update Tracking

Skills that depend on external software need update tracking:

| Skill | Dependencies | Check Frequency |
|-------|--------------|-----------------|
| cloudflare-tunnel | Cloudflare API, cloudflared | Monthly |
| railway-deploy | Railway API, Nixpacks | Monthly |
| dotnet-dev | .NET SDK releases | Quarterly |
| github | gh CLI | Quarterly |

**Pattern:** Each skill should note its external dependencies and last-verified versions.

---

## Next Steps

1. Create `feature-millwork-docs` skill (V5.1 is documented, just need to package)
2. Finish Railway deployment → create `railway-deploy` skill
3. Set up monthly calendar reminder for skill reviews
4. Add Brave API key for web search (stay current on updates)
