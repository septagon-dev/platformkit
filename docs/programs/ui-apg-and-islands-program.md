# UI APG And Islands Program

Updated: `2026-03-31`

## Purpose

Raise PlatformKit's interactive UI quality from "server-rendered and
controller-based" to "APG-correct, WCAG 2.2 conscious, selectively loaded, and
regression-gated" across the split-repo workspace.

This program is the execution plan behind the frontend standards defined in:

- `platformkit-frontend-kit/docs/platform-composition-standard.md`
- `platformkit-frontend-kit/docs/browser-asset-strategy.md`
- `platformkit-frontend-kit/docs/platform-apg-and-islands-standard.md`

## Proposed GitHub Milestone

Title:

`UI APG and Islands Hardening`

Definition of complete:

1. shared widgets map to explicit APG patterns
2. known semantic mismatches have fixes or tracked migrations
3. `island` means a real loading boundary instead of eager global bootstrap
4. inline behavior exceptions only shrink
5. flagship app flows prove the contracts end to end

## Scope

Primary delivery repos:

- `septagon-dev/platformkit`
- `septagon-dev/platformkit-frontend-kit`
- `septagon-dev/platformkit-business-modules`
- `septagon-dev/platformkit-design-system`
- `septagon-dev/platformkit-apps`
- `septagon-dev/platformkit-tests`
- `septagon-dev/platformkit-devtools`
- `septagon-dev/platformkit-backend-kit`

Secondary or watch-only repos for this milestone:

- `septagon-dev/platformkit-agent-runtime`
- `septagon-dev/platformkit-shared`

Out of scope for the first milestone unless web-contract work expands there:

- `septagon-dev/platformkit-mobile`
- infrastructure and automation repos

## Workstreams

### W1 Pattern Contract Freeze

Goal:

Make shared interactive behavior map to explicit APG and WCAG rules.

Deliverables:

- canonical APG pattern matrix for shared widgets
- widget-level semantic decisions for tabs, dialogs, menus, comboboxes, and
  listboxes
- WCAG 2.2 focus, target-size, drag-alternative, and authentication rules in
  platform docs
- repo-level definition of what `island` means technically

Primary repos:

- `platformkit`
- `platformkit-frontend-kit`
- `platformkit-design-system`

### W2 Frontend Runtime Hardening

Goal:

Make shared browser behavior both semantically correct and selectively loaded.

Deliverables:

- split action-menu and selection-dropdown semantics cleanly
- normalize command palette to dialog plus combobox or dialog plus search-list
  with explicit semantics
- document and implement tiny-core runtime versus island bundles
- stop treating eager `boot.js` imports as a valid island end-state
- add audits for inline handler drift

Primary repo:

- `platformkit-frontend-kit`

### W3 Module Adoption And Exception Burn-Down

Goal:

Move module-owned UI off inline bridges and onto the shared contract model.

Deliverables:

- replace login password-toggle inline script with controller-backed behavior
- replace audit explorer `onclick` bridges
- move rich homepage interactions onto module-owned controllers or shared
  surfaces
- eliminate generic shell mechanics from business modules

Primary repo:

- `platformkit-business-modules`

### W4 Flagship Composition Proof

Goal:

Prove that the flagship app consumes the standards without becoming a local fork
of the interaction model.

Deliverables:

- composition-only adoption of hardened shared widgets
- smoke coverage for keyboard, dialog, menu, combobox, and island paths
- proof that only required island bundles load on flagship surfaces

Primary repos:

- `platformkit-apps`
- `platformkit`

### W5 Regression Gates

Goal:

Prevent backsliding after migrations land.

Deliverables:

- repo-level inline behavior audits
- shared APG smoke selectors and E2E assertions
- CI lanes that fail on new semantic or loading regressions
- codemod or audit helpers for migration follow-through

Primary repos:

- `platformkit-tests`
- `platformkit-devtools`
- `platformkit-frontend-kit`
- `platformkit-business-modules`

## Repo Task Plan

### `platformkit`

1. Publish and maintain the cross-repo execution program.
2. Create the GitHub milestone and keep issue alignment current.
3. Track milestone batches and close-out criteria from the flagship repo.

### `platformkit-frontend-kit`

1. Normalize command palette semantics to an explicit dialog plus combobox
   contract.
2. Split action-menu behavior from selection-dropdown behavior.
3. Define tiny-core runtime versus lazy island bundle ownership.
4. Move heavy organisms off the eager global runtime path.
5. Add and tighten inline behavior audits and APG-facing tests.

