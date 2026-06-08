# r/golang

**Suggested title:**

PlatformKit: an open-source Go backend for multi-tenant SaaS — clone and `go run .`

**Flair:** `show & tell`

---

**Body:**

We've been rebuilding the same SaaS substrate in every Go project — tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them — so we packaged it as composable modules and open-sourced it. It's Apache-2.0, pure Go, no CGO, no npm, no Docker, SQLite by default.

One command from a cold clone:

```bash
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
# admin UI at http://localhost:8080/admin
# seeded auth login: admin@local.test / changeme (tenant tenant_acme)
```

That boots a seeded multi-tenant app — tenants, users, auth, admin UI, audit, API keys, content, notifications — composed from nine modules. First build downloads a handful of modules (tens of seconds); warm starts are about two seconds.

The shape, briefly. Modules never import each other's implementations; they depend on interfaces (ports), and DI (uber/fx) supplies the concrete type at startup:

```go
// A module declares what it needs as a port, not an import:
standard.WithDep(module.RequiresPort[ports.AuditService](module.PortSpec{
    Purpose:           "Audit changes",
    PreferredProvider: "audit_management",
}))
```

So you swap a module's implementation without the change cascading, and you add your own module the same way the nine built-ins are added. Multi-tenancy is in the data layer and the auth flow, not retrofitted — the seeded login is tenant-scoped, which is why the auth API needs `tenant_id` in the body.

Honest scope: it's early (v0.1.0 — our first public release; expect APIs to move), verified on Linux/x86_64, Go 1.26, `modernc.org/sqlite v1.50.1`, fresh DB. `/admin` is an open dashboard right now, not a gated login. SQLite is the zero-setup default — for production at scale you put your own store behind the store port. It's not a Rails/Django-style web framework: no ORM, no router opinion, no generators-for-everything. fx-based DI is a real tradeoff if you dislike that style; it's what makes the compose-and-swap work rather than being a slogan.

It's open core: the boundary is the *provider*, never the *contract* — every public interface stays in OSS, Pro plugs new implementations in behind the same ports. We're Septagon and we use this ourselves.

Repo: https://github.com/septagon-oss/platformkit — feedback on the port/DI boundary (does it hold when you add a tenth module?) is what we're most after.
