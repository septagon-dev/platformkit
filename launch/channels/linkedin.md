# LinkedIn

Professional voice, still plain. No hype, no emoji-spam. Author = Septagon.

---

**Post:**

We're open-sourcing PlatformKit — an open-source Go backend for multi-tenant SaaS, under Apache-2.0.

The premise is simple. Every multi-tenant SaaS project rebuilds the same substrate: tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them. PlatformKit is that substrate, packaged as ten composable modules. You run one command and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, notifications, and tenant branding.

```
go run github.com/septagon-oss/platformkit@latest
```

Pure Go: no CGO, no npm, no Docker, SQLite by default (Postgres supported). Modules depend on interfaces (ports) rather than on each other, and dependency injection supplies the concrete type at startup — so teams can swap or add modules without changes cascading across the codebase. `platformkit new app` and `platformkit new module` scaffold your own.

A note on the open-core model, because it's where trust is earned or lost: the boundary is drawn at the *provider*, never at the *contract*. Every public interface a module exposes stays in open source. Pro adds hosted and cloud-scale providers — clustered Postgres, enterprise SSO, hosted observability — behind those same interfaces, so nothing you build against today moves out of OSS.

For teams that need self-hosting, this matters: PlatformKit runs entirely on your own infrastructure, with no managed dependency required to build and operate the substrate. You own the deployment.

The tenth module — tenant branding, with WCAG-corrected palette derivation so tenant brand colors stay accessible — landed this week through the same public ports the other nine use. That is the extension mechanism working as designed, on ourselves first.

It's early — the code has been public since July 2026 and is at v0.15; this is our first announcement. Expect APIs to move (verified on Linux and Go 1.26), and note the current limits we state plainly: in-memory per-process rate limiting and login lockout, coarse role-based access control, an unsigned audit log, and branding is SQLite-only until its Postgres adapter lands (a Postgres deployment composes nine and fails loudly on branding config). We build PlatformKit and use it ourselves, and we'd genuinely value feedback from teams shipping multi-tenant products.

Repo and docs: https://github.com/septagon-oss/platformkit

#golang #opensource #saas #softwarearchitecture
