# PlatformKit OSS — Release & Run Model

> Status: **LANDED ON MAIN LOCALLY + RE-VERIFIED — NOT PUSHED.** The run-model
> work is merged to `main` in every OSS repo locally; local `v0.1.0` tags are
> cut; the front-door module builds + boots green (9 modules, 7 healthy stores,
> login 201) and the workspace dev build (`go build ./pk-apps/...` via
> `go.work`) is clean. **Nothing is pushed:** no remote was touched, no remote
> tag created or moved, no GitHub repo created. The public push is gated. The
> final outward actions are enumerated in the **Gated Push Steps** section and
> await explicit human approval.

This runbook defines how a PlatformKit OSS application resolves its
dependencies (the "run model") and how the repo split is released so an
outsider can `git clone … && go run .` and get a booting app (the "release
model"). It records the design, the rationale (including the rejected
monorepo alternative), and the **evidence from a real local proof** that the
outsider proxy path works.

**Version namespaces (do not conflate):** per-module `ModuleVersion` (the port
contract value) stays **`0.0.0`** — it is the module-contract version, and the
release does **not** bump it. An earlier attempt to bump `ModuleVersion` to
`0.1.0` was reverted because it broke module-dependency compose (hardcoded
`Version: "0.0.0"` require-constraints). The **release** version is **`v0.1.0`**,
which is purely the git-tag / distribution version. `v0.1.0` ≠ `ModuleVersion`.

**Repo set (canonical):** OSS module repos that get a `v0.1.0` tag = pk-shared,
pk-core, pk-runtime, pk-design, pk-client, pk-registry, pk-testkit, pk-modules,
pk-tools, pk-apps, platformkit-ui (11 Go modules). Plus the **front-door repo
`platformkit`** (a new repo: root `main`, also tagged `v0.1.0`). `pk-docs` is a
**non-module docs repo** (not on the Go build train). `pk-deploy` and the
internal-only repos are **excluded** from the OSS launch train.

Toolchain of record for all evidence below: `go version go1.26.4 linux/amd64`
(`go.work` pins `go 1.26`).

---

## 1. The decision (and why)

### 1.1 Remove ALL `replace` directives from published consumer go.mods

The launch blocker was that published consumer go.mods (e.g. `pk-apps/go.mod`)
carried `replace github.com/septagon-oss/pk-core => ../pk-core` and friends.
Those relative paths exist only inside the local multi-repo workspace. A real
outsider who runs `git clone pk-apps && cd apps/starter-saas && go build .`
hits `replacement directory ../pk-core does not exist` and is dead in the
water.

**Decision:** published consumer go.mods carry **no** `replace` of any
`github.com/septagon-oss/*` module and **no** relative-path replace. Modules
resolve purely **by version** from the Go module proxy. Local cross-repo
development keeps working through the workspace `go.work` (which does
`use ./pk-core`, `use ./pk-modules`, …) — the workspace, not replaces, is what
wires sibling repos together on disk.

Current state: **already clean.** A scan of every workspace go.mod finds zero
`replace` of a septagon-oss module and zero `=> ../` / `=> ./` directive. The
release-blocking grep guard (§5.2) passes against all 11 Go modules.

### 1.2 Keep the repo split — rejected alternative: monorepo

We considered collapsing the split into a single Go module / monorepo. That
would make the replace problem disappear (one module, no cross-repo
resolution) and simplify tagging to a single version.

**Rejected, because:**

- The split is the product. PlatformKit's thesis is *independently versioned,
  independently consumable* layers (`pk-core`, `pk-modules`, `pk-runtime`, …).
  A monorepo erases the very boundary the framework teaches.
- Consumers want to depend on `pk-core` without pulling `pk-modules`,
  `pk-tools`, etc. The front-door proof below shows `go mod tidy` pruning
  `pk-shared`/`pk-testkit` out of the starter's build graph — granularity the
  split delivers and a monorepo cannot.
- A monorepo forces lockstep versioning: a docs typo in one corner bumps the
  whole product's version. The split lets each layer cut patch releases on its
  own cadence.
- The replace problem is fully solved by §1.1 + §1.3 + §1.5 without sacrificing
  any of the above. Collapsing to a monorepo would be paying a large
  architectural price to fix a one-line-per-file bug.

### 1.3 Front door = a NEW repo that does NOT duplicate the starter

The public entry point is a new repo `github.com/septagon-oss/platformkit`.
The naive version would copy the starter's `main.go` + app graph into it,
creating a second source of truth that silently drifts from `pk-apps`.

