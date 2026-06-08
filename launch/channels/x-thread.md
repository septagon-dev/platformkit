# X / Twitter Thread

One idea per post. Plain voice, no hype, no emoji-spam. Author = Septagon.

> **Asset notes:**
> - Post 1 should carry the **OG card** (repo social image / hero) so the link unfurls cleanly.
> - Post 3 (the one-command demo) is where the **asciinema cast** (or a short screen capture of `go run .` → admin UI) goes.

---

**1/ (hook)**

We kept rebuilding the same SaaS backend in every Go project — tenants, users, auth, an audit trail, an admin screen — and wiring it by hand every time. So we packaged that substrate and open-sourced it. PlatformKit. Apache-2.0.

https://github.com/septagon-oss/platformkit

---

**2/ (what it is)**

PlatformKit is an open-source Go backend for multi-tenant SaaS. Clone it and you get a seeded multi-tenant app — tenants, users, auth, admin UI, audit, API keys, content, notifications — composed from nine modules. Pure Go: no CGO, no npm, no Docker, SQLite by default.

---

**3/ (one command — attach the demo cast)**

```
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
# admin UI at http://localhost:8080/admin
```

That's the whole first run. Warm starts in about two seconds.

---

**4/ (ports / DI — the actual idea)**

The modules don't import each other. They depend on interfaces (ports), and dependency injection supplies the concrete type at startup. So you swap one module's implementation without it cascading — and you add your own module the same way the nine built-ins are added.

---

**5/ (open core, honest)**

It's open core, and the line is drawn at the provider, never the contract: every public interface stays in OSS. Pro plugs new implementations in behind the same ports — e.g. a Postgres-cluster store behind the relevant module store interface. Nothing you build against today moves out of open source.

---

**6/ (what it's NOT)**

Honest scope: not a no-code tool (you write Go). Not a Rails/Django replacement. SQLite is the zero-setup local default — for production you put your own store behind the relevant module store interface (auth uses `WithSessionStore`). `/admin` is an open dashboard today, not a gated login — the seeded creds authenticate against the auth API (`POST /api/v1/auth/sessions`, with `tenant_id` in the body), so gate it before exposing the port. And it's early: v0.1.0, our first public release; expect APIs to move, verified on Linux + Go 1.26. Pin a commit if you need stability.

---

**7/ (call for feedback)**

We're Septagon. We build PlatformKit and use it ourselves. What we want most: does the port/DI boundary hold up when you add or swap a module? Try it, tell us where it breaks.

Repo + Show HN in the thread: https://github.com/septagon-oss/platformkit
