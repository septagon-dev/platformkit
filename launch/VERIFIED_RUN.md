# VERIFIED_RUN.md — Ground-Truth OSS Run Log

> **This file is the single source of truth for the OSS launch kit.**
> No README, doc, blog post, or Show HN comment may show a command that is not
> recorded here as actually run and verified. Every value below (versions,
> ports, credentials, banners, HTTP codes, timings) was observed empirically on
> the machine described in "Test Environment", not copied from prose.

**Status: 🔴 LAUNCH BLOCKER — the documented hero path does NOT work on a cold
clone.** The app builds and serves HTTP, but on a fresh database every data
table is missing and `/healthz` returns `503 unhealthy`. Details in
[The Launch Blocker](#the-launch-blocker). Do not write launch copy that claims
"`go run .` → working admin" until this is fixed.

---

## 1. What "run it" means today (entry-point inventory)

The public surface a user clones is the workspace at
`github.com/septagon-oss/septagon-oss-workspace`, mirrored locally at
`/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/`. It contains the
sibling repos (`pk-core`, `pk-modules`, `pk-apps`, …) wired by a root `go.work`,
and each module's `go.mod` uses `replace ... => ../pk-core` style directives, so
the whole workspace must be present as siblings (a single clone provides this).

Three candidate entry points exist and are all real:

| Entry point | Location | Verb | Status |
|---|---|---|---|
| **Starter app** (hero) | `pk-apps/apps/starter-saas/` (`main.go`) | `go run .` | Builds + serves, **but unhealthy on fresh DB** |
| `pk` CLI | `pk-tools/cmd/pk/` (`main.go`; `doctor`, `verify`, `explain`) | `go run ./cmd/pk ...` | Exists (not the run-the-app path; not exercised here) |
| Examples | `pk-apps/examples/minimal`, `pk-apps/examples/runtime` | `make example` / `make runtime-example` | Exist; not the hero path |

There is no `make up` / `make showroom` in the OSS workspace. `pk-apps/Makefile`
exposes only `test`, `vet`, `staticcheck`, `verify`, `example`, `runtime-example`.

**Decided hero verb:** `go run .` inside `pk-apps/apps/starter-saas/`. This
matches the app's own `README.md` and `main.go` doc comment ("the flagship
'git clone and go run .' demo"). It is the intended dummy-proof first run.

---

## 2. Prerequisites (real, verified)

| Requirement | Value | Source / verification |
|---|---|---|
| Go toolchain | **1.26+** | `go.work` and `pk-apps/go.mod` both pin `go 1.26`. Verified with `go1.26.3` installed. |
| CGO | **Not needed** | SQLite driver is `modernc.org/sqlite v1.50.1` (pure Go). No C compiler required. |
| npm / Node | **Not needed** | Admin UI ships as embedded Go templates + one embedded CSS file (`/admin/static/_admin.css`). Zero JS build step. |
| External services | **None** | SQLite file + in-memory cache. No Postgres, Redis, Docker. |
| Network | First build downloads Go modules (~9 deps); after that, offline-capable. |
| Free TCP port | The app binds **`:18090`** (see the port note below), NOT `:8080`. |

---

## 3. The verbatim command block (what was actually executed)

> Run from inside the workspace, not from `/tmp`. Go caches are redirected to
> local `.tmp-*` dirs so the build does not fill `/tmp`.

```bash
cd septagon-oss-workspace/pk-apps/apps/starter-saas

# Redirect Go caches locally (workspace convention; avoids filling /tmp)
export GOCACHE="$PWD/../../../.tmp-go-cache"
export GOMODCACHE="$PWD/../../../.tmp-go-mod"
export GOTMPDIR="$PWD/../../../.tmp-go-tmp"
export TMPDIR="$PWD/../../../.tmp-go-tmp"
mkdir -p "$GOCACHE" "$GOMODCACHE" "$GOTMPDIR"

# Start fresh (a real clone has no pk.db; it is gitignored)
rm -f pk.db pk.db-shm pk.db-wal pk.db-journal

go run .
# then, in another shell:
curl -s http://localhost:18090/healthz
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:18090/admin
curl -s http://localhost:18090/api/v1/tenants
```

### Build result (cold cache)

- Cold build (`go build` after `go clean -cache`, incl. downloading 9 modules):
  **~16.7 s wall** on the test machine. A stranger adds their own network time
  for the module download.
- Exit code `0`. Binary size ~19 MB. **The build is healthy — no compile
  errors, no missing deps.**

### Startup banner (verbatim, from a run on a warm DB)

```
============================================================
 starter-saas — PlatformKit OSS monolith
  listening:    http://localhost:18090
  admin UI:     http://localhost:18090/admin
  health:       http://localhost:18090/healthz
  metrics:      http://localhost:18090/metrics
  default login: admin@local.test / changeme
  modules:      9 composed (admin_management, health_management, tenant_management, user_management, audit_management, auth_management, api_key_management, content_management, notification_management)
============================================================
```

(The banner is correct and reads the port from `config.yaml`. Note: under
`go run .` the banner is sometimes still buffered when the HTTP listener is
already up — curl can succeed before the banner flushes to the terminal.)

### Seeded values (verbatim from `pk-apps/apps/starter-saas/seed/seed.go`)

- Tenant: `Acme Inc` (id `tenant_acme`, slug `acme`)
- Admin user: **`admin@local.test`** / **`changeme`** (id `user_admin`)

### HTTP results

| Path | Fresh DB (cold clone reality) | Warm/pre-existing DB |
|---|---|---|
| `GET /` (HTML landing) | `200` | `200` |
| `GET /admin` (admin shell HTML) | `200` | `200` |
| `GET /admin/static/_admin.css` | `200` | `200` |
| `GET /live` | `204` | `204` |
| `GET /ready` | `200` (only checks module plan composed) | `200` |
| `GET /metrics` | `200` | `200` |
| **`GET /healthz`** | **`503` unhealthy** | `200` healthy |
| **`GET /api/v1/tenants`** | **`500` no such table** | `200` `[{"name":"Acme Inc",...}]` |
| **`GET /api/v1/users?tenant_id=tenant_acme`** | **`500`** | `200` |
| `POST /api/v1/auth/sessions` (login) | `401`/`500` (table races) | also flaky (see blocker) |

**Time-to-first-HTTP-200 on `/admin`:** ~0.27 s (prebuilt binary) / ~0.77 s
(`go run .`, includes link step). So the *server* is fast; the problem is the
*data layer*, below.

---

## 4. The Launch Blocker

### Symptom
On a **fresh** `pk.db` (i.e. exactly what a new user gets after cloning),
`go run .` boots, prints the banner, and serves HTTP — but **every data
module's table is missing** and the aggregated health check fails:

```
GET /healthz  →  503
{"status":"unhealthy","components":[
  {"name":"tenant_management.store","status":"unhealthy","error":"tenant/sqlite: list: SQL logic error: no such table: tenants (1)"},
  {"name":"user_management.store","status":"unhealthy","error":"... no such table: users ..."},
  {"name":"audit_management.store","status":"unhealthy","error":"... no such table: audit_events ..."},
  {"name":"auth_management.sessions","status":"unhealthy","error":"... no such table: auth_sessions ..."},
  {"name":"api_key_management.store","status":"unhealthy","error":"... no such table: api_keys ..."},
  {"name":"content_management.store","status":"unhealthy","error":"... no such table: content ..."},
  {"name":"notification_management.store","status":"unhealthy","error":"... no such table: notifications ..."}
]}

GET /api/v1/tenants  →  500   tenant/sqlite: list: SQL logic error: no such table: tenants (1)
```

This reproduced on **5 / 5** consecutive cold runs (and again via `go run .`).
The seeded admin/tenant from the banner are NOT actually queryable.

### Reproducibility / why earlier runs looked OK
The **very first** observation appeared to succeed (`/healthz 200`, tenants
returned `Acme Inc`) — but that was against a **pre-existing `pk.db`** left in
the working tree from prior builds. Once `pk.db` is deleted (the cold-clone
state), the failure is **deterministic**: every fresh boot is unhealthy.

### Root cause
In `pk-apps/apps/starter-saas/app.go`, each of the 7 data modules is constructed
with `WithSQLiteDSN(cfg.Database.DSN)` pointing at the **same file**
(`file:./pk.db?cache=shared&mode=rwc`). Each module's sqlite store calls its own
`sql.Open(driver, dsn)` (verified: 7 separate `sql.Open` sites under
`pk-modules/pkg/*/store/sqlite/sqlite.go`), producing **7 independent
`*sql.DB` connection pools** over one file. Each store runs
`CREATE TABLE IF NOT EXISTS ...` on construct, and `seed.Run` writes through the
tenant/user pools. On a brand-new file the table creation / commit does not
become visible to the other pools' connections before they read, so queries hit
connections where the table "does not exist".

Empirically, swapping the DSN to a plain file (no `cache=shared`) or adding
`_pragma=busy_timeout(5000)` did **not** fix it — confirming the problem is the
multiple-independent-pools-over-one-file design, not just the `cache=shared`
flag. A real fix is one of: share a single `*sql.DB` across all modules; serialize
to one connection (`SetMaxOpenConns(1)`); or run all migrations once, up front,
before any module opens its pool.

### Why CI/tests did not catch it
`pk-apps/apps/starter-saas/main_test.go` passes (`ok 0.363s`). Its smoke tests
call `buildApp` against a per-test `t.TempDir()/pk.db` with the same
`cache=shared` DSN and assert seeding + route registration **in-process and
synchronously**, without hitting the concurrent `/healthz` aggregation that the
running binary exposes. So the green tests gave false confidence; the README's
"it boots and seeds" claims were written against tests, not against a real
cold `go run .`.

### Verdict
**This is a launch blocker, not a documentation problem.** The hero promise
("clone → `go run .` → working admin with a seeded tenant + login") is currently
false on a cold clone. The launch kit must NOT ship copy asserting a working
first run until the starter-saas data-layer wiring is fixed and this log is
re-verified to show `/healthz 200` and `GET /api/v1/tenants → 200 [Acme Inc]`
on a fresh DB.

---

## 5. Secondary findings (also real, lower severity)

1. **Wrong port in the app README.** `pk-apps/apps/starter-saas/README.md` says
   the app boots on `:8080` and lists `http://localhost:8080/...` URLs. The
   shipped `config.yaml` sets `http.addr: ":18090"`, and the app reads
   `config.yaml` from the working dir, so the real port is **`:18090`**. (The
   compiled-in *default* when no config file is present is `:8080`, per
   `config.go`.) Every launch URL must use `:18090` to match the shipped config,
   or the config must be changed to `:8080`. Pick one and make doc + config agree.

2. **`:8080` was already occupied** on the test machine by an unrelated process.
   This is exactly the "port busy" gotcha a stranger hits — and a reason the
   `:18090` default in `config.yaml` is arguably safer, but it must be documented.

3. **Broken admin sidebar links.** The admin dashboard renders, and its
   **"Modules" entity links work** (e.g. `/admin/tenant_management/Tenant` → 200).
   But the **left-sidebar links 404**: they point at `/admin/admin/tenants`,
   `/admin/admin/users`, etc. (`200`-rendered page, dead links). The working
   entity routes are `/admin/<module_id>/<EntityName>` (capitalized, e.g.
   `/admin/user_management/User`). Sidebar `SidebarSection.Path` values do not
   match the entity router. Cosmetic relative to the blocker, but a stranger
   clicking the obvious nav gets a 404.

4. **The admin is an open shell, not a gated login.** `/admin` serves an
   unauthenticated dashboard. The seeded `admin@local.test / changeme`
   credentials are for the **auth API** (`POST /api/v1/auth/sessions`), which is
   itself broken on a fresh DB (no `auth_sessions` table). Launch copy should not
   imply "log into the admin UI with these creds" — there is no admin login wall
   today.

---

## 6. Gotchas a stranger hits (curated)

- **Health is red out of the box.** `GET /healthz` → `503` and all entity APIs
  → `500 no such table` on a fresh clone. This is the blocker above; it is the
  first thing anyone careful will notice.
- **Wrong port in the README.** README says `:8080`; the app actually listens on
  `:18090` (from `config.yaml`). Curling `:8080` connects to *something else* or
  fails.
- **Port 8080 may be busy.** Common on dev machines; not the app's port anyway,
  but a source of confusion given the README.
- **Stale `pk.db` masks the bug.** If you run once, delete nothing, and run
  again, an old `pk.db` can make the app *look* healthy. Always `rm -f pk.db*`
  to see the true cold-clone behavior.
- **First build takes ~15-20 s + download time.** Cold `go build` here was
  ~16.7 s including module downloads; a stranger on slow network sees more.
  No compile errors — this part is fine.
- **No npm, no Docker, no CGO** — pleasant surprise; lead with this once the
  blocker is fixed.

---

## 7. Test Environment (for reproducibility)

- Host OS: Linux (Arch, kernel 7.0.x), x86_64.
- Go: `go version go1.26.3-X:nodwarf5 linux/amd64` (satisfies `go 1.26` pin).
- Workspace: `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace`
  (`go.work` pins `go 1.26`; module `replace` directives point at sibling repos).
- App: `pk-apps/apps/starter-saas`, `config.yaml` `http.addr: ":18090"`,
  DSN `file:./pk.db?cache=shared&mode=rwc`, driver `modernc.org/sqlite v1.50.1`.
- Go caches redirected to `septagon-oss-workspace/.tmp-go-*` during all builds.
- Date of capture: 2026-06-02.

## 8. Self-verification

The exact block in §3 was re-run in a fresh shell against a freshly deleted
`pk.db`. It **reproduces deterministically**: build succeeds, server listens on
`:18090`, `/admin` and `/` return `200`, and `/healthz` returns `503` with all 7
data modules reporting `no such table`, while `GET /api/v1/tenants` returns
`500`. The 5-run loop confirmed 5/5 failures on cold DB. The "warm DB" success
column is reproducible only when a previously-created `pk.db` is left in place.

**Bottom line for the launch:** the build/serve story is solid and the DX
prerequisites are genuinely lean (Go-only, no CGO/npm/Docker), but the
first-boot data layer is broken on a cold clone. Fix the starter-saas SQLite
wiring, then re-capture §3-§4 before any external-facing copy is written.
