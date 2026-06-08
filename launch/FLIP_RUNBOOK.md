# PlatformKit OSS v0.1.0 — Public Flip Runbook

> Status: **STAGED — do not execute until every Pre-flip blocker is cleared and the human gives an explicit go.** Nothing in here has been pushed or made public.

Scope: 12 public repos under `github.com/septagon-oss/` —
`pk-shared, pk-registry, pk-design, pk-client, pk-core, pk-runtime, pk-testkit, pk-modules, pk-tools, pk-apps, platformkit-ui, pk-docs`. `pk-deploy` is **excluded**.

Sources: local readiness gate (`.tmp-oss-gate/ledger.md`) + tri-model council (codex/grok; deepseek was down for the final run). The code gate is green; the items below are launch-mechanics the local gate could not see.

---

## A. Pre-flip blockers (clear ALL before any push)

| # | Blocker | Status | Fix | Decision needed |
|---|---------|--------|-----|-----------------|
| A1 | **CI baseline fails:** `.github/workflows/repository-baseline.yml:15` requires a **root** `CODEOWNERS`; Go repos only have `.github/CODEOWNERS`; `platformkit-ui` has none. First public CI run fails everywhere. | Verified | Either (a) relax the workflow to accept `.github/CODEOWNERS`, or (b) add root `CODEOWNERS` to all 11 Go repos. | Pick (a) or (b). |
| A2 | **Tag messages are placeholders:** all 10 backbone `v0.1.0` tags say *"local offline-proxy verification tag"*; `platformkit-ui`/`pk-docs` are lightweight. Tags are immutable once on the proxy. | Verified | Re-create `v0.1.0` as annotated (optionally signed) tags on the same commits with a real release message, immediately before push. | Tag message text; sign? |
| A3 | **pk-apps README broken link:** links to `pk-docs/.../docs/v0.1.0/starter-saas-tutorial.md` which doesn't exist (tutorial is at `docs/v0.0.0/`). 404 once public. | Verified | Point the link at the real path, or create `docs/v0.1.0/`. Coupled to A4. | — |
| A4 | **Docs versioned `v0.0.0` while launching `v0.1.0`:** whole `pk-docs/docs/v0.0.0/` tree, `RELEASING.md` says v0.0.0 and omits `pk-registry`/`platformkit-ui`, and the tutorial tells users to clone `septagon-oss-workspace` (not a public repo). | Verified | Rename/copy `docs/v0.0.0`→`docs/v0.1.0`, update release notes + repo list, change quickstart to clone `pk-apps`. | Versioning strategy: rename to v0.1.0 vs keep v0.0.0 + fix links only. |
| A5 | **pk-tools scaffold emits non-public roots:** defaults are `example.com/platformkit/backend-kit|business-modules|frontend-kit` (placeholder + old monorepo layout, not the `pk-core`/`pk-modules` split). Publicly-advertised CLI would generate broken scaffolds. | Verified | Update scaffold defaults to the public split, **or** de-emphasize/remove scaffold from the v0.1.0 public surface. | Rework scaffold vs de-scope for v0.1.0. |
| A6 | **NOTICE / third-party attribution:** every repo has Apache-2.0 `LICENSE`, none has `NOTICE`. Not required for source-only repos with non-vendored deps, but `pk-docs` ships branding assets. | Verified | Add `NOTICE`/`THIRD_PARTY_NOTICES` only where you ship NOTICE-bearing upstream code or derived assets; do not add blanket fake notices. | Confirm no vendored NOTICE-bearing deps/assets. |

## B. Pre-flip verification (run after blockers fixed, before push)

```bash
# B1 — every repo clean, HEAD==v0.1.0, on main
for r in pk-shared pk-registry pk-design pk-client pk-core pk-runtime pk-testkit pk-modules pk-tools pk-apps platformkit-ui pk-docs; do
  git -C septagon-oss-workspace/$r status --short
  [ "$(git -C septagon-oss-workspace/$r rev-parse HEAD)" = "$(git -C septagon-oss-workspace/$r rev-parse v0.1.0^{})" ] || echo "$r HEAD!=tag"
done
# B2 — final cold compose from tags (already PASS via mirrors): re-run after any fix
#   .tmp-oss-gate/cold.sh github.com/septagon-oss/pk-apps   # expect COLD-OK
# B3 — hero path (already PASS): cd pk-apps/apps/starter-saas && go run . ; curl :8080/admin
```

## C. Push order (layered — NOT concurrent)

Push `main` and the (normalized) `v0.1.0` tag per layer; let each layer settle before the next so dependents resolve upstream `@v0.1.0`.

