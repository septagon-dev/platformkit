# PlatformKit OSS v0.0.0 — Design Spec

- **Status:** Draft, awaiting user review
- **Date:** 2026-05-17
- **Author:** Claude (with maxdiscite@gmail.com)
- **Related:** `OSS_OPEN_CORE_SPLIT.md`, `OSS_EXTRACTION_PLAN.md`, `OSS_QUALITY_GATE.md`, `OSS_REPOSITORY_MANIFEST.tsv`, `PLATFORMKIT_FORMULA.md`

## 0. Summary

Cut the first public release of PlatformKit by extracting the full set of architectural pillars and a curated 9-module pack from `septagon-dev/*` into `septagon-oss-workspace/*`. The release ships under the `github.com/septagon-oss/*` namespace, tagged `v0.0.0` across 10 repos. A one-module Pro-extension PoC (`user_management`) proves the open-core extension contract end-to-end before tag.

The bar is **masterpiece quality**, scoped to what is genuinely best-in-class today. Any capability that already exists in production form inside `septagon-dev` and meets the public/private boundary rules is in scope.

## 1. Goals

1. **All architectural pillars of PlatformKit live in OSS.** Module system, application lifecycle, infrastructure providers (logger/cache/db/router), observability, security baseline, resilience, event bus + outbox, entity/CRUD framework, design tokens, runtime/host, testkit. The OSS is not a subset of the framework — it is the framework.
2. **A 9-module essentials pack ships polished.** Each module has ports, sqlite default implementation, embedded migrations, admin pages, extension hooks, tests, and a Pro-extension example.
3. **The Pro extension model is proved.** `platformkit-business-modules/user_management` refactors to embed `pk-modules/pkg/user.Module` and all its existing tests still pass. If the contract is not extensible enough for one module, it is not ready.
4. **The first developer hour works.** `git clone septagon-oss/pk-starter-saas && cd pk-starter-saas && go run .` opens an admin at `http://localhost:8080/admin` against a SQLite database, with a seeded tenant + admin user, zero external dependencies, zero npm.
5. **Every OSS repo has CI from day one.** GitHub Actions (test, vet, staticcheck, codeql, dependency-review, release) wired in all 10 OSS repos.
6. **The quality gate is green.** The architecture + execution gates defined in `OSS_QUALITY_GATE.md` pass for every touched repo.

## 2. Non-Goals (explicit, not deferred-quiet)

The following are **out of scope for v0.0.0** and ship in v0.0.1 or later:

- Vue / registry / A2UI / SPA admin UI — admin is server-rendered Go templates + pk-design tokens
- `pk new <project> --template <t>` scaffold generators — first-run path is `git clone` of a starter repo
- Storybook for OSS components
- NATS / JetStream / Kafka event providers — only in-memory + sqlite-outbox in OSS; cloud providers stay Pro
- SCIM provisioning — stays in Pro `auth_management`
- Magic-link login, OAuth providers, MFA-TOTP, WebAuthn — v0.0.0 ships username/password + session cookies; richer auth is v0.0.1
- `site_management`, `entitlement_management`, `billing_management`, `chat_management`, `file_management`, `mail_management` as full modules — `mail_management` ships as a `MailSender` port + logger-stub default; the rest are v0.1.0+ candidates
- `translation_management` — v0.0.0 modules use literal English strings; a no-op `TranslationRegistrar` port is exposed for forward compatibility
- `change_management` — already optional in source, dropped from v0.0.0 default
- Full bridge of all 9 modules in `septagon-dev` — only `user_management` is bridged as PoC
- Multi-region deployment, Pulumi/Terraform overlays, Helm charts — all stay private
- Sourcegraph/MCP/A2A-style ancillary services
- End-to-end smoke test through Playwright (planned for v0.0.1)
- Rate limiting on `api_key_management` (planned for v0.0.1; rate-limit primitive ships in pk-core/pkg/security/ratelimit but is not wired into the module by default)

## 3. Public / Private Boundary

The line between OSS and Pro is drawn at the **provider, not the contract**.

### OSS owns

- All public contracts (ports, descriptors, interfaces)
- All in-memory / sqlite / stdlib / file-based default providers
- All security baseline primitives (csrf, cors, headers, passhash, signed-cookies, ratelimit primitives, signature verification)
- The reference admin UI implementation (Go templates + tokens)
- The starter app, CLI, and documentation
- The 9-module essentials pack

### Pro keeps

