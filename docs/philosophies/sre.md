# Site Reliability Engineering (SRE)

## What It Is

SRE applies software engineering practices to operations problems. Originated at Google, it uses SLIs, SLOs, and error budgets to balance reliability with feature development. SREs automate operations tasks and treat infrastructure as code.

## Core Principles (Non-Negotiables)

- **SLIs/SLOs** — Measurable service level indicators and objectives
- **Error budgets** — Acceptable unreliability budget for risk-taking
- **Toil reduction** — Automate repetitive manual work
- **Blameless postmortems** — Learn from failures without blame
- **Software engineering approach** — Apply coding to ops problems

## How It Applies to Cambium

### Where We Align

- **Health endpoint**: `HealthController.cs` for basic health checks
- **Automation**: Deployment automated via Railway

### Where We Dont (NOT ADOPTED)

- **No SLIs/SLOs defined**: No formal reliability targets
- **No error budget**: No quantified acceptable downtime
- **No on-call rotation**: Solo context
- **No incident management**: No PagerDuty, Opsgenie, etc.
- **Limited observability**: Basic logging, no distributed tracing

### Compliance Desirable?

**Selective adoption.** For current scale:

- **Define basic SLO**: e.g., 99% availability monthly
- **Add structured logging**: Serilog with context
- **Health checks**: Expand beyond basic ping

Full SRE practices (error budgets, on-call) appropriate for larger teams.

## Key Terms

| Term         | Definition                                           |
| ------------ | ---------------------------------------------------- |
| SLI          | Service Level Indicator — metric of service health   |
| SLO          | Service Level Objective — target for SLI             |
| SLA          | Service Level Agreement — contract with consequences |
| Error Budget | Allowed unreliability (100% - SLO)                   |
| Toil         | Repetitive, automatable operational work             |
| Postmortem   | Analysis of incident to prevent recurrence           |
| On-Call      | Rotation of responders for incidents                 |
| MTTR         | Mean Time to Recovery                                |
| MTTF         | Mean Time to Failure                                 |
