# API-First Design

## What It Is

API-First treats the API as a first-class product. You design the API contract (OpenAPI/Swagger) before implementing it, allowing consumers to develop against the spec while the backend is built. The contract is the source of truth.

## Core Principles (Non-Negotiables)

- **Design before implement** — API spec comes before code
- **Contract as source of truth** — Spec drives implementation and documentation
- **Consumer-oriented** — Design for API consumers, not backend convenience
- **Versioning strategy** — Plan for API evolution from the start
- **Machine-readable spec** — OpenAPI, GraphQL SDL, or similar

## How It Applies to Cambium

### Where We Align

- **REST API**: Well-structured controllers with conventional routes
- **Consistent patterns**: Controllers follow similar structure across modules

**Evidence**:

- `src/Cambium.Api/Controllers/` — 46 controllers with REST patterns
- Endpoint patterns: `GET /api/jobs`, `POST /api/jobs`, `PUT /api/jobs/{id}`

### Where We Dont

- **No OpenAPI spec**: No `swagger.json` or `openapi.yaml` in repo
- **No API versioning**: Endpoints not versioned (`/api/v1/jobs`)
- **Implementation-first**: Controllers written, then consumed
- **No generated clients**: Frontend uses manual API calls

### Compliance Desirable?

**Moderate.** Consider if:

- External consumers need API access
- Multiple frontend teams consume the API
- API documentation is frequently requested

**Quick win**: Add Swashbuckle for auto-generated OpenAPI docs.

## Key Terms

| Term            | Definition                                            |
| --------------- | ----------------------------------------------------- |
| OpenAPI         | Specification format for REST APIs (formerly Swagger) |
| API Contract    | Machine-readable definition of API interface          |
| Swagger UI      | Interactive API documentation                         |
| Code Generation | Generate client SDKs from OpenAPI spec                |
| Breaking Change | API change that breaks existing consumers             |
| Versioning      | Strategy for evolving API (URL, header, query param)  |
| HATEOAS         | Hypermedia links in responses for discoverability     |
