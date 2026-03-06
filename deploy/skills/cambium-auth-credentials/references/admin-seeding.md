# Admin Password Seeding

## Current Behavior (Fixed)

The admin password seeding has two mechanisms:

1. **Fallback seeding** (Program.cs lines 676-704) — seeds admin on fresh DB, repairs corrupted hashes
2. **Emergency override** (Program.cs lines 1192-1211) — `ADMIN_DEFAULT_PASSWORD` env var

This document covers the emergency override mechanism.

## `EnsureAdminPasswordFromEnvAsync` Function

**Location:** `src/Cambium.Api/Program.cs` lines 1192-1211

```csharp
static async Task EnsureAdminPasswordFromEnvAsync(IServiceProvider services)
{
    var adminPassword = Environment.GetEnvironmentVariable("ADMIN_DEFAULT_PASSWORD");
    if (string.IsNullOrEmpty(adminPassword)) return;

    using var scope = services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<CambiumDbContext>();

    var admin = await dbContext.Users.FirstOrDefaultAsync(u => u.Username == "admin");
    if (admin == null) return;

    // Always reset when env var is set — this is an intentional override mechanism.
    admin.PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword);
    admin.FailedLoginAttempts = 0;
    admin.LockoutUntil = null;
    await dbContext.SaveChangesAsync();
    Log.Warning("Admin password reset from ADMIN_DEFAULT_PASSWORD env var — remove env var after recovery");
}
```

## Two Code Paths

### Path 1: Env var absent or empty (No-op)

**Condition:** `ADMIN_DEFAULT_PASSWORD` env var is not set or is empty string

**Behavior:** Silent return at line 1194-1195. No log message. Password unchanged.

**This is normal operation.** UI password changes persist across deploys.

### Path 2: Env var set (Override)

**Condition:** `ADMIN_DEFAULT_PASSWORD` env var contains any non-empty value

**Behavior:**
1. Hash the env var value with BCrypt
2. Overwrite admin's `PasswordHash`
3. Reset `FailedLoginAttempts` to 0
4. Clear `LockoutUntil` to null (unlocks account)
5. Save changes
6. Log warning: `"Admin password reset from ADMIN_DEFAULT_PASSWORD env var — remove env var after recovery"`

**Log level:** Warning (shows in Railway logs by default)

## Why "Always Overwrite"?

There is **NO hash-gate** — the function does not check if the existing password is valid, corrupted, or matches any particular hash. This is intentional:

1. **Explicit opt-in:** Setting `ADMIN_DEFAULT_PASSWORD` is a deliberate operator action
2. **Emergency recovery:** When admin is locked out, you need guaranteed reset
3. **Simplicity:** No conditional logic that could silently fail

The fallback seeding (lines 676-704) handles corrupted hashes separately — it only repairs hashes that are NULL, empty, or don't start with `$2` (invalid BCrypt format).

## Warning: Continuous Reset

> **If `ADMIN_DEFAULT_PASSWORD` is set in Railway Variables and you push to Railway, the admin password resets on every deploy. Remove it immediately after recovery.**

This is the most common mistake: setting the env var, confirming login works, then forgetting to remove it. Six months later, an admin changes their password via UI, you deploy an unrelated fix, and the password silently reverts.

## Recovery Procedure

### When: Admin locked out on Railway, password unknown, can't login

1. **Set env var in Railway:**
   - Railway dashboard → Cambium service → Variables
   - Add: `ADMIN_DEFAULT_PASSWORD` = `<your-new-password>`
   - Click "Deploy" or wait for auto-deploy

2. **Watch deploy logs:**
   - Look for: `"Admin password reset from ADMIN_DEFAULT_PASSWORD env var — remove env var after recovery"`
   - If you see this, the password was updated

3. **Test login:**
   - Go to `https://cambium.luxifysystems.com`
   - Login with username `admin` and your new password

4. **Remove the env var immediately:**
   - Railway dashboard → Cambium service → Variables
   - Delete `ADMIN_DEFAULT_PASSWORD`
   - Redeploy to confirm it's gone

5. **Verify removal:**
   - Check deploy logs — the warning message should NOT appear
   - Password now persists through future deploys

## Troubleshooting

### "ADMIN_DEFAULT_PASSWORD is set but password isn't changing"

1. **Check the env var value isn't empty** — whitespace-only values may be treated as empty
2. **Check deploy actually completed** — look for ACTIVE status in Railway
3. **Check logs for the warning message** — if it's there, password was updated
4. **Are you logging in as "admin"?** — this only affects username `admin`, not other accounts

### "Password keeps reverting after I change it in UI"

You forgot to remove `ADMIN_DEFAULT_PASSWORD` from Railway Variables. Remove it now.

### "Lockout cleared but still can't login"

The password hash was updated but you're using the old password. Use the new password from the env var.

## Related: Fallback Seeding

The fallback seeding (lines 676-704) is different:

- Uses `CAMBIUM_ADMIN_PASSWORD` env var (different name!)
- Only seeds admin if missing
- Only repairs corrupted hashes (NULL, empty, or non-BCrypt)
- Does NOT overwrite valid BCrypt hashes
- Always runs on startup (not emergency-only)

For emergency override, always use `ADMIN_DEFAULT_PASSWORD`, not `CAMBIUM_ADMIN_PASSWORD`.