**Decision: extract the app graph into an importable package and make BOTH
entry points thin wrappers over it.** See §2.

### 1.4 Versioning: clean `v0.1.0`, retract `v0.0.0`, never reuse

- The remote `v0.0.0` tag on all 10 repos is broken (it was cut with the local
  replace directives baked in) and can never resolve from the proxy.
- We **never reuse or move** `v0.0.0`. Tags are immutable once on the proxy.
- Each module's go.mod declares
  `retract v0.0.0 // broken: contained local replace directives`, so
  `go list -m -versions` and `go get` steer consumers to `v0.1.0+` and hide the
  poison tag. (Proven in §4.4 — the proxy reports only `v0.1.0`.)
- The release cuts fresh, clean `v0.1.0` tags on every repo, topologically
  leaf-first (§3).

**Tag policy (single rule):** `v0.1.0` tags point at the merged `main` commit.
`main` may advance afterward **only** for post-tag docs/CI changes; those do not
move the tag. There is **no** `HEAD == v0.1.0` invariant — `main` being one
commit ahead of the tag (e.g. a CI baseline fix) is expected and intentional,
and avoids a go.sum cascade. The published module is whatever the immutable
`v0.1.0` tag points at; never move or re-cut a published `v0.1.0`.

### 1.5 Release-blocking guards

Every repo's CI must, from a clean checkout:

1. Build and test with `GOWORK=off` (no workspace rescue — exactly what an
   outsider gets).
2. Run a **block-aware replace guard** that fails if any published go.mod
   contains a `replace` of any `github.com/septagon-oss/*` module **or** any
   local-path (`./` or `../` or absolute) replace — including `replace ( … )`
   block form, which a naive single-line grep misses. The reliable way is
   `go mod edit -json | jq` over the structured `Replace` array (§5.2).
3. For the front door: a real **clone + `GOWORK=off go run .` smoke** that
   clones the public repo, boots it, and asserts `/healthz` 200,
   `/api/v1/tenants` 200, and `POST /api/v1/auth/sessions` with a `tenant_id`
   in the body → 201 (§5.3).

See §5 for the exact commands; all three were prototyped locally and pass.

---

## 2. The importable-starter design

### 2.1 What moved

The starter's application graph moved from `package main` in
`pk-apps/apps/starter-saas/` into a new importable package
**`github.com/septagon-oss/pk-apps/pkg/starterapp`**:

| Before (`apps/starter-saas/`, `package main`) | After (`pkg/starterapp/`, `package starterapp`) |
|---|---|
| `app.go` — `buildApp`, `App`, `(*App).mux`, `(*App).Close`, `indexHandler`, `bundleName` | `app.go` — `BuildApp`, `App`, `(*App).Mux`, `(*App).Close`, `indexHandler`, `BundleName` + accessors |
| `config.go` — `Config`, `loadConfig`, `defaultConfig` | `config.go` — `Config`, `LoadConfig`, `DefaultConfig` |
| `run` + `printBanner` (in `main.go`) | `serve.go` — `Run` (build → serve → graceful shutdown) + `printBanner` |
| `seed/` package | `pkg/starterapp/seed/` (moved with the package) |
| `main_test.go`, `firstboot_test.go` | `app_test.go`, `firstboot_test.go` (moved in-package) |

`App`'s fields stay **unexported** — the construction graph is encapsulated.
The exported surface is exactly what wrappers and tests need: `BuildApp`,
`Run`, `(*App).Mux`, `(*App).Close`, `Config`/`LoadConfig`/`DefaultConfig`, and
read-only accessors (`ModuleIDs`, `AdminBasePath`, `SeedEmail`, `SeedPassword`,
`Catalog`). The tests live in-package so they can keep asserting against the
unexported graph (`app.catalog`, `app.tenant`, `app.db`, …) with no behavior
change.

### 2.2 The two wrappers (single source of truth)

`pk-apps/apps/starter-saas/main.go` is now ~25 lines: load `config.yaml`,
register the SQLite driver, hand a signal context to `starterapp.Run`.

The front-door repo's `main.go` is the same shape (~30 lines), but uses
`starterapp.DefaultConfig()` so it boots with **zero config files**:

```go
package main

import (
	"context"; "log"; "os/signal"; "syscall"
	_ "modernc.org/sqlite"
	"github.com/septagon-oss/pk-apps/pkg/starterapp"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()
	cfg := starterapp.DefaultConfig()
	if err := starterapp.Run(ctx, cfg); err != nil {
		log.Fatalf("platformkit: %v", err)
	}
}
```

