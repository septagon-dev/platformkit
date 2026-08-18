# PlatformKit OSS v0.1.0 — Public Flip Runbook

> Status: **EXECUTED — HISTORICAL.** The flip this runbook gated happened: the `septagon-oss` org has been **public since 2026-07-22** — 17 public repos, front door `github.com/septagon-oss/platformkit` now at **v0.14.1** with 20 published GitHub Releases, live docs at <https://septagon-oss.github.io/pk-docs>. What has **not** happened is the announcement: nothing has been posted anywhere (0 stars, 0 issues). The remaining work is the announcement track (`CHECKLIST.md` §B/§C). This file is kept as the record of how the flip was done; the commands and values below are v0.1.0-era history (seed credentials, tags, and the quickstart have since moved — see the stale-capture note in `VERIFIED_RUN.md`).

Scope:

- **11 module repos** (Go modules, get a `v0.1.0` tag) under
  `github.com/septagon-oss/` — `pk-shared, pk-core, pk-runtime, pk-design,
  pk-client, pk-registry, pk-testkit, pk-modules, pk-tools, pk-apps,
  pk-ui`.
- **Front-door repo** `platformkit` (a NEW repo, created + tagged `v0.1.0` after
  pk-apps — the final module layer).
- **`pk-docs`** — a non-module docs repo, published but not a Go module and not
  on the build train.
- **Excluded:** `pk-deploy` and the internal-only repos.

Throughout, define the workspace root once:

```bash
# $SEPTAGON_DEV = root of your septagon-dev checkout
OSS="$SEPTAGON_DEV/overlays/septagon-oss-workspace"
```

Sources: local readiness gate (`.tmp-oss-gate/ledger.md`) + tri-model council (codex/grok; deepseek was down for the final run). The code gate is green; the items below are launch-mechanics the local gate could not see.

---

## A. Pre-flip blockers (clear ALL before any push)

| # | Blocker | Status | Fix | Decision needed |
|---|---------|--------|-----|-----------------|
| A1 | **CI baseline fails:** `.github/workflows/repository-baseline.yml:15` requires a **root** `CODEOWNERS`; Go repos only have `.github/CODEOWNERS`; `pk-ui` has none. First public CI run fails everywhere. | Verified | Either (a) relax the workflow to accept `.github/CODEOWNERS`, or (b) add root `CODEOWNERS` to all 11 Go repos. | Pick (a) or (b). |
| A2 | **Tag messages are placeholders:** all 10 backbone `v0.1.0` tags say *"local offline-proxy verification tag"*; `pk-ui`/`pk-docs` are lightweight. Tags are immutable once on the proxy. | Verified | Re-create `v0.1.0` as annotated (optionally signed) tags on the same commits with a real release message, immediately before push. | Tag message text; sign? |
| A3 | **pk-apps README broken link:** links to `pk-docs/.../docs/v0.1.0/starter-saas-tutorial.md` which doesn't exist (tutorial is at `docs/v0.0.0/`). 404 once public. | Verified | Point the link at the real path, or create `docs/v0.1.0/`. Coupled to A4. | — |
| A4 | **Docs versioned `v0.0.0` while launching `v0.1.0`:** whole `pk-docs/docs/v0.0.0/` tree, `RELEASING.md` says v0.0.0 and omits `pk-registry`/`pk-ui`, and the tutorial tells users to clone `septagon-oss-workspace` (not a public repo). | Verified | Rename/copy `docs/v0.0.0`→`docs/v0.1.0`, update release notes + repo list, change quickstart to clone `pk-apps`. | Versioning strategy: rename to v0.1.0 vs keep v0.0.0 + fix links only. |
| A5 | **pk-tools scaffold emits non-public roots:** defaults are `example.com/platformkit/backend-kit|business-modules|frontend-kit` (placeholder + old monorepo layout, not the `pk-core`/`pk-modules` split). Publicly-advertised CLI would generate broken scaffolds. | Verified | Update scaffold defaults to the public split, **or** de-emphasize/remove scaffold from the v0.1.0 public surface. | Rework scaffold vs de-scope for v0.1.0. |
| A6 | **NOTICE / third-party attribution:** every repo has Apache-2.0 `LICENSE`, none has `NOTICE`. Not required for source-only repos with non-vendored deps, but `pk-docs` ships branding assets. | Verified | Add `NOTICE`/`THIRD_PARTY_NOTICES` only where you ship NOTICE-bearing upstream code or derived assets; do not add blanket fake notices. | Confirm no vendored NOTICE-bearing deps/assets. |

## B. Pre-flip verification (run after blockers fixed, before push)

