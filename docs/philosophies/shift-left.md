# Shift Left

## What It Is

Shift Left moves testing, security, and quality activities earlier ("left") in the development lifecycle. Instead of finding bugs in production, find them during development. The earlier you find a problem, the cheaper it is to fix.

## Core Principles (Non-Negotiables)

- **Test early** — Write tests during development, not after
- **Security early** — Security reviews and scanning in development
- **Fail fast** — Catch issues before they reach production
- **Developer ownership** — Developers responsible for quality
- **Automated gates** — CI blocks bad code from merging

## How It Applies to Cambium

### Where We Align

- **Unit tests exist**: `tests/Cambium.Tests.Unit/`
- **Lint on commit**: Prettier runs via lint-staged
- **Type safety**: TypeScript on frontend, C# on backend

### Where We Dont

- **No security scanning**: No SAST/DAST in pipeline
- **No dependency scanning**: No Dependabot, Snyk
- **Tests not gated**: Can push without passing tests
- **No code review**: Solo context, no PR process

### Compliance Desirable?

**Yes — strengthen.** Recommended:

- **Add SAST scanning**: CodeQL, SonarQube
- **Enable Dependabot**: Automated security updates
- **Gate on tests**: Require passing tests to deploy

## Key Terms

| Term         | Definition                                          |
| ------------ | --------------------------------------------------- |
| Shift Left   | Move quality activities earlier in lifecycle        |
| SAST         | Static Application Security Testing (code analysis) |
| DAST         | Dynamic Application Security Testing (runtime)      |
| SCA          | Software Composition Analysis (dependencies)        |
| Quality Gate | Checkpoint requiring quality criteria               |
| Fail Fast    | Detect problems early when cheap to fix             |
| DevSecOps    | Integrating security into DevOps                    |
