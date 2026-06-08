# LinkedIn

Professional voice, still plain. No hype, no emoji-spam. Author = Septagon.

---

**Post:**

We're open-sourcing PlatformKit — an open-source Go backend for multi-tenant SaaS, under Apache-2.0.

The premise is simple. Every multi-tenant SaaS project rebuilds the same substrate: tenant isolation, a login flow, an audit trail, an admin screen, and the wiring between them. PlatformKit is that substrate, packaged as nine composable modules. You clone it, run one command, and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, and notifications.

```
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
```

Pure Go: no CGO, no npm, no Docker, SQLite by default. Modules depend on interfaces (ports) rather than on each other, and dependency injection supplies the concrete type at startup — so teams can swap or add modules without changes cascading across the codebase.

A note on the open-core model, because it's where trust is earned or lost: the boundary is drawn at the *provider*, never at the *contract*. Every public interface a module exposes stays in open source. Pro adds hosted and cloud-scale providers — clustered Postgres, enterprise SSO, hosted observability — behind those same interfaces, so nothing you build against today moves out of OSS.

For teams with data-residency or sovereignty requirements, this matters: PlatformKit runs entirely on your own infrastructure, with no managed dependency required to build and operate the substrate. You own the deployment.

It's an early release — v0.1.0, our first public release; expect APIs to move, verified on Linux and Go 1.26. We build PlatformKit and use it ourselves, and we'd genuinely value feedback from teams shipping multi-tenant products.

Repo and docs: https://github.com/septagon-oss/platformkit

#golang #opensource #saas #softwarearchitecture
