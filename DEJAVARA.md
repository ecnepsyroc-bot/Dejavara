# Dejavara Platform

> Monorepo for platform-wide tooling. Cambium is a standalone clone at `C:\Dev\Cambium`.

## Important

**Cambium is NOT a submodule.** It was removed from Dejavara on 2026-03-18.
The canonical dev repo is `C:\Dev\Cambium` (standalone clone).

## Layout

- `OpenClaw/` — AI controller (active development here)
- `Phteah-pi/` — Home server config (active development here)
- `AutoCAD-AHK/` — AutoCAD panning scripts
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
cd C:\Dev\Cambium
claude
```
