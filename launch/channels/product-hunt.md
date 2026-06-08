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

PlatformKit is an open-source Go backend for multi-tenant SaaS. Clone it, run `go run .`, and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, and notifications — composed from nine modules. Pure Go: no CGO, no npm, no Docker, SQLite by default. Apache-2.0.

---

**Maker's first comment:**

Hi PH — Septagon here. We kept rebuilding the same SaaS substrate in every Go project: tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them. PlatformKit is that substrate, packaged as nine composable modules you clone and run with one command.

The honest version: it's early (v0.1.0 — our first public release; expect APIs to move) and we're not dressing that up. The default store is SQLite for a zero-setup first run — for production at scale you swap your own store in behind the store port. `/admin` is an open dashboard today, not a gated login. It's a Go codebase, not a no-code tool, and not a Rails/Django replacement.

What makes it more than nine CRUD modules: modules depend on interfaces (ports), not each other, and dependency injection supplies the concrete type at startup — so you swap or add modules without edits cascading, the same way the built-ins are added. It's open core, with the line drawn at the provider and never the contract: every public interface stays in OSS.

```
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
# admin UI at http://localhost:8080/admin
```

We use this ourselves and we'll be in the comments. Honest feedback on the module/port boundary is exactly what we're after.
