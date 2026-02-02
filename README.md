# Dejavara

Personal platform ecosystem with OpenClaw as central AI controller.

## Structure

```
Dejavara/
├── OpenClaw/        ← Central AI assistant (Claude API)
├── Cambium/         ← Work domain (millwork automation)
├── Phteah-pi/       ← Home domain (Raspberry Pi server)
└── FileOrganizer/   ← Shared file organization utility
```

## Domains

| Domain | Purpose | Tech Stack |
|--------|---------|------------|
| **OpenClaw** | Central AI controller | TypeScript, Claude API |
| **Cambium** | Work - Millwork factory automation | C#/.NET, React, PostgreSQL |
| **Phteah-pi** | Home - Raspberry Pi server | Docker, Traefik, Home Assistant |
| **FileOrganizer** | Shared - File organization CLI | C#/.NET |

## Setup

```bash
# Clone with all submodules
git clone --recursive https://github.com/ecnepsyroc-bot/Dejavara.git

# Or if already cloned, initialize submodules
git submodule update --init --recursive
```

## Working with Submodules

```bash
# Update all submodules to latest
git submodule update --remote --merge

# Work in a specific domain
cd Cambium
git checkout main
# make changes, commit, push

# Update parent to track new submodule commits
cd ..
git add Cambium
git commit -m "Update Cambium submodule"
```
