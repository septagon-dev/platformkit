# Module Normalization Program

## Scope

This program applies only to:

- `septagon-dev/platformkit-business-modules`
- `septagon-dev/platformkit-backend-kit`
- `septagon-dev/platformkit-frontend-kit`
- `septagon-dev/platformkit`
- `septagon-clients/*` where client overrides depend on module contracts

Reference repositories under `ComumCowork/*` are not delivery targets.

## Goal

Make every PlatformKit business module conform to one explicit product-grade
contract for:

- structure
- routes
- permissions
- fine-grained access control
- events
- internationalization
- ports and dependency boundaries
- admin integration
- PWA and client-state policy declarations where applicable

## Definition of Normalized

A module is normalized only when all of the following are true:

1. structure is canonical and passes conformance checks
2. routes are declared in contracts and consumed from contracts
3. permissions are explicit at module and feature level
4. admin pages and actions declare permission coverage
5. domain events are declared, namespaced, and documented
6. translations are owned by the module and override-friendly
7. cross-module dependencies use `ports/` and declared contract adapters
8. DI wiring is explicit and testable
9. module manifests and docs match runtime behavior
10. regression checks prevent drift

## Non-Goals

- one-off cosmetic cleanup without guardrails
- module-specific special cases that bypass the shared contract model
- direct implementation work in `ComumCowork/*`

## Canonical Module Shape

Each module should converge on this shape:

```text
module_name/
├── module.go
├── metadata.go
├── dependencies.go
├── events.go
├── invocations.go
├── admin.go
├── providers.go
├── migrations.go
├── module.manifest.yaml
├── README.md
├── contracts/
│   ├── module.go
│   ├── permissions.go
│   ├── routes.go
│   ├── providers.go
│   └── provides/
├── features/
│   └── feature_name/
│       ├── feature.go
│       ├── handler.go
│       ├── service.go
│       ├── permissions.go
│       └── routes.go
└── translations/
```

Modules may add specialized files, but they should not collapse the canonical
concerns back into `module.go` or ad hoc helpers.

## Workstreams

### W1 Structure and Contract Conformance

Goal: make module structure machine-verifiable.

Deliverables:

- canonical required file set
- `contracts/module.go`, `contracts/permissions.go`, and `contracts/routes.go`
- feature-level `permissions.go` and `routes.go`
- conformance checker for missing files and forbidden inline route literals

Primary repo:

- `platformkit-business-modules`

### W2 Fine-Grained Access Control

Goal: make authorization explicit and auditable.

Deliverables:

- module-level permission vocabulary in `contracts/permissions.go`
- feature-level permission declarations in `features/*/permissions.go`
- handler and admin action permission coverage
- route-to-permission mapping checks
- admin capability alignment with runtime authz

Primary repos:

- `platformkit-business-modules`
- `platformkit-backend-kit`

### W3 Event Contracts

Goal: make all domain events declared, namespaced, and consumable.

Deliverables:

- `events.go` per module
- canonical event naming rules
- payload and consumer documentation in manifests or docs
- event-to-invalidation-tag mapping where relevant
- conformance checks for mutation-heavy features missing events

Primary repos:

- `platformkit-business-modules`
- `platformkit-backend-kit`

### W4 Internationalization

Goal: make translations module-owned and client-override friendly.

Deliverables:

- in-module translation assets as defaults
- explicit translation key namespace conventions
- no large user-facing inline strings in runtime code
- client override guidance and merge rules
- checks for missing translation assets in flagship modules

Primary repos:

- `platformkit-business-modules`
- `platformkit`
- `septagon-clients/*`

### W5 Ports and Dependency Boundaries

Goal: eliminate direct module-to-module coupling.

Deliverables:

- declared dependencies in `dependencies.go`
- adapters in module-local `providers.go` or `contracts/provides`
- conformance checks for forbidden direct imports
- split-repo safe dependency graph

Primary repos:

- `platformkit-business-modules`
- `platformkit-backend-kit`

### W6 Admin and Surface Integration

Goal: make admin surfaces structurally consistent across modules.

Deliverables:

