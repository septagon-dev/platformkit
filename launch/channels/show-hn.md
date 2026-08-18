# Show HN

**Title (≤80 chars, use exactly):**

```
Show HN: PlatformKit – open-source Go backend for multi-tenant SaaS
```

**URL:** https://github.com/septagon-oss/platformkit

---

**Body:**

PlatformKit is an open-source Go backend for multi-tenant SaaS. You run one command and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, notifications, and tenant branding — composed from ten modules. Pure Go: no CGO, no npm, no Docker, no external database required (SQLite by default; Postgres is supported). It's the part of a SaaS backend you'd otherwise rebuild from scratch in every project.

```
go run github.com/septagon-oss/platformkit@latest
# admin UI at http://localhost:8080/admin (auth-gated)
# seeded dev login: operator@local.test / local-development-only (tenant tenant_local)
```

The modules don't import each other — they depend on interfaces (ports like `AdminRegistrar`, or a provider's published contract), and dependency injection supplies the concrete type at startup. So you can swap a module's implementation without it cascading, and you add your own module the same way the ten built-ins are added — `platformkit new module` scaffolds one, and `platformkit new app` scaffolds your own app on the kit. Multi-tenancy is in the data layer and the auth flow from the first line, not retrofitted — which is why the auth API needs `tenant_id` in the request body. It's Apache-2.0 and open core, with the line drawn at the *provider*, never the *contract*: every public interface stays in OSS, and Pro plugs new implementations in behind the same ports. We're Septagon; we build PlatformKit and use it ourselves.

What it's honestly not: not a no-code tool (you write Go), not a Rails/Django replacement (no ORM, no router opinion, no generators-for-everything), and not production-hardened at scale on the default store — SQLite is the zero-setup default (Postgres is a supported driver), and you can swap your own store in behind the relevant module store interfaces (auth uses `WithSessionStore`). Current limits we'll name up front: rate limiting and login lockout are in-memory and per-process, access control is coarse role-based, the audit log is unsigned, and the newest module (tenant branding, landed this week through the same ports the other nine use) is SQLite-only so far — a Postgres deployment composes the other nine and refuses branding config loudly rather than silently. On maturity: the code has been public since July 2026 and is at v0.15 — this is our first announcement, not our first release; expect APIs to keep moving — verified on Linux/x86_64, Go 1.26. Pin a version if you need stability today.

What we'd love feedback on: whether the port/DI boundary holds up when you try to add or swap a module, whether the one-command run is actually clean on your machine, and where the open-core line feels honest versus where it doesn't. Happy to answer anything in the thread.