```bash
# B1 — per module repo: clean tree, on main, v0.1.0 tag exists, go.mod is sane.
#   NOTE: we deliberately do NOT require HEAD == v0.1.0. main is allowed to be
#   ahead of the tag (e.g. the CI baseline fix) — see the tag policy in
#   RELEASE_AND_RUN_MODEL.md §1.4. We verify the *tag's* go.mod, not HEAD's.
set -euo pipefail
OSS="$SEPTAGON_DEV/overlays/septagon-oss-workspace"
for r in pk-shared pk-core pk-runtime pk-design pk-client pk-registry \
         pk-testkit pk-modules pk-tools pk-apps pk-ui; do
  d="$OSS/$r"
  # dirty tree → fail
  [ -z "$(git -C "$d" status --porcelain)" ] || { echo "FAIL $r: dirty tree"; exit 1; }
  # on main
  [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" = main ] || { echo "FAIL $r: not on main"; exit 1; }
  # v0.1.0 tag exists
  git -C "$d" rev-parse -q --verify v0.1.0^{} >/dev/null || { echo "FAIL $r: no v0.1.0 tag"; exit 1; }
  # the TAGGED go.mod must retract v0.0.0 and carry NO septagon-oss / local-path replace
  mod="$(git -C "$d" show v0.1.0:go.mod)"
  echo "$mod" | grep -qE '^[[:space:]]*retract[[:space:]]+v0\.0\.0' || { echo "FAIL $r: tag go.mod missing retract v0.0.0"; exit 1; }
  # catches single-line AND block-form replaces: any septagon-oss replace, or any local-path target
  if echo "$mod" | grep -qE 'replace[[:space:]]+github\.com/septagon-oss/|github\.com/septagon-oss/[^[:space:]]+[[:space:]]+=>|=>[[:space:]]*(\.|/|\.\.)'; then
    echo "FAIL $r: tag go.mod has a septagon-oss or local-path replace"; exit 1
  fi
  echo "OK $r"
done
# B2 — final cold compose from tags (already PASS via mirrors): re-run after any fix
#   .tmp-oss-gate/cold.sh github.com/septagon-oss/pk-apps   # expect COLD-OK
# B3 — hero path (already PASS): cd "$OSS/pk-apps/apps/starter-saas" && go run . ; curl :8080/admin
```

## C. Push order (layered — NOT concurrent)

Push `main` and the (normalized) `v0.1.0` tag per layer; let each layer settle before the next so dependents resolve upstream `@v0.1.0`.

```
Layer 0 (leaves):   pk-shared pk-registry pk-design pk-client pk-core pk-ui
Layer 1:            pk-runtime pk-testkit pk-modules
Layer 2:            pk-tools
Layer 3:            pk-apps
Layer 4 (front door, NEW repo): platformkit   # create the repo first, then push main + tag
```

`pk-docs` is **not** a layer on this train — it is a non-module docs repo. Push
it whenever its content is final; nothing in the Go build train depends on it.

Per layer, push each repo's `main` then its tag:
```bash
for r in <repos in this layer>; do
  git -C "$OSS/$r" push origin main
  git -C "$OSS/$r" push origin v0.1.0
done
```

**Layer 4 — front door.** The `platformkit` repo does not exist on the remote
yet; its source lives in **`$OSS/platformkit-frontdoor`** (a thin root `main`
over `pk-apps/pkg/starterapp`). Because the front door resolves `pk-apps` (and
its deps) from the proxy by version, generate its committed `go.sum` only AFTER
Layer 3 (`pk-apps`) is pushed AND public, then commit, create, and tag:
```bash
FD="$OSS/platformkit-frontdoor"
( cd "$FD" && GOWORK=off GOFLAGS= go mod tidy )   # deps now public → real go.sum
git -C "$FD" add go.sum && git -C "$FD" commit -m "build(platformkit): pin go.sum from public modules"
git -C "$FD" tag -a v0.1.0 -m "PlatformKit OSS v0.1.0"
gh repo create septagon-oss/platformkit --private --source "$FD" --remote origin
git -C "$FD" push origin main
git -C "$FD" push origin v0.1.0
```

## D. Visibility flip (after tags pushed, same layer order)

```bash
for r in <repos in this layer>; do
  gh repo edit "septagon-oss/$r" --visibility public --accept-visibility-change-consequences
done
```
Include `platformkit` in Layer 4 and flip `pk-docs` when its content is final.

## E. Post-flip verification (proxy/sumdb — the part the gate can't simulate)

> **Run a layer's proxy/sumdb checks ONLY after that layer is public.** You
> cannot query `proxy.golang.org`/`sum.golang.org` for a private repo, and a
> premature query can poison the proxy with a cached 404 for several minutes.
> So: flip a layer public (Section D) → then run the checks below for that
> layer → then move to the next layer.

