# JWT + Cookie Dual Authentication

Cambium serves both a vanilla JS SPA (same-origin) and external API clients. The "Smart" policy scheme auto-selects JWT or Cookie based on the request.

## The PolicyScheme

**Location:** `Program.cs` lines 201-214

```csharp
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = "Smart";
    options.DefaultChallengeScheme = "Smart";
})
.AddPolicyScheme("Smart", "JWT or Cookie", options =>
{
    options.ForwardDefaultSelector = context =>
    {
        var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
        if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer "))
            return JwtBearerDefaults.AuthenticationScheme;
        return CookieAuthenticationDefaults.AuthenticationScheme;
    };
})
```

**Decision logic:**
1. Check for `Authorization` header
2. If header exists AND starts with `"Bearer "` (case-sensitive, note the space) → use JWT
3. Otherwise → use Cookie

**Consequence:** Requests without an Authorization header use cookies. The SPA uses `credentials: 'include'` to send cookies automatically.

## JWT Configuration

### Claims

| Claim Key | Source Property | Purpose |
|-----------|-----------------|---------|
| `ClaimTypes.NameIdentifier` | `user.UserId` | User ID for DB lookups and authorization |
| `ClaimTypes.Name` | `user.Username` | Username for display and audit logging |
| `ClaimTypes.Role` | `user.Role` | Role-based authorization (`admin`, `viewer`, etc.) |
| `"userType"` | `user.UserType` (enum) | Access tier: Management, Shop, Office |
| `JwtRegisteredClaimNames.Jti` | `Guid.NewGuid()` | Unique token ID (for revocation, not currently used) |

### Signing

| Property | Value |
|----------|-------|
| Algorithm | `HS256` (HmacSha256) |
| Key (env var) | `JWT_SECRET_KEY` |
| Key (fallback) | `Jwt:Key` in appsettings |
| Issuer | `"Cambium"` (configurable) |
| Audience | `"CambiumUsers"` (configurable) |
| Default expiry | 1440 minutes (24 hours) |

**Key retrieval (Program.cs lines 187-193):**
```csharp
var jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")
    ?? builder.Configuration["Jwt:Key"];
if (string.IsNullOrEmpty(jwtKey))
{
    throw new InvalidOperationException("JWT_SECRET_KEY environment variable or Jwt:Key config is required");
}
```

### What Happens When JWT Key Changes

**All existing tokens become invalid.** Users must re-login.

The key is used to sign and verify tokens. If the signing key changes, tokens signed with the old key fail verification with a signature mismatch error.

**Mitigation:** On Railway, set `JWT_SECRET_KEY` once and never change it unless you intend to invalidate all sessions.

## Cookie Configuration

**Location:** `Program.cs` lines 216-224

| Property | Value | Notes |
|----------|-------|-------|
| Name | `Cambium.Auth` | Cookie identifier |
| HttpOnly | `true` | JavaScript cannot access (XSS protection) |
| SameSite | `Lax` | Sent with top-level navigation, blocked in cross-site POST |
| SecurePolicy | `SameAsRequest` | HTTPS in production, HTTP allowed in development |
| Path | `"/"` | Available on all routes |
| ExpireTimeSpan | 30 days | Maximum session duration |
| SlidingExpiration | `true` | Every request resets the 30-day timer |

### Sliding Expiration

The cookie expiry resets on every successful request. If the user is active, they stay logged in indefinitely. If inactive for 30+ days, they must re-login.

### 401 vs Redirect

**Critical configuration (lines 54-66):**
```csharp
options.Events = new CookieAuthenticationEvents
{
    OnRedirectToLogin = context =>
    {
        context.Response.StatusCode = 401;
        return Task.CompletedTask;
    },
    OnRedirectToAccessDenied = context =>
    {
        context.Response.StatusCode = 403;
        return Task.CompletedTask;
    }
};
```

This overrides ASP.NET's default behavior of redirecting to `/Account/Login`. Instead, API endpoints return 401/403 status codes that the SPA handles.

## DataProtection (Cookie Encryption)

**Location:** `Program.cs` lines 158-161

```csharp
builder.Services.AddDataProtection()
    .SetApplicationName("Cambium")
    .PersistKeysToDbContext<CambiumDbContext>();
```

### DataProtection Table

| Property | Value |
|----------|-------|
| Table name | `DataProtectionKeys` |
| Database | Same PostgreSQL as Cambium |
| Auto-created | Yes (line 725) |
| Columns | `Id` (serial), `FriendlyName` (text), `Xml` (text) |

**Auto-creation SQL (line 725):**
```sql
CREATE TABLE IF NOT EXISTS "DataProtectionKeys"
  ("Id" SERIAL PRIMARY KEY, "FriendlyName" TEXT, "Xml" TEXT)
```

### What Happens If Table Is Missing/Empty

1. App tries to create table on startup
2. If creation fails, logs warning but continues
3. **Cookies encrypted with old keys cannot be decrypted**
4. Users see session expired / must re-login

**When this happens:**
- Railway PostgreSQL database recreated
- Table accidentally dropped
- App deployed to new database

**Fix:** Let the app auto-create the table, then all users re-login once.

## Frontend Auth (app.js)

### authFetch Helper (lines 383-396)

```javascript
async function authFetch(url, options = {}) {
  const res = await fetch(url, { ...options, credentials: 'include' })
  if (res.status === 401) {
    sessionStorage.removeItem('cambium_authenticated')
    currentUser = null
    isAuthenticated = false
    if (chatApp) chatApp.style.display = 'none'
    const loginModal = document.getElementById('login-modal')
    if (loginModal) loginModal.style.display = 'flex'
    showLoginError('Session expired — please sign in again')
  }
  return res
}
```

**Key points:**
- `credentials: 'include'` sends cookies with every request
- Global 401 interceptor shows login modal on session expiry
- Uses `sessionStorage` (cleared on browser close, not persistent)

### Login Response

```javascript
return Ok(new LoginResponseDto
{
    Success = true,
    Token = token,           // JWT for external clients
    ExpiresAt = expiresAt,   // DateTime (UTC)
    LandingPage = user.UserType.GetLandingPage(),
    MustChangePassword = user.MustChangePassword,
    User = new UserDto { ... }
});
```

The SPA **ignores the JWT token** for normal requests (uses cookies). The token is only used for:
- First-time password change (`MustChangePassword = true`)
- External API integrations

## SignalR

SignalR uses **cookie authentication only** (no JWT). The WebSocket connection negotiates using the same `Cambium.Auth` cookie.

**Cross-origin WebSocket:** If SignalR needs to connect from a different origin, cookies won't work due to SameSite. This is not currently a concern (SPA is same-origin).

## Rate Limiting

**Login endpoint:** 5 attempts per minute per IP

**Location:** `Program.cs` lines 537-549

**Account lockout:** 5 failed attempts → 15-minute lockout (handled in AuthController)

## Common Issues

### 401 after deploy

**Cause:** DataProtection keys changed (new database, table dropped)

**Fix:** Users must re-login. No action needed.

### Cookie not being set

**Cause:** `SignInAsync` not called in login controller

**Check:** AuthController login flow calls `HttpContext.SignInAsync()`

### CORS errors with credentials

**Cause:** `withCredentials: true` but CORS not configured for credentials

**Check:** `AllowCredentials()` in CORS policy (Program.cs)

### JWT signature invalid

**Cause:** `JWT_SECRET_KEY` changed or different between instances

**Fix:** Ensure all instances use the same key
