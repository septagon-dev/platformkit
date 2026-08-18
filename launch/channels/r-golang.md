# r/golang

**Suggested title:**

PlatformKit: an open-source Go backend for multi-tenant SaaS — one `go run` away

**Flair:** `show & tell`

---

**Body:**

We've been rebuilding the same SaaS substrate in every Go project — tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them — so we packaged it as composable modules and open-sourced it. It's Apache-2.0, pure Go, no CGO, no npm, no Docker, SQLite by default (Postgres supported).

One command, no clone:

```bash
go run github.com/septagon-oss/platformkit@latest
# admin UI at http://localhost:8080/admin (auth-gated)
# seeded dev login: operator@local.test / local-development-only (tenant tenant_local)
```

That boots a seeded multi-tenant app — tenants, users, auth, admin UI, audit, API keys, content, notifications, tenant branding — composed from ten modules. First build downloads the modules (tens of seconds); warm starts take a couple of seconds. When you outgrow the starter, `platformkit new app` scaffolds your own app on the kit and `platformkit new module` scaffolds a module.

The shape, briefly. Modules never import each other's implementations; they depend on interfaces (ports), and the module catalog supplies the concrete type at startup — plain Go wiring, no DI framework:

```go
// A module declares what it needs as a port (in its Compose()), not an import:
pkmodule.WithDependencies(
    pkmodule.RequiresPort[user.UserBoundaryReader](pkmodule.PortSpec{
        Version:           "0.0.0",
        Purpose:           "Resolve user credentials at login time.",
        PreferredProvider: "user_management",
    }),
)
```

So you swap a module's implementation without the change cascading, and you add your own module the same way the ten built-ins are added. Multi-tenancy is in the data layer and the auth flow, not retrofitted — the seeded login is tenant-scoped, which is why the auth API needs `tenant_id` in the body.

Honest scope: it's early — the code has been public since July 2026 and is at v0.15; this post is the first announcement, so expect APIs to keep moving — verified on Linux/x86_64, Go 1.26, `modernc.org/sqlite v1.54.0`, fresh DB. SQLite is the zero-setup default and Postgres is a supported driver — beyond that you put your own store behind the relevant module store interfaces (auth uses `WithSessionStore`). Known limits today: rate limiting and login lockout are in-memory and per-process, access control is coarse role-based, the audit log is unsigned, and the newest module (tenant branding) is SQLite-only so far — a Postgres deployment composes the other nine and refuses branding config loudly rather than silently. It's not a Rails/Django-style web framework: no ORM, no router opinion, no generators-for-everything. The module-catalog composition is a real tradeoff if you dislike that style; it's what makes the compose-and-swap work rather than being a slogan.

It's open core: the boundary is the *provider*, never the *contract* — every public interface stays in OSS, Pro plugs new implementations in behind the same ports. We're Septagon and we use this ourselves.

Repo: https://github.com/septagon-oss/platformkit — feedback on the port/DI boundary is what we're most after. We just added the tenth module ourselves (tenant branding, with WCAG-corrected palette derivation) through the same ports the other nine use; tell us whether the boundary holds when you add yours.