Change the module graph once in `pkg/starterapp/app.go` and **both** the
pk-apps binary and the front door inherit it. There is no logic duplication.

### 2.3 Front-door repo layout (for the real push)

```
github.com/septagon-oss/platformkit
├── go.mod          # module github.com/septagon-oss/platformkit; require pk-apps v0.1.0 + modernc.org/sqlite
├── go.sum
├── main.go         # the ~30-line wrapper above
├── README.md       # "git clone && go run ." quickstart
└── LICENSE
```

No `replace`. No `config.yaml` (DefaultConfig boots). No app logic.

---

## 3. Topological tag order (leaf-first, right-sized)

### 3.1 The real dependency edges (from each go.mod's `require`)

```
pk-shared      → (no septagon-oss deps)        ── leaf
pk-core        → (no septagon-oss deps)        ── leaf
pk-design      → (no septagon-oss deps)        ── leaf
pk-client      → (no septagon-oss deps)        ── leaf
pk-registry    → (no septagon-oss deps)        ── leaf
platformkit-ui → (no septagon-oss deps)        ── leaf
pk-runtime     → pk-core
pk-modules     → pk-core
pk-testkit     → pk-shared
pk-tools       → pk-core, pk-modules
pk-apps        → pk-core, pk-modules, pk-runtime, pk-shared, pk-testkit
platformkit    → pk-apps                       ── front door (new repo)
```

### 3.2 Tag order

Cut and (later) push `v0.1.0` in this order so each repo's deps already exist
by version when it is tagged:

1. **Layer 0 (leaves):** `pk-shared`, `pk-core`, `pk-design`, `pk-client`,
   `pk-registry`, `platformkit-ui`
2. **Layer 1:** `pk-runtime`, `pk-modules`, `pk-testkit`
3. **Layer 2:** `pk-tools`
4. **Layer 3:** `pk-apps`
5. **Layer 4 (front door, new repo):** `platformkit`

### 3.3 Right-sizing the runnable train

The full split is 11 Go modules, but the **starter monolith only needs four of
them transitively.** Proof: a fresh `go mod tidy` on the front door (which
imports only `pkg/starterapp`) produced this graph:

```
github.com/septagon-oss/pk-apps    v0.1.0
github.com/septagon-oss/pk-core    v0.1.0 // indirect
github.com/septagon-oss/pk-modules v0.1.0 // indirect
github.com/septagon-oss/pk-runtime v0.1.0 // indirect
```

`pk-shared` and `pk-testkit` appear in **pk-apps's** `require` block (other
pk-apps packages/tests use them) but are **pruned from the starter's build
graph** — granularity the repo split delivers. The minimal runnable train is
therefore **pk-core → {pk-runtime, pk-modules} → pk-apps → platformkit**.
`pk-shared`/`pk-testkit` tags must still exist because `go get pk-apps@v0.1.0`
must satisfy pk-apps's own go.mod, but they are not compiled into the binary.

`pk-design`, `pk-client`, `pk-registry`, `pk-tools`, and `platformkit-ui` are
tagged `v0.1.0` (they are module repos) but are **not** on the runnable train.
`pk-docs` is a **non-module docs repo** — it is published but is not a Go module
and not tagged on the build train. `pk-deploy` and the internal-only repos are
**excluded** from the v0.1.0 train (operational/internal tooling, consistent
with `launch/FLIP_RUNBOOK.md`).

---

## 4. Verified-locally evidence (the crux)

The hard claim is: *an outsider, with no workspace, resolving purely by
version, gets a booting app.* Proving this without touching GitHub required
simulating the proxy locally.

### 4.1 The mechanism

A **git `insteadOf` URL rewrite to local file paths, with `GOPROXY=direct`.**
This is the most faithful simulation: Go runs its real VCS code path
(`git ls-remote`, `git fetch`, `.info`/`.mod`/`.zip` synthesis, go.sum hashing)
against the local clones, reading the real `v0.1.0` git tags. Nothing is
hand-stubbed.

