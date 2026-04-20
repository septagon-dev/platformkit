# Workspace Authoring Contract

This document defines the authoring standard for code across the PlatformKit
workspace.

The goal is not cosmetic uniformity. The goal is stronger:

- code should read as if it came from one engineering organization
- the same decisions should be made the same way in every repository
- architectural intent should be visible in the file layout, naming, contracts,
  and tests
- drift back to ad hoc local conventions should be treated as a defect

This contract complements:

- [PRODUCT_CONTRACT.md](PRODUCT_CONTRACT.md) for the curated flagship product
- [FEDERATED_PLATFORM_AUDIT.md](FEDERATED_PLATFORM_AUDIT.md) for the broader
  cross-repo contract floor

## Core Rule

PlatformKit code should prefer one canonical path per concern.

We do not keep parallel legacy and replacement paths unless the overlap is
explicitly temporary, documented, and guarded by a removal plan.

If two files solve the same problem in two different styles, the workspace is
already drifting.

## Authoring Principles

### 1. Ownership is explicit

Every surface must have one owner:

- backend runtime contracts live in `platformkit-backend-kit`
- business semantics and domain declarations live in
  `platformkit-business-modules`
- shared UI primitives and controller/runtime behavior live in
  `platformkit-frontend-kit`
- tokens, themes, and design semantics live in `platformkit-design-system`
- final product composition lives in `platformkit-apps`
- shared vocabulary belongs in `platformkit-shared` only when it is genuinely
  cross-repo and stable

Apps compose. They do not redefine lower-level contracts.

### 2. Declarations live close to the domain

Domain facts should be declared next to the domain that owns them:

- permissions
- routes
- settings
- events
- admin surfaces
- docs metadata
- observability metadata

Interpreters and renderers may be centralized, but declarations should not be
 scattered across unrelated repos.

### 3. Composition happens through contracts, not concrete reach-through

Cross-repo and cross-module behavior should flow through:

- ports
- provider contracts
- manifests
- typed configuration
- explicit event contracts

Direct reach-through into another module's internals is a design failure unless
the boundary is intentionally being collapsed.

### 4. Configuration is explicit, typed, and discoverable

Every configurable behavior should have:

- one declaration point
- one canonical key shape
- defaults
- validation
- documentation
- tenant and CMS integration rules where applicable

Hard-coded branch-specific behavior is acceptable only for genuinely fixed
platform invariants.

### 5. Events are named like public contracts

Events are not stringly incidental implementation details.

They must be:

- explicit
- namespaced
- documented
- published and consumed through declared contracts

If a module emits events, the event surface is part of the module API.

### 6. UI code must use the design system and theme

Product surfaces should be expressed through:

- semantic design tokens
- canonical component primitives
- shared renderer/controller runtime contracts

Bespoke styling is only acceptable inside the design system itself or where the
design system is being deliberately extended.

### 7. Errors are structured and intentional

Warnings, user errors, contract violations, and operational failures should not
be mixed.

The platform should prefer:

- structured error payloads
- stable error formatting
- explicit warning semantics
- consistent logging fields
- predictable HTTP and renderer behavior

### 8. Observability is part of the contract

A capability is not complete if it cannot be understood in production.

Modules and runtimes should declare:

- what is logged
- what is measured
- what is traced
- which failures should warn versus fail hard

### 9. Documentation must match the code boundary

Every important surface should be described in the same grammar:

- what it owns
- what it exposes
- what it depends on
- how it is configured
- which events it emits or consumes
- how it is tested
- what it explicitly does not own

README files are not marketing wrappers. They are boundary documents.

### 10. Tests should prove contracts before implementation detail

The strongest tests in PlatformKit should answer:

- does this surface still satisfy its contract?
- can this compose with the rest of the platform?
- did a second path or local exception reappear?

Pure implementation tests still matter, but contract and composition tests are
the primary anti-drift mechanism.

### 11. Prefer deletion over compatibility theater

When a better path exists, prefer:

- consolidating onto one path
- removing stale abstractions
- deleting compatibility glue that no longer serves a launch requirement

PlatformKit is pre-launch. We should optimize for clarity and durable shape, not
legacy preservation.

## How This Should Feel In Code

Across repositories, code should consistently feel:

- declarative before imperative
- contract-first before ad hoc composition
- explicit before inferred
- semantic before incidental
- centralized in interpretation and local in ownership
- strict about boundaries and generous about reuse

This means similar problems should produce similar file layouts, naming
patterns, test shapes, and documentation structure.

## Workspace Review Scorecard

Every repo and module should be reviewable against the same questions:

1. Is the owner of this surface obvious?
2. Is there one canonical path for this concern?
3. Are configuration and defaults declared in one place?
4. Are contracts explicit rather than implied by wiring?
5. Are naming and file layout consistent with sibling surfaces?
6. Does UI code stay inside theme and design-system rules?
7. Are errors and warnings intentional and structured?
8. Are observability expectations explicit?
9. Does documentation describe the same boundary the code implements?
10. Do tests guard the contract, not only the implementation?

If the answer to any of these is "no", the code may work, but it is not yet
written in the PlatformKit authoring style.

## Expected Ratchets

This contract should be enforced progressively through:

- repo-local lint and formatting rules
- module structure checks
- contract generators and checkers
- docs and manifest validation
- Storybook and renderer audits
- migration and settings audits
- CI guards that fail on drift

Until a rule is mechanically enforced, it should be treated as provisional.

## Immediate Application

The highest-value normalization work should focus on:

1. collapsing duplicate paths
2. removing cross-module reach-through
3. making settings explicit
4. making event namespaces explicit
5. enforcing design-system and theme usage
6. standardizing warnings and errors
7. upgrading module docs into true boundary documents

That is how the workspace starts to read as if it was written by one person with
one set of principles instead of many local exceptions.