```bash
# Per layer, AFTER it is public. Example for the full module set once all are public:
for r in pk-shared pk-registry pk-design pk-client pk-core pk-runtime pk-testkit pk-modules pk-tools pk-apps pk-ui; do
  m="github.com/septagon-oss/$r"
  curl -fsS "https://proxy.golang.org/$m/@v/v0.1.0.info" >/dev/null || echo "PROXY FAIL $m"
  curl -fsS "https://sum.golang.org/lookup/$m@v0.1.0" >/dev/null || echo "SUMDB pending $m"
done

# Real consumer hero path — clone the public front door and actually boot it
# (NOT a no-op go get + go build in an empty module, which passes trivially):
d="$(mktemp -d)/platformkit"
git clone https://github.com/septagon-oss/platformkit "$d"
( cd "$d" && GOWORK=off go run . ) & PID=$!
trap 'kill "$PID" 2>/dev/null' EXIT
# first cold build downloads + compiles (~tens of seconds) — poll, don't sleep-3
for i in $(seq 1 60); do curl -fsS -o /dev/null http://localhost:8080/healthz && break; sleep 2; done
test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/healthz)"        = 200
test "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/v1/tenants)" = 200
test "$(curl -s -o /dev/null -w '%{http_code}' -X POST http://localhost:8080/api/v1/auth/sessions \
          -H 'Content-Type: application/json' \
          -d '{"tenant_id":"tenant_acme","email":"admin@local.test","password":"changeme"}')" = 201
kill "$PID" 2>/dev/null; trap - EXIT
```
**If any module reached the proxy/sumdb with bad content, cut `v0.1.1` — never retag `v0.1.0`.**

## F. GitHub settings (verify live; local clones can't prove these)

```bash
# Only over repos that already EXIST publicly (skip platformkit until it's created).
for r in pk-shared pk-core pk-runtime pk-design pk-client pk-registry \
         pk-testkit pk-modules pk-tools pk-apps pk-ui pk-docs platformkit; do
  gh repo view "septagon-oss/$r" --json visibility,defaultBranchRef,isArchived,isFork
  gh api "repos/septagon-oss/$r/actions/permissions"
done
```
Ensure: visibility public, default branch `main`, Actions enabled, release repos have `contents: write`. Apply branch protection **only after** the first green CI run exists.

## G. Rollback

- Repos can be set back to private (`gh repo edit ... --visibility private`).
- **Published module versions on the Go proxy are immutable** — they cannot be recalled. Hence the hard pre-flip gate and the "cut v0.1.1, never retag" rule.

---

### Status (flip EXECUTED 2026-07-22 — historical record + what was not re-verified)

Honest state: the push, visibility flip, and front-door creation happened on
2026-07-22. The org is public with 17 repos; releases have since iterated to
`platformkit v0.14.1` (20 GitHub Releases), `pk-modules v0.17.0`,
`pk-ui v0.6.3`; the docs site is live. Items marked TODO below were staged
before the flip but have not been independently re-verified against the live
public state.

| Item | Status |
|------|--------|
| Code gate (build/test/vet/staticcheck/race, govulncheck, gitleaks, actionlint, neutrality, godoc, tidy/no-replace) | ✅ green locally at flip time (historical) |
| Branches landed on `main` + `v0.1.0` tags (11 module repos) | ✅ done — pushed 2026-07-22; tags have since iterated well past v0.1.0 |
| Front-door module builds + boots (9 modules, 7 healthy stores, login 201) | ✅ verified at v0.1.0; re-capture against v0.14.1 for the announcement (`VERIFIED_RUN.md`) |
| go.sum "cascade" | ✅ was a stale-cache illusion; true `pk-modules@v0.1.0` = recorded go.sum (historical) |
| A1 CI CODEOWNERS | pushed with the flip; TODO: confirm the public CI baseline runs are green (not re-verified) |
| A2 tag normalization | ✅ done — public tags exist and 20 GitHub Releases are published |
| A3 pk-apps broken link | `pk-docs` is public and the docs site is live (5 pages); TODO: re-verify the pk-apps README link resolves |
| A4 docs | superseded — docs now ship on the live site (<https://septagon-oss.github.io/pk-docs>); TODO: confirm no v0.0.0-era labels remain |
| A5 pk-tools scaffold | superseded — scaffolding is now a supported front-door surface: `platformkit new app` / `platformkit new module` (since v0.13.0) |
| A6 NOTICE | not required at flip time (no vendored NOTICE-bearing deps confirmed; historical) |
| pk-docs private refs (velora/apex, private org) | scrubbed before the flip (historical) |
| Cold-resolve + hero path | ✅ v0.1.0-era verification; the current hero path is `go run github.com/septagon-oss/platformkit@latest` — re-capture before the announcement |
| Front-door repo `platformkit` created on remote | ✅ created + public (now v0.14.1) |

(Historical push note: dependency repos' `main` was intentionally one commit ahead of `v0.1.0` — the A1 CI fix — to avoid a go.sum cascade; `main` and the tag were pushed together.)

### Remaining work (the announcement track)
- **Re-capture `VERIFIED_RUN.md`** against `go run github.com/septagon-oss/platformkit@latest` (seed login is now `operator@local.test` / `local-development-only`, tenant `tenant_local`; `/admin` is auth-gated).
- Clear the TODOs above (public CI green, pk-apps README link, docs version labels).
- Work `CHECKLIST.md` §A open boxes, then §B launch hour and §C day-after. Nothing has been announced anywhere yet.