### `platformkit-business-modules`

1. Replace login password-toggle inline JS with shared or module controller
   contracts.
2. Remove raw `onclick` bridges from audit explorer.
3. Migrate branded homepage and rich module interactions to approved controller
   lanes.
4. Consume corrected menu, dialog, and combobox contracts from
   `platformkit-frontend-kit`.

### `platformkit-design-system`

1. Add WCAG-facing guidance for focus visibility, target size, and reduced
   motion to the design-system contract.
2. Ensure token guidance supports compliant focus rings and hit-target sizing.
3. Document accessibility implications of theme and client overlay decisions.

### `platformkit-apps`

1. Keep flagship surfaces composition-only while adopting hardened widgets.
2. Add smoke flows for tabs, dialogs, menus, comboboxes, and island-heavy
   surfaces.
3. Prove correct bundle inclusion on representative flagship pages.

### `platformkit-tests`

1. Add APG regression coverage for keyboard and focus behavior.
2. Add smoke assertions for dialog, menu, combobox, and password-toggle paths.
3. Add bundle-loading or script-inclusion checks for island surfaces where
   practical.

### `platformkit-devtools`

1. Add audit helpers or codemods for inline-handler and inline-script detection.
2. Add migration helpers for shared controller adoption where it reduces manual
   churn.
3. Support milestone reporting across split repos.

### `platformkit-backend-kit`

1. Verify CSP and asset-serving posture remains compatible with selective island
   loading.
2. Add backend-facing helpers only if selective loading needs manifest or nonce
   integration beyond current frontend ownership.
3. Stay out of UI semantics unless backend output contracts need tightening.

### `platformkit-agent-runtime`

1. Audit operator-facing agent surfaces to ensure they consume the shared
   command palette, dialog, and focus contracts instead of drifting.
2. Defer implementation unless a concrete agent-runtime UI surface blocks the
   milestone.

### `platformkit-shared`

1. Stay watch-only unless common APG or accessibility constants prove reusable
   across repos.
2. Do not extract prematurely.

## Execution Order

### Batch A: Freeze The Standard

1. publish the APG and islands standard
2. publish this program and issue map
3. add initial frontend audit coverage

### Batch B: Fix Shared Semantic Gaps

1. command palette semantics
2. dropdown pattern split
3. dialog and drawer focus-policy normalization

### Batch C: Make Islands Real

1. define tiny-core runtime ownership
2. move heavy organisms onto selective loading paths
3. prove loading boundaries in flagship surfaces

### Batch D: Burn Down Module Exceptions

1. login password-toggle migration
2. audit explorer migration
3. homepage and branded surface cleanup

### Batch E: Lock The Gates

1. cross-repo E2E and smoke assertions
2. devtools audits and reporting
3. milestone close-out review

## Proposed Issue Seeds

These are the issue titles that should sit under the GitHub milestone once auth
is available.

### `platformkit`

- Track UI APG and islands hardening milestone

### `platformkit-frontend-kit`

- Normalize command palette to explicit dialog and combobox semantics
- Split action-menu and selection-dropdown contracts
- Define tiny-core runtime versus lazy island bundles
- Replace eager island imports with selective loading for heavy organisms
- Add frontend inline-behavior allowlist audit

### `platformkit-business-modules`

- Replace login password-toggle inline script with controller contract
- Remove audit explorer inline handler bridges
- Migrate homepage rich interactions onto approved controller lanes

### `platformkit-design-system`

- Add WCAG 2.2 focus, target-size, and motion guidance to design-system docs

### `platformkit-apps`

- Add flagship smoke coverage for APG widget flows and island loading

### `platformkit-tests`

- Add cross-repo APG regression pack for dialog, menu, combobox, and tabs

### `platformkit-devtools`

- Add split-repo inline behavior and APG audit helpers

### `platformkit-backend-kit`

- Verify CSP and asset posture for selective island loading

### `platformkit-agent-runtime`

- Audit agent surfaces for shared dialog and command palette contract reuse

### `platformkit-shared`

- Evaluate whether any APG or accessibility constants deserve shared extraction

## Current Status

Started locally:

- cross-repo program drafted
- frontend APG and islands standard published
- frontend inline-behavior audit added
- first semantic fix in progress in `platformkit-frontend-kit`

Blocked:

- GitHub milestone and issue creation require valid `gh` authentication

## Next Actions

1. restore `gh` authentication and create the milestone plus issue set
2. land the first frontend semantic fixes
3. start the first business-module exception migration
