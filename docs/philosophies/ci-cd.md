# CI/CD (Continuous Integration / Continuous Deployment)

## What It Is

CI/CD automates the process of integrating code changes and deploying to production. Continuous Integration merges and tests code frequently. Continuous Deployment automatically releases every change that passes tests.

## Core Principles (Non-Negotiables)

- **Frequent integration** — Merge code multiple times per day
- **Automated builds** — Every commit triggers a build
- **Automated tests** — Tests run on every build
- **Fast feedback** — Know within minutes if something is broken
- **Always deployable** — Main branch is always production-ready

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Continuous Deployment**:

- Push to main -> Railway auto-builds -> Auto-deploys
- No manual deployment steps
- No staging environment (straight to production)

**Evidence**:

- Railway connected to GitHub repo
- Every push to `main` triggers deployment
- Lint-staged runs Prettier on commit

### Where We Dont

- **No automated tests in pipeline**: Tests exist but not gated
- **No test coverage requirements**: No coverage thresholds
- **Manual migrations**: DB migrations not auto-applied
- **No staging environment**: Direct to production

### Compliance Desirable?

**Strengthen.** Recommended improvements:

- Add test execution to Railway build
- Auto-apply migrations on startup
- Consider staging environment for risky changes

## Key Terms

| Term         | Definition                                              |
| ------------ | ------------------------------------------------------- |
| CI           | Continuous Integration — frequent merging and testing   |
| CD           | Continuous Deployment — automated release to production |
| Pipeline     | Sequence of automated steps                             |
| Build        | Compilation and packaging step                          |
| Gate         | Checkpoint that must pass to proceed                    |
| Artifact     | Output of build process (binary, container)             |
| Green Build  | Build where all steps pass                              |
| Broken Build | Build that failed some step                             |
