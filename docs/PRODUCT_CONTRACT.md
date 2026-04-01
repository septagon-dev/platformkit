# Product Contract

This document defines the minimum integrated contract that `platformkit` must
hold before it is treated as a product instead of a loose collection of sibling
repositories.

## Goal

The flagship product is not "all repos are green."

The flagship product is the smallest end-to-end surface that a team can
evaluate, deploy, and build against with confidence:

- a versioned backend runtime contract
- interoperable API, event, identity, and telemetry seams
- a flagship app that runs in lean and composed deployment modes
- AI-operable UI and data surfaces
- a governed agent runtime and operator workbench

## Product Surface

The current product contract is intentionally curated.

Included:

- `platformkit-backend-kit`
  - stable runtime boundary
  - interoperability profile
  - runtime capability manifest
  - runtime release policy
- `platformkit-frontend-kit`
  - MCP-facing component registry
  - A2UI presentation bridge
  - flagship workbench UI primitives
- `platformkit-agent-runtime`
  - policy-safe agent control plane
  - approvals, budgets, and execution traces
- `platformkit-apps`
  - lean flagship runtime
  - composed monolith and microservices app compositions
  - flagship bootstrap surfaces such as mobile UI endpoints

Excluded for now:

- `platformkit-devtools`
- `platformkit-module-bindings`
- `platformkit-infra-pulumi`
- experimental or legacy compatibility branches outside the curated flagship
  runtime

Those repos still matter, but they are not part of the product contract until
their surfaces are stable enough to version and support.

## Verification

Run the curated product contract from the flagship repo:

```bash
make verify-product
```

This command validates:

1. backend runtime boundary and release policy enforcement
2. backend interoperability guarantees
3. frontend AI-facing registry and workbench surface health
4. agent runtime governance surface health
5. flagship app lean bootstrap and composed deployment contracts

## Maturity Rules

A new surface should not be called part of the product until it satisfies all of
these:

- it has one canonical path, not parallel legacy and replacement paths
- it is covered by a machine-runnable contract, not only prose
- it has a clear owner repo
- it is safe to document externally without caveats about instability
- it composes cleanly into the flagship app without bespoke local glue

## Near-Term Standard

The next maturity tranches should focus on:

1. collapsing duplicate admin and protocol paths onto canonical platform seams
2. promoting more AI/operator surfaces into curated product verification
3. shrinking the gap between the curated flagship contract and the full runtime
4. adding release artifacts and consumer-facing compatibility notes on top of
   this verified base
