# Show HN

**Title (≤80 chars, use exactly):**

```
Show HN: PlatformKit – open-source Go backend for multi-tenant SaaS
```

**URL:** https://github.com/septagon-oss/platformkit

---

**Body:**

PlatformKit is an open-source Go backend for multi-tenant SaaS. You clone it, run `go run .`, and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, and notifications — composed from nine modules. Pure Go: no CGO, no npm, no Docker, no external database (SQLite by default). It's the part of a SaaS backend you'd otherwise rebuild from scratch in every project.

```
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
# admin UI at http://localhost:8080/admin
# seeded auth login: admin@local.test / changeme (tenant tenant_acme)
```

The modules don't import each other — they depend on interfaces (ports like `AdminRegistrar`, or a provider's published contract), and dependency injection supplies the concrete type at startup. So you can swap a module's implementation without it cascading, and you add your own module the same way the nine built-ins are added. Multi-tenancy is in the data layer and the auth flow from the first line, not retrofitted — which is why the auth API needs `tenant_id` in the request body. It's Apache-2.0 and open core, with the line drawn at the *provider*, never the *contract*: every public interface stays in OSS, and Pro plugs new implementations in behind the same ports. We're Septagon; we build PlatformKit and use it ourselves.

What it's honestly not: not a no-code tool (you write Go), not a Rails/Django replacement (no ORM, no router opinion, no generators-for-everything), and not production-hardened at scale on the default store — SQLite is the zero-setup local default, and for production you swap your own store in behind the store port. It's also early: v0.1.0 — our first public release; expect APIs to move — verified on Linux/x86_64, Go 1.26. Things will move; pin a commit if you need stability today.

What we'd love feedback on: whether the port/DI boundary holds up when you try to add or swap a module, whether the one-command run is actually clean on your machine, and where the open-core line feels honest versus where it doesn't. Happy to answer anything in the thread.
