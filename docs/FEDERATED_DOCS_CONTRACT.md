# Federated Docs Contract

PlatformKit documentation should grow as a federated system, not as one giant
central handbook and not as repo-local prose with no composition model.

The current contract stack is:

- `DITA principles` for typed, reusable topics
- `Diataxis` for audience/job-to-be-done structure
- `OpenAPI`, `AsyncAPI`, and `JSON Schema` as the preferred machine-readable
  sources for reference
- `Antora` and `TechDocs` as the federation targets for assembly and discovery

## Boundaries

### Repo Boundary

Each repository is a documentation component.

A repo owns:

- a repo-level docs manifest
- at least one tutorial topic
- the declaration of which modules have adopted the typed docs contract
- the declaration of which federation and machine-reference standards it uses

Tutorials live at the repo boundary because they usually span multiple modules
or a wider operator workflow.

### Module Boundary

Each module owns a compact documentation bundle.

The first required bundle is:

- `explanation`
- `how-to`
- `reference`

That maps onto DITA as:

- `concept -> explanation`
- `task -> how-to`
- `reference -> reference`

Each module should keep only a small manifest at module root. Authored topics
should live next to the feature or use case that owns the behavior.

Examples:

- `visit_management/docs.manifest.yaml`
- `visit_management/features/visit_tracking/visit-lifecycle-model.explanation.md`
- `admin_management/features/admin/author-admin-surface-contribution.howto.md`

Module tutorials are allowed later, but they are not the starting requirement.

### Topic Boundary

A topic is the smallest stable unit. Each topic should declare:

- `topic_id`
- `title`
- `component_id`
- `module_id` when scoped to a module
- `scope` (`repo` or `module`)
- `dita_type`
- `diataxis`

The goal is typed, composable topics, not long mixed-purpose pages.

## Federation Targets

This contract is intentionally compatible with:

- `Antora` for component/module/version assembly
- `TechDocs` for repository-local publication into one central portal

PlatformKit does not need to choose only one assembler immediately. The local
authoring contract should stay portable to both.

## Pilot

The first implementation lives in `platformkit-business-modules`:

- repo-level manifest in `.platformkit/docs.manifest.yaml`
- repo tutorial at `docs/tutorials/`
- module-root manifests for `admin_management` and `visit_management`
- feature-local topics for those pilot modules
- a boundary ratchet requiring `boundary.explanation.md` in each pilot feature or use-case boundary
- guard enforced through `make check-module-doc-contract`

## Next Ratchets

1. Expand the docs manifest pattern to more repositories.
2. Declare machine-readable references per module as OpenAPI, AsyncAPI, or JSON Schema artifacts become available.
3. Add central assembly metadata for Antora or TechDocs publication once enough repos have adopted the contract.
