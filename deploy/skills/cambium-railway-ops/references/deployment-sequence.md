# Railway Deployment Sequence

## Pre-Push Checklist

**Complete ALL items before `git push origin main`:**

1. **Build passes:**
   ```bash
   dotnet build Cambium/Root.sln
   ```
   - 0 errors required
   - 22 MSB3277 warnings are pre-existing (EF Core version conflict) — acceptable

2. **Tests pass:**
   ```bash
   dotnet test Cambium/tests/Cambium.Tests.Unit
   ```
   - 167 tests expected

3. **Schema check clean:**
   ```bash
   psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql
   ```
   - All critical tables must show `OK`
   - `*** MISSING ***` on critical columns = **STOP** — apply `fix-railway-emergency.sql` first

4. **If new EF entity properties were added:**
   - Apply matching `ALTER TABLE` on Railway before pushing
   - Add to self-healing block in `Program.cs` if auth-critical
   - Record in `docs/migrations/manual/YYYYMMDD_Description.sql`

5. **Rebase before push:**
   ```bash
   git pull --rebase origin main
   ```

## Push

```bash
git push origin main
```

Railway auto-deploys within ~2 minutes.

## Post-Deploy Monitoring

Watch Railway deployment logs for:

| Log Entry | Status |
|-----------|--------|
| `Schema verification passed: all 14 user columns present` | OK |
| `Admin password reset from ADMIN_DEFAULT_PASSWORD env var` | OK (if intended) |
| `Cambium API starting on port 8080 in Production mode` | OK |
| `28P01: password authentication failed` | **FAIL** — DATABASE_URL is stale |
| `42P01: relation "users" does not exist` | **FAIL** — critical table missing |
| `42703: column "x" does not exist` on critical table | **FAIL** — schema drift |

## Post-Deploy Verification

1. Navigate to `cambium.luxifysystems.com`
2. Log in with admin credentials
3. Verify the feature you deployed works
4. Check Railway logs for any errors in the first few minutes

## Rollback

Railway keeps previous deployments. To rollback:

1. Railway dashboard > Cambium > Deployments
2. Find the last working deployment
3. Click "Redeploy"

Or revert the git commit and push:
```bash
git revert HEAD
git push origin main
```

## Submodule Push Order

If both Cambium and Dejavara have changes:

1. Push Cambium first: `cd Cambium && git push origin main`
2. Push Dejavara second: `cd .. && git push origin main`

This ensures the submodule ref exists on remote before the parent repo points to it.