- NATS / JetStream / Kafka event providers (paid infrastructure)
- Postgres-cluster / read-replica / cloud-db providers (hosted defaults)
- SCIM provisioning, enterprise OAuth providers, SAML
- Cloud secrets management (AWS Secrets, GCP Secret Manager, Vault)
- Vertical modules (`traffic_management`, `spatial_management`, `pricing_engine`, `sku_management`, `order_management`, `payment_management`, `review_queue_management`)
- Demo/client overlays (`septagon-demos/*`, client extensions)
- Synology routing, GitOps mirrors, staging release runners
- Hosted observability backends (Datadog, Honeycomb adapters)
- Vue/registry frontend kit (until extracted in a later release)
- Pro distribution tag (`platformkit-pro`)

### Boundary enforcement

A test in `pk-core/pkg/architecture` fails CI if any `github.com/septagon-oss/*` package imports `github.com/septagon-dev/*`. The reverse direction is allowed and expected.

## 4. OSS Workspace Topology

After v0.0.0, `septagon-oss-workspace/` looks like:

```
septagon-oss-workspace/
├── go.work                              # uses all 10 repos
├── README.md
│
├── pk-shared/                           # cross-repo vocabulary
│   pkg/{composition,contract,flowdef,statemachine,ids,errors,clock}
│
├── pk-core/                             # platform kernel — ALL pillars
│   pkg/
│   ├── module/                          # module bundles, catalog, composition (already exists)
│   ├── application/                     # NEW: lifecycle, fx wiring, app construction
│   ├── infrastructure/                  # NEW: logger/cache/db/router provider contracts
│   ├── observability/                   # NEW: logger, metrics, tracing, health, guardrail
│   ├── security/                        # NEW: authn, authz, cookies, cors, csrf, headers, passhash, ratelimit, signature
│   ├── resilience/                      # NEW: retry, circuit-breaker, transactions
│   ├── event/                           # NEW: envelope, in-memory bus, noop, resilient, sqlite outbox
│   ├── entity/                          # entity descriptors (already exists) + CRUD handler helpers
│   ├── authz/                           # policy declarations (already exists)
│   ├── registry/                        # (already exists)
│   ├── mutation/                        # (already exists)
│   └── architecture/                    # fitness tests + boundary enforcement (extended)
│
├── pk-design/                           # unchanged surface, possibly extend with semantic primitives
│   pkg/{catalog,components,themes,tokens}
│
├── pk-runtime/                          # unchanged surface (host, httpx, health, request)
│
├── pk-testkit/                          # unchanged surface (apitest, flowtest, conformance)
│
├── pk-client/                           # unchanged surface (small HTTP transport + SDK primitive)
│
├── pk-tools/                            # ADD cmd/pk binary
│   cmd/pk/{doctor,verify,explain,main}.go
│   pkg/{cliapp,tui}                     # (already exists)
│
├── pk-modules/                          # the 9 essential modules
│   pkg/portslib/                        # shared ports across modules (AdminRegistrar, MailSender, HealthRegistrar, ...)
│   pkg/tenant/                          # ports + sqlite default + admin pages + extension example
│   pkg/user/
│   pkg/auth/
│   pkg/api_key/
│   pkg/audit/
│   pkg/health/
│   pkg/notification/
│   pkg/content/
│   pkg/admin/                           # admin plugin (renderer, registrar impl, default pages)
│
├── pk-apps/                             # runnable examples
│   apps/starter-saas/                   # ADD: clonable monolith
│   examples/{minimal,runtime}           # (already exists, kept as smaller demos)
│
└── pk-docs/                             # documentation
    docs/v0.0.0/                         # ADD: overview, extension-guide, module-reference,
                                         # security-baseline, observability-guide, starter-saas-tutorial
```

Each repo is its own Git remote (`github.com/septagon-oss/pk-*`). The workspace is a developer convenience, not a published artifact.

## 5. Core Pillars — `pk-core` extraction detail

For each pillar, the source location in `septagon-dev` and the public API shape in `pk-core`.

### 5.1 `pk-core/pkg/application` — application lifecycle

Source: `platformkit-backend-kit/app/application`

Public API:
```go
type App struct { /* fx wiring + module catalog */ }
type Option func(*config)

func New(opts ...Option) *App
func WithName(name string) Option
func WithVersion(v string) Option
func WithCatalog(c module.Catalog) Option
func WithInfrastructure(p infrastructure.Provider) Option
func WithSecurity(...) Option
func WithObservability(...) Option

func (*App) Run(ctx context.Context) error
func (*App) Stop(ctx context.Context) error
```

Strip: hosted/cloud overrides, private telemetry sinks, traffic-management hooks.

