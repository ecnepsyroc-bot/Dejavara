# Infrastructure as Code (IaC)

## What It Is

IaC manages infrastructure through code and version control rather than manual processes. Servers, networks, and configurations are defined in files that can be versioned, reviewed, and automated.

## Core Principles (Non-Negotiables)

- **Declarative definitions** — Describe desired state, not steps
- **Version controlled** — Infrastructure changes tracked in Git
- **Reproducible** — Same code produces same infrastructure
- **Automated provisioning** — No manual server setup
- **Immutable infrastructure** — Replace, dont modify

## How It Applies to Cambium

### Where We Align

- **Railway managed**: Platform handles infrastructure
- **Containerized**: Application runs in containers

### Where We Dont (NOT ADOPTED)

- **No Terraform/Pulumi**: No infrastructure code in repo
- **Railway dashboard config**: Settings managed in UI, not code
- **No environment templates**: Cant spin up identical environments

**Current state**:

- Railway manages: compute, networking, TLS
- Not in Git: Railway config, environment variables
- SQL migrations: in code (`src/Cambium.Data/Migrations/`)

### Compliance Desirable?

**Low priority.** Railway abstracts infrastructure. IaC valuable when:

- Self-hosting on cloud (AWS, Azure, GCP)
- Need multiple identical environments
- Compliance requires infrastructure audit trail

## Key Terms

| Term           | Definition                                        |
| -------------- | ------------------------------------------------- |
| Terraform      | HashiCorp IaC tool for multi-cloud                |
| Pulumi         | IaC with general-purpose languages                |
| CloudFormation | AWS-native IaC                                    |
| Declarative    | Describe end state, system figures out steps      |
| Imperative     | Describe steps to reach end state                 |
| State File     | Record of current infrastructure state            |
| Drift          | Difference between code and actual infrastructure |
| Immutable      | Replace infrastructure, dont modify in place      |
