---
name: cambium-auth-credentials
description: >
  Cambium authentication, credential management, and Railway deployment safety.
  Use this skill whenever touching: auth endpoints, admin seeding, password logic,
  JWT/cookie configuration, connection strings, appsettings files, Program.cs startup
  block, authFetch(), login flow, Railway Variables, DATABASE_URL, ADMIN_DEFAULT_PASSWORD,
  cambium_sync role, or any pre-Railway-push preparation. Also triggers for: "login not
  working", "password not applying", "Railway credential rotation", "admin locked out",
  "auth 401", "cookie expired", "JWT invalid". When in doubt, read this skill first.
---

# Cambium Auth & Credentials

Cambium uses dual JWT + Cookie authentication (ASP.NET Core), PostgreSQL on Railway, and a startup self-healing block that repairs schema drift. Three auth incidents shaped this skill: Railway password rotation causing outages (fixed by Variable References), admin password env var not applying (fixed by removing hash-gate), and credential exposure in chat sessions (prevented by pre-push checklist).

## Quick Reference: Credentials

| Credential | Where It Lives | Rotation | Blast Radius |
|------------|----------------|----------|--------------|
| Postgres superuser | `${{Postgres.DATABASE_URL}}` | Railway DB tab | Zero if Variable Reference; full outage if hardcoded |
| JWT signing key | `JWT_SECRET_KEY` env var | Manual | All tokens invalid (users re-login) |
| Admin password | `users` table (BCrypt) | `ADMIN_DEFAULT_PASSWORD` env var | Admin locked out |
| cambium_sync | External scripts only | Manual | Backup sync fails |
| Cloudflare tunnel | Dashboard | Manual | Shop LAN unreachable |

## The Variable Reference Rule

**DATABASE_URL in Railway Cambium Variables must always be `${{Postgres.DATABASE_URL}}`** — never a hardcoded connection string. Hardcoded strings break silently when the Postgres password is regenerated.

## Admin Password Recovery Pattern

When `ADMIN_DEFAULT_PASSWORD` env var is set (non-empty), startup **always overwrites** the admin password and clears lockout. There is no hash-gate or conditional logic — this is a deliberate emergency override.

**Recovery procedure:**
1. Set `ADMIN_DEFAULT_PASSWORD=<new-password>` in Railway Variables
2. Redeploy (automatic on variable change)
3. Watch logs for: `"Admin password reset from ADMIN_DEFAULT_PASSWORD env var"`
4. Test login at `cambium.luxifysystems.com`
5. **Remove the env var immediately** — it resets password on every deploy

## Reference Files

| File | When to Read |
|------|--------------|
| [admin-seeding.md](references/admin-seeding.md) | Admin locked out, password not applying, ADMIN_DEFAULT_PASSWORD questions |
| [connection-strings.md](references/connection-strings.md) | DATABASE_URL, Railway setup, connection failures, cambium_sync role |
| [jwt-cookie-scheme.md](references/jwt-cookie-scheme.md) | 401 errors, cookie not set, JWT claims, token expiry, DataProtection |
| [credential-inventory.md](references/credential-inventory.md) | Before rotating any credential, blast radius assessment |
| [pre-push-checklist.md](references/pre-push-checklist.md) | **Before every Railway deploy** |

## Hard Rule

**Read [pre-push-checklist.md](references/pre-push-checklist.md) before every Railway deploy. No exceptions.**

This checklist was derived from actual incidents. Every item earned its place by causing a production issue.

## Key Code Locations

| Component | File | Lines |
|-----------|------|-------|
| Admin seeding | `Program.cs` | 1192-1211 |
| Connection string parsing | `Program.cs` | 43-55 |
| PolicyScheme (JWT/Cookie) | `Program.cs` | 201-214 |
| Self-healing ALTERs | `Program.cs` | 622-642 |
| Schema verification | `Program.cs` | 645-674 |
| Login flow | `AuthController.cs` | 40-190 |
| JWT generation | `AuthController.cs` | 1226-1256 |
| Frontend authFetch | `wwwroot/app.js` | 383-396 |