### 5.2 `pk-core/pkg/infrastructure` — provider contracts

Source: `platformkit-backend-kit/infrastructure/config`

Public API: contracts for `Logger`, `Cache`, `Database`, `Router`. Default providers:
- `Logger`: stdlib `log/slog` JSON to stderr
- `Cache`: in-memory `sync.Map` with TTL
- `Database`: `database/sql` over `modernc.org/sqlite` (pure-Go, no CGO)
- `Router`: stdlib `net/http.ServeMux` wrapped with middleware chain

Pro replaces providers via constructor options.

### 5.3 `pk-core/pkg/observability` — logger, metrics, tracing, health, guardrail

Source: `platformkit-backend-kit/observability/{logger,metrics,tracing,guardrail,health}` + `LOGGING_STANDARDS.md`

Public API:
```go
package observability

type Logger interface { Debug/Info/Warn/Error(ctx, msg, attrs...) }
type Metrics interface { Counter/Histogram/Gauge(...) }
type Tracer interface { Start(ctx, name) (ctx, Span) }
type HealthReporter interface { Report(name string, check HealthCheck) }
type Guardrail interface { Verify(invariant string) error }
```

Default providers:
- `Logger`: slog JSON
- `Metrics`: stdlib expvar + Prometheus-compatible scrape endpoint at `/metrics` (using `prometheus/client_golang`, vendored)
- `Tracer`: OpenTelemetry SDK with OTLP-HTTP exporter (configurable endpoint; off by default)
- `HealthReporter`: in-memory registry, exposed at `/healthz` and `/readyz`

### 5.4 `pk-core/pkg/security` — security baseline

Source: `platformkit-backend-kit/security/*` minus enterprise-only paths

Brings in (verbatim or rewritten clean):
- `authn` — session middleware contract, no specific provider
- `authz` — policy evaluation contract, no specific provider
- `cookies` — signed/encrypted cookies, secure defaults
- `cors` — CORS middleware
- `csrf` — double-submit token CSRF protection
- `headers` — HSTS, X-Frame-Options, CSP, X-Content-Type-Options, Referrer-Policy
- `passhash` — bcrypt (cost 12) + argon2id primitive
- `ratelimit` — token-bucket primitive (not wired by default; users opt in)
- `signature` — HMAC request signing
- `identity` — request identity context (subject, tenant, scope)
- `middlewarepolicy` — declarative middleware composition

Excludes: `previewauth` (private feature gate), provider-specific impls.

### 5.5 `pk-core/pkg/resilience` — retry, circuit-breaker, transactions

Source: `platformkit-backend-kit/resilience/*`

Public API: `Retry`, `CircuitBreaker`, `Bulkhead`, `Transaction` interfaces with sensible defaults. Strip provider-specific implementations.

### 5.6 `pk-core/pkg/event` — event bus + outbox

Source: `platformkit-backend-kit/app/event/{envelope,memory,noop,resilient}`

Brings in:
- `envelope` — CloudEvents-compatible event envelope
- `bus` — in-memory pub/sub
- `noop` — discards events (for tests)
- `resilient` — wraps any bus with retry + outbox

Adds:
- `outbox/sqlite` — outbox table + dispatcher loop, durable across restarts

Stays in Pro:
- `nats`, `jetstream`, `kafka`, `websocket`, `cloudevents/http`

### 5.7 `pk-core/pkg/entity` — entity descriptors + CRUD helpers

Source: existing `pk-core/pkg/entity` + `platformkit-backend-kit/api/GenericHandler`

Existing descriptors stay. Add:
- `entity.GenericHandler[T]` — auto-CRUD HTTP handler bound to a `Store[T]`
- `entity.Store[T]` — generic sqlite-backed store with migrations

This is the spine modules use for entity CRUD.

## 6. The 9-Module Pack (`pk-modules`)

Each module lives at `pk-modules/pkg/<name>/` and ships:

```
pk-modules/pkg/<name>/
├── module.go                           # Module struct, NewModule(opts...), exported for embedding
├── options.go                          # WithStore, WithMailer, WithExtraRoutes, WithExtraAdminPages
├── ports.go                            # public ports for Pro to consume/extend
├── entities.go                         # entity descriptors
├── handler.go                          # HTTP routes via entity.GenericHandler + custom routes
├── service.go                          # business logic
├── admin.go                            # admin pages (Go template strings + AdminRegistrar registration)
├── store/
│   ├── store.go                        # Store interface
│   └── sqlite/sqlite.go                # default sqlite impl
├── migrations/
│   ├── 0001_initial.up.sql
│   └── embed.go                        # //go:embed FS
├── module_test.go                      # unit tests
├── extension_example_test.go           # demonstrates Pro embedding & compiles in CI
└── doc.go                              # package doc comment
```

