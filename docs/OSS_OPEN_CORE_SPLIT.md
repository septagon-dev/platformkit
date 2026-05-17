# PlatformKit Open-Core Split

This document is the operating contract for splitting PlatformKit into a public
OSS upstream under `septagon-oss` and a paid downstream distribution under
`septagon-dev`.

## Goal

The OSS version must be a smaller PlatformKit, not a different PlatformKit. It
must preserve the same architecture shape:

- module bundles and catalogs
- ports-only cross-module contracts
- declarative Fx composition
- tenant, auth, audit, and admin control-plane basics
- token-authored design system
- registry-backed UI rendering
- CLI scaffolding and verification
- CLI/TUI foundation with context-aware command visibility, JSON output, and
  terminal-safe rendering
- reusable E2E harness
- one runnable reference app

The underlying formula is documented in
[PLATFORMKIT_FORMULA.md](PLATFORMKIT_FORMULA.md): core defines the rules,
modules add capabilities, and clients compose capabilities into products and
user flows.

The paid version may be a fork, but it should build on the public architecture
instead of redefining it.

The quality bar for moving code into the public upstream is defined in
[OSS_QUALITY_GATE.md](OSS_QUALITY_GATE.md). No split or migration step should
continue unless the architecture and execution gates are green for the current
foundation.

## Repository Model

`septagon-oss` is the public upstream. It owns the stable contracts that
community users build against.

`septagon-dev` is the private downstream. It owns Pro modules, hosted/cloud
operations, customer/client overlays, private deployment automation, and
commercial defaults.

The minimum OSS shape is:

```text
septagon-oss/pk-core         backend/module/runtime kernel
septagon-oss/pk-shared       stable cross-repo schemas and vocabulary
septagon-oss/pk-design       token/design-system engine
septagon-oss/pk-client       public client and SDK primitives
septagon-oss/pk-tools        composable CLI and terminal UX foundation
septagon-oss/pk-modules      OSS essential module pack
septagon-oss/pk-apps         runnable reference apps
septagon-oss/pk-docs       public docs source, ADRs, requirements, and the
                            PlatformKit page renderer fed by
                            septagon-clients/platformkit overlay content

septagon-dev/platformkit-pro          private downstream distribution/fork
septagon-dev/platformkit-pro-modules  paid module packs
septagon-dev/platformkit-cloud        hosted control plane and operations
septagon-dev/platformkit-enterprise-adapters  private/paid integrations
```

## Fork Policy

Pro may fork the distribution. Pro should not privately fork the core contracts
unless the change is intentionally short-lived.

Allowed Pro-only changes:

- add module bundles
- add module presets and module sets
- add providers, adapters, and deployment targets
- add CLI, testkit, UI runtime, and agent governance packages when they are
  mature enough to publish separately or fold into Pro
- add hosted control-plane workflows
- add enterprise auth, billing, compliance, and support surfaces
- add client and demo overlays
- add commercial defaults and documentation

Avoid Pro-only changes to:

- `module.Bundle`, `module.Catalog`, and module manifest semantics
- port publication and dependency declaration semantics
- tenant and identity context contracts
- migration and outbox contracts
- token schema and theme layering semantics
- renderer permission/redaction contracts
- CLI scaffold contract formats
- testkit flow definition formats

If Pro needs one of those changed, the default path is upstream-first: change
the OSS contract, tag it, then consume that tag from Pro.

## Minimum OSS Platform

The first public release should prove this path:

```bash
platformkit doctor
platformkit new my-saas --pack core
cd my-saas
platformkit up
platformkit verify
platformkit explain modules
```

That path must produce:

- one local modular monolith
- tenant/user/auth/admin/audit/health modules
- content/site/mail/notification basics where feasible
- tokenized admin/entity UI
- generated CRUD or entity surfaces for a scaffolded module
- public design tokens emitted as CSS/Tailwind/W3C-compatible outputs
- Playwright smoke coverage through `platformkit-testkit`
- a reference app with no private infrastructure assumptions

## OSS Module Pack

The initial public module pack should include only modules that make the
platform credible and supportable:

- `tenant_management`
- `user_management`
- `auth_management`
- `admin_management`
- `api_key_management`
- `audit_management`
- `health_management`
- `entitlement_management`
- `notification_management`
- `mail_management`
- `content_management`
- `site_management`

Potentially public after hardening:

- `billing_management` if the public version is provider-neutral and does not
  imply hosted/commercial billing features
- `chat_management` if assistant/provider-specific behavior is optional
- `file_management` if storage providers are generic and local-first

Keep private/Pro initially:

- `pricing_engine`
- `sku_management`
- `order_management`
- `payment_management`
- `spatial_management`
- `operator_management` beyond public admin essentials
- `traffic_management`
- `review_queue_management`
- vertical/demo/client modules
- staging, GitOps, release-runner, and private infrastructure modules

## Dependency Direction

Public dependencies flow downward:

```text
pk-apps
  -> pk-modules
  -> pk-tools
  -> pk-client
  -> pk-design
  -> pk-core
  -> pk-shared

pk-docs
  -> pk-apps
  -> pk-modules
  -> pk-tools
  -> pk-client
  -> pk-design
  -> pk-core
  -> pk-shared
```

Private dependencies flow on top:

```text
platformkit-pro
  -> septagon-oss public tags
  -> platformkit-pro-modules
  -> platformkit-cloud
  -> platformkit-enterprise-adapters
```

No public repo may import a private `septagon-dev` package.

## Release Lanes

Use independent public tags per repo, then keep a compatibility matrix in
`pk-apps` or a later lightweight release-manifest repo.

Example:

```text
pk-shared    v0.1.0
pk-core      v0.1.0
pk-design    v0.1.0
pk-client    v0.1.0
pk-tools     v0.1.0
pk-modules   v0.1.0
pk-apps      v0.1.0
pk-docs     v0.1.0
```

Pro consumes the public distribution tag and adds a private Pro tag:

```text
platformkit-pro pro-0.1.0 imports the septagon-oss v0.1.0 tags
```

## Split Phases

1. Create `septagon-oss` and the public repos with standard community files.
2. Publish `pk-shared` and `pk-core` first.
3. Publish `pk-design`, `pk-client`, and `pk-tools`.
4. Publish `pk-modules` with the OSS essential module set only.
5. Publish `pk-apps` and prove first-run DevX.
6. Publish `pk-docs` after private live-publish workflows are removed. The
   PlatformKit page content comes from the public-safe
   `septagon-clients/platformkit` overlay and the renderer lives in OSS.
7. Create or update `septagon-dev/platformkit-pro` as a downstream fork that
   consumes the public tags plus private packs.

## Current Extracted Surface

- `pk-core/pkg/module`: module metadata, typed ports, dependency validation,
  provider compatibility, bundle/catalog composition, and Pro embedding
  contract.
- `pk-shared/pkg/flowdef`: neutral reusable flow definitions for UI/API
  coverage, authoring, and E2E/testkit bridges. Private
  `platformkit-shared/flowdef` is now a compatibility layer over the OSS
  package; flow execution remains downstream.
- `pk-shared/pkg/statemachine`: declarative lifecycle definitions, structural
  validation, traversal helpers, and Mermaid rendering. Private
  `platformkit-shared/statemachine` is now a compatibility layer over the OSS
  package; runtime execution remains downstream.
- `pk-tools/pkg/cliapp` and `pk-tools/pkg/tui`: reusable CLI root/output and
  terminal rendering foundations.
- `pk-modules/pkg/homepage/overlay`: public-safe homepage overlay rendering
  primitives used by downstream site modules.

## Downstream Refactor Contract

After the public repos exist, `septagon-dev` should refactor toward a downstream
extension model instead of carrying a separate framework.

Target shape:

- `platformkit-backend-kit/app/module` becomes a temporary compatibility layer
  over `github.com/septagon-oss/pk-core/pkg/module`.
- Pro modules embed `pk-core/pkg/module.Module` and add Pro metadata,
  providers, adapters, entitlements, and hosted defaults around it.
- Stable cross-repo vocabulary moves to `pk-shared`; private schemas stay in
  Pro repos and must not leak into public package APIs.
- Generic design tokens and export primitives move to `pk-design`; private
  themes, client overlays, and commercial brand systems remain downstream.
- Generic client transports and SDK primitives move to `pk-client`; generated
  Pro SDKs, hosted auth defaults, and private telemetry remain downstream.
- Generic CLI and terminal UX primitives move to `pk-tools`; private devtools
  keep Pro-only commands for hosted ops, release automation, enterprise/client
  workflows, and internal agent normalization.
- The `platformkit client ...` CLI from devtools should be extracted after the
  public client-overlay contract is scrubbed from private app names, private
  design-system imports, and hosted Docker/deployment assumptions.
- Public essential modules move to `pk-modules`; paid, vertical, client, and
  hosted operations modules live in private Pro module packs.
- Reference apps in `pk-apps` consume public packs only; private apps consume
  the Pro distribution and can fork `pk-apps` when commercial defaults are
  needed.
- Public ADRs, requirements, docs composer code, and the base PlatformKit
  public-page renderer move to `pk-docs`. Downstream client overlays feed that
  renderer; private client docs and live-publish workflows stay in Pro/private
  repos.

Refactor sequence:

1. Tag `pk-shared`, `pk-core`, `pk-design`, `pk-client`, and `pk-tools`.
2. Add those public modules to the private `go.work` and consume them through
   temporary local replaces while the split is active.
3. Re-export current module types from `platformkit-backend-kit/app/module`
   so existing code compiles while imports are migrated.
4. Move one low-risk internal package at a time to the public contract imports,
   starting with module metadata, dependency declarations, and catalog tests.
5. Convert Pro module constructors to embed and extend the public
   `module.Module`.
6. Add boundary tests that fail if any `github.com/septagon-oss/pk-*` repo
   imports `github.com/septagon-dev/...` or if public APIs expose private types.
7. Remove compatibility shims only after all downstream imports have moved.

## First Split Criteria

A repo is ready to push to `septagon-oss` only when:

- it builds without private GitHub/Gitea credentials
- its module path references `github.com/septagon-oss/...`
- it has no client/demo/staging/Synology/private registry references
- it has no generated caches, videos, screenshots, or release workspaces
- it has a README, LICENSE, SECURITY, CONTRIBUTING, and CODEOWNERS
- it has at least one runnable verification command
- every Pro-only dependency is either removed or hidden behind an extension
  interface