A scratch `GIT_CONFIG_GLOBAL` file (never the user's real `~/.gitconfig`) maps
each septagon-oss module URL to its local clone, while preserving the SSH
fallback so non-oss (e.g. private `septagon-dev/*`) deps still resolve:

```gitconfig
[url "git@github.com:"]
    insteadOf = https://github.com/
[url "file:///…/septagon-oss-workspace/pk-core"]
    insteadOf = https://github.com/septagon-oss/pk-core
# … one block per septagon-oss module …
```

Local `v0.1.0` tags were (re)pointed at the branch tips that contain the
importable-starter refactor + the `retract v0.0.0` directives. **These are
local annotated tags only — the remote still carries only the old `v0.0.0`.**
The stale `septagon-oss` entries were purged from the module cache so the sim
fetched fresh `v0.1.0`.

### 4.2 The outsider build (GOWORK=off, by version, no replace)

In a **pristine scratch dir** (`.tmp-frontdoor/`, prototyping the front-door
repo), with the exact env an outsider's machine approximates:

```bash
export GOWORK=off                 # NO workspace rescue
export GOPROXY=direct             # resolve via git (→ local clones via insteadOf)
export GOSUMDB=off                # local tags aren't on sum.golang.org
export GOFLAGS=-mod=mod           # allow go.mod/go.sum population (non-workspace)
export GIT_CONFIG_GLOBAL=…/.tmp-gitconfig

go mod init github.com/septagon-oss/platformkit
go get github.com/septagon-oss/pk-apps@v0.1.0      # → "added … pk-apps v0.1.0"
go mod tidy                                         # pulls pk-core/modules/runtime @v0.1.0
go build -o pk-frontdoor .                          # clean build
```

Resulting front-door `go.mod` — **zero `replace`**, all pk-* pinned `v0.1.0`:

```
require (
	github.com/septagon-oss/pk-apps v0.1.0
	modernc.org/sqlite v1.50.1
)
require (
	github.com/septagon-oss/pk-core    v0.1.0 // indirect
	github.com/septagon-oss/pk-modules v0.1.0 // indirect
	github.com/septagon-oss/pk-runtime v0.1.0 // indirect
	… stdlib-adjacent indirects …
)
```

`go.sum` carried real content + go.mod hashes for each pk-* module, e.g.:

```
github.com/septagon-oss/pk-apps v0.1.0 h1:Dh3iN2jgwe4QRj3dWmCvmKXzLk+0Pf9Q1XwbktZxtz8=
github.com/septagon-oss/pk-apps v0.1.0/go.mod h1:msIXdtF6i/TPbpUXwsb2qLBrpmzJs/DI0oeU/iD66H8=
github.com/septagon-oss/pk-core v0.1.0 h1:w/BHSGP5UUUxGMstHZRNF1GQIw9B2hSbOI//+Cg73Z0=
…
```

### 4.3 The outsider boot (real HTTP probes)

```text
============================================================
 starter-saas — PlatformKit OSS monolith
  listening:    http://localhost:8080
  admin UI:     http://localhost:8080/admin
  health:       http://localhost:8080/healthz
  default login: admin@local.test / changeme
  modules:      9 composed (admin_management, health_management, tenant_management,
                user_management, audit_management, auth_management,
                api_key_management, content_management, notification_management)
============================================================

GET /healthz          → HTTP 200
  {"status":"healthy","components":[
     {"name":"tenant_management.store","status":"healthy"},
     {"name":"user_management.store","status":"healthy"},
     {"name":"audit_management.store","status":"healthy"},
     {"name":"auth_management.sessions","status":"healthy"},
     {"name":"api_key_management.store","status":"healthy"},
     {"name":"content_management.store","status":"healthy"},
     {"name":"notification_management.store","status":"healthy"}]}

GET /api/v1/tenants   → HTTP 200
  [{"id":"tenant_acme","slug":"acme","name":"Acme Inc", …}]

POST /api/v1/auth/sessions  (body includes tenant_id) → HTTP 201
  {"session":{ … },"user":{ … }}
```

All three required assertions pass: **`/healthz` 200**, **`/api/v1/tenants`
200**, and **`POST /api/v1/auth/sessions` (with `tenant_id`) 201** on a fresh
database, with every dependency resolved by version.

### 4.4 The retract works

```bash
go list -m -versions github.com/septagon-oss/pk-apps
# → github.com/septagon-oss/pk-apps v0.1.0      (v0.0.0 suppressed: retracted)
```

The broken `v0.0.0` is hidden from version selection exactly as intended.

### 4.5 `buildvcs` caveat (and why it is not a resolution issue)

`go build` in the *non-git* scratch dir first failed with
`error obtaining VCS status` — Go's build-stamping wants a VCS root. This is a
property of the scratch directory, **not** of dependency resolution. Proven
two ways: (a) `go build -buildvcs=false` succeeds and runs; (b) after
`git init` in the scratch dir, a plain `go build` (VCS stamping ON) also
succeeds. A real cloned repo is a git repo, so the front door builds clean with
no flag.

### 4.6 What remains verifiable only after a real push

The local sim covers everything except the public network surface:

- That `proxy.golang.org` serves the same `.mod`/`.zip`/hashes (our `GOSUMDB`
  was off; the real proxy + `sum.golang.org` will compute identical content
  hashes because the git trees are identical).
- That `sum.golang.org` records the new modules (first `go get` after push).
- That the public CI runners reach the tags (GitHub availability/timing).

These are availability/transport facts, not logic facts; the logic — by-version
resolution, no replaces, retract suppression, green boot — is proven.

---

## 5. Release gates (CI), prototyped locally

### 5.1 GOWORK=off build + test (per repo, clean state)

```bash
# In each repo, with NO workspace:
GOWORK=off go build ./...
GOWORK=off go test ./...
```

Run locally (via the local proxy) for the runnable train and all leaves —
green.

### 5.2 Replace guard — block-aware, no septagon-oss replace, no local-path replace

A naive `grep '=> ../'` misses `replace ( … )` block-form entries and
absolute-path replaces. Parse the **structured** replace array instead:

```bash
# Fails (exit 1) if a published go.mod replaces ANY septagon-oss module
# or uses ANY local-path replace (./, ../, or an absolute path).
# Catches both single-line and replace ( … ) block forms.
guard() {
  local mod="$1"
  go mod edit -json "$mod" | jq -e '
    [ .Replace // [] | .[]
      | select(
          (.Old.Path | startswith("github.com/septagon-oss/"))
          or (.New.Path | test("^(\\.|/|\\.\\.)"))   # ./  ../  or absolute /
        )
    ] | length == 0
  ' >/dev/null || { echo "GUARD FAIL ($mod): forbidden replace directive"; return 1; }
}
guard go.mod
```

`jq -e` exits non-zero when the filter yields `false`/empty, so the guard fails
on any septagon-oss replace or any local-path (relative or absolute) replace,
in either single-line or block form. Prototyped against all 11 Go modules — all
PASS (exit 0).

### 5.3 Front-door clone + run smoke (a REAL outsider check)

Do **not** smoke-test by `go get …@v0.1.0 && go build ./...` in an empty
module — that passes trivially without ever exercising the app. Clone the real
front-door repo and run it exactly as an outsider would:

```bash
# In CI for the platformkit front-door repo (or from any clean machine):
git clone https://github.com/septagon-oss/platformkit
cd platformkit
GOWORK=off go run . & PID=$!
trap 'kill "$PID" 2>/dev/null' EXIT
# first cold build downloads + compiles (~tens of seconds) — poll, don't sleep-3
for i in $(seq 1 60); do curl -fsS -o /dev/null http://localhost:8080/healthz && break; sleep 2; done
test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/healthz)"        = 200
test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/v1/tenants)" = 200
# Auth login must return 201; tenant_id is required in the body:
test "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:8080/api/v1/auth/sessions \
          -H 'Content-Type: application/json' \
          -d '{"tenant_id":"tenant_acme","email":"admin@local.test","password":"changeme"}')" = 201
kill $PID
```

Run locally against the by-version build — `/healthz` 200, `/api/v1/tenants`
200, and auth `POST` 201 (§4.3).

---

## 6. Per-repo go.mod cleanup summary

| Repo | replace of oss? | retract v0.0.0? | requires (oss) |
|------|-----------------|-----------------|----------------|
| pk-shared      | none (clean) | added | — |
| pk-core        | none (clean) | added | — |
| pk-runtime     | none (clean) | added | pk-core |
| pk-modules     | none (clean) | added | pk-core |
| pk-testkit     | none (clean) | added | pk-shared |
| pk-design      | none (clean) | added | — |
| pk-client      | none (clean) | added | — |
| pk-registry    | none (clean) | added | — |
| pk-tools       | none (clean) | added | pk-core, pk-modules |
| platformkit-ui | none (clean) | added | — |
| pk-apps        | none (clean) | added | pk-core, pk-modules, pk-runtime, pk-shared, pk-testkit |

`replace` removal was already done by prior launch-prep work; this pass added
the `retract v0.0.0` directive everywhere and refactored pk-apps for
importability. The front-door repo `platformkit` is also tagged `v0.1.0` (a new
repo, requires `pk-apps`). `pk-docs` (non-module docs repo), `pk-deploy`, and
the internal-only repos are out of the Go-module v0.1.0 train.

---

## 7. Landed on main + local tags (NOT pushed)

The run-model branches below are **merged to `main` locally** in every repo, and
local annotated `v0.1.0` tags are cut on those `main` commits. The remote is
untouched (it still carries only the old broken `v0.0.0`). The commit column
records the `main` commit the local `v0.1.0` tag points at.

| Repo | Local `v0.1.0` → `main` commit (snapshot — regenerate before push) |
|------|--------------------------------------------------------------------|
| pk-shared      | `b72f53d` |
| pk-core        | `6d45c32` |
| pk-runtime     | `027a5f0` |
| pk-design      | `00959fc` |
| pk-client      | `c3f7055` |
| pk-registry    | `1c8f9a3` |
| pk-testkit     | `2834367` |
| pk-modules     | `9cb05e4` |
| pk-tools       | `77b2958` |
| pk-apps        | `639e982` |
| platformkit-ui | `d1eadde` |

The `run-model/*` branches are merged into each repo's `main` (pk-tools landed
via `fix/scaffold-born-conformant`); the annotated local `v0.1.0` tags point at
the `main` commits above. **These SHAs are a snapshot — regenerate them right
before the push**, since any late fix moves them:

