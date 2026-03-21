# Revenue Engine Program

## Intent

Build a realistic path from the current PlatformKit asset base to
`$1M/month` in revenue without assuming enterprise-scale sales before the
product and deployment motion are proven.

This is not a 12-month target. The planning horizon is `36 months`.

## Starting Point

The current platform already has four assets worth commercializing:

1. `complete-saas` as a runnable flagship application surface
2. client overlays under `septagon-clients/*` for white-label delivery
3. the module composer under `module_management`
4. the agent runtime for operator automation and approval flows

The current gaps are commercial, not just technical:

1. no locked vertical wedge
2. no explicit commercial package
3. no payment-led revenue rail
4. no partner control plane
5. no repeatable launch motion with measured cycle time

## Hard Assumptions

1. First wedge is `coworking/flex-space`.
2. Primary customer is a `partner`:
   agency, consultant, operator group, or franchise-style buyer.
3. The product sold first is a `white-label operator OS`, not a generic
   low-price SMB SaaS.
4. Revenue must come from a mix of:
   platform fees, per-brand fees, automation usage, and payment volume.
5. The path is invalid if payment flow is still outside PlatformKit after
   `M2`.

## Revenue Model

Target steady-state blend:

1. partner platform fees
2. per-live-brand fees
3. automation and support usage fees
4. payment or booking take rate

Illustrative end-state math:

1. `150` partners x `$2,500/mo` = `$375k/mo`
2. `2,000` live brands x `$125/mo` = `$250k/mo`
3. automation usage = `$125k/mo`
4. `0.5%` take on `$50M` monthly volume = `$250k/mo`

Total: `$1.0M/mo`

This math is only useful if each layer is proven in sequence.

## Milestones

### M0 Offer Lock

Target date: `2026-05-15`

Goal: stop treating PlatformKit as a broad platform and define the first
 sellable offer.

Exit criteria:

1. one vertical wedge: `coworking/flex-space`
2. one commercial package: `white-label operator OS`
3. one recommended module preset for the wedge
4. one partner-facing pricing model
5. one demo path from branding to deployment to payment collection

### M1 Design Partner Proof

Target date: `2026-08-15`

Goal: prove that real buyers will pay for the offer.

Exit criteria:

1. `3` signed design partners
2. `1` live payment-enabled deployment
3. `10` committed downstream launches across those partners
4. first case study with measured launch time and operator outcome
5. booked recurring revenue of at least `$8k/mo`

### M2 Repeatable Launch Motion

Target date: `2026-11-30`

Goal: reduce founder-led setup work and make deployment repeatable.

Exit criteria:

1. launch cycle time from signed partner to live brand under `10` business days
2. `5` active paying partners
3. `15` live brands
4. payment flow integrated into the standard launch path
5. monthly recurring revenue of at least `$25k`

### M3 Partner Control Plane

Target date: `2027-05-31`

Goal: make one partner capable of operating many brands without direct
 founder support.

Exit criteria:

1. `15` active partners
2. `75` live brands
3. partner console for brand status, upgrades, usage, and support
4. automation handling at least `30%` of routine support and onboarding tasks
5. monthly recurring revenue of at least `$100k`

### M4 Marketplace and Network Effects

Target date: `2027-11-30`

Goal: let third parties extend the platform and create non-linear revenue.

Exit criteria:

1. paid themes, modules, or automations available through a governed marketplace
2. rev share model for certified builders
3. `40` active partners
4. `250` live brands
5. monthly recurring revenue of at least `$300k`

### M5 Scale to $1M/Month

Target date: `2029-03-31`

Goal: reach blended monthly revenue at or above `$1M`.

Exit criteria:

1. `150` active partners
2. `2,000` live brands
3. monthly platform volume at or above `$50M`
4. monthly recurring and usage revenue at or above `$1M`

## Kill Criteria

The program should be reviewed or stopped if any of the following are true:

1. no design partner signs by `2026-08-15`
2. payment flow is still not part of the standard launch path by `2026-11-30`
3. average launch still requires custom engineering after the fifth live brand
4. partners do not expand to additional brands after initial launch

## Workstreams

### W1 Offer and Packaging

Primary repos:

- `platformkit`
- `platformkit-apps`
- `platformkit-business-modules`

Deliverables:

1. wedge definition and ICP
2. pricing model and package boundaries
3. one-click recommended module preset
4. demo story and ROI framing

### W2 White-Label Launch System

Primary repos:

- `platformkit-devtools`
- `platformkit-apps`
- `septagon-clients/*`

Deliverables:

1. generated client setup path
2. branded deployment overlays
3. launch checklist and smoke verification
4. measured deployment lead time

### W3 Payments and Revenue Capture

Primary repos:

- `platformkit-business-modules`
- `platformkit-apps`

Deliverables:

1. payment-enabled default flow
2. booking and billing instrumentation
3. take-rate ready settlement model
4. partner and brand-level revenue reporting

### W4 Partner Operations

Primary repos:

- `platformkit-agent-runtime`
- `platformkit-business-modules`
- `platformkit-frontend-kit`

Deliverables:

1. partner dashboard
2. launch queue and approval workflow
3. support triage and automation
4. brand fleet management

### W5 Marketplace

Primary repos:

- `platformkit-business-modules`
- `platformkit-devtools`
- `platformkit`

Deliverables:

1. theme packaging
2. module packaging and compatibility checks
3. extension billing and rev share
4. partner certification surface

## Next 6 Weeks

### Week 1-2

1. lock the `coworking/flex-space` wedge and reject adjacent vertical work
2. add a recommended coworking preset to the platform composer
3. define the first commercial package and draft pricing
4. map the current flagship demo path and list broken steps

### Week 3-4

1. make the composer output a partner-readable summary, not just a technical selection
2. define the standard client launch artifact set
3. instrument launch cycle time and payment path gaps
4. identify the minimum billing and booking events needed for GMV reporting

### Week 5-6

1. publish a partner launch checklist
2. stand up one internal reference deployment using the full path
3. prepare the first design-partner demo script
4. create the first case-study template and launch scorecard

## Immediate Repo Task Map

### `platformkit`

1. keep this program document current
2. add product-facing packaging and pricing docs
3. publish the canonical wedge narrative

### `platformkit-business-modules`

1. make the composer opinionated around the first wedge
2. add payment and partner reporting requirements to the relevant modules
3. remove demo-path breakage in validation, composition, and deployment flows

### `platformkit-devtools`

1. turn client materialization into a standard launch path
2. emit launch-ready artifacts for partners
3. validate the minimum client contract automatically

### `platformkit-apps`

1. make `complete-saas-monolith` the commercial reference surface
2. define the standard payment-enabled demo path
3. publish a launch smoke that matches partner onboarding

### `septagon-clients/*`

1. keep one clean reference client for the coworking wedge
2. keep one internal staging deployment current with the standard path

## Current Status

`M0` is in progress.

Execution backlog:

- `docs/programs/revenue-engine-backlog.md`
- `docs/programs/revenue-engine-30-day-execution.md`
- `docs/programs/revenue-engine-issue-alignment.md`
- `docs/programs/revenue-engine-research.md`
- `docs/programs/revenue-engine-testing-remediation.md`
