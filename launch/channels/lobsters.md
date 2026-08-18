# Lobsters

**Submit as:** link to https://github.com/septagon-oss/platformkit

**Title:**

`PlatformKit: an open-source Go backend for multi-tenant SaaS`

**Suggested tags:** `go`, `databases`, `practices`

(`go` is the language; `databases` because the store/port boundary and SQLite-by-default are central; `practices` for the ports/DI composition model. Drop `databases` if it reads as a stretch to the mod queue.)

---

**Authored comment (post as author after submitting):**

PlatformKit is the multi-tenant SaaS substrate — tenants, users, auth, audit, an admin UI, API keys, content, notifications — packaged as ten composable Go modules. `go run github.com/septagon-oss/platformkit@latest` and you get a seeded multi-tenant app with an auth-gated admin at `http://localhost:8080/admin` (seeded dev login `operator@local.test` / `local-development-only`, tenant `tenant_local`); `platformkit new app` / `new module` scaffold your own. Pure Go: no CGO, no npm, no Docker, SQLite by default (Postgres supported). Modules depend on interfaces (ports) and DI supplies the concrete type at startup, so you swap or add modules without imports cascading; the open-core line is drawn at the provider, never the contract (Apache-2.0, every interface stays in OSS). It's early — the code has been public since July 2026, now at v0.15, but this is our first announcement; expect APIs to move (verified on Linux/x86_64 + Go 1.26). Known limits today: in-memory per-process rate limiting and login lockout, coarse role-based access control, an unsigned audit log, and the newest module (tenant branding) is SQLite-only — on Postgres you compose nine and branding config fails loudly; SQLite/Postgres are the defaults you'd swap for scale behind the relevant module store interfaces (auth uses `WithSessionStore`). We're Septagon and we use it ourselves; feedback on the port boundary is what we want most.
