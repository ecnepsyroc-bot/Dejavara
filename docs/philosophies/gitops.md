# GitOps

## What It Is

GitOps uses Git as the single source of truth for infrastructure and application configuration. Changes are made via pull requests, and automation ensures the running system matches the Git state. If something drifts, it is reconciled automatically.

## Core Principles (Non-Negotiables)

- **Git as source of truth** — Desired state stored in Git
- **Declarative configuration** — Describe what, not how
- **Automated reconciliation** — System converges to Git state
- **Pull-based deployment** — Cluster pulls changes, not push
- **Audit trail** — Git history shows all changes

## How It Applies to Cambium

### Where We Align

- **Code in Git**: All application code version-controlled
- **Audit trail**: Git history tracks all changes
- **Automated deployment**: Push to main triggers deployment

### Where We Dont

- **No declarative infrastructure**: Railway config not in Git
- **Push-based deployment**: Railway pulls from Git (close to GitOps)
- **No reconciliation**: If Railway state drifts, no auto-fix
- **No Kubernetes**: GitOps tools (ArgoCD, Flux) are K8s-focused

### Compliance Desirable?

**Low priority for current scale.** GitOps shines with:

- Kubernetes clusters
- Multi-environment deployments
- Team requiring audit/approval workflows

**Consider if** moving to self-hosted Kubernetes.

## Key Terms

| Term           | Definition                                     |
| -------------- | ---------------------------------------------- |
| Reconciliation | Process of converging actual to desired state  |
| Drift          | Difference between Git state and running state |
| ArgoCD         | GitOps continuous delivery tool for Kubernetes |
| Flux           | GitOps toolkit for Kubernetes                  |
| Pull-based     | System pulls changes vs being pushed           |
| Declarative    | Describing desired end state                   |
