---
name: aspnet-dataprotection-db
description: Persist ASP.NET Core DataProtection encryption keys to PostgreSQL/SQL Server database. Use when user sessions invalidate after every deploy, when cookies stop working after app restart, when running on Railway/Heroku/ephemeral filesystems, or when authentication tokens become invalid after deployment.
---

# DataProtection Key Persistence to Database

ASP.NET Core encrypts cookies and tokens with DataProtection keys. By default, keys are stored in the filesystem and regenerate on deploy, invalidating all user sessions.

## The Problem

On ephemeral platforms (Railway, Heroku, Azure App Service, Docker), the filesystem resets on each deploy. New keys = all existing cookies invalid = users logged out.

## Solution: Store Keys in Database

### 1. Add NuGet Package

```bash
dotnet add package Microsoft.AspNetCore.DataProtection.EntityFrameworkCore
```

### 2. Update DbContext

```csharp
using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;

public class AppDbContext : DbContext, IDataProtectionKeyContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    
    public DbSet<DataProtectionKey> DataProtectionKeys => Set<DataProtectionKey>();
    
    // ... other DbSets ...
}
```

### 3. Configure in Program.cs

```csharp
builder.Services.AddDataProtection()
    .SetApplicationName("YourAppName")
    .PersistKeysToDbContext<AppDbContext>();
```

### 4. Create Migration

```bash
dotnet ef migrations add AddDataProtectionKeys
dotnet ef database update
```

Or apply via Railway/production:
```bash
dotnet ef database update --connection "Host=...;Database=...;..."
```

## Created Table

The migration creates a `data_protection_keys` table (snake_case with EF Core conventions):

| Column | Type | Purpose |
|--------|------|---------|
| id | int | Primary key |
| friendly_name | text | Key identifier |
| xml | text | Encrypted key data |

## Package Version Alignment

`DataProtection.EntityFrameworkCore` depends on a specific EF Core version. If you get version conflicts:

```xml
<!-- Cambium.Data.csproj -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.*" />
<PackageReference Include="Microsoft.AspNetCore.DataProtection.EntityFrameworkCore" Version="8.0.*" />
```

Update all projects referencing EF Core to the same major.minor version.

## Complete Example

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddDataProtection()
    .SetApplicationName("MyApp")
    .PersistKeysToDbContext<AppDbContext>();

builder.Services.AddAuthentication(...)
    .AddCookie(options => {
        options.Cookie.Name = "MyApp.Auth";
        options.ExpireTimeSpan = TimeSpan.FromDays(30);
    });
```

## Verification

After deploying, check the table has keys:
```sql
SELECT id, friendly_name, created_at FROM data_protection_keys;
```

Deploy again, then verify users remain logged in.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Sessions still invalidate | Migration not applied | Run `ef database update` |
| Table doesn't exist | Missing `IDataProtectionKeyContext` | Add interface to DbContext |
| Version conflict | EF Core mismatch | Align all packages to same 8.0.* |
| Keys not persisting | Wrong DbContext registered | Check DI registration order |

## Railway-Specific Notes

- Railway uses ephemeral filesystem (keys lost on deploy)
- PostgreSQL persists across deploys
- Connection string from `DATABASE_URL` environment variable
- EF Core uses snake_case by default: `data_protection_keys` not `DataProtectionKeys`
