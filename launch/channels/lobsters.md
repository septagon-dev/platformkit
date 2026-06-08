# Lobsters

**Submit as:** link to https://github.com/septagon-oss/platformkit

**Title:**

`PlatformKit: an open-source Go backend for multi-tenant SaaS`

**Suggested tags:** `go`, `databases`, `practices`

(`go` is the language; `databases` because the store/port boundary and SQLite-by-default are central; `practices` for the ports/DI composition model. Drop `databases` if it reads as a stretch to the mod queue.)

---

**Authored comment (post as author after submitting):**

PlatformKit is the multi-tenant SaaS substrate — tenants, users, auth, audit, an admin UI, API keys, content, notifications — packaged as nine composable Go modules. Clone it, `go run .`, and you get a seeded multi-tenant app at `http://localhost:8080/admin`. Pure Go: no CGO, no npm, no Docker, SQLite by default. Modules depend on interfaces (ports) and DI supplies the concrete type at startup, so you swap or add modules without imports cascading; the open-core line is drawn at the provider, never the contract (Apache-2.0, every interface stays in OSS). It's early — v0.1.0, our first public release; expect APIs to move, verified on Linux/x86_64 + Go 1.26, `/admin` is an open dashboard rather than a gated login, and SQLite is the local default you'd swap for production behind the relevant module store interfaces (auth uses `WithSessionStore`). We're Septagon and we use it ourselves; feedback on the port boundary is what we want most.
