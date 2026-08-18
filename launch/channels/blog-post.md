# Why we built PlatformKit, and how it works

*Published on the Septagon site. The canonical link the launch posts point to.*

---

## The problem: rebuilding the same SaaS substrate

If you've shipped more than one multi-tenant SaaS product, you've built the same backend twice. Maybe more than twice. Not the part that makes your product different — the part underneath it that every product needs and nobody wants to write again.

It's the tenant isolation that has to be in the data layer rather than bolted on after launch. It's the login flow. It's the audit trail you wish you'd added before the customer asked who changed that record. It's the admin screen for support staff. And it's the wiring that holds all of it together so the pieces actually compose.

Most SaaS starters hand you a CRUD demo. You then spend a month deleting their opinions and bolting on the things every product actually needs, by hand, again. The starter was a demo of a backend. It wasn't the backend.

We got tired of that, so we built the backend instead — and we're open-sourcing it.

## What PlatformKit is

PlatformKit is an open-source Go backend for multi-tenant SaaS. You run one command and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, notifications, and tenant branding — composed from ten modules. Pure Go: no CGO, no npm, no Docker, no external database required. SQLite is the default store so the first run needs no setup; Postgres is a supported driver when you want it. It's Apache-2.0.

It is the part of a SaaS backend you would otherwise rebuild from scratch in every project, and it's the backend itself, not a demo of one.

## The one-command demo

```bash
go run github.com/septagon-oss/platformkit@latest
```

No clone needed. That boots the starter app, seeds a tenant and an administrator, and serves the admin UI:

<!-- Re-verify this banner verbatim via the VERIFIED_RUN.md re-capture before publishing. -->

```
============================================================
 PlatformKit OSS
  listening:    http://127.0.0.1:8080
  admin UI:     http://127.0.0.1:8080/admin
  health:       http://127.0.0.1:8080/healthz
  OpenAPI:      http://127.0.0.1:8080/openapi/extensions.json
  local tenant: tenant_local
  local login:  operator@local.test / local-development-only
  modules:      9 composed (admin_management, health_management, tenant_management, user_management, audit_management, auth_management, api_key_management, content_management, notification_management)
============================================================
```

Open `http://127.0.0.1:8080/admin`. The first build downloads the Go modules and takes tens of seconds; subsequent starts take a couple of seconds.

PlatformKit is multi-tenant from the first line, so the seeded login is scoped to a tenant. The credentials — `operator@local.test` / `local-development-only`, tenant `tenant_local` — work on the admin login screen, and the same auth API sits underneath; its request body must include `tenant_id`:

```bash
curl -s -X POST http://127.0.0.1:8080/api/v1/auth/sessions \
  -H 'Content-Type: application/json' \
  -d '{"tenant_id":"tenant_local","email":"operator@local.test","password":"local-development-only"}'
```

One thing to be precise about: `/admin` is auth-gated. Anonymous requests are redirected to `/admin/login`, and the console requires the `admin` role plus the `console:access` scope — the seeded operator login above satisfies both. The seeded password is a development-mode convenience; production runs make you set your own.

The front door listens on `127.0.0.1:8080` by default and ships no config file. If 8080 is busy, pass `--port` (or `--addr`), or generate a config with `platformkit config init`.

## The architecture: core → modules → clients

PlatformKit has three layers.

The **core** defines the rules: the contracts, the kernel, and the wiring. It doesn't know about tenants or users — it knows how modules are composed.

**Modules** add capabilities behind those rules: tenant, user, auth, api_key, audit, content, notification, health, branding, and admin. Each is a self-contained vertical slice.

**Clients** compose the modules they want into a running application. The starter app is one such client.

The rule that makes this hold together: **modules never import each other's implementations.** They depend only on interfaces — ports like `AdminRegistrar` and `HealthRegistrar`, or a provider's published contract such as `audit.AuditEmitter`. Dependency injection supplies the concrete type at startup.

A module declares what it needs as a dependency on a port, not as an import of another module:

```go
// Declared in the module's Compose(), inside WithDependencies(...):
pkmodule.RequiresPort[user.UserBoundaryReader](pkmodule.PortSpec{
    Version:           "0.0.0",
    Purpose:           "Resolve user credentials at login time.",
    PreferredProvider: "user_management",
})
```

