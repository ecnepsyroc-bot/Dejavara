# Waterfall

## What It Is

Waterfall is a sequential software development methodology where each phase (requirements, design, implementation, testing, deployment) must be completed before the next begins. Changes are expensive because you cant easily go back to previous phases.

## Core Principles (Non-Negotiables)

- **Sequential phases** — Complete each phase before starting next
- **Comprehensive documentation** — Detailed specs before coding
- **Sign-offs** — Formal approval at phase gates
- **Big-bang delivery** — Ship everything at the end
- **Change control** — Formal process for requirement changes

## How It Applies to Cambium

### Where We Align

Minimal alignment — Cambium explicitly uses iterative development.

### Where We Dont

- **Iterative delivery**: Features ship incrementally, not big-bang
- **Evolving requirements**: Architecture changes mid-flight (hexagonal migration)
- **No phase gates**: No formal sign-offs between design and implementation
- **Continuous deployment**: Railway deploys on every push

### Compliance Desirable?

**No.** Waterfall is inappropriate for:

- Evolving requirements (ERP systems change constantly)
- Solo/small team development
- Modern tooling (CI/CD, cloud deployment)

## Key Terms

| Term                 | Definition                                         |
| -------------------- | -------------------------------------------------- |
| Requirements Phase   | Gathering and documenting all requirements upfront |
| Design Phase         | Creating system and detailed design documents      |
| Implementation Phase | Writing all code                                   |
| Verification Phase   | Testing the complete system                        |
| Maintenance Phase    | Post-deployment bug fixes and updates              |
| Phase Gate           | Formal review and approval between phases          |
| Change Request       | Formal document to modify requirements             |
