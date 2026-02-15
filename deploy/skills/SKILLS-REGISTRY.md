# Skills Registry

Track custom skills and their revision status.

## Custom Skills

| Skill | Version | Last Updated | Next Review | Status |
|-------|---------|--------------|-------------|--------|
| aspnet-dual-auth | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| aspnet-dataprotection-db | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| cloudflare-tunnel | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| dev-passwords | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| railway-deploy | 1.1.0 | 2026-02-13 | 2026-03-13 | Active |
| session-to-skill | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| postgres-failover-sync | 1.1.0 | 2026-02-13 | 2026-03-13 | Active |
| postgres-remote-ops | 1.0.0 | 2026-02-13 | 2026-03-13 | Active |
| cambium-hosting | - | - | - | Planned |

## Revision Schedule

- **Monthly review**: Check for API changes, deprecated features, new best practices
- **On failure**: Update skill when a documented workflow fails
- **On success**: Capture new patterns that worked

## Revision Checklist

When reviewing a skill:
1. Test main workflows still work
2. Check for API version changes
3. Update response examples if changed
4. Add new common issues encountered
5. Update version number and dates

## Changelog

### 2026-02-13
- Created `postgres-remote-ops` skill v1.0.0
  - Execute SQL when psql isn't locally installed
  - Node.js `pg` package one-liners and scripts
  - SSH jump box patterns for Cambium-server
  - Batch file approach to avoid escaping hell
  - Railway-specific notes (external vs internal hosts)
  - Decision tree for method selection
- Updated `postgres-failover-sync` to v1.1.0
  - Added post-sync verification section
  - Column drift detection and repair
  - Node.js fallback when psql unavailable
  - Common issues table with fixes
- Updated `railway-deploy` to v1.1.0
  - Added database sync & verification section
  - Column drift explanation and prevention
  - Free plan limitations documented
  - Cross-reference to postgres-remote-ops

### 2026-02-12
- Created `postgres-failover-sync` skill v1.0.0
  - Schema nuke pattern for reliable full-database sync
  - pg_terminate_backend before restore
  - Cross-auth JWT key matching
  - Windows batch and Linux script templates
  - Lessons: incremental --clean fails on schema drift; nuke and rebuild wins

### 2026-02-08 (evening)
- Created `aspnet-dual-auth` skill v1.0.0
  - Policy scheme selector for JWT vs Cookie based on request
  - Cookie config for SPA (HttpOnly, SameSite=Lax, 30-day expiry)
  - Critical: Return 401 instead of redirect for API calls
  - Login controller pattern to set both JWT and cookie
  - SPA client configuration (withCredentials: true)
- Created `aspnet-dataprotection-db` skill v1.0.0
  - IDataProtectionKeyContext implementation
  - Migration for data_protection_keys table
  - Package version alignment (EF Core 8.0.*)
  - Railway-specific notes (ephemeral filesystem)

### 2026-02-08
- Created `dev-passwords` skill v1.0.0
  - BCrypt library compatibility across platforms (.NET, Node.js, Python)
  - How to diagnose auth failures from hash mismatches
  - Hash generation examples for each platform
  - Lesson captured: bcryptjs ≠ BCrypt.Net
- Created `railway-deploy` skill v1.0.0
  - .NET 8 deployment workflow
  - PostgreSQL provisioning and connection
  - EF Core migrations via SQL scripts (timeout workaround)
  - Troubleshooting reference: duplicate appsettings, gitignore conflicts, port config
- Created `cloudflare-tunnel` skill v1.0.0
  - API workflows for domain, tunnel, DNS management
  - Helper script `cf-tunnel.sh`
  - API response examples reference
- Created `session-to-skill` skill v1.0.0
  - Meta-skill for capturing sessions as documentation
  - Skill template reference
  - Quality checklist for skill creation

## Planned Skills

### cambium-hosting (Priority: Medium)
- Cambium-specific deployment config
- Environment variables
- Database migration
- Frontend deployment

### hosting-general (Priority: Low)
- Compare hosting options (Railway, Render, Fly.io, Hetzner)
- Cost/complexity tradeoffs
- When to use which