### 6.1 Per-module overview

| Module | Public ports | Key responsibilities | Notable cuts vs source |
|---|---|---|---|
| **tenant** | `TenantService`, `TenantContextProvider`, `TenantIsolationEnforcer` | tenant CRUD, current-tenant context, query-scope middleware | drops vertical tenant types (traffic, spatial) |
| **user** | `UserService`, `UserBoundaryReader`, `UserBoundaryRoleManager` | user CRUD, profile, role assignment | drops SCIM, enterprise SSO |
| **auth** | `AuthService`, `SessionStore`, `PasswordHasher`, `LoginPolicy` | login/logout, session lifecycle, password reset email | drops magic links, OAuth, MFA (v0.0.1) |
| **api_key** | `APIKeyService`, `APIKeyAuthenticator`, `RateLimiter` (port only) | API key CRUD, key auth middleware | rate-limit primitive in pk-core, wiring deferred to v0.0.1 |
| **audit** | `AuditService`, `AuditReader`, `AuditEmitter` | append-only audit log, query, subscribe-to-event-bus | drops vertical audit categories |
| **health** | `HealthRegistrar`, `HealthReporter` | health check registry, /healthz, /readyz | thin wrapper over pk-core/pkg/observability |
| **notification** | `NotificationService`, `NotificationChannel`, `NotificationSubscriber` | create/dispatch notifications via channels (mail, in-app); subscribes to event bus | drops translation_management dep (English literals); drops change_management (optional anyway) |
| **content** | `ContentService`, `ContentReader`, `ContentPublisher` | generic content CRUD (page, post, snippet types) | drops site/SEO/CDN concerns (those stay Pro/v0.1.0) |
| **admin** (plugin) | `AdminRegistrar`, `AdminRenderer`, `AdminPage` | register CRUD pages, render server-side, sidebar | wrap above modules; replaceable by Pro |

### 6.2 Shared ports (`pk-modules/pkg/portslib`)

```go
type MailSender interface { Send(ctx context.Context, msg Mail) error }
type TranslationRegistrar interface { Register(key, lang, text string) error }  // no-op default
type HealthRegistrar interface { Register(name string, check HealthCheck) }
type AdminRegistrar interface {
    RegisterEntityCRUD(moduleID, entityName, apiPath string) error
    RegisterPage(p AdminPage) error
    RegisterSidebarSection(s SidebarSection) error
}
type SettingsRegistrar interface { Register(group, key string, schema SettingSchema) error }
```

Default implementations live next to the port and are wired by default in `NewModule()`.

### 6.3 Module composition contract (the extension surface)

Every module exposes:
```go
type Module struct {
    metadata module.Metadata
    store    Store
    mailer   portslib.MailSender
    // ... unexported impl details
}

func NewModule(opts ...Option) *Module       // returns *Module that Pro can embed
func (*Module) Compose() module.Composable   // returns pk-core/module.Composable
func (*Module) Migrations() fs.FS            // exposes embedded migrations for Pro to chain
```

Pro embeds:
```go
package user_management
import "github.com/septagon-oss/pk-modules/pkg/user"

type ProModule struct {
    *user.Module
    sso SSOService
}

func NewModule(deps Deps) *ProModule {
    base := user.NewModule(
        user.WithStore(postgres.NewUserStore(deps.DB)),
        user.WithMailer(ses.NewMailer(deps.SES)),
        user.WithExtraAdminPages(scimAdminPage),
    )
    return &ProModule{Module: base, sso: deps.SSO}
}
```

## 7. Admin Plugin Boundary

`admin` ships as a module in the pack but is architecturally **swappable**:

- Other 8 modules call `AdminRegistrar.RegisterEntityCRUD(...)` at boot via fx invoke
- They never import `pk-modules/pkg/admin` — only `pk-modules/pkg/portslib`
- A different admin implementation can be wired by calling `module.NewCatalog().Add(other8...).WithAdminRegistrar(custom).Build()` and omitting `admin.Module()`
- The default `admin` renders Go `html/template` views with CSS imported from `pk-design/pkg/tokens` (compiled to a `_admin.css` stylesheet at build time)
- No npm, no Vite, no JS framework in the OSS admin
- Pro's richer Vue/registry admin slots in via the same `AdminRegistrar` interface

### 7.1 Admin styling

