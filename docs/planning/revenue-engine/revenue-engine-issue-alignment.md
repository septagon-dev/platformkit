# Revenue Engine Issue Alignment

Updated: `2026-03-21`

## Purpose

Map the currently open issues across the split repos to the active platform
objective:

Build PlatformKit into a credible, partner-led, AI-augmented vertical platform
with a realistic path to payment-linked revenue, while preserving split-repo
integrity and thin app composition boundaries.

## Active Platform Objectives

For the current phase, the objectives are:

1. make the flagship platform credible and runnable
2. keep apps thin and composition-only
3. make the operator surface trustworthy and certifiable
4. make billing and payment-adjacent workflows reliable
5. make the split-repo toolchain usable for launches
6. prove one supervised AI workflow end to end
7. preserve client-scoped branding and white-label delivery

## Decision Rule

An issue is `Now` if it directly supports one of the current objectives or is a
hard prerequisite.

An issue is `Later` if it is useful but not on the critical path for the first
commercial wedge.

An issue is `Keep Watching` if it matters, but should not preempt the current
launch, trust, or payment path.

## Current Issue Alignment

### Now

These issues are aligned with the current platform objective and should stay in
the active planning lane.

#### Flagship credibility and public product surface

- `platformkit#1` Track platformkit foundation alpha
- `platformkit#2` Compose the flagship repo from released split modules
- `platformkit#3` Publish quickstart and architecture overview
- `platformkit#4` Demonstrate one supervised AI workflow end to end
- `platformkit#5` Document local development for the split ecosystem

Why:

Without a buildable flagship, quickstart, and visible AI-operated workflow, the
platform cannot sell itself to partners or design customers.

#### Reference app integrity and release confidence

- `platformkit-apps#22` Enforce smoke checks in verify-ci and release gating
- `platformkit-apps#24` Deduplicate monolith and microservices parity tests into a shared harness
- `platformkit-apps#25` Program tracker: foundation hardening, platform operating system, and reference app composition
- `platformkit-apps#26` Keep flagship app surfaces composition-only and push defaults back to module repos

Why:

The commercial product cannot sit on top of app-level drift or release promises
that are not enforced.

#### CLI and launch-system prerequisites

- `platformkit-devtools#1` Migrate and harden platformkit-devtools
- `platformkit-devtools#2` Define CLI extraction boundary from ComumCowork root

Why:

The launch system needs a reliable CLI and an explicit extraction boundary
before it can become a repeatable partner deployment tool.

#### Billing, admin trust, and modular platform operating system

- `platformkit-business-modules#8` Track business-modules contract hardening
- `platformkit-business-modules#15` Harden admin route resolution and remove synthetic fallback pages
- `platformkit-business-modules#16` Classify workflow entities with explicit admin behavior semantics
- `platformkit-business-modules#17` Persist admin workspace tabs and prompt-authored operator views
- `platformkit-business-modules#28` Make subscription plan changes transactional and proration exact
- `platformkit-business-modules#30` Adopt canonical shared shells and atomic primitives across section renderers
- `platformkit-business-modules#31` Enforce ports-only boundaries and keep shell mechanics out of business modules

Why:

These issues directly support revenue-critical trust:
billing correctness, auditable admin behavior, and a reusable operator surface
that does not collapse into module-local one-offs.

#### Backend and frontend trust prerequisites

- `platformkit-backend-kit#25` Harden CSP nonce handling and add regression coverage
- `platformkit-backend-kit#27` Replace panic-prone nil DB seams with typed errors
- `platformkit-frontend-kit#5` Track frontend-kit operator-surface hardening
- `platformkit-frontend-kit#13` Replace ad hoc admin CRUD booleans with an explicit entity behavior contract
- `platformkit-frontend-kit#22` Restore frontend compile health and resolve button/logout API drift
- `platformkit-frontend-kit#23` Operationalize JS runtime tests and real frontend test entrypoints
- `platformkit-frontend-kit#24` Stabilize atomic component builder contracts and shared interaction APIs
- `platformkit-frontend-kit#25` Define canonical operator shell primitives for list, form, detail, and admin surfaces

Why:

If core frontend and backend surfaces are not trustworthy, every partner launch
becomes support-heavy and non-certifiable.

#### Cross-repo verification and agent control plane

- `platformkit-tests#4` Track cross-repo test harness hardening
- `platformkit-agent-runtime#5` Track agent-runtime control-plane hardening

Why:

The strategy requires both:
cross-repo confidence and an AI/runtime surface that is safe enough to demo and
eventually monetize.

