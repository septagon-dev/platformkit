# Product Contract

This document defines the minimum integrated contract that `platformkit` must
hold before it is treated as a product instead of a loose collection of sibling
repositories.

## Goal

The flagship product is not "all repos are green."

The flagship product is the smallest end-to-end surface that a team can
evaluate, deploy, and build against with confidence:

- a shared workspace authoring contract
- a versioned backend runtime contract
- interoperable API, event, identity, and telemetry seams
- a flagship app that runs in lean and composed deployment modes
- AI-operable UI and data surfaces
- a governed agent runtime and operator workbench

## Open Source Product Surface

The public product contract is intentionally smaller than the working
workspace. PlatformKit OSS should be the minimum complete path for a developer
to understand, run, extend, and verify a governed SaaS platform.

Included in the OSS core:

- `platformkit`
  - public product contract
  - quickstart and contributor documentation
  - OSS surface audit
- `platformkit-devtools`
  - `platformkit` CLI
  - workspace doctor, scaffolding, verification, and contract checks
  - no private staging, Synology, or release-runner assumptions in public paths
- `platformkit-backend-kit`
  - stable runtime boundary
  - API, config, tenancy, authn/authz, events, observability, and module
    composition contracts
  - runtime capability manifest and release policy
- `platformkit-frontend-kit`
  - renderer, component registry, Storybook contract, A2UI bridge, and UI
    primitives
  - public theming and interaction contracts
- `platformkit-design-system`
  - token engine
  - provider-neutral design contracts
  - Figma/Storybook parity checks where they do not require private data
- `platformkit-shared`
  - only stable cross-repo schemas that cannot yet live in one owning repo
  - every package here must have an extraction or ownership note
- `platformkit-business-modules`
  - OSS essentials pack only: tenant, user, auth, admin, API key, audit,
    entitlement, notification, mail, chat, billing, content, and site
  - other modules stay outside the public core until they are independently
    useful, documented, and supportable
- `platformkit-apps`
  - one starter app and one flagship composed example
  - no staging-only, customer-specific, or private release orchestration in the
    OSS path

Excluded from the OSS core:

- private deployment state, GitOps mirrors, staging configs, Synology routing,
  registry credentials, and release-runner implementation details
- generated release workspaces, local Go/module caches, node modules, E2E
  artifacts, screenshots, videos, and temporary probe files
- vertical/client demos that exist to sell or validate a private business wedge
- modules outside the essentials pack until they have public docs, tests, and a
  stable support story
- experimental compatibility branches, duplicate renderers, and replacement
  paths without a removal plan

Those excluded surfaces may remain valuable, but they should live in private or
separately versioned repositories until they are mature enough to support as
public product.

## Verification

Run the curated product contract from the flagship repo:

```bash
make verify-product
```

Or run the typed checker directly from the standalone devtools CLI:

```bash
platformkit verify contract product --dir <workspace-root>
```

This command validates:

1. backend runtime boundary and release policy enforcement
2. backend interoperability guarantees
3. frontend AI-facing registry and workbench surface health
4. agent runtime governance surface health
5. flagship app lean bootstrap and composed deployment contracts
6. alignment with the workspace authoring standard described in
   [WORKSPACE_AUTHORING_CONTRACT.md](WORKSPACE_AUTHORING_CONTRACT.md)

## Complementary Workspace Guard

The curated product contract is intentionally narrower than the whole platform.

For a broader workspace-level ratchet around federated modular contracts, run
the complementary guard from this repo:

```bash
make verify-federated-platform
```

Or run the typed checker directly:

```bash
platformkit verify contract federated --dir <workspace-root>
```

That guard checks the cross-repo contract floor for build orchestration,
runtime boundaries, admin surfaces, authz, i18n, UI composition,
observability, and docs governance without claiming the entire workspace is one
fully integrated product surface.

## Maturity Rules

A new surface should not be called part of the product until it satisfies all of
these:

- it has one canonical path, not parallel legacy and replacement paths
- it is covered by a machine-runnable contract, not only prose
- it follows the workspace authoring contract, not a repo-local dialect
- it has a clear owner repo
- it is safe to document externally without caveats about instability
- it composes cleanly into the flagship app without bespoke local glue

## Near-Term Standard

The next maturity tranches should focus on:

1. deleting local/generated weight from public worktrees before moving code
2. splitting staging and customer-specific release state out of public repos
3. shrinking `platformkit-business-modules` to an OSS essentials pack
4. collapsing duplicate app compositions into one starter and one flagship
   example
5. promoting the CLI, design-system parity checks, and module contracts into a
   first-class public DevX