`pk-design/pkg/tokens` already produces a `Resolve` API that returns `{key: value}` token maps. The admin module includes a `go:generate` step that reads the default `pk-design` theme and emits `pk-modules/pkg/admin/static/_admin.css`. This file is embedded via `//go:embed` and served at `/static/_admin.css`.

### 7.2 Admin templates

Templates live in `pk-modules/pkg/admin/templates/*.tmpl`, embedded via `//go:embed`. The renderer pre-parses on init. Each registered entity gets:

- `GET /admin/<entity>` — list view (paginated, searchable)
- `GET /admin/<entity>/new` — create form
- `POST /admin/<entity>` — create action
- `GET /admin/<entity>/:id` — detail/edit form
- `PUT /admin/<entity>/:id` — update action
- `DELETE /admin/<entity>/:id` — delete action with confirm

Form fields are derived from the `entity.Descriptor` (already exists in pk-core).

## 8. Storage / Provider Contract

### 8.1 Default stack

| Concern | OSS default | Pro override |
|---|---|---|
| DB | sqlite (modernc.org/sqlite — pure Go) | postgres, mysql, planetscale, etc. |
| Cache | sync.Map with TTL | redis, memcached |
| Logger | slog JSON | datadog, honeycomb, otel sink |
| Mailer | logger stub (writes "would send" to logs) | SES, SendGrid, Postmark, SMTP |
| Event bus | in-memory + sqlite outbox | NATS, JetStream, Kafka |
| Session store | sqlite | redis, cookie-encrypted, JWT |
| Object storage | local filesystem | S3, GCS, R2 |

### 8.2 Override mechanism

Every provider is injected via a `With*` option on the module or via the application builder:

```go
app := application.New(
    application.WithInfrastructure(infrastructure.SQLite("./pk.db")),
    application.WithModules(
        tenant.NewModule(),
        user.NewModule(user.WithStore(myCustomStore)),
        ...
    ),
)
```

### 8.3 Migration management

Each module embeds its own migrations via `//go:embed migrations/*.sql` and registers them with `pk-core/module.RegisterModuleMigrations(...)`. The application runs migrations on boot in dependency-ordered fashion. Migrations are append-only (existing PlatformKit invariant); editing an existing file is rejected by a CI check.

## 9. CLI Surface — `pk-tools/cmd/pk`

A single binary, three subcommands:

```
pk doctor          # check Go ≥1.22, sqlite available, port 8080 free, env summary
pk verify          # go vet ./... && go test ./... with structured output
pk explain modules [--json]   # load the OSS catalog, print module graph
```

Built on existing `pk-tools/pkg/cliapp` (cobra root) + `pk-tools/pkg/tui` (renderer). Both subcommands use `os/exec` for shelling out to `go`; `explain` imports `pk-modules` + `pk-core/module` directly.

Packaged as `go install github.com/septagon-oss/pk-tools/cmd/pk@v0.0.0`. A `Makefile` target in `pk-tools` builds the binary; a future Goreleaser config can produce cross-platform binaries (deferred to v0.0.1).

Explicitly **out of scope**: `pk new`, `pk scaffold`, `pk up`, `pk migrate`, `pk seed`, `pk app status`. The first-run path is `git clone` of `pk-starter-saas`.

## 10. Starter App — `pk-apps/apps/starter-saas`

The flagship clonable repo. Eventually mirrored as `septagon-oss/pk-starter-saas`; for v0.0.0 it lives in `pk-apps/apps/starter-saas`.

### 10.1 Contents

```
pk-apps/apps/starter-saas/
├── main.go                 # ~80 lines, composes all 9 modules
├── config.yaml             # database.dsn: file:./pk.db, http.addr: :8080
├── seed/seed.go            # creates demo tenant + admin user on first boot
├── go.mod                  # depends on pk-* OSS modules at v0.0.0
├── README.md               # quickstart
└── .gitignore              # excludes pk.db, .env
```

### 10.2 First-run UX

```bash
git clone https://github.com/septagon-oss/pk-starter-saas
cd pk-starter-saas
go run .
# → Listening on :8080
# → Admin at http://localhost:8080/admin
# → Login: admin@local.test / changeme
```

The first boot:
1. Migrates SQLite schema (all 9 modules)
2. Seeds one tenant ("Acme Inc"), one admin user, one demo content entry
3. Starts HTTP server
4. Prints startup banner with admin URL + creds

### 10.3 Configuration

Single YAML file, environment variable overrides:

```yaml
http:
  addr: :8080
database:
  dsn: file:./pk.db
auth:
  session_secret: ${PK_SESSION_SECRET}    # auto-generated on first boot if absent
  cookie_secure: false                    # production override to true
observability:
  log_level: info
  otel_endpoint: ""                       # set to enable
```

## 11. Documentation — `pk-docs`

Adds `docs/v0.0.0/`:

| File | Purpose |
|---|---|
| `overview.md` | What PlatformKit is, the open-core model, where to start |
| `extension-guide.md` | How Pro extends OSS — the embedding pattern, with worked example |
| `module-reference.md` | Per-module: ports, options, default providers, admin pages |
| `security-baseline.md` | What `pk-core/pkg/security` provides and what users still own |
| `observability-guide.md` | Logger/metrics/tracing wiring + OTel setup |
| `starter-saas-tutorial.md` | First-run walkthrough + "add your first module" |
| `architecture.md` | The formula: core defines rules, modules add capabilities, clients compose |
| `release-notes-v0.0.0.md` | What's in v0.0.0, what's coming in v0.0.1 |

Pre-existing assets in `pk-docs` (adr/, requirements/, antora-playbook.yml) stay in place; v0.0.0 just adds the user-facing slice.

## 12. CI / Release Pipeline

Each of the 10 OSS repos receives the following GitHub Actions workflows (copied from `platformkit-backend-kit/.github/workflows/` and adapted):

| Workflow | Trigger | Action |
|---|---|---|
| `go-ci.yml` | push, PR | `go vet ./... && go test ./... && staticcheck ./...` |
| `codeql.yml` | weekly + PR | CodeQL Go security scan |
| `dependency-review.yml` | PR | reject PRs introducing high-risk dependencies |
| `release.yml` | tag push (`v*`) | build, generate release notes, attach pkg.go.dev link |
| `repository-baseline.yml` | daily | verify LICENSE, README, SECURITY, CONTRIBUTING, CODEOWNERS present |

`pk-docs` additionally runs Antora site build on push.

`pk-tools` additionally runs cross-platform build for the `pk` binary (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64).

### 12.1 Repo hygiene fixes baked into v0.0.0

- Add `CODEOWNERS` to all 10 repos (currently missing per quality gate)
- Remove tracked `pk-docs/node_modules/` (should be gitignored)
- Remove tracked `pk-design/coverage.out`
- Fix two `github.com/septagon-dev` URL refs in `pk-docs/overlays/platformkit/site/homepage.{en,pt}.json` → point to `github.com/septagon-oss`

## 13. The Pro-Extension PoC — `user_management`

The single non-negotiable validation gate is that the extension contract works for one real module before tagging.

### 13.1 Scope of the bridge

After `pk-modules/pkg/user` lands, `platformkit-business-modules/user_management` is refactored to:

1. Add `github.com/septagon-oss/pk-modules` to its `go.mod`
2. Replace its internal `Module` type with `type Module struct { *user.Module; /* Pro fields */ }`
3. Replace its internal `User` entity with a Pro entity that embeds the OSS `user.User` (so OSS fields are addressable and Pro fields are additive)
4. Provide a Pro `postgres.UserStore` that implements OSS `user.Store`, injected via `user.WithStore(...)` on the embedded module; the OSS `user.SQLiteStore` remains available for local dev and test paths
5. Keep all Pro-only ports (SCIM, enterprise SSO) as Pro additions on the embedded module
6. Pass its **existing** test suite without modification

If the existing tests cannot pass against the bridged shape, the OSS contract is wrong and the spec is reopened.

### 13.2 What this proves

- The OSS `user.Module` type is correctly exported and embeddable
- The `user.Store` interface accommodates a custom backend (postgres) without internal changes
- The `user.Mailer` swap works
- Admin pages from OSS + admin pages from Pro coexist via `AdminRegistrar`
- Tests written against the OSS module also pass when consumed by Pro

### 13.3 What stays in Pro

The other 8 modules in `platformkit-business-modules` stay on their current (non-bridged) implementation in v0.0.0. They will be bridged module-by-module in v0.1.0 once the PoC pattern is validated.

## 14. Validation Gates — what counts as "done"

A v0.0.0 tag is only cut when **every** gate is green.

### 14.1 Per-OSS-repo gates

For each of pk-shared, pk-core, pk-design, pk-runtime, pk-testkit, pk-client, pk-tools, pk-modules, pk-apps, pk-docs:

1. `go test ./...` passes
2. `go vet ./...` clean
3. `staticcheck ./...` clean
4. Module path is `github.com/septagon-oss/<repo>`
5. LICENSE, README, SECURITY, CONTRIBUTING, **CODEOWNERS** all present
6. No imports of `github.com/septagon-dev/*`
7. CI workflows pass
8. `make verify` (per-repo target) green

