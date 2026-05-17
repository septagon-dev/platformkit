# PlatformKit Formula

This document defines the PlatformKit architecture formula we are converging
on. It is intentionally written as a working agreement: we should iterate on it
until the boundaries feel obvious enough that new code can be placed without
debate.

## Thesis

PlatformKit is a composable platform kernel with module capability packs and
client compositions on top.

The formula is:

```text
PlatformKit = Core Kernel + Modules + Clients
```

Or, more explicitly:

```text
Core defines the rules.
Modules add capabilities.
Clients compose capabilities into business products and user flows.
```

The paid version should build on the same formula. Pro may add modules,
providers, adapters, hosted operations, commercial defaults, and private client
compositions, but it should not require a different architectural model.

## Non-Goals

PlatformKit should not become:

- a bag of unrelated packages
- a code generator with no runtime contract
- a monolith where every feature lives in core
- a UI kit detached from backend contracts
- a private product whose OSS version is only a brochure
- a framework that requires private infrastructure to understand or run

The OSS version must be a smaller PlatformKit, not a different PlatformKit.

## Layer Model

PlatformKit has three product layers and one packaging support layer.

```text
Shared vocabulary
  -> Core kernel
    -> Modules
      -> Clients
```

The conceptual model is simple, but the repository layout may split the pieces
for release and dependency hygiene.

### Shared Vocabulary

Shared vocabulary contains portable contracts that would otherwise create
cycles between core, modules, tools, clients, and tests.

Examples:

- flow definitions
- state machine definitions
- stable contract schemas
- validation/result vocabulary
- cross-runtime identifiers and metadata types

Shared vocabulary must stay small. A package belongs here only when at least two
independent layers need the same public type and no single layer is the natural
owner.

Decision test:

- If it describes a platform rule, prefer core.
- If it describes a design or rendering contract, prefer design.
- If it describes a module-owned domain concept, prefer the module.
- If multiple independent layers need the exact same stable wire contract,
  shared vocabulary is acceptable.

### Core Kernel

Core is the base level. It defines the rules that make PlatformKit a platform
instead of a collection of apps.

Core owns:

- module identity and metadata
- module lifecycle contracts
- feature declarations
- dependency declarations
- provided and required contracts
- dependency graph validation
- registry substrate and registry validation rules
- entity identity and entity descriptor contracts
- runtime context vocabulary
- tenant, actor, request, and environment context primitives
- authz primitives
- policy declarations and evaluation interfaces
- change-intent and mutation-gate contracts
- manifest validation
- platform health/readiness contracts
- design surface descriptors when they are needed for cross-layer composition

Core should provide the smallest complete kernel that lets a module say:

```text
I am this module.
I provide these contracts.
I require these contracts.
I expose these features.
I register these entities, routes, surfaces, policies, migrations, events,
translations, and extension contributions.
I can be validated before runtime.
```

Core should not own:

- concrete SaaS business behavior
- client-specific user journeys
- tenant-specific copy, branding, or overlays
- hosted operations
- enterprise integrations
- concrete OAuth/SSO/payment/email providers
- application seed data
- staging or private deployment assumptions

Core can define extension points for those things. It should not implement the
commercial or customer-specific versions.

### Registries

Registries are one of the most important pieces of the kernel. They are how
PlatformKit remains composable without turning every module into handwritten
glue.

It must be possible to add registries. Core should not hardcode every registry
PlatformKit will ever need.

The better model is:

```text
Core owns the registry substrate.
Core owns only the registries required to validate platform composition.
Modules and tools own domain/runtime-specific registries.
```

A registry in PlatformKit should have a declared shape:

- registry ID
- owning layer
- contribution type
- contribution key
- uniqueness and conflict policy
- validation rules
- deterministic ordering rules
- manifest projection
- runtime resolver interface, when execution is needed
- diagnostics for missing, duplicate, or incompatible contributions

This gives us extensibility without letting arbitrary global maps appear across
the platform.

### Kernel Registries

These registries are candidates for `pk-core` because they define whether a
composition is valid before the app runs:

