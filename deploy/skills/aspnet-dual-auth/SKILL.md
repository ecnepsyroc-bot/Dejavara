---
name: aspnet-dual-auth
description: Configure ASP.NET Core with dual JWT + Cookie authentication for APIs serving both SPAs and external clients. Use when login works but SPA keeps redirecting to signin, when cookies aren't being set, when 401s redirect instead of returning status codes, or when setting up authentication for a React/Vue/Angular SPA served from the same origin.
---

# ASP.NET Core Dual Authentication (JWT + Cookie)

When an API serves both SPAs (same-origin) and external clients (Bearer tokens), use a "Smart" policy scheme that auto-selects based on the request.

## The Problem

SPAs on the same origin should use cookies (HttpOnly, secure, no localStorage). External clients use JWT Bearer tokens. Default ASP.NET auth only supports one.

## Solution: Policy Scheme Selector

```csharp
// Program.cs
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = "Smart";
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
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
})
.AddCookie(options =>
{
    options.Cookie.Name = "YourApp.Auth";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    options.ExpireTimeSpan = TimeSpan.FromDays(30);
    options.SlidingExpiration = true;
    
    // CRITICAL: Return 401 instead of redirect for API calls
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
});
```

## Login Controller: Set Both JWT and Cookie

```csharp
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginRequest request)
{
    // ... validate credentials, get user ...
    
    var claims = new List<Claim>
    {
        new(ClaimTypes.NameIdentifier, user.Id.ToString()),
        new(ClaimTypes.Name, user.Username),
        new(ClaimTypes.Email, user.Email ?? "")
    };
    
    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
    var principal = new ClaimsPrincipal(identity);
    var expiresAt = DateTimeOffset.UtcNow.AddDays(30);
    
    // Set cookie for SPA
    await HttpContext.SignInAsync(
        CookieAuthenticationDefaults.AuthenticationScheme,
        principal,
        new AuthenticationProperties
        {
            ExpiresUtc = expiresAt,
            IsPersistent = true
        });
    
    // Return JWT for external clients
    var token = GenerateJwtToken(claims, expiresAt);
    
    return Ok(new { success = true, token, expiresAt });
}
```

## SPA Client Configuration

```typescript
// Axios
axios.defaults.withCredentials = true;

// Fetch
fetch('/api/endpoint', { credentials: 'include' });
```

Handle 401 by redirecting to login:
```typescript
axios.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      window.location.href = '/signin';
    }
    return Promise.reject(error);
  }
);
```

## Required Usings

```csharp
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Cookie not set | Missing `SignInAsync` | Add to login controller |
| 302 redirect on 401 | Default cookie behavior | Add `OnRedirectToLogin` event |
| CORS errors | Missing credentials | Set `withCredentials: true` |
| Cookie ignored | Wrong SameSite | Use `Lax` for same-origin |

## Session Persistence Across Deploys

Cookies are encrypted with DataProtection keys. If keys regenerate on deploy, sessions invalidate. See **aspnet-dataprotection-db** skill for database persistence.
