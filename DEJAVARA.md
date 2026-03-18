# Dejavara Platform

> Monorepo for platform-wide tooling. Cambium lives separately.

## Important

**Cambium development happens at `C:\Users\cory\repos\Cambium\` — NOT in this submodule.**

The Cambium submodule here is a secondary reference copy only.

## Layout

- `Cambium/` — Submodule reference (secondary — DO NOT develop here)
- `OpenClaw/` — AI controller (active development here)
- `Phteah-pi/` — Home server config (active development here)
- `deploy/` — Syncthing-managed, syncs to Phteah-Pi
- `scripts/` — Platform-wide scripts (not Cambium-specific)

## Machines

| Machine | IP | Role | SSH |
|---------|-----|------|-----|
| DEJAVARA | DHCP | Dev primary | (this machine) |
| Cambium-Server | 192.168.0.108 | Prod SSOT | cambium-server-tunnel |
| Phteah-Pi | 192.168.1.76 | Home server | phteah-pi |

## For Cambium Work

```powershell
cd C:\Users\cory\repos\Cambium
claude
```