| Registry | Purpose |
| --- | --- |
| Module registry | Knows which modules exist and validates identity, metadata, dependencies, and lifecycle. |
| Contract registry | Tracks what each module provides and requires. |
| Feature/capability registry | Lets modules publish feature-level capabilities without direct imports. |
| Entity descriptor registry | Tracks module-owned entities, entity identity, schemas, relationships, capabilities, and ownership. |
| Route/API registry | Lets modules expose HTTP/API operations through a common contract. |
| UI surface registry | Lets modules expose admin, operator, tenant, and public surfaces. |
| Design contribution registry | Lets modules publish provider-neutral token, theme, component, and surface descriptors. |
| Policy registry | Lets modules declare authz requirements and enforcement points. |
| Migration registry | Lets modules contribute append-only database migrations. |
| Event registry | Lets modules publish and consume domain events through contracts. |
| Settings schema registry | Lets modules declare configurable settings without owning the settings UI. |
| Health registry | Lets modules report readiness, liveness, and diagnostics. |
| Change gate registry | Lets modules declare governed mutation types and connect them to a composed change-management implementation. |

Registries should be declarative first. The runtime can execute them, but the
declarations must be inspectable by tools before the app boots.

### Extension Registries

Some registries are important, but they should not be kernel-owned in the first
OSS formula. Core may allow them to exist through the registry substrate and
manifest projection, but their semantics belong to modules, tools, or runtime
packages.

| Registry | Owner | Reason |
| --- | --- | --- |
| Job/schedule registry | Runtime module or Pro/runtime package | Jobs are execution infrastructure. Core may describe async contributions, but the scheduler and retry semantics should be replaceable. |
| E2E/flow registry | `pk-tools`, testkit, or `pk-shared` flow catalog | E2E is verification tooling. Modules should publish reusable flows, but the app kernel should not depend on test execution. |
| Translation catalog registry | Translation/design/client layer | Modules contribute translations, but runtime locale loading is a presentation/client concern. |
| Notification channel registry | `notification_management` | Channels and providers are domain infrastructure, not kernel rules. |
| Approval workflow registry | `change_management` plus approval/audit modules | Core should know a mutation can be gated; workflow policy execution belongs to governance modules. |
| Search/query source registry | Data/search module or backend runtime adapter | Query sources are valuable, but the generic entity descriptor is the kernel part. |
| Mobile/client surface registry | `pk-client` or app/client packages | Client surfaces vary by delivery target. |
| AI tool registry | AI module pack or Pro | Tools are capability-specific and should plug into the same registry substrate. |

The distinction matters. A module can still publish jobs and E2E flows; they
are simply not core registries. The manifest can expose those contributions so
tools can validate them when the relevant runtime or testkit is composed.

### Authz And Policy Core

Authorization is part of the core formula, but concrete identity providers are
not.

Core should define:

- principal
- subject
- resource
- action
- scope
- tenant boundary
- policy declaration
- policy decision
- policy evaluation interface
- enforcement metadata for routes, commands, async work, and UI surfaces

Modules should declare policies. Clients may compose policies into business
flows. Pro may add enterprise policy engines, hosted enforcement, audit
pipelines, and integrations, but those should plug into the same public
contract.

The core authz rule:

```text
Every operation that can change state, reveal protected data, or trigger side
effects must be policy-addressable.
```

### Design Contract

Design is part of the platform formula because modules do not only add backend
logic. They also add UI surfaces, design tokens, translations, and interaction
contracts.

The design layer should define:

- tokens
- themes
- component descriptors
- surface descriptors
- form descriptors
- table/list descriptors
- navigation descriptors
- action descriptors
- empty/error/loading state descriptors
- permission-aware redaction rules
- responsive behavior contracts
- Storybook/Figma/export bridges where they are provider-neutral

The renderer can live outside core, but the contract that lets modules publish
renderable surfaces must be stable and public.

The design rule:

```text
Modules publish UI intent. Renderers decide final presentation.
```

This keeps modules portable across web, admin, CLI, generated docs, and future
agent-operated surfaces.

### Entity System

Entities are core to PlatformKit, but not every entity implementation detail
belongs in core.

The core entity system should define:

