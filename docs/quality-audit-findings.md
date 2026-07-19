# PlatformKit ISO 25010 + Modularity Quality Audit Findings (2026)

**Auditor**: Grok (primary analysis)
**Date**: Current session
**Scope**: Traceability, logging/theming, event propagation, error handling, duplication, modularity/extensibility invariants, and broader ISO 25010 characteristics (maintainability, reliability, usability, etc.).
**Basis**: Deep code search (grep across backend-kit + business-modules), file reads (app/event/*, app/errors/*, app/appcontext/*, observability/*, design-system/*, devtools checks, multiple modules), module_contracts, docs/ADRs, conformance tooling, and existing CLAUDE.md/AGENTS.md invariants.

This document is the artifact for Codex review and subsequent council (Grok + Codex + DeepSeek) fix collaboration.

## Executive Summary

The platform has **excellent governance machinery** and strong core contracts (import boundaries largely hold, error contract *checks* exist, observability has standards + providers + contracts, design system has parity + contribution model, event bus is rich with OSS bridge, traceability tooling is sophisticated).

The primary problems are:
- The "correct/intended" path (durability, safe errors, full traceability annotations, minimal boilerplate) is often **not the path of least resistance** for module authors.
- Significant duplication in feature scaffolding and cross-cutting concerns.
- Gaps between documented invariants (e.g. ADR-0007 outbox) and actual call sites.
- Partial enforcement (ratchets exist but are not yet at zero; C-14 is not universal).

These hurt **Maintainability** (analyzability, modifiability), **Reliability** (event durability), and **Usability** (both end-user surfaces and developer experience of extending the platform) the most.

## 1. Event Propagation & Durability (Highest Severity — Reliability + Invariant Violation)

**Finding**: Widespread use of `event.PublishBestEffort` (or direct `bus.Publish` / `events.Publish`) despite repeated documentation, module comments, and ADR-0007 requiring outbox for transactional/durable emission.

**Evidence** (non-exhaustive from searches):
- `order_management/features/orders/service.go:469-472`: Local `emit` helper does `event.PublishBestEffort(ctx, s.bus, evt, s.log)`.
- `billing_management/features/subscriptions/service.go` and `entitlements.go`: Many BestEffort calls (210, 233, 318, 392, 461, 570, 747, etc.).
- `file_management/features/file_catalog/service.go` + `service_image_standardization.go`: Multiple BestEffort.
- `content_management/features/articles/service.go:376`, `mail_management/*`, `payment_management`, `tenant_management`, `auth_management/*`, `api_key_management`, `sku_management`, `site_management`, `change_management`, `entitlement_management`, `notification_management/*`, `collectibles_management`, `user_management/features/profile/*` and preferences, `cart_management`, `print_request_management` (mixed — some have adapters), etc.
- Count from broad grep: 80+ sites across modules.
- Many services have private `emit(...)` helpers that hard-code the non-durable path.
- Positive examples (correct intent): `print_request_management`, `spatial_management/features/scenes` (has emitter adapter + outbox comments), `chat_management`, `internal/outbox/*`, clinical_record docs.
- Outbox implementation: Lives in `platformkit-business-modules/internal/outbox` (entity + service) + bridged to OSS `pk-core/pkg/event/outbox` via `app/event/oss_adapter.go` (well-documented lossy bridge for the split-repo model). `NewOSSOutbox` exists.
- Declaration side is good: `standard.WithEvent(...)` + catalog + events.go comments saying "emit through the outbox (ADR-0007)".

**Why this matters**:
- Violates the stated durability contract for events (ADR-0007, CLAUDE.md "Events durability").
- Loses transactional guarantees (state change + event in same tx via outbox).
- Hurts audit, change management integration, replay, and cross-module reliability.
- "Not truly modular and extensible" in practice: the durable path is harder/special-cased.

**Proposed fix** (from prior analysis):
- Promote / canonicalize a `ports.EventEmitter` or outbox-backed emitter that modules inject.
- Provide a simple `Emit(ctx, evt)` or `EmitTransactional(ctx, tx, evt)` helper that is the *only easy path*.
- Make BestEffort explicit + audited (or remove from feature code).
- Update scaffolding, examples, and add/enhance a modulecheck (expand event check or new action_governance rule).
- Drive migration of the high-frequency emitters first (billing, user, file, content, auth, notification).

## 2. Error Handling Contracts & Consistency (High — Usability + Maintainability)

**Finding**: Strong central `app/errors/` (AppError, codes, wrapping, stack traces, Huma mapping, APIError handling) and excellent static checker in `platformkit-devtools/internal/modulechecks/error_contracts.go`.

**Resolved (2026-07-19)**: the compatibility budget and its CLI/configuration
surface were removed. The checker is now strict, and all canonical business
module handlers use `SafeError` for private 5xx causes.

**Evidence**:
- The strict checker reports zero raw client messages and zero direct 5xx constructors across canonical business-module production files.
- Checker rules reject raw `err.Error()` client messages and every direct Huma/application 5xx constructor, including message-only calls. Violations point to `apperrors.SafeError`, `api.ExecuteResultMapped`, or `NewPublicError`.
- `SafeError` keeps a generic client message while retaining context-wrapped causes in `AppError.Err` for server-side diagnostics.
- Ports define good sentinels (`ErrEntityActionNotFound` etc.), but mapping at boundaries is inconsistent.
- No universal per-module "domain error registry + automatic public boundary mapper".

**Impact**: The client-leakage path is closed and permanently guarded. Domain
error registration and automatic boundary mapping remain maintainability
opportunities, not safety exceptions.

**Follow-up**:
- Introduce or strengthen a small core helper + codegen / convention for "register domain errors → SafeError mapping at handler".
- Update module scaffolds to emit the safe pattern by default.

## 3. Traceability (C-14 / REQ-ADR Links) — Partial Enforcement (Maintainability / Analyzability)

**Finding**: Tooling is sophisticated (`check-traceability` understands cross-cutting + module-prefixed REQs, AC evidence, test links, capability lean checks; `check-file-purpose`; normrules). Some packages do it well (agent-runtime, some clinical_record, appcontext tests with explicit REQ links, normrules).

But it is not uniform or a hard gate for new code.

**Evidence**:
- Grep for `// Implements: REQ|// Per: ADR|// Discipline: C-14` shows concentration in governance/agent/normrule areas; sparse in most business module feature code, services, and even many backend-kit files.
- `check-traceability/main.go` exists and is detailed (bidirectional, capability discipline requiring non-wiring files to carry `Implements`).
- CLAUDE.md explicitly says "C-14 discipline + anatomy/ports hygiene... (enforced by check-file-purpose; backfill in core)".
- Result: Reduced ability to answer "why does this code exist?" without archaeology. Hurts long-term maintainability and onboarding.

**Proposed fix**:
- Make the header (or equivalent machine-readable tag) a hard failure for new non-generated files in the checks + pre-commit/CI.
- Backfill focused high-churn packages (core event/error paths, a few flagship modules).
- Possibly integrate into `platformkit` CLI doctor or a new "explain why this file" command.

## 4. Duplicated Logic & Feature Boilerplate (Maintainability / Platform Usability)

**Finding**: Extremely repetitive per-feature structure.

**Evidence** (pattern across nearly all modules):
- `features/<name>/feature.go`, `handler.go`, `service.go` (often + `service_crud.go`, `service_*.go`), `routes.go`, `permissions.go`, `e2e.go`, `table_handler.go` or section renderers, constants, ui.go, etc.
- Core helpers exist (`app/module/helpers/generic_section_renderer.go`, `feature_builder.go`, `entity_builder.go`, `crud.go`) and are used, but the tax remains high — authors still write a lot of wiring + registration code for every surfaced entity + admin + public projection.
- Similar repetition in authz.go / permissions.go / entity_permissions.go per module.
- Proxies: `proxies/publisher_port_providers.go` has a long manual list of PublishRequest for every service (duplication of catalog knowledge; intentional LayerApp carve-out but maintenance-heavy).
- Event emission helpers duplicated per service.

**Impact**: High cognitive and maintenance cost to add/extend capabilities. Reduces the "extensible" claim in practice. Slows the flywheel for new modules or client overlays.

**Proposed fix**:
- Significantly strengthen the generic builders / registration so a common "own an Entity with full surfaces" case collapses to far fewer files (while still emitting the owned `feature.go` etc. for customization and clear ownership).
- Or safe codegen that respects boundaries and regenerates wiring.
- Generate/validate the proxies publisher lists from manifests/catalog instead of hand maintenance.
- Extract more shared "feature skeleton" enforcement (devtools already has `feature_skeleton.go` check — expand it).

## 5. Logging Context Hygiene & Guardrails

**Strength**: Outstanding `observability/LOGGING_STANDARDS.md`, guardrail package (must-use for fallbacks), slowwatch (integrated to health), structured Fields, providers (zap primary), rich `app/appcontext` (tenant, correlation, actor, cross-tenant reasons, RequestLogAttributes).

**Gap**: Not every log site consistently enriches from context. Ad-hoc logs and some module `s.log` calls can miss tenant/trace/correlation. Guardrail/slowwatch are the enforced paths; general logging is still easy to do inconsistently.

**Proposed**: Lightweight wrappers or linter rules so common logger usage auto-pulls context unless opted out. Make the structured + context-enriched path the obvious one in module scaffolds.

## 6. Theming / Design Propagation (Good Extensibility, Polish Gap)

**Strengths**: One of the strongest areas — CUE token IR (pkds), multiple compilers (tw/, cssbundle), Figma parity + coverage tests, module design token contributions, tenant/client overlays, experiences (brand_forward, editorial), frontend-kit renderer + registry consuming contributions, theme behavior contracts, design_management module.

**Gaps**:
- Multiple emission paths still create surface (even with parity guards).
- Default flagship/admin/public visual + interaction quality (states, motion, accessibility, mobile) is "very good for a governed system" but not yet "hands-down masterpiece" level.
- Polish is being driven via skills (animate, delight, etc.), but the core reference surfaces need a focused delight + consistency pass.

**Extensibility verdict**: Genuinely good here. Contribution + overlay model works.

## 7. Other Modularity / Invariant Notes

- **Direct imports**: No `import "other_management"` in normal business modules (importboundary + grep confirmation). Good.
- **Legacy dep syntax**: Mostly migrated to `WithDep(RequiresPort[T]/OptionalPort[T])`. Normalize tools and `port_modernization` checks exist. Some docs still reference old form.
- **Carve-outs**: proxies/, previewcatalog, apps/modulecatalog, certain cmd surfaces are intentional LayerApp for composition/MCP/catalog. Documented. Prefer generated registration over ad-hoc New*Admin in future (per Phase 3 notes).
- **Migrations**: Append-only discipline appears respected.
- **Singleton**: `module.NewSingleton` + `GetModule()` guidance followed in most places.
- **Entity permissions**: Many modules have `entity_permissions.go` + wiring (enforced for surfaces via conformance + catalog). Good (REQ-018/ADR-0009).

## Prioritized Refactor Recommendations (from initial synthesis)

1. **Event durability unification** (Reliability + trust in invariants).
2. **Error contract to zero + boundary mapper** (Usability + consistency).
3. **Traceability / C-14 hard gate + backfill** (Analyzability / Maintainability).
4. **Feature/entity boilerplate collapse** (Maintainability + platform DX / velocity).
5. **Theming default experience + emission unification + delight pass** (Usability of surfaces).
6. **Proxies / composition surface generation** (Reduce manual duplication in carve-outs).
7. **Logging context auto-enrichment** (Observability consistency).

Additional: Expand modulechecks (events, errors, feature skeleton, ports) and integrate more into `platformkit` CLI + precommit.

## Next Steps for Collaboration

This document + the preceding deep analysis chat turn are the input for Codex review.

Codex (as strict reviewer): Please validate each section with code evidence you can read, rate severity/impact on ISO 25010, call out any overstatements or missed items, comment on the proposed fixes (feasibility, better alternatives, order), and recommend the minimal set of changes that would give the biggest quality lift.

After Codex review, we will run a council (Grok + Codex + DeepSeek) to agree the exact list of issues to fix in this cycle, then implement (with proper `make precommit` / verify runs and re-review).

---

**References** (for reviewers):
- Prior analysis turn (detailed evidence + file:line examples).
- `platformkit-backend-kit/app/event/`, `app/errors/`, `app/appcontext/`, `observability/`
- `platformkit-devtools/internal/modulechecks/{error_contracts.go, event*.go, feature_skeleton.go, port_modernization.go}`
- Multiple `*/events.go`, `*/service.go` (search for PublishBestEffort)
- `platformkit-business-modules/internal/outbox/`
- Design system + frontend-kit renderer + parity tests.
- `make check-module-contracts`, `make precommit` targets, CLAUDE.md invariants.

Reviewers: open any of the cited files as needed. Focus on whether the "correct path" is the default one and where duplication or enforcement gaps remain.