#### White-label branding and theme path

- `platformkit-design-system#7` Promote module token packs and theme-management integration
- `platformkit-design-system#8` Fix client-scoped content and branding override gaps

Why:

White-label delivery is part of the commercial motion. Client-scoped theming
and branding gaps sit on that path.

### Later

These issues are valid, but they should not preempt launch, billing, or first
partner-proof work.

- `platformkit-apps#23` Replace demo-style mobile UI bootstrap with a preview or production contract
- `platformkit-backend-kit#26` Make file sync persistence atomic and tenant-safe
- `platformkit-devtools#5` Cut over root CLI entrypoint to compatibility shim
- `platformkit-design-system#9` Prepare design-system docs, examples, and playground strategy
- `platformkit-design-system#10` Extract runtime-free frontend primitives and helper packages
- `platformkit-design-system#11` Extract reusable atoms and generic molecules from frontend kit
- `platformkit-design-system#12` Define metadata, registry, and playground split for design-system components
- `platformkit-design-system#13` Define asset pipeline ownership for fonts, icons, and design CSS inputs

Why:

They improve long-term structure or polish, but are not on the shortest path to
the first credible commercial wedge.

### Keep Watching

These issues matter, but are outside the first wedge or are not currently
revenue-critical.

- `platformkit-business-modules#29` Fail fast on device command state persistence and tighten shared test mocks

Why:

It is important for device-control quality, but device command persistence is
not on the critical path for the coworking and flex-space commercial wedge.

## Gaps In The Current Open Issue Set

The current issue set is strong on platform hardening, but still underspecified
for the actual revenue motion.

Missing issue categories:

1. payment-enabled reference flow for the flagship app
2. partner-facing composer output:
   preset, quote, recommended package, and launch summary
3. standard coworking reference client contract and launch checklist
4. launch instrumentation:
   time-to-live, manual interventions, and failure reasons
5. partner and brand metrics:
   live brands, active partners, monthly volume, and usage
6. AI-assisted support and onboarding operations
7. design-partner offer, qualification, and evidence capture

These gaps are already reflected in the local revenue backlog docs, but not yet
fully represented in the issue trackers.

## Proposed Execution Order

### Batch A: Trust the flagship

1. `platformkit#2`
2. `platformkit#3`
3. `platformkit-apps#22`
4. `platformkit-frontend-kit#22`
5. `platformkit-tests#4`

### Batch B: Make the operator surface certifiable

1. `platformkit-business-modules#15`
2. `platformkit-business-modules#16`
3. `platformkit-frontend-kit#13`
4. `platformkit-frontend-kit#24`
5. `platformkit-frontend-kit#25`
6. `platformkit-business-modules#30`
7. `platformkit-business-modules#31`

### Batch C: Make revenue workflows trustworthy

1. `platformkit-business-modules#28`
2. `platformkit-backend-kit#25`
3. `platformkit-backend-kit#27`

### Batch D: Make launches repeatable

1. `platformkit-devtools#1`
2. `platformkit-devtools#2`
3. `platformkit-apps#24`
4. `platformkit-apps#26`
5. `platformkit-design-system#7`
6. `platformkit-design-system#8`

### Batch E: Prove the AI layer

1. `platformkit#4`
2. `platformkit-agent-runtime#5`
3. `platformkit-business-modules#17`

## Planning Implication

We do not need to replace the existing open issues. Most of them align.

What we need is:

1. a clearer execution order
2. a sharper distinction between `Now` and `Later`
3. additional issue creation for the commercial gaps listed above

## Next Actions

1. keep the aligned `Now` issues active
2. avoid letting `Later` issues displace payment, trust, and launch work
3. open missing issues for partner launch, payment flow, metrics, and AI-supported ops

## Proposed New Issues

These are the highest-signal additions to the issue trackers.

### `platformkit-apps`

1. Wire one payment-enabled reference flow through `complete-saas-monolith`
2. Define the standard coworking reference client and launch smoke contract
3. Instrument launch-cycle timing and manual intervention reporting

### `platformkit-business-modules`

1. Make the platform composer emit a partner-readable package and launch summary
2. Add partner and brand reporting primitives for live brands, active partners, and monthly volume

### `platformkit-devtools`

1. Materialize the canonical coworking preset into a launch-ready client scaffold
2. Emit a launch checklist and missing-contract report from `platformkit client validate`

### `platformkit-agent-runtime`

1. Add one AI-assisted onboarding or support workflow that operates on the flagship app safely

### `platformkit-tests`

1. Add payment-enabled flagship smoke coverage for the canonical wedge
