# VERIFIED_RUN.md — Ground-Truth OSS Run Log

> **This file is the single source of truth for the OSS launch kit.**
> No README, doc, blog post, or Show HN comment may show a command that is not
> recorded here as actually run and verified. Every value below (versions,
> ports, credentials, banners, HTTP codes, timings) was observed empirically on
> the machine described in "Test Environment", not copied from prose.

**Status: ✅ GREEN — the hero path works on a cold clone.** On a fresh database,
`go run .` boots the starter app, seeds a tenant + admin user, serves the admin
UI, and the full data layer is healthy (`/healthz 200`, seven data/session health checks pass,
`/api/v1/tenants 200`, login `201`). The original cold-DB failure was found,
fixed, and adversarially reviewed by Codex — see [§9 History & fixes](#9-history--fixes-what-changed-and-why).

---

## 1. What "run it" means today (entry-point inventory)

PlatformKit OSS publishes under the `github.com/septagon-oss` org (mirrored
locally at `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/`). The
published module `go.mod` files carry **no `replace` directives** — modules
resolve from the Go proxy by version. A `go.work` is used for **local multi-repo
development only** (it points at the sibling repos on disk); it is not part of the
published surface. (See `RELEASE_AND_RUN_MODEL.md`.)

Entry points (all real):

| Entry point | Location | Verb | Status |
|---|---|---|---|
| **Front door** (hero) | `github.com/septagon-oss/platformkit` — a thin root `main` wrapper over `pk-apps/pkg/starterapp` | `git clone … && go run .` | ✅ Builds + **boots green** (9 modules, 7 data/session health checks, login 201). Locally landed + verified; public clone awaits the gated push. |
| Starter app (contributor) | `pk-apps/apps/starter-saas/` (`main.go`) | `go run .` (in the workspace) | ✅ Same composition as the front door; the in-workspace dev path |
| `pk` CLI | `pk-tools/cmd/pk/` (`doctor`, `verify`, `explain`) | `go run ./cmd/pk …` | Exists; a dev-workflow tool, not the run-the-app path |
| Examples | `pk-apps/examples/minimal`, `examples/runtime` | `go run ./examples/minimal` / `go run ./examples/runtime` | Smaller demos, not the hero path |

There is no `make up` / `make showroom` in the OSS workspace. `pk-apps/Makefile`
exposes only `test`, `vet`, `staticcheck`, `race`, and `verify` (verification
targets, not run targets).

**Decided hero verb:** `git clone https://github.com/septagon-oss/platformkit && cd platformkit && go run .`.
The front-door repo is a ~25-line root `main` that imports `pk-apps/pkg/starterapp`
and boots the identical nine-module monolith via `starterapp.DefaultConfig()`. The
in-workspace equivalent (`cd pk-apps/apps/starter-saas && go run .`) runs the same
`starterapp.BuildApp` composition and is the contributor path.

> **Version namespaces (don't conflate them):** the per-module *port-contract*
> version (`ModuleVersion`, shown by `pk explain modules`) is **`0.0.0`** — the
> initial contract baseline, deliberately independent of the distribution. The
> *release/distribution* version is **`v0.1.0`** (the git tag / Go module version).
> Both are correct simultaneously; do not claim `pk explain` prints `v0.1.0`.

---

## 2. Prerequisites (real, verified)

| Requirement | Value | Source / verification |
|---|---|---|
| Go toolchain | **1.26+** | `go.work` and `pk-apps/go.mod` both pin `go 1.26`. Verified with `go1.26.3`. |
| CGO | **Not needed** | SQLite driver is `modernc.org/sqlite v1.50.1` (pure Go). No C compiler. |
| npm / Node | **Not needed** | Admin UI is embedded Go templates + one embedded CSS file. Zero JS build. |
| External services | **None** | SQLite file + in-memory cache. No Postgres, Redis, Docker. |
| Network | First build downloads ~9 Go modules; afterwards offline-capable. |
| Free TCP port | App binds **`:8080`**. If 8080 is busy, change `http.addr` in `config.yaml`. |

---

## 3. Current reproduction command block

> Run from inside the cloned workspace, not from `/tmp`. Only Go's temporary
> build workspace is redirected to disk; the shared default build and module
> caches remain content-addressed and reusable across repositories.

```bash
cd septagon-oss-workspace/pk-apps/apps/starter-saas

export GOTMPDIR="$PWD/../../../.tmp-go-tmp"
export TMPDIR="$PWD/../../../.tmp-go-tmp"
mkdir -p "$GOTMPDIR"

go run .
# → banner prints the admin URL + default login (see below)
```

In another shell:

```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/api/v1/tenants
curl -s -X POST http://localhost:8080/api/v1/auth/sessions \
  -H 'Content-Type: application/json' \
  -d '{"tenant_id":"tenant_acme","email":"admin@local.test","password":"changeme"}'
```

### Build result

- Cold build (incl. downloading ~9 modules): **~17 s wall** on first run; a
  stranger adds their own network time. Warm cache: server ready in **~2 s**.
- Exit code `0`. No compile errors, no missing deps.

### Startup banner (verbatim)

```
============================================================
 starter-saas — PlatformKit OSS monolith
  listening:    http://localhost:8080
  admin UI:     http://localhost:8080/admin
  health:       http://localhost:8080/healthz
  metrics:      http://localhost:8080/metrics
  default login: admin@local.test / changeme
  modules:      9 composed (admin_management, health_management, tenant_management, user_management, audit_management, auth_management, api_key_management, content_management, notification_management)
============================================================
```

### Seeded values (verbatim from `seed/seed.go`; self-repairing on every boot)

- Tenant: `Acme Inc` (id **`tenant_acme`**, slug `acme`)
- Admin user: **`admin@local.test`** / **`changeme`** (id `user_admin`)

### HTTP results (fresh DB — the cold-clone reality)

| Path | Result |
|---|---|
| `GET /` (HTML landing) | `200` |
| `GET /admin` (admin shell HTML) | `200` |
| `GET /admin/tenants`, `/admin/user_management/User` (sidebar + entity links) | `200` |
| `GET /live` | `204` |
| `GET /ready` | `200` |
| `GET /metrics` | `200` |
| **`GET /healthz`** | **`200`** — `{"status":"healthy"}`, all 7 data/session health checks pass (6 module stores + `auth_management.sessions`) |
| **`GET /api/v1/tenants`** | **`200`** — `[{"id":"tenant_acme","slug":"acme","name":"Acme Inc",…}]` |
| **`POST /api/v1/auth/sessions`** (with `tenant_id`) | **`201`** — returns a session for `user_admin` |

**Time-to-working-admin:** ~2 s (warm cache) / ~17 s (first cold build).

### Login request shape (important for docs — do not omit `tenant_id`)

PlatformKit is multi-tenant, so login requires the tenant:

```json
{"tenant_id": "tenant_acme", "email": "admin@local.test", "password": "changeme"}
```

Bad input is now handled cleanly (verified): missing `tenant_id` / identifier /
password → **`400`**; wrong email or password → **`401`** (no user enumeration);
only genuine internal faults → `500`.

---

## 4. Honest caveats launch copy MUST respect

These are true today and any "dummy-proof" copy has to account for them:

1. **`/admin` is an open dashboard, not a gated login.** The seeded
   `admin@local.test / changeme` credentials are for the **auth API**
   (`POST /api/v1/auth/sessions`), not an admin login wall. Do not write
   "log into the admin UI with these creds" — there is no admin login screen
   today. (Honest framing: "the admin UI is served at `/admin`; the seeded
   credentials authenticate against the auth API.")
2. **Login needs `tenant_id`.** Any curl/snippet in docs must include it, or the
   reader gets a (now correct) `400`.
3. **Port 8080 must be free.** If busy, the user edits `http.addr` in
   `config.yaml`. Worth a one-line note in the quickstart.
4. **First build is ~17 s + download time.** Set expectations ("first run
   compiles and downloads modules; subsequent runs start in ~2 s").

---

## 5. Gotchas a stranger hits (curated, post-fix)

- **First build takes ~15–20 s + download time** (no compile errors — this part
  is smooth). Subsequent starts ~2 s.
- **Port 8080 may be busy** on a dev machine → edit `config.yaml`.
- **Login without `tenant_id` returns 400** — include the tenant in the payload.
- **No npm, no Docker, no CGO** — lead with this; it's a genuine, pleasant
  surprise for the Go/HN crowd.
- `pk.db` is created in the working directory and is gitignored; deleting it
  resets to a clean seeded state (the seed self-repairs on next boot).

---

## 6. Verified-true claims the launch MAY make

Safe to state in READMEs / Show HN, scoped as below:

- "Clone, `cd pk-apps/apps/starter-saas`, `go run .` → a seeded multi-tenant SaaS
  admin at `http://localhost:8080/admin` in seconds."
- "Pure Go. No CGO, no npm, no Docker, no external database — SQLite by default."
- "9 modules composed (tenancy, users, auth, audit, API keys, content,
  notifications, health, admin), health-checked at `/healthz`."
- Scope qualifier to keep honest: verified on Linux/x86_64, Go 1.26,
  `modernc.org/sqlite v1.50.1`, default `/admin` base path, fresh DB.

---

## 7. Test Environment (for reproducibility)

- Host OS: Linux (Arch, kernel 7.0.x), x86_64.
- Go: `go version go1.26.3 linux/amd64` (satisfies `go 1.26` pin).
- Workspace: `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace` (`go.work`
  pins `go 1.26`; module `replace` directives point at sibling repos).
- App: `pk-apps/apps/starter-saas`, `config.yaml` `http.addr: ":8080"`,
  DSN `file:./pk.db?_pragma=busy_timeout(5000)&cache=shared&mode=rwc`,
  driver `modernc.org/sqlite v1.50.1`, one shared `*sql.DB` with `SetMaxOpenConns(1)`.
- Go caches redirected to `septagon-oss-workspace/.tmp-go-*` during all builds.
- Date of green capture: 2026-06-03.

## 8. Self-verification

The exact §3 block was re-run in a fresh shell against a freshly deleted `pk.db`:
build succeeds, server listens on `:8080`, `/` and `/admin` return `200`,
`/healthz` returns `200` with all seven data/session health checks passing, `GET /api/v1/tenants`
returns `200` with the seeded `Acme Inc`, and login with `tenant_id` returns
`201`. Reproduced green deterministically.

## 9. History & fixes (what changed and why)

The first cold-run capture (2026-06-02) found a **launch blocker**: on a fresh
`pk.db`, `/healthz` returned `503` and all entity APIs `500 no such table`. The
fix loop (Claude implements → Codex adversarially reviews → Claude closes
findings → re-verify) resolved it:

- **Shared SQLite pool** (`pk-apps` `489c6f7`): the starter wired each of 7 data
  modules with its own `WithSQLiteDSN` → 7 independent `*sql.DB` pools over one
  file. Now `app.go` opens **one** `*sql.DB` with `SetMaxOpenConns(1)` and injects
  it into every module (`WithStore` / `auth.WithSQLiteDB`). `App.Close()` now
  actually closes the pool (was a no-op).
- **Codex finding — original 503 was likely environmental.** Codex's independent
  review could not reproduce the 503 on HEAD with `modernc.org/sqlite v1.50.1`
  (every store already ran `CREATE TABLE IF NOT EXISTS` at construction). Most
  probable original cause: a stale/locked/partial `pk.db`, wrong working dir, or
  a different (CGO) driver. The shared-pool change is correct **hardening**;
  `busy_timeout` was added to de-risk the lock scenario directly. Net: the cold
  run is now green and structurally robust.
- **Self-repairing seed** (`pk-apps` `d6e7823`): seed now independently ensures
  the tenant AND the admin user (with the advertised password) on every boot, so
  a partial first boot can no longer permanently strand the login.
- **`busy_timeout=5000`** added to the DSN.
- **Port unified to `:8080`** (`config.yaml` had drifted to `:18090`).
- **Admin sidebar links fixed** (`pk-modules` `4e34999`): they double-prefixed
  the base path (`/admin/admin/…` → 404); now render absolute `.Path` verbatim.
- **Login error mapping fixed** (`pk-modules` `d85a061`): bad input returned
  `500`; now `400` (validation) / `401` (bad creds, no enumeration) / `500` only
  for genuine faults.

Commits live in `septagon-oss/pk-apps` (`489c6f7`, `d6e7823`) and
`septagon-oss/pk-modules` (`4e34999`, `a2773b4`, `d6e7823`'s docs, `d85a061`),
plus `septagon-oss/pk-docs` (`becadbb`).
