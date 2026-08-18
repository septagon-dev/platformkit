# Product Hunt

**Name:** PlatformKit

**Tagline (outcome-first, ≤60 chars):**

`The multi-tenant SaaS backend you stop rebuilding`

**Alternate taglines:**
- `Open-source Go backend for multi-tenant SaaS`
- `Clone, run, get a multi-tenant SaaS backend`

**Topics:** Developer Tools, Open Source, SaaS, GitHub

**Links:** https://github.com/septagon-oss/platformkit

---

**Description (short):**

PlatformKit is an open-source Go backend for multi-tenant SaaS. Run `go run github.com/septagon-oss/platformkit@latest` and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, notifications, and tenant branding — composed from ten modules. Pure Go: no CGO, no npm, no Docker, SQLite by default (Postgres supported). Apache-2.0.

---

**Maker's first comment:**

Hi PH — Septagon here. We kept rebuilding the same SaaS substrate in every Go project: tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them. PlatformKit is that substrate, packaged as ten composable modules you run with one command.

The honest version: it's early — the code has been public since July 2026 and is at v0.15, but this is our first announcement; expect APIs to keep moving — and we're not dressing that up. The default store is SQLite for a zero-setup first run and Postgres is a supported driver; beyond that you swap your own store in behind the relevant module store interfaces (auth uses `WithSessionStore`). Known limits today: rate limiting and login lockout are in-memory and per-process, access control is coarse role-based, the audit log is unsigned, and the newest module (tenant branding) is SQLite-only so far — on Postgres you compose nine and branding config fails loudly. It's a Go codebase, not a no-code tool, and not a Rails/Django replacement.

What makes it more than ten CRUD modules: modules depend on interfaces (ports), not each other, and dependency injection supplies the concrete type at startup — so you swap or add modules without edits cascading, the same way the built-ins are added (`platformkit new module` scaffolds your own). It's open core, with the line drawn at the provider and never the contract: every public interface stays in OSS.

```
go run github.com/septagon-oss/platformkit@latest
# admin UI at http://localhost:8080/admin (auth-gated)
# login: operator@local.test / local-development-only (tenant tenant_local)
```

We use this ourselves and we'll be in the comments. Honest feedback on the module/port boundary is exactly what we're after.