### 14.2 Cross-repo gates (run from workspace root)

9. `cd platformkit && make audit-oss` passes
10. `cd platformkit && make validate-oss-split` passes
11. `cd platformkit && make validate-open-core-workspace` passes
12. `cd septagon-oss-workspace/pk-core && make fitness` passes (architecture invariants)
13. The architecture gate in `OSS_QUALITY_GATE.md` Sections 1-7 is green
14. The execution gate in `OSS_QUALITY_GATE.md` Sections 1-7 is green

### 14.3 Per-module gates (each of the 9 modules)

15. `extension_example_test.go` exists and compiles
16. Module composes in `starter-saas` without errors
17. Admin pages render (HTTP smoke test in `module_test.go`)
18. Migrations run idempotently on SQLite (up + down + up)

### 14.4 Starter-app gate

19. `cd pk-apps/apps/starter-saas && go run .` boots, listens, serves `/admin` and `/healthz` returning 200, login with seeded creds succeeds, audit log records the login event

### 14.5 Pro-extension gate

20. `cd platformkit-business-modules && go test ./user_management/...` passes after the bridge refactor

### 14.6 CI gate

21. All 10 OSS repos have all 5 CI workflows checked in and passing on their `main` branch

## 15. Repository Manifest Update

`OSS_REPOSITORY_MANIFEST.tsv` is updated to reflect the v0.0.0 source paths:

```
pk-shared    1    platformkit-shared             composition,fieldmeta,flowdef,observability,presentation,registry,standards,statemachine,sync,tokens
pk-core      1    platformkit-backend-kit        app/module,app/application,app/event,core,infrastructure/config,observability,resilience,security,api,entity
pk-design    2    platformkit-design-system      adapters,experiences,moduletokens,overlays,pkds,themes,tokens,tw
pk-client    2    platformkit-backend-kit        client
pk-tools     2    platformkit-devtools           cmd/platformkit/{doctor,verify,explain},platformkit/cli,platformkit/contractcheck
pk-modules   3    platformkit-business-modules   tenant_management,user_management,auth_management,api_key_management,audit_management,health_management,notification_management,content_management,admin_management,ports,catalog
pk-apps      4    platformkit-apps               complete-saas-monolith (skeleton, no private overlays)
pk-docs      5    platformkit-docs               adr,architecture,requirements,docs,apps,packages,schemas
```

(The existing manifest had `pk-runtime` and `pk-testkit` missing; this spec adds them as stage-1 alongside pk-core and pk-shared.)

## 16. Phasing & Timeline

Approximate phasing for the work, ordered by dependency. Each phase ends with a green workspace.

### Phase A — Foundation extraction (~2 weeks)
- Extract `pk-core/pkg/application` from `platformkit-backend-kit/app/application`
- Extract `pk-core/pkg/infrastructure` from `platformkit-backend-kit/infrastructure/config`
- Extract `pk-core/pkg/observability` from `platformkit-backend-kit/observability`
- Extract `pk-core/pkg/security` from `platformkit-backend-kit/security`
- Extract `pk-core/pkg/resilience` from `platformkit-backend-kit/resilience`
- Extract `pk-core/pkg/event` from `platformkit-backend-kit/app/event` (memory + outbox only)
- Extend `pk-core/pkg/entity` with `GenericHandler[T]`
- Run `make fitness` and quality gate after each pillar

### Phase B — Module pack (~2.5 weeks)
- Build `pk-modules/pkg/portslib`
- Implement 8 stable modules (tenant, user, auth, api_key, audit, health, notification, content)
- Implement `pk-modules/pkg/admin` (renderer + templates + token CSS bake)
- Per-module: ports, store, sqlite impl, migrations, admin pages, tests, extension example
- The `extension_example_test.go` files become the contract documentation

### Phase C — Starter app + CLI (~1 week)
- Build `pk-apps/apps/starter-saas`
- Build `pk-tools/cmd/pk` with doctor, verify, explain
- Smoke test the full path: clone → run → login → audit

### Phase D — Documentation + CI + hygiene (~1 week)
- Write all `pk-docs/v0.0.0/*` files
- Copy CI workflows into all 10 repos
- Add CODEOWNERS to all repos
- Remove tracked node_modules / coverage.out
- Fix homepage JSON URLs
- Update `OSS_REPOSITORY_MANIFEST.tsv`

