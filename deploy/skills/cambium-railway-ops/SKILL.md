---
name: cambium-railway-ops
description: >
  Railway deployment operations for Cambium. Use this skill whenever touching:
  Railway deployments, DATABASE_URL configuration, Variable References, Railway
  Variables, pre-push schema checks, Railway logs, production login verification,
  Railway credentials, or anything involving cambium.luxifysystems.com. Also
  triggers for: "Railway is down", "deployment failed", "login not working on
  Railway", "schema drift", "28P01 error", "42P01 error". Read this before
  any git push to main. Supersedes the railway-deploy skill.
---

# Cambium Railway Operations

Railway auto-deploys from GitHub main. Every `git push origin main` triggers a redeploy. Initialize or append to AUDIT.log before starting any Railway operations session.

## The Variable Reference Rule

**DATABASE_URL in Railway Cambium Variables MUST be `${{Postgres.DATABASE_URL}}`** — never a hardcoded connection string.

Why: Password regeneration on the Postgres service auto-updates the reference. Hardcoded strings break silently on regeneration.

## Quick Reference

| What | How |
|------|-----|
| Check schema before push | `psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql` |
| Verify Variable Reference | Railway dashboard > Cambium > Variables > DATABASE_URL |
| Watch deploy logs | Railway dashboard > Cambium > Deployments > View Logs |
| Post-deploy verify | Log into `cambium.luxifysystems.com` |
| Emergency schema repair | `psql "$DATABASE_PUBLIC_URL" -f scripts/fix-railway-emergency.sql` |

## Log Patterns to Watch After Deploy

| Pattern | Meaning |
|---------|---------|
| `Schema verification passed: all 14 user columns present` | Self-healing succeeded |
| `Cambium API starting on port 8080 in Production mode` | Normal startup |
| `28P01: password authentication failed` | DATABASE_URL stale — update Variable Reference |
| `42P01: relation does not exist` on critical tables | Run `fix-railway-emergency.sql` |
| `42P01` on unshipped feature tables | Normal — 55 tables are expected-missing |

## Reference Files

| File | When to Read |
|------|--------------|
| [variable-references.md](references/variable-references.md) | DATABASE_URL setup, password rotation, Variable Reference verification |
| [schema-check.md](references/schema-check.md) | Pre-push schema validation, critical tables, expected-missing tables |
| [deployment-sequence.md](references/deployment-sequence.md) | Pre-push checklist, deploy monitoring, post-deploy verification |
| [credential-rotation.md](references/credential-rotation.md) | Postgres password regeneration, ADMIN_DEFAULT_PASSWORD recovery |

## Hard Rules

1. **Read [deployment-sequence.md](references/deployment-sequence.md) before every Railway deploy. No exceptions.**
2. **DATABASE_URL must always be a Variable Reference** (`${{Postgres.DATABASE_URL}}`).
3. **Never paste Railway credentials into chat sessions.**