```bash
for r in pk-shared pk-core pk-runtime pk-design pk-client pk-registry pk-testkit pk-modules pk-tools pk-apps platformkit-ui; do
  printf '%-16s %s\n' "$r" "$(git -C "$OSS/$r" rev-parse --short v0.1.0^{})"
done
```

The remote still carries only the old broken `v0.0.0`.

---

## 8. GATED PUSH STEPS (await user approval)

The branches are already merged to `main` and local `v0.1.0` tags are cut
(§7). Nothing below has touched a remote. Each step is an outward,
irreversible-on-the-proxy action.

1. **Normalize the tag messages (optional, local).** If the current `v0.1.0`
   tags carry a "local verification" message, re-create them as annotated
   (optionally signed) tags on the **same `main` commits** with a real release
   message immediately before push. Per the tag policy (§1.4), `v0.1.0` points
   at the merged `main` commit; `main` may already be one commit ahead for the
   CI baseline fix and that is fine — do **not** force `HEAD == v0.1.0`.
   **Never** reuse or move `v0.0.0`.
2. **Clear the launch-mechanics blockers** tracked in
   `launch/FLIP_RUNBOOK.md` §A (CI CODEOWNERS baseline, docs `v0.0.0→v0.1.0`,
   README links). These live on `main` and may leave `main` ahead of the tag.