Two consequences follow, and they're the whole point. You can replace one module's implementation without the change cascading through the others — swap the store, swap the auth provider, and the modules that depend on those ports don't notice. And you add your own module the same way the ten built-ins are added — by declaring its ports and letting DI wire it in.

This is why "ten modules" is not the claim. Ten CRUD modules would not be a platform. The substrate is the tenant/auth/audit/admin boundary plus the compose-and-swap mechanism. The ten modules are the reference implementations that prove the mechanism works and give you a running app on the first command.

We compose modules through a small module catalog — plain Go constructor wiring, no DI framework. The contract types are container-agnostic, so a larger app could drop in uber/fx or another container, but the OSS core forces none. It's still a real tradeoff: composition adds indirection, and if you dislike that style this won't convert you. We think it's worth it because it's what makes compose-and-swap an actual property of the system rather than a slogan.

## Honest open core

PlatformKit is Apache-2.0, and the thing you clone and run is the whole substrate, not a trial slice.

Free is everything you need to build and run a multi-tenant SaaS backend on your own infrastructure: all the public contracts and ports, the default providers that make it run with zero setup (SQLite, in-memory, stdlib, file-based), the security baseline (CSRF, CORS, security headers, password hashing, signed cookies, rate-limiting and signature primitives), the reference admin UI, the starter app, the `pk` CLI, and the ten-module essentials pack.

Pro adds the operational and at-scale concerns: hosted and cloud-scale providers (NATS/JetStream/Kafka event buses, Postgres-cluster and read-replica backends, cloud secrets managers), enterprise identity (SCIM, SAML, SSO), vertical business modules, hosted observability, and a hosted control plane.

Here's the commitment, stated plainly because this is where open-core projects earn or lose trust: **the boundary is drawn at the provider, never at the contract.** Every public interface a module exposes stays in OSS. Pro plugs new implementations in behind those same interfaces — a Postgres-cluster store behind a module's store interface, an enterprise SSO provider behind the auth interface. Nothing in Pro requires re-typing your code against a closed API. The contracts you build against today do not move out of open source.

## What's not there yet

We'd rather you read this from us than write it in a GitHub issue.

It's not a no-code tool — it's a Go codebase, and you write Go to extend it. It's not a Rails or Django replacement — there's no ORM, no router opinion, no generator for everything; if you want batteries-included web MVC, this isn't that.

It's not production-hardened at scale on the default providers. SQLite is the zero-setup local default and Postgres is a supported driver; beyond that you swap in your own store behind the relevant module store interfaces (auth uses `WithSessionStore`). That's exactly what the port boundary is for. Four limits we know about today: rate limiting and login lockout are in-memory and per-process (they don't coordinate across replicas), access control is coarse role-based, the audit log is unsigned, and the newest module (tenant branding) has no Postgres adapter yet — a Postgres deployment composes the other nine and refuses branding configuration loudly rather than degrading silently.

And it's early. The code has been public since July 2026 and is at v0.15 — this post is our first announcement, not our first release — verified on Linux/x86_64, Go 1.26, `modernc.org/sqlite v1.54.0`, on a fresh database. APIs will keep moving. Pin a version if you need stability today.

## How to try it, and how to contribute

Run it:

```bash
go run github.com/septagon-oss/platformkit@latest
```

When you outgrow the demo, `platformkit new app` scaffolds your own application on the kit, and `platformkit new module` scaffolds a module of your own alongside the ten built-ins.

Then poke at the boundary — that's the part we most want stress-tested. Add a module of your own. Swap the store. Try to make the port abstraction leak. If it holds, tell us; if it breaks, definitely tell us. Issues and discussions are open on the repo.

We're Septagon. We build PlatformKit and use it ourselves to ship multi-tenant products, which is why the substrate looks the way it does — it's the stuff we got tired of rebuilding. The OSS substrate is the same one our own work composes from.

Repo: https://github.com/septagon-oss/platformkit — docs: https://septagon-oss.github.io/pk-docs
