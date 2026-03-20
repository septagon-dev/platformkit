# PWA Cache and Storage Program

## Scope
This program applies only to the `septagon-dev/platformkit-*` repos and `septagon-clients/*` repos.

Reference repositories under `ComumCowork/*` are not delivery targets. They are used only to inspect prior patterns and recover historical implementations.

## Goal
Make platformkit's PWA, offline, cache, and client-storage behavior contract-driven across backend, frontend, business modules, apps, and client repos.

## Principles
- Backend defines route and sync policy semantics.
- Frontend executes client storage and purge semantics.
- Business modules declare policy, they do not hand-roll cache logic.
- Client repos override policy through approved configuration only.
- Sensitive and tenant-scoped data must never rely on implicit persistence behavior.

## Scenario Coverage
1. Public site and marketing pages
2. Auth entry points and credential recovery
3. Admin shell and admin read models
4. Tenant-scoped and user-scoped read models
5. User preferences, drafts, and profile state
6. Queueable and non-queueable mutations
7. Realtime and device-control workflows
8. Push notifications and background sync
9. Logout, tenant switch, and version bump invalidation
10. Client-specific policy overrides

## Canonical Defaults
- Authenticated read models default to `tenant-user` scope.
- Mutations default to `network-only` and are not queueable unless explicitly declared.
- Auth and other sensitive flows must not use durable persistence by default.
- Public pages are cacheable and offline-readable.
- Device control and realtime operations must not present fake stale control state.

## Flagship Modules
1. `site_management`
2. `auth_management`
3. `admin_management`
4. `user_management`
5. `device_management`

## Milestones

### M1 Contract Freeze
Goal: lock the platform vocabulary and allowed behavior.

#### `platformkit-backend-kit`
- Freeze cache class taxonomy.
- Freeze offline mode taxonomy.
- Freeze storage scope taxonomy.
- Freeze sensitivity taxonomy.
- Define invalidation tag conventions.
- Add policy validation for unsafe combinations.
- Document route and sync policy semantics.

#### `platformkit-frontend-kit`
- Freeze storage policy semantics.
- Freeze purge trigger semantics.
- Freeze scoped key format.
- Define sensitive persistence restrictions.

#### `platformkit-business-modules`
- Document authoring rules for PWA-capable modules.
- Ban ad hoc cache and offline logic outside the shared contracts.

### M2 Runtime Execution
Goal: make policy contracts operational.

#### `platformkit-backend-kit`
- Expose normalized route and sync policy export.
- Make service worker generation fully policy-driven.
- Execute invalidation tags in runtime policy output.
- Add regression tests for generated policy and service worker output.

#### `platformkit-frontend-kit`
- Add storage policy registry.
- Add scoped key builder.
- Add purge coordinator for logout, tenant switch, and version bump.
- Add policy-aware storage helpers and adapters.

### M3 Flagship Module Adoption
Goal: prove the model on the highest-value workflows.

#### `platformkit-business-modules`
- Adopt shared PWA policy contracts in the flagship modules.
- Declare invalidation tags for flagship module read models and mutations.
- Remove remaining ad hoc PWA or cache behavior from those modules.
- Add module-level policy completeness tests or conformance checks.

### M4 Invalidation and Lifecycle
Goal: make cache correctness production-safe.

#### `platformkit-backend-kit`
- Add event-to-invalidation-tag mapping.
- Emit invalidation metadata for flagship entity and module changes.

#### `platformkit-frontend-kit`
- Implement purge by logout.
- Implement purge by tenant switch.
- Implement purge by app version bump.
- Implement tag-driven invalidation of client-side state.

#### `platformkit-business-modules`
- Map flagship module events to invalidation tags.
- Add examples for public page updates, profile updates, admin config changes, and device state changes.

### M5 Client Override Model
Goal: allow safe client-specific policy changes without framework forks.

#### `septagon-clients/*`
- Define override schema for TTLs, offline enablement, install metadata, and notification policy.
- Provide reference override configs for `septagon`, `platformkit`, and `comumcowork`.
- Add validation for unsafe or contradictory overrides.

#### `platformkit-backend-kit` and `platformkit-frontend-kit`
- Respect client override inputs only through approved surfaces.
- Reject unsupported or unsafe override combinations.

### M6 Release Quality
Goal: make the subsystem shippable.

#### `platformkit-backend-kit`
- Add policy and service worker regression tests.

#### `platformkit-frontend-kit`
- Add storage purge tests, scoped key tests, and sensitive-persistence tests.

#### `platformkit-business-modules`
- Add policy conformance checks for all PWA-capable modules.

#### `platformkit-apps`
- Wire policy export and frontend runtime together in the flagship app.
- Add installability, offline, and purge lifecycle integration checks.

#### `platformkit-tests`
- Add offline smoke coverage.
- Add logout and tenant-switch purge coverage.
- Add sensitive persistence safety checks.

## Repo Task Map

### `platformkit-backend-kit`
1. Freeze PWA route and sync policy taxonomy.
2. Add normalized policy export for frontend and runtime consumption.
3. Execute invalidation tags in generated PWA runtime output.
4. Add validator for unsafe policy combinations.
5. Keep service worker generation aligned with the policy registry.

### `platformkit-frontend-kit`
1. Add storage policy registry and scoped key coordinator.
2. Implement purge coordinator for logout, tenant switch, and version bump.
3. Add policy-aware storage helpers and adapters.
4. Integrate offline and cache lifecycle coordination into the frontend runtime.
5. Add regression tests for storage policy behavior.

### `platformkit-business-modules`
1. Adopt shared PWA policy contracts in flagship modules.
2. Add invalidation tag mappings for flagship module events.
3. Add conformance checks for PWA-capable modules.
4. Remove remaining ad hoc PWA and cache behavior from modules.

### `platformkit-apps`
1. Wire the backend policy export and frontend runtime together.
2. Add installability and offline integration checks.
3. Add app-level purge lifecycle hooks.

### `platformkit-tests`
1. Add offline and installability smoke coverage.
2. Add logout and tenant-switch purge coverage.
3. Add sensitive persistence safety checks.

### `septagon-clients/*`
1. Define client override schema for PWA, cache, and storage policy.
2. Add reference configs for `septagon`, `platformkit`, and `comumcowork`.
3. Add validation for unsafe client overrides.

## Execution Order
1. Invalidation tag taxonomy
2. Policy export surface
3. Frontend purge coordinator
4. Flagship module completion
5. Client override schema
6. Release test coverage

## Exit Criteria
- Every PWA-capable module uses shared policy contracts.
- No module relies on free-form cache logic.
- Logout and tenant switch purge correctly.
- Version bumps invalidate stale client state.
- Client repos can tighten policy without forking framework code.
