# Revenue Engine Program

## Intent

Build a realistic path from the current PlatformKit asset base to
`$1M/month` in revenue without assuming enterprise-scale sales before the
product and deployment motion are proven.

This is not a 12-month target. The planning horizon is `36 months`.

## Starting Point

The commercial hierarchy is now explicit:

1. PlatformKit is the flagship commercial product.
2. Septagon is the parent company that develops and supports PlatformKit.
3. COMUM, Incomum, Apex, and Velora are full products built on PlatformKit,
   not disposable demos.

The current platform already has assets worth commercializing:

1. `platformkit.dev` and `platformkit-marketing` as the commercial site surface
2. `complete-saas` as the runnable PlatformKit evaluation surface
3. product overlays under `septagon-clients/*` and `septagon-demos/*`
4. the module composer under `module_management`
5. the agent runtime for operator automation and approval flows

The current gaps are commercial and operational, not just technical:

1. PlatformKit's public page does not yet read as the flagship commercial page.
2. the product portfolio lacks one shared end-to-end readiness contract
3. COMUM, Incomum, Apex, and Velora have uneven runtime readiness
4. payment-led revenue paths are not yet standard across products
5. partner, support, and launch operations are not yet repeatable

## Hard Assumptions

1. The first commercial surface is PlatformKit itself, not a Septagon parent
   company page.
2. Septagon appears as the maker, support organization, and operator behind
   PlatformKit.
3. The first product proofs are COMUM, Incomum, Apex, and Velora.
4. A product is not public-ready until it passes the readiness gates in
   [`product-portfolio-readiness.md`](./product-portfolio-readiness.md).
5. Revenue must come from a mix of:
   platform fees, product subscriptions, partner fees, automation usage, and
   payment/booking volume.
6. The path is invalid if the named products cannot run end to end.

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

Goal: stop treating PlatformKit as a loose engineering umbrella and make it the
flagship commercial product page with a product portfolio behind it.

Exit criteria:

1. `platformkit.dev` has one clear commercial promise and one primary CTA
2. Septagon is positioned as maker/parent, not as the competing product brand
3. COMUM, Incomum, Apex, and Velora each have a readiness score
4. one commercial PlatformKit package and pricing strawman exist
5. one local evaluation path proves PlatformKit from install to product flow

### M1 Design Partner Proof

Target date: `2026-08-15`

Goal: prove that real buyers will pay for the offer.

Exit criteria:

1. `1` named product passes every readiness gate
2. `3` signed design partners, customers, or implementation partners
3. `1` live payment-enabled deployment
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

### W1 PlatformKit Commercial Surface

Primary repos:

- `platformkit`
- `platformkit-marketing`

Deliverables:

1. flagship homepage, product narrative, and primary CTA
2. Septagon-as-maker positioning
3. pricing model and package boundaries
4. comparison, FAQ, and AI-search-readable pages

### W2 Product Portfolio Readiness

Primary repos:

- `platformkit-apps`
- `septagon-clients/*`
- `septagon-demos/*`
- `platformkit-tests`

Deliverables:

1. readiness score for COMUM, Incomum, Apex, and Velora
2. one local runbook per product
3. one E2E smoke per product covering the primary flow
4. measured launch and onboarding time per product

### W3 Payments and Revenue Capture

Primary repos:

- `platformkit-business-modules`
- `platformkit-apps`

Deliverables:

1. payment-enabled default flow in PlatformKit
2. booking, subscription, and billing instrumentation for product lines
3. take-rate ready settlement model where the product has transaction volume
4. product, partner, and brand-level revenue reporting

### W4 Product and Partner Operations

Primary repos:

- `platformkit-agent-runtime`
- `platformkit-business-modules`
- `platformkit-frontend-kit`

Deliverables:

1. product readiness dashboard
2. launch queue and approval workflow
3. support triage and automation
4. partner console for builders and operators

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

1. publish the PlatformKit flagship commercial positioning
2. define Septagon's role as maker/parent/support organization
3. score COMUM, Incomum, Apex, and Velora against the readiness contract
4. map the current PlatformKit evaluation path and list broken steps

### Week 3-4

1. make the composer output a buyer-readable product summary, not just a technical selection
2. define the standard product launch artifact set
3. instrument product launch time and payment path gaps
4. identify the minimum billing, booking, and subscription events needed for revenue reporting

### Week 5-6

1. publish product launch checklists for the first two readiness candidates
2. stand up one product using the full path
3. prepare the first PlatformKit commercial walkthrough
4. publish the first case-study template and product readiness scorecard

## Immediate Repo Task Map

### `platformkit`

1. keep this program document current
2. add product-facing packaging and pricing docs
3. publish the PlatformKit flagship narrative
4. maintain the product portfolio readiness contract

### `platformkit-business-modules`

1. make the composer output product-readable summaries
2. add payment and partner reporting requirements to the relevant modules
3. remove product-path breakage in validation, composition, and deployment flows

### `platformkit-devtools`

1. turn product materialization into a standard launch path
2. emit launch-ready artifacts for products and partners
3. validate the minimum product contract automatically

### `platformkit-apps`

1. make `complete-saas-monolith` the PlatformKit evaluation surface
2. define the standard payment-enabled product path
3. publish launch smokes that match product onboarding

### `septagon-clients/*`

1. keep COMUM and Incomum honest as full product/customer surfaces
2. keep one internal staging deployment current with the standard path

### `septagon-demos/*`

1. promote Apex and Velora from product stories into end-to-end product surfaces
2. close readiness gaps before public pages imply production readiness

## Current Status

`M0` is in progress.

Execution backlog:

- `docs/programs/revenue-engine-backlog.md`
- `docs/programs/revenue-engine-30-day-execution.md`
- `docs/programs/revenue-engine-issue-alignment.md`
- `docs/programs/revenue-engine-research.md`
- `docs/programs/revenue-engine-testing-remediation.md`
