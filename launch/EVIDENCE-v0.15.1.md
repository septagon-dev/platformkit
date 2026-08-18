# Launch evidence — PlatformKit v0.15.1 (2026-07-30)

**Announce v0.15.1, not v0.15.0.** Same ten-module composition; v0.15.1 adds
the x/text security bump and a gosec-clean scaffolder. On the v0.15.1 push,
ALL THREE workflows (Go, CodeQL, Security) are green — the Security gate had
been red on every run since 0.13.0, so the README badge goes green with this
launch. Battery re-run at v0.15.1 (4e55495): boot 3s, 10 composed, anon 401s,
admin 303, login OK, authed 200, revoke 204 → reuse 401.

One page tying the launch claims to what was actually verified. Everything
below was executed on 2026-07-30; nothing is projected.

## The release train (all landed 2026-07-30, dependency order)

| Repo | Version | Gate that passed before the tag |
|---|---|---|
| pk-design | v0.3.0 | `make verify` (test, vet, staticcheck, race), GOWORK=off clean worktree |
| pk-guard | v0.1.0 | self-hosting `make verify` (pk-guard runs pk-guard) + pre-push hook re-ran it |
| pk-modules | v0.18.0 | `make verify` incl. **pk-guard gate** (test, vet, guard, staticcheck, race) |
| pk-tools | **v0.3.2** | `make verify`; OSS boundary test proves no `septagon-dev` imports |
| pk-apps | v0.15.0 | `make verify` after the branding merge (main = tag = edf256e) |
| platformkit (front door) | v0.15.0 | verify + the clean-clone boot smoke below (f8f3136) |

CI: Repository Baseline + CodeQL green on every landed main.
Dependabot: live org-wide, first update PRs opened and green same-day.

**Incident, disclosed:** pk-tools v0.3.0 and v0.3.1 are RETRACTED
(`retract [v0.3.0, v0.3.1]` in v0.3.2). Both were tagged from a commit whose
go.mod pinned pk-modules v0.15.0 (no `pkg/branding`) — a silent pre-commit-hook
rejection dropped the pin-bump amend, and two concurrent sessions each cut a
tag before catching it. The proxy has both cached immutably; the retraction is
the correct remedy. `go get github.com/septagon-oss/pk-tools@latest` resolves
to v0.3.2.

## What the guard gate proved (pk-modules)

First run of pk-guard over the module surface: 26 discarded-error findings.
7 propagated — including two real bugs shipped in earlier releases:
- migrate: a failed `pg_advisory_unlock` was discarded; `sql.Conn.Close`
  returns the session to the pool, so the advisory lock could be stranded and
  block every future migration run across processes.
- apikey: corrupt scopes JSON in the store silently became the empty scope
  set instead of an error — corruption masking on the credential path.
19 sites kept their discard with a written, site-specific justification
(post-header response writes, best-effort audit fan-out, login-timing decoy
hash, compensating deletes, deferred rollbacks).

## Clean-clone boot smoke at v0.15.0 — EXECUTED, ALL PASS

Fresh `git clone https://github.com/septagon-oss/platformkit`, checkout
v0.15.0 (f8f3136), `GOWORK=off`, no replace directives, deps resolved from the
public proxy. Boot ready in 2s on a fresh SQLite database.

- ✅ banner: `modules: 10 composed (..., branding_management)`; dev login printed
- ✅ `modules --json`: 10 entries, `branding_management` present
- ✅ healthz 200
- ✅ anonymous: `/api/v1/tenants` 401 · `/api/v1/users` 401 · `/metrics` 401 ·
  `/admin` 303→login · anonymous session DELETE 401
- ✅ `POST /api/v1/auth/sessions` with banner credentials → session issued
- ✅ authed: tenants 200 · users 200 · content 200
- ✅ tenant isolation: foreign tenant by-id → 404 (no existence oracle);
  own tenant → 200
- ✅ **session revocation** (evidence gap CLOSED): by-id routes require the
  canonical opaque path segment `id-<hex>` (`pk-shared/pkg/pathsegment`);
  with it, `DELETE /api/v1/auth/sessions/{id}` → **204**, revoked session
  reuse → **401**, repeat DELETE → 401 (anonymous, gate holds). The
  long-standing "400" in earlier batteries was this encoding requirement —
  by design, and the 400 body says exactly how to encode.

## Known-good statements for the announcement

- Ten modules including tenant branding, composed in one process. SQLite
  profile (the `go run .` default) composes all ten.
- **Postgres caveat, stated plainly:** branding has no Postgres adapter yet.
  The Postgres profile composes the other nine, keeps stock chrome, and
  refuses to boot if branding seed values are configured — loud, not silent.
  README and CHANGELOG both say this.
- Every by-id store query carries a tenant predicate; the cross-tenant IDOR
  class from the v0.1.0 audit has regression tests, re-proven live above.
- The module boundary is compiler- and linter-enforced (AST boundary test,
  pk-guard in the verify gate) — "governance for AI-generated code."
- Pre-1.0, pinned-set model: the front door pins an exact tested set; tiers
  documented in the front-door README (Released set / Toolchain / Foundations).

## Deliberately not in this launch

- pk-docs `feat/turnkey-faq` branch (asset deletions conflict with the gated
  marketing overlay decision) — parked, trailer-free, on origin.
- pk-ui local surface WIP (36 files) and pk-client pk-shared pseudo-version
  bump — user WIP, untouched (pk-client's also preserved in stash@{0}).
- 5 repos remain private (pk-deploy, pk-registry, problem, standards,
  statemachine) — user decision pending.

## Remaining user-side checklist

- [ ] Decide the 5 private repos
- [ ] Org security A3b remainder
- [ ] Social previews / topics on the new repos
- [ ] Launch-hour posts (positioning: the enforced module boundary as
      governance for AI-generated code)
- [ ] Push estate backend-kit's 2 local commits (geography logging, gateway
      endpoint reservation) — deliberately left for user review
- [ ] Branding Postgres adapter (first post-launch milestone; removes the
      nine-on-Postgres caveat)