- entity identity
- entity ownership by module
- entity descriptor shape
- field descriptors
- relationship descriptors
- capability flags
- table/list/form/detail surface hints
- read/write policy hooks
- tenant-scope requirements
- entity-to-route and entity-to-surface links
- validation that every surfaced entity has a declared owner and permissions

Core should not own:

- concrete domain entities
- ORM-specific base classes
- database repositories
- entity-specific services
- generated admin pages
- client-specific entity workflows

The current private workspace already points toward this shape:

- `core/entity` defines generic entity contracts and base abstractions.
- the entity registry tracks metadata, UI schema, ownership, route path, and
  display information.
- module ports expose row sources, query sources, permission declarations, and
  capability discovery.
- admin/operator surfaces validate that a renderable entity has a matching
  source and read permissions.

The OSS formula should preserve the contract while reducing implementation
coupling:

```text
pk-core:
  EntityID
  EntityDescriptor
  FieldDescriptor
  RelationshipDescriptor
  EntityRegistry contract
  entity ownership and permission coverage validation

pk-modules:
  concrete entities
  migrations
  repositories/services
  row/query source implementations
  entity read/write policy declarations

pk-design / pk-client:
  form/table/detail rendering contracts
  client-specific entity presentation

clients:
  composed entity workflows and product-specific pages
```

The entity rule:

```text
Core knows what an entity is and how to validate that it is safely exposed.
Modules own the entity's behavior and data.
Clients decide how entities become product workflows.
```

### Change Management

Change management is a platform governance capability, but the full change
management system should not live in the kernel.

Core should own only the small mutation-governance contract:

- change intent
- governed mutation classification
- policy hook for "apply now" versus "requires gate"
- stable change decision/result vocabulary
- links from entity operations, routes, and policies to a change gate
- validation that guarded mutations declare a gate when required

The `change_management` module should own:

- change records
- change request persistence
- change provider registry
- approval workflow lookup
- pending/applied/rejected/apply-failed lifecycle
- dispatcher behavior
- approval-service integration
- operator/admin change surfaces
- notifications and audit integration

Producer modules should own:

- which entity types they can change
- change type vocabulary for their domain
- old/new payload construction
- apply callbacks
- auto-approve versus approval-required defaults
- module-local tests for each governed mutation path

Clients should own:

- product-specific approval journeys
- cross-module flows that generate change requests
- acceptance tests for pending approval and applied/rejected outcomes
- tenant-specific copy, routing, and escalation policy

The current implementation already matches this direction in spirit:

- `ports.ChangeRegistrar` lets modules register change providers without
  depending on `change_management` internals.
- `change_management` owns the provider registry and `SubmitChange` gate.
- `audit_management` can provide the human approval bridge.
- producer modules such as tenant or billing modules register domain-specific
  change providers.

The OSS boundary should make that explicit:

```text
pk-core:
  mutation gate contract
  policy hooks
  change decision vocabulary
  manifest validation hooks

pk-modules/change_management:
  durable records
  provider registry
  workflow resolution
  dispatcher
  admin/operator surfaces

pk-modules/audit_management:
  approval bridge
  evidence and audit trail

clients:
  composed approval journeys
  product-specific escalation rules
```

The change-management rule:

```text
Core knows that a mutation may be governed.
The change_management module decides how governed mutations move through
approval and application.
```

## Modules

Modules add functionality to core.

A PlatformKit module is a capability bundle. It can include:

- domain logic
- entities and persistence
- API routes
- event publishers and subscribers
- background jobs
- migrations
- authz policies
- contracts it provides
- contracts it requires
- admin/operator/public UI surfaces
- design tokens or token extensions
- component descriptors or concrete components
- translations
- settings schemas
- seeds and fixtures
- health checks
- E2E flows
- documentation

The module boundary is the main design primitive.

Modules should communicate through contracts, ports, events, and registries.
They should not directly import another business module's internals.

The module rule:

```text
A module may depend on contracts. It may not depend on another module's
implementation.
```

### Module Manifest

Every mature module should be describable by a manifest, whether the manifest is
generated, checked in, or both.

A module manifest should answer:

- What is this module?
- What features does it expose?
- What contracts does it provide?
- What contracts does it require?
- What entities does it own?
- What routes does it register?
- What policies does it declare?
- What UI surfaces does it publish?
- What translations does it contribute?
- What migrations does it own?
- What events does it publish or consume?
- What async work does it contribute when a job runtime is composed?
- What reusable flow fragments prove its capabilities when testkit is composed?
- What governed mutation types does it declare?
- What other modules are compatible providers for its required contracts?

The manifest is the bridge between code, docs, CLI inspection, validation, and
testing.

### Module Categories

The public module layer should be organized as packs instead of one giant list.

Suggested packs:

| Pack | Purpose |
| --- | --- |
| Core SaaS | Tenant, user, auth, admin, audit, API key, entitlement, health. |
| Governance | Change management, approval, evidence, compliance reports, policy review. |
| Communication | Notification, mail, templates, inbox, chat where provider-neutral. |
| Content | Site, content, media, public pages, docs-ready publishing. |
| Commerce | Billing, pricing, orders, payments, subscriptions, only when provider-neutral enough. |
| Operations | Review queues, operator tools, traffic, observability, support workflows. |
| AI | Assistant, tool, memory, model, prompt, and agent governance modules. |
| Vertical | Customer or industry-specific modules, usually private or separately versioned. |

The OSS core should start with the smallest credible packs. Pro can add richer
packs without changing the kernel.

### E2E In Modules

Modules should own reusable E2E fragments, not full customer journeys.

Those fragments should be published to the tooling/testkit layer, not to the
core runtime. The core module manifest can declare that a module has testable
flows, but executing those flows is a `pk-tools` / testkit responsibility.

Examples:

- "create user"
- "invite team member"
- "issue API key"
- "publish content page"
- "send notification"
- "verify audit event"

Those fragments should be:

- declarative
- parameterized
- runnable against a local app
- composable into client journeys
- linked to module requirements
- registered so tooling can discover coverage

The module E2E rule:

```text
Modules prove capability. Clients prove business journeys.
```

## Clients

Clients compose modules into business products.

A client can be:

- an OSS starter app
- a flagship reference app
- a customer product
- a demo product
- a vertical distribution
- a Pro-hosted composition

Clients own:

- product-specific business logic
- cross-module user journeys
- user-facing information architecture
- tenant or brand overlays
- workflow orchestration
- page composition
- copy and content
- product-specific translations
- product-specific theme choices
- product-specific seed data
- acceptance tests for full journeys
- deployment defaults

Clients should not own:

- generic module contracts
- reusable kernel rules
- shared policy vocabulary
- reusable design primitives
- module-internal implementation details
- framework-level CLI behavior

The client rule:

```text
Clients compose modules. They do not redefine the platform.
```

### Client Flows

Client E2E flows should be built from module-owned fragments plus
client-specific steps.

Example:

```text
Client onboarding flow =
  auth.sign_up
  + tenant.create_workspace
  + user.invite_member
  + entitlement.enable_plan
  + admin.verify_dashboard
  + client-specific welcome/content/payment steps
```

The result is a test model where:

- module authors prove capability in isolation
- client authors prove composition
- platform tooling can detect missing coverage
- Pro can add private journeys without forking public module contracts

## OSS And Pro Relationship

The public product should be the foundation. The paid product should be an
extension.

```text
septagon-oss
  pk-shared
  pk-core
  pk-design
  pk-client
  pk-tools
  pk-modules
  pk-apps
  pk-docs

septagon-dev
  platformkit-pro
  platformkit-pro-modules
  platformkit-cloud
  platformkit-enterprise-adapters
  client/product repositories
```

Pro may add:

- private modules
- richer module packs
- hosted operations
- commercial defaults
- enterprise auth providers
- billing/payment provider integrations
- deployment automation
- customer/client overlays
- private E2E journeys
- support and observability extensions

Pro should not privately redefine:

- module semantics
- dependency semantics
- contract semantics
- authz vocabulary
- design descriptor semantics
- flow definition semantics
- registry semantics
- manifest validation semantics

If Pro needs one of those changed, the default path is upstream-first.

## Repository Mapping

