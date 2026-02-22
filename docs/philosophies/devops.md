# DevOps

## What It Is

DevOps is a culture and set of practices that unifies development and operations. It emphasizes automation, continuous delivery, monitoring, and shared responsibility. The goal is to ship faster with higher quality through collaboration and tooling.

## Core Principles (Non-Negotiables)

- **Culture of collaboration** — Dev and Ops work together, shared ownership
- **Automation** — Automate builds, tests, deployments, infrastructure
- **Continuous improvement** — Measure, learn, iterate
- **Infrastructure as Code** — Version-controlled, reproducible infrastructure
- **Monitoring and feedback** — Know what is happening in production

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Automated deployments**:

- Railway auto-deploys on push to main
- No manual deployment steps
- Single branch deployment strategy

**Evidence**:

- Push to `main` -> Railway builds -> Auto-deploys to production
- Environment variables managed in Railway dashboard

### Where We Dont

- **No formal ops team**: Solo/small team context
- **Limited monitoring**: Basic Railway metrics, no custom dashboards
- **Manual migrations**: DB migrations not auto-applied
- **No runbooks**: Incident response not documented

### Compliance Desirable?

**Partially — appropriate for scale.** Improvements to consider:

- Auto-apply migrations on deploy
- Add structured logging (already using Serilog)
- Create runbooks for common issues

## Key Terms

| Term                  | Definition                                      |
| --------------------- | ----------------------------------------------- |
| CI/CD                 | Continuous Integration / Continuous Deployment  |
| Pipeline              | Automated workflow from code to production      |
| IaC                   | Infrastructure as Code                          |
| Runbook               | Documented procedure for operations tasks       |
| Observability         | Ability to understand system state from outputs |
| Mean Time to Recovery | Average time to restore service after failure   |
| Blameless Postmortem  | Learning from failures without assigning blame  |
