---
name: dev-passwords
description: Create development/test user passwords with compatible bcrypt hashes. Use when seeding databases, creating test users, debugging authentication, or when login fails despite "correct" passwords.
---

# Dev Passwords

## The Golden Rule

**Always use the same bcrypt library the application uses.** Different implementations produce incompatible hashes.

## Quick Diagnosis

Login failing despite correct password? Check for library mismatch:

| App Stack | Library Used | Create Hash With |
|-----------|--------------|------------------|
| .NET / C# | BCrypt.Net-Next | .NET console or app's own endpoint |
| Node.js | bcryptjs or bcrypt | Node.js script |
| Python | bcrypt | Python script |
| PHP | password_hash() | PHP script |

## Find What Library an App Uses

```bash
# .NET - check csproj or search code
grep -r "BCrypt" --include="*.cs" --include="*.csproj" .

# Node.js - check package.json
grep -E "bcrypt|bcryptjs" package.json

# Python - check requirements
grep bcrypt requirements.txt
```

## Generate Compatible Hashes

### .NET (BCrypt.Net-Next)

```csharp
// In C# Interactive or console app
using BCrypt.Net;
Console.WriteLine(BCrypt.Net.BCrypt.HashPassword("YourPassword123!"));
```

Or use the app's seed migration / user creation endpoint.

### Node.js (bcryptjs)

```javascript
const bcrypt = require('bcryptjs');
bcrypt.hash('YourPassword123!', 11).then(console.log);
```

### Node.js (bcrypt - native)

```javascript
const bcrypt = require('bcrypt');
bcrypt.hash('YourPassword123!', 11).then(console.log);
```

### Python

```python
import bcrypt
print(bcrypt.hashpw(b'YourPassword123!', bcrypt.gensalt(rounds=11)).decode())
```

## Common Pitfalls

1. **bcryptjs ≠ BCrypt.Net** - Both start with `$2a$` but verification can fail
2. **Cost factor matters** - Match the app's rounds (usually 10-12)
3. **Check seed migrations** - Apps often have default admin credentials in migrations
4. **Case sensitivity** - Username lookup may be case-sensitive

## When Debugging Auth

1. Find the auth controller/service
2. Check which bcrypt library is imported
3. Look for seed migrations with default users
4. Use the app's own hash generation, not a different language

## Lessons Learned

### 1. Library Mismatch
We created a user with Node.js `bcryptjs` for a .NET app using `BCrypt.Net.BCrypt.Verify()`. Login failed. The seed migration had `admin` / `Admin123!` that worked because it used the right library.

### 2. Placeholder Hashes in Seed Migrations
A seed migration contained a placeholder hash that *looked* valid (`$2a$11$K3R4h...`) but wasn't actually a hash of the password. Login failed because the hash was never generated from the actual password string.

**Fix:** Generated a real hash with the same library the app uses:
```csharp
// .NET console app with BCrypt.Net-Next
Console.WriteLine(BCrypt.Net.BCrypt.HashPassword("Admin123!"));
// Output: $2a$11$ypLDNfJTRvkmtfaIm3X5.OrDEyn1h7yCsG8IpI2/yB9uiqc9JhGIK
```

Then updated the database directly:
```sql
UPDATE users SET password_hash = '$2a$11$ypLDNfJTRvkmtfaIm3X5.OrDEyn1h7yCsG8IpI2/yB9uiqc9JhGIK' WHERE username = 'admin';
```

**Tip:** If login works locally but not in production, the production DB may have the original (broken) seed hash. Always verify the hash in the database matches what you expect.