The conceptual formula maps to repositories like this:

| Concept | Public repo | Notes |
| --- | --- | --- |
| Shared vocabulary | `pk-shared` | Only stable cross-layer contracts that need no single owner. |
| Core kernel | `pk-core` | Module model, registry substrate, kernel registries, entities, lifecycle, context, authz primitives, mutation gates, validation. |
| Design contract | `pk-design` | Tokens, surface descriptors, component contracts, provider-neutral exports. |
| Client primitives | `pk-client` | SDK and client/runtime primitives that are not product-specific. |
| CLI and tools | `pk-tools` | Doctor, scaffold, validate, explain, TUI, graph inspection. |
| Public modules | `pk-modules` | Essential capability packs. |
| Reference apps | `pk-apps` | Starter and flagship compositions. |
| Public docs | `pk-docs` | Docs, ADRs, requirements, generated reference, PlatformKit page. |

This layout is not the architecture itself. It is the packaging that keeps the
architecture releasable.

## Placement Rules

Use these rules when deciding where code belongs.

| Question | Placement |
| --- | --- |
| Does it define what a module is? | Core. |
| Does it define the generic registry substrate or a composition-critical registry? | Core. |
| Does it define a domain/runtime-specific registry such as jobs, E2E, notifications, approvals, or AI tools? | Owning module, tools, or runtime package. |
| Does it define stable authz vocabulary? | Core. |
| Does it define entity identity, descriptors, ownership, and exposure validation? | Core. |
| Does it implement concrete entity persistence or behavior? | Module. |
| Does it define the mutation-gate contract? | Core. |
| Does it persist change records or run approval workflows? | `change_management` / governance module. |
| Does it define provider-neutral UI/design descriptors? | Design, with core hooks if needed. |
| Does it implement a domain capability? | Module. |
| Does it compose several modules into a user journey? | Client. |
| Does it exist only for a specific customer, brand, or demo? | Client or private/pro repo. |
| Does it improve scaffold, validation, explanation, or local DevX? | Tools. |
| Does it define a stable wire contract used by multiple layers? | Shared vocabulary. |
| Does it require private infrastructure? | Pro/private, not OSS core. |

## Quality Bar

Every public PlatformKit surface should satisfy this bar before it is treated as
part of the formula:

- the owner layer is obvious
- the public contract is small and documented
- it can run without private infrastructure
- it has a validation path
- it has focused tests
- it has examples or generated docs
- it composes through registries, contracts, or manifests
- it does not require direct imports across module internals
- Pro can extend it without forking semantics

## Current Working Formula

The formula we should use until we revise it:

```text
Core is the platform kernel:
  module model
  registry substrate
  composition-critical registries
  contracts
  entities
  lifecycle
  runtime context
  authz primitives
  mutation gate contract
  validation

Modules are capability bundles:
  logic
  entities
  persistence
  routes
  policies
  contracts
  UI surfaces
  design contributions
  translations
  jobs/events
  change providers
  migrations
  reusable E2E fragments

Clients are product compositions:
  business journeys
  cross-module orchestration
  information architecture
  brand/content overlays
  product-specific policies
  deployment defaults
  full E2E acceptance flows
```

That is the architectural center of PlatformKit.

## Open Questions

These are the questions we should settle through iteration:

- Which registries are truly composition-critical enough to live in `pk-core`
  for the first OSS release?
- What is the minimal generic registry substrate that lets modules/tools add
  registries without creating ungoverned global state?
- Should design surface descriptors live entirely in `pk-design`, or should
  `pk-core` own only the minimal surface-contribution registry interface?
- What is the exact OSS contract for entities: descriptor only, or descriptor
  plus generic repository interfaces?
- What is the exact OSS contract for change management: mutation gate only, or
  gate plus stable change-record vocabulary?
- How much authn belongs in OSS modules versus Pro providers?
- Which modules are essential for the first public module pack?
- Should `pk-apps` have one starter app only, or both starter and flagship?
- What is the minimum flow fragment every module must publish to testkit
  without making E2E a core runtime concern?
- Which current private packages should become standalone community libraries
  instead of being folded into `pk-core` or `pk-modules`?
