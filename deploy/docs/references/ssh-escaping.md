# SSH Escaping for Agentic Workflows

When executing SSH commands to Windows servers (cambium-server), there are 4 escaping layers:
1. Local Bash (Git Bash on Windows, or Linux shell)
2. SSH transport
3. Remote cmd.exe
4. Remote PowerShell (if used)

## Key Rules

### Simple commands (no $ variables)
Double quotes work fine:
```bash
ssh cambium-server-tunnel "schtasks /run /tn TaskName"
ssh cambium-server-tunnel "dir C:\tmp"
```

### Commands with $_ or $env:
Use SINGLE quotes outer to prevent local bash interpretation:
```bash
ssh cambium-server-tunnel 'powershell -Command "Get-Service | Where-Object { $_.Name -like \"*Cambium*\" }"'
```

### NEVER do this
```bash
# WRONG - $_ gets mangled by local bash to extglob.Name
ssh cambium-server-tunnel "powershell -Command ... $_.Name ..."
```

## Cambium Hosts

| Alias | Access | Use |
|-------|--------|-----|
| `cambium-server` | Shop LAN only | 192.168.0.108 |
| `cambium-server-tunnel` | Anywhere | Via Cloudflare |

## Fallback: Batch Files

When escaping gets too complex, create a batch file on the server:
```bash
# Create the batch file
ssh cambium-server-tunnel 'echo @echo off > C:\tmp\run.bat && echo YOUR_COMMAND_HERE >> C:\tmp\run.bat'

# Run it
ssh cambium-server-tunnel "C:\tmp\run.bat"
```

## Quick Reference

| Scenario | Pattern |
|----------|---------|
| Simple cmd | `ssh host "command"` |
| PowerShell with $ | `ssh host 'powershell -Command "... $_.Name ..."'` |
| Complex escaping | Create batch file on server |
| psql via SSH | Interactive: `ssh host` then run psql |
