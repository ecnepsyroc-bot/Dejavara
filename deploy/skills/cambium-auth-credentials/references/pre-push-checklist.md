# Pre-Push Railway Checklist

**Run this before every `git push` to main that will auto-deploy to Railway.**

Every item on this checklist earned its place by causing a production incident. Do not skip items.

---

## Credentials

- [ ] **No credentials in this chat session or any open chat window**
  - Scan: Did you copy-paste any connection string, password, or token?
  - If yes: Start a new chat session before pushing

- [ ] **DATABASE_URL in Railway Cambium Variables is `${{Postgres.DATABASE_URL}}`**
  - Check: Railway dashboard → Cambium → Variables → DATABASE_URL
  - Raw Value should show `${{Postgres.DATABASE_URL}}`, NOT a hardcoded string
  - If hardcoded: Delete and recreate with the Variable Reference

- [ ] **ADMIN_DEFAULT_PASSWORD is NOT set in Railway Variables**
  - Exception: This is a deliberate admin recovery
  - If set for recovery: Remove it immediately after confirming login works
  - If forgotten: Password resets on every deploy

- [ ] **JWT secret key is set in Railway env vars**
  - Variable name: `JWT_SECRET_KEY`
  - If missing: App will crash on startup with "JWT_SECRET_KEY required" error

---

## Schema

- [ ] **Run schema verification against Railway before push**
  ```bash
  # From Cambium repo root
  psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql
  ```
  - If `DATABASE_PUBLIC_URL` not set, get connection string from Railway dashboard

- [ ] **All critical tables have expected column counts**
  - `users`: 14 columns
  - `factory_orders`: 18 columns
  - `jobs`: verify exists
  - `laminates`: verify exists
  - `user_preferences`: verify exists

- [ ] **Any new EF entity class has a corresponding migration file**
  - Check: `Cambium.Data/Migrations/` for new migration
  - Migration naming: `YYYYMMDDHHMMSS_Description.cs`

- [ ] **That migration has been applied to Railway**
  - Check: `__EFMigrationsHistory` table on Railway
  - If missing: Run migration SQL manually before deploying code that depends on it

---

## Build

- [ ] **`dotnet build` — 0 errors**
  ```bash
  cd Cambium/src/Cambium.Api
  dotnet build
  ```

- [ ] **Pre-push git hook passed**
  - 0 new warnings beyond pre-existing 22 MSB3277 (duplicate assembly) warnings
  - If hook fails: Fix issues before pushing

- [ ] **`dotnet test` — 167 tests pass**
  ```bash
  cd Cambium
  dotnet test
  ```
  - If new test failures: Fix or document why they're acceptable

---

## Deploy

- [ ] **Rebase on latest main**
  ```bash
  git pull --rebase origin main
  ```
  - Resolves conflicts before pushing, not during Railway build

- [ ] **Push to main**
  ```bash
  git push origin main
  ```

- [ ] **Watch Railway deploy logs**
  - Railway dashboard → Cambium → Deployments → Latest
  - Wait for ACTIVE status
  - Check for startup errors (auth failures, missing tables)

- [ ] **Verify login at cambium.luxifysystems.com**
  - Test with your user account
  - If admin: Test admin login specifically

- [ ] **If `ADMIN_DEFAULT_PASSWORD` was set for this deploy: Remove it now**
  - Railway dashboard → Cambium → Variables → Delete ADMIN_DEFAULT_PASSWORD
  - Redeploy to confirm removal (password should persist)

---

## Post-Deploy Verification

- [ ] **Schema verification log line present**
  - Look for: `"Schema verification passed: all 14 user columns present"`
  - If missing or shows FATAL with missing columns: Investigate immediately

- [ ] **No 28P01 errors** (password authentication failed)
  - Cause: `DATABASE_URL` is hardcoded and password was rotated
  - Fix: Set `DATABASE_URL = ${{Postgres.DATABASE_URL}}`

- [ ] **No 42P01 errors** (relation does not exist)
  - Cause: Migration not applied or table dropped
  - Fix: Check which table is missing; run migration or recreate table

---

## Emergency Recovery Links

- Railway dashboard: https://railway.app/dashboard
- Cloudflare dashboard: https://dash.cloudflare.com
- Cambium production: https://cambium.luxifysystems.com
- Cambium API: https://cambium-production.up.railway.app

---

## Quick Reference: Common Deploy Failures

| Error | Cause | Fix |
|-------|-------|-----|
| 28P01 password auth failed | Hardcoded DATABASE_URL | Use `${{Postgres.DATABASE_URL}}` |
| JWT_SECRET_KEY required | Missing env var | Add to Railway Variables |
| 42P01 relation not found | Missing table/migration | Apply migration to Railway |
| FATAL: SCHEMA DRIFT | Self-heal couldn't add columns | Check ALTER TABLE permissions |
| 502 Bad Gateway | App crashed on startup | Check deploy logs for exception |