3. **Push `main` + `v0.1.0` per layer, leaf-first** (§3.2), letting each layer
   settle on the proxy before the next so dependents resolve `@v0.1.0`:
   - Layer 0: pk-shared, pk-core, pk-design, pk-client, pk-registry, platformkit-ui
   - Layer 1: pk-runtime, pk-modules, pk-testkit
   - Layer 2: pk-tools
   - Layer 3: pk-apps
4. **Create + push the new front-door repo**
   `github.com/septagon-oss/platformkit` (AFTER pk-apps) from the §2.2/§2.3
   layout (the prototyped `.tmp-frontdoor/` is the template; add it as a git
   repo with README + LICENSE), push `main`, then tag `v0.1.0`. The front door
   is the final module layer — **not** `pk-docs` (which is a non-module docs
   repo, published separately and not on the build train).
5. **Post-push verification (real proxy):** from a clean machine with the
   default `GOPROXY`,
   `git clone https://github.com/septagon-oss/platformkit && cd platformkit &&
   GOWORK=off go run .`, then assert `/healthz` 200, `/api/v1/tenants` 200, and
   `POST /api/v1/auth/sessions` (with `tenant_id`) 201 (§5.3). A no-op
   `go get …@v0.1.0 && go build ./...` in an empty module does **not** count.
6. **(Optional) `v0.0.0` retraction reach:** the retract is in the `v0.1.0`
   go.mods, so it takes effect once `v0.1.0` is on the proxy. No action needed
   on the `v0.0.0` tag itself — leave it; never move it.

> The runnable contract is proven locally. The only remaining variable is the
> public proxy/CI transport, which steps 3–5 exercise once approved.
