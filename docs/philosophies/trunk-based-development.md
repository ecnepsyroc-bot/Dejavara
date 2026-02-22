# Trunk-Based Development

## What It Is

Trunk-Based Development has all developers commit to a single branch (trunk/main). Instead of long-lived feature branches, changes are small and integrated frequently. Feature flags control incomplete features in production.

## Core Principles (Non-Negotiables)

- **Single shared branch** — Everyone commits to main/trunk
- **Short-lived branches** — Branch lifespan measured in hours, not days
- **Frequent integration** — Commit multiple times per day
- **Feature flags** — Hide incomplete features in production
- **Always deployable** — Trunk is always production-ready

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Single branch workflow**:

- All development on `main` branch
- No long-lived feature branches observed
- Frequent, small commits
- Railway auto-deploys from main

**Evidence**:

- Git log shows regular commits to main
- No PR-based workflow (solo context)
- Direct push to production

### Where We Dont

- **No feature flags**: Incomplete features not hidden behind flags
- **No branch protection**: Can push anything to main

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Consider:

- Feature flags for larger changes
- Branch protection if team grows

## Key Terms

| Term                   | Definition                                               |
| ---------------------- | -------------------------------------------------------- |
| Trunk                  | Main shared branch (also called main, master)            |
| Feature Branch         | Short-lived branch for single feature                    |
| Feature Flag           | Toggle to enable/disable features                        |
| Release Branch         | Branch cut for release stabilization                     |
| Continuous Integration | Frequently merging to trunk                              |
| Green Build            | All tests passing on trunk                               |
| Git Flow               | Alternative with long-lived branches (opposite approach) |
