# Phase B Overview — 9 Modules in pk-modules

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Replace `pk-modules`' current 3-stub pack (tenant/audit/content placeholders) with the 9-module essentials pack from the OSS v0.0.0 design spec. Every module satisfies the Composable + Chainable contract and is Pro-embeddable.

**Architecture:** Each module under `pk-modules/pkg/<name>/`. Shared types in `pk-modules/pkg/portslib/`. Each module:
1. Exports a `Module` struct (NOT just an interface) — Pro embeds it
2. Constructor `NewModule(opts ...Option) *Module`
3. Composable via `module.Compose() module.Composable`
4. Default sqlite store (`store/sqlite/`)
5. Embedded migrations (`migrations/*.sql` + `embed.go`)
6. Admin pages via Go templates + pk-design tokens
7. `extension_example_test.go` proves Pro embedding compiles

---

## Shared portslib (`pk-modules/pkg/portslib/`)

```go
package portslib

// AdminRegistrar lets modules register entity-CRUD pages and custom admin pages.
type AdminRegistrar interface {
    RegisterEntityCRUD(moduleID, entityName, apiPath string) error
    RegisterPage(p AdminPage) error
    RegisterSidebarSection(s SidebarSection) error
}

// HealthRegistrar lets modules register health checks.
type HealthRegistrar interface {
    Register(name string, check observability/health.Checker) error
}

// NotificationChannel is satisfied by built-in in-app channel; Pro adds mail/SMS/push.
type NotificationChannel interface {
    Name() string
    Deliver(ctx context.Context, n Notification) error
}

// TranslationRegistrar (no-op default; OSS modules use English literals).
type TranslationRegistrar interface {
    Register(key, lang, text string) error
}

// AdminPage, SidebarSection, Notification, SettingsRegistrar types defined here.
```

---

## Module dependency graph (build order)

```
1. tenant          (no deps; foundation)
2. user            (depends on tenant via TenantService port)
3. auth            (depends on user + tenant)
4. audit           (no deps; consumed by user/auth/api_key)
5. health          (no deps; can be added anywhere)
6. api_key         (depends on user + tenant + audit)
7. content         (depends on tenant; could depend on user but optional)
8. notification    (depends on tenant + user; subscribes to event bus)
9. admin (plugin)  (consumes AdminRegistrar from all other modules)
```

Build order: portslib → 1 → 2,4,5 (parallel) → 3,6,7 → 8 → 9

## Module template (each module follows this shape)

```
pk-modules/pkg/<name>/
├── doc.go                              # package overview + Composable scorecard
├── module.go                           # Module struct, NewModule(opts...), Compose()
├── options.go                          # Option type, WithStore, WithExtraRoutes, ...
├── ports.go                            # Pro-consumable ports (e.g., UserService, TenantService)
├── entities.go                         # entity descriptors
├── handler.go                          # HTTP routes
├── service.go                          # business logic
├── admin.go                            # admin pages (Go templates)
├── store/
│   ├── store.go                        # Store interface
│   └── sqlite/sqlite.go                # default sqlite impl
├── migrations/
│   ├── 0001_initial.up.sql
│   └── embed.go                        # //go:embed FS
├── module_test.go
└── extension_example_test.go           # demonstrates Pro embedding
```

## Composable + Chainable contract per module

Every module must satisfy in its `doc.go`:

| Property | Realization |
|---|---|
| Identity | Stable package path |
| Boundary | Private state; ports + Options exported |
| Contract | Module struct + ports + sentinels |
| Composition | Multiple modules coexist; declares ports it provides + requires |
| Replacement | Any `Store` impl swaps via `WithStore` |
| Extension | Pro embeds `*Module` and adds fields/methods |
| Runtime binding | `module.Catalog` composition |
| Evidence | `extension_example_test.go` + unit/integration tests |

## Constraints (every module)

- Stdlib + `modernc.org/sqlite` (test-only via the database/sql interface caller wires)
- C-14/ADR-0029 headers
- External `_test` packages
- NO Co-Authored-By trailers
- NO duplicate `Principal` types (use either `pk-core/pkg/authz.Principal` or `pk-core/pkg/security/identity.Principal` and convert at boundary)

## Phase B sub-plans

Each module gets its own focused plan (one per dispatch):

- B.0: portslib (shared types)
- B.1: tenant_management
- B.2: user_management
- B.3: audit_management
- B.4: health_management
- B.5: auth_management
- B.6: api_key_management
- B.7: content_management
- B.8: notification_management
- B.9: admin_management (plugin)

We do NOT ship until extension_example_test.go compiles in each module.

## Migration cleanup

After Phase B completes, the existing `pk-modules/pkg/coremodules/` and `pk-modules/pkg/homepage/` are EITHER:
- Removed (if redundant with new modules)
- Reframed as legacy demos under `examples/`

This cleanup happens at the END of Phase B, not module-by-module.