```
Layer 0 (leaves):   pk-shared pk-registry pk-design pk-client pk-core platformkit-ui
Layer 1:            pk-runtime pk-testkit pk-modules
Layer 2:            pk-tools
Layer 3:            pk-apps
Layer 4:            pk-docs
```

Per repo, per layer:
```bash
git -C septagon-oss-workspace/$r push origin main
git -C septagon-oss-workspace/$r push origin v0.1.0
```

## D. Visibility flip (after tags pushed, same layer order)

```bash
gh repo edit septagon-oss/$r --visibility public --accept-visibility-change-consequences
```

## E. Post-flip verification (proxy/sumdb — the part the gate can't simulate)

```bash
tmp="$(mktemp -d)"
for r in pk-shared pk-registry pk-design pk-client pk-core pk-runtime pk-testkit pk-modules pk-tools pk-apps platformkit-ui; do
  m="github.com/septagon-oss/$r"
  env -u GOPRIVATE -u GONOSUMDB GOPROXY=https://proxy.golang.org GOSUMDB=sum.golang.org GOWORK=off \
      GOMODCACHE="$tmp/m" GOCACHE="$tmp/c" go list -m -json "$m@v0.1.0" >/dev/null || echo "PROXY FAIL $m"
  curl -fsS "https://sum.golang.org/lookup/$m@v0.1.0" >/dev/null || echo "SUMDB pending $m"
done
# Real consumer hero path from the public proxy:
cd "$(mktemp -d)" && go mod init consumer.test && go get github.com/septagon-oss/pk-apps@v0.1.0 && go build ./...
```
**If any module reached the proxy/sumdb with bad content, cut `v0.1.1` — never retag `v0.1.0`.**

## F. GitHub settings (verify live; local clones can't prove these)

```bash
for r in <all 12>; do
  gh repo view septagon-oss/$r --json visibility,defaultBranchRef,isArchived,isFork
  gh api repos/septagon-oss/$r/actions/permissions
done
```
Ensure: visibility public, default branch `main`, Actions enabled, release repos have `contents: write`. Apply branch protection **only after** the first green CI run exists.

## G. Rollback

- Repos can be set back to private (`gh repo edit ... --visibility private`).
- **Published module versions on the Go proxy are immutable** — they cannot be recalled. Hence the hard pre-flip gate and the "cut v0.1.1, never retag" rule.

---

### Status after fix pass (all LOCAL, nothing pushed)

| Item | Status |
|------|--------|
| Code gate (build/test/vet/staticcheck/race, govulncheck, gitleaks, actionlint, neutrality, godoc, tidy/no-replace) — all 12 | ✅ green |
| go.sum "cascade" | ✅ was a stale-cache illusion; true `pk-modules@v0.1.0` = recorded go.sum |
| A1 CI CODEOWNERS | ✅ baseline workflow relaxed (accepts `.github/CODEOWNERS`) in 11 repos; ui CODEOWNERS added |
| A2 tag normalization | ✅ all 12 `v0.1.0` are annotated `PlatformKit OSS v0.1.0` |
| A3 pk-apps broken link | ✅ repointed to existing `docs/v0.0.0/` path |
| A4 docs | ⚠️ PARTIAL — clone instruction + RELEASING order fixed; **full v0.0.0→v0.1.0 docs rewrite DEFERRED** (seed-release narrative, repo counts; needs a content pass, not a mechanical rename) |
| A5 pk-tools scaffold | ✅ marked experimental / de-scoped from v0.1.0 surface |
| A6 NOTICE | ✅ not required (no vendored deps) |
| pk-docs private refs (velora/apex, private org) | ✅ scrubbed |
| Cold-resolve 11 + hero path (re-tagged) | ✅ verified |

**Important — dependency repos `main` is ahead of `v0.1.0` by one commit** (the A1 CI fix). This is intentional: the relaxed workflow lives on `main` (where baseline CI runs), and the `v0.1.0` *module* is deliberately left unchanged to avoid a go.sum cascade. When pushing, push `main` **and** the `v0.1.0` tag for each repo.

### Still TODO before/at flip (need a human + network)
- **A4 full docs rewrite** — decide: rewrite `docs/v0.0.0` content to accurate v0.1.0 (12 repos, no "first seed release"/"ten repos"/"v0.0.1 expected"), or keep honest v0.0.0 labels. Currently links work but version labels say v0.0.0.
- Everything in Sections C–F (layered push, visibility flip, proxy/sumdb post-publish checks, GitHub settings via `gh`) — these require the actual flip and are gated on your explicit go.