- standardized admin provider shape
- contract-driven admin routes
- admin section metadata from module contracts
- permission-aware admin actions
- route and capability alignment checks

Primary repos:

- `platformkit-business-modules`
- `platformkit-frontend-kit`

### W7 Regression Gates

Goal: lock the normalized shape in place.

Deliverables:

- structure checker
- permissions checker
- events checker
- i18n checker
- forbidden inline route/import checker
- targeted module integration tests

Primary repos:

- `platformkit-business-modules`
- `platformkit-backend-kit`
- `platformkit-tests`

## Milestones

### M1 Contract Freeze

Goal: freeze the normalization target.

Tasks:

1. Publish canonical module shape and required files
2. Publish permission naming rules and scope rules
3. Publish event naming and payload rules
4. Publish i18n ownership and override rules
5. Publish ports and dependency boundary rules

### M2 Conformance Tooling

Goal: make the shape enforceable.

Tasks:

1. Extend structure checker for canonical files
2. Add forbidden inline route literal check
3. Add forbidden direct cross-module import check
4. Add permission coverage checker
5. Add event declaration checker
6. Add i18n asset presence checker

### M3 Access Control Normalization

Goal: make authorization complete and explicit.

Tasks:

1. Normalize module-level permission vocabularies
2. Normalize feature-level `permissions.go`
3. Map admin routes and actions to permissions
4. Validate mutation routes for permission coverage
5. Align admin capabilities with runtime authz model

### M4 Event Normalization

Goal: make module events first-class contracts.

Tasks:

1. Add or normalize `events.go` for all modules
2. Standardize event names and namespaces
3. Add missing events for mutation-heavy features
4. Map events to invalidation tags where needed
5. Document event contracts in module manifests or docs

### M5 Internationalization Normalization

Goal: make localization scalable and client-safe.

Tasks:

1. Move default translations into modules
2. Normalize translation key namespaces
3. replace inline user-facing strings in runtime code
4. define client override merge model
5. validate flagship modules for translation completeness

### M6 Boundary and Integration Hardening

Goal: make modules composable and split-repo safe.

Tasks:

1. remove remaining direct module-to-module imports
2. add missing `ports/` interfaces and adapters
3. validate DI contracts and provider wiring
4. add targeted module integration tests

### M7 Release Gates

Goal: keep the repo normalized.

Tasks:

1. wire all conformance checks into CI
2. fail PRs on structural regressions
3. publish authoring docs for new modules
4. add release criteria for normalized modules only

## Repo Task Map

### `platformkit-business-modules`

1. Freeze canonical module shape
2. Add structure, permissions, events, and i18n conformance checks
3. Normalize fine-grained access control across all modules
4. Normalize event declarations and invalidation mappings
5. Move default translations into modules with override support
6. Remove remaining direct module coupling
7. Add targeted integration tests for normalized modules

### `platformkit-backend-kit`

1. Align authz/runtime expectations with module permission contracts
2. Provide shared helpers for route and permission coverage validation
3. support event emission and invalidation mapping contracts
4. enforce split-repo safe dependency usage where backend helpers participate

### `platformkit-frontend-kit`

1. keep admin and UI surfaces aligned with module route and permission contracts
2. support module-driven i18n and client override composition
3. consume event and invalidation metadata where browser behavior depends on it

### `platformkit`

1. publish the normalization, authz, events, and i18n standards
2. define release criteria for normalized modules
3. make the roadmap and milestones visible across the platform

### `septagon-clients/*`

1. document how client overrides layer on top of module-owned translations
2. document how client-specific access and UX policies consume normalized module contracts

## Execution Order

1. Contract freeze
2. Conformance tooling
3. Fine-grained access control normalization
4. Event normalization
5. Internationalization normalization
6. Ports and dependency boundary hardening
7. CI and release gates

## Exit Criteria

- every module follows the canonical structure
- permissions are explicit and validated
- admin routes and actions have permission coverage
- events are declared, namespaced, and documented
- translations live with modules and support client overrides
- ports and DI boundaries are explicit and enforced
- conformance checks prevent regressions
- release quality is tied to normalized module status