### Phase E — Pro extension PoC + tag (~1 week)
- Refactor `platformkit-business-modules/user_management` to bridge `pk-modules/pkg/user`
- Make all existing `user_management` tests pass
- Run all 21 validation gates
- Tag v0.0.0 across all 10 OSS repos in publish order: pk-shared → pk-core → pk-runtime → pk-testkit → pk-design → pk-client → pk-tools → pk-modules → pk-apps → pk-docs

**Total: ~7.5 weeks of focused work.**

## 17. Risks

| Risk | Mitigation |
|---|---|
| `pk-core` shape diverges from `platformkit-backend-kit/app/module` and Pro bridge breaks | The PoC bridge for `user_management` in Phase E is the early-warning system. If it doesn't work, we stop and fix `pk-core` before tagging. |
| Extraction of `observability/security/resilience/event` drags in transitive deps that aren't OSS-safe | Each extraction phase reviews `go mod why` for every new dep. Any non-stdlib non-Apache/MIT/BSD dep gets explicit approval. |
| SQLite default doesn't scale enough to feel real | SQLite is fine for starter; the bar is "git clone && go run works" not "production-grade at scale." Pro adapter is the production answer. |
| Admin Go templates feel dated and weaken "best of the best" perception | Acknowledged. The plugin boundary means Pro/community can replace with a Vue admin later without forking. v0.0.1 can backfill a Vue admin in `pk-modules/pkg/admin/vue` if desired. |
| Extraction is slower than 7.5 weeks because of unanticipated interdependencies | Phase A is the highest-risk phase; budget a 2-week slip. Worst case v0.0.0 ships in ~9-10 weeks. |
| Quality gate keeps failing on architectural invariants | The gate is the work, not a checkbox. If it fails, we fix the contract — that's the whole point of the gate. |

## 18. Open Questions

1. **Logger backend default**: slog JSON is the recommendation. Confirm acceptable.
2. **Tracing default**: OTel SDK present but off by default (endpoint blank). Confirm.
3. **Where does `pk-starter-saas` actually live for v0.0.0**: inside `pk-apps/apps/starter-saas` (this spec) or as its own `github.com/septagon-oss/pk-starter-saas` repo? Both work; this spec uses the in-pk-apps option for v0.0.0 and mirrors as a standalone repo in v0.0.1.
4. **CODEOWNERS content**: pending the user's GitHub team setup; default to `* @maxdiscite` for v0.0.0.

## 19. Appendix — File mapping (informative)

A rough mapping of `septagon-dev/*` source paths to OSS targets. This is illustrative; the actual extraction may diverge module-by-module.

| Source | Target |
|---|---|
| `platformkit-backend-kit/app/application/*.go` | `pk-core/pkg/application/*.go` |
| `platformkit-backend-kit/app/module/*.go` | already in `pk-core/pkg/module` |
| `platformkit-backend-kit/app/event/{envelope,memory,noop,resilient}/**` | `pk-core/pkg/event/**` |
| `platformkit-backend-kit/observability/{logger,metrics,tracing,guardrail,health}/**` | `pk-core/pkg/observability/**` |
| `platformkit-backend-kit/security/{authn,authz,cookies,cors,csrf,headers,identity,middlewarepolicy,passhash,ratelimit,signature}/**` | `pk-core/pkg/security/**` |
| `platformkit-backend-kit/resilience/{providers,resiliencecontract,transactions}/**` | `pk-core/pkg/resilience/**` |
| `platformkit-backend-kit/infrastructure/config/**` | `pk-core/pkg/infrastructure/**` |
| `platformkit-backend-kit/api/GenericHandler*.go` | `pk-core/pkg/entity/handler.go` |
| `platformkit-business-modules/<m>/contracts/provides/*.go` | `pk-modules/pkg/<m>/ports.go` (verbatim) |
| `platformkit-business-modules/<m>/entities/*.go` | `pk-modules/pkg/<m>/entities.go` |
| `platformkit-business-modules/<m>/features/<f>/{handler,service,routes}.go` | `pk-modules/pkg/<m>/{handler,service}.go` (rewritten against pk-core) |
| `platformkit-business-modules/<m>/migrations/*.sql` | `pk-modules/pkg/<m>/migrations/*.sql` |
| `platformkit-devtools/cmd/platformkit/{doctor,verify,explain}/*.go` | `pk-tools/cmd/pk/{doctor,verify,explain}.go` |
| `platformkit-apps/complete-saas-monolith/main.go` | `pk-apps/apps/starter-saas/main.go` (rewritten — drops all septagon-dev imports) |
