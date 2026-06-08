# Why we built PlatformKit, and how it works

*Published on the Septagon site. The canonical link the launch posts point to.*

---

## The problem: rebuilding the same SaaS substrate

If you've shipped more than one multi-tenant SaaS product, you've built the same backend twice. Maybe more than twice. Not the part that makes your product different — the part underneath it that every product needs and nobody wants to write again.

It's the tenant isolation that has to be in the data layer rather than bolted on after launch. It's the login flow. It's the audit trail you wish you'd added before the customer asked who changed that record. It's the admin screen for support staff. And it's the wiring that holds all of it together so the pieces actually compose.

Most SaaS starters hand you a CRUD demo. You then spend a month deleting their opinions and bolting on the things every product actually needs, by hand, again. The starter was a demo of a backend. It wasn't the backend.

We got tired of that, so we built the backend instead — and we're open-sourcing it.

## What PlatformKit is

PlatformKit is an open-source Go backend for multi-tenant SaaS. You clone it, run one command, and you get a seeded multi-tenant app — tenants, users, auth, an admin UI, audit, API keys, content, and notifications — composed from nine modules. Pure Go: no CGO, no npm, no Docker, no external database. SQLite is the default store so the first run needs no setup. It's Apache-2.0.

It is the part of a SaaS backend you would otherwise rebuild from scratch in every project, and it's the backend itself, not a demo of one.

## The one-command demo

```bash
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
```

That boots the starter app, seeds a tenant and an admin user, and serves the admin UI:

```
starter-saas — PlatformKit OSS monolith
  listening:    http://localhost:8080
  admin UI:     http://localhost:8080/admin
  default login: admin@local.test / changeme
```

Open `http://localhost:8080/admin`. The first build downloads a handful of Go modules and takes tens of seconds; subsequent starts take about two seconds.

PlatformKit is multi-tenant from the first line, so the seeded login is scoped to a tenant. The credentials — `admin@local.test` / `changeme`, tenant `tenant_acme` — authenticate against the auth API, and the request body must include `tenant_id`:

```bash
curl -s -X POST http://localhost:8080/api/v1/auth/sessions \
  -H 'Content-Type: application/json' \
  -d '{"tenant_id":"tenant_acme","email":"admin@local.test","password":"changeme"}'
```

One thing to be precise about: `/admin` is an open dashboard today, not a gated login wall. The seeded credentials are for the auth API, not an admin login screen — that doesn't exist yet. We'd rather tell you that than let you discover it.

The front door listens on `:8080` and ships no config file. If 8080 is busy, run the full starter in pk-apps (`pk-apps/apps/starter-saas`, which reads `http.addr` from its `config.yaml`) or change the address in the wrapper's `main.go`.

## The architecture: core → modules → clients

PlatformKit has three layers.

The **core** defines the rules: the contracts, the kernel, and the wiring. It doesn't know about tenants or users — it knows how modules are composed.

**Modules** add capabilities behind those rules: tenant, user, auth, api_key, audit, content, notification, health, and admin. Each is a self-contained vertical slice.

**Clients** compose the modules they want into a running application. The starter app is one such client.

The rule that makes this hold together: **modules never import each other's implementations.** They depend only on interfaces — ports like `AdminRegistrar` and `HealthRegistrar`, or a provider's published contract such as `audit.AuditEmitter`. Dependency injection supplies the concrete type at startup.

A module declares what it needs as a dependency on a port, not as an import of another module:

```go
standard.WithDep(module.RequiresPort[ports.AuditService](module.PortSpec{
    Purpose:           "Audit changes to records",
    PreferredProvider: "audit_management",
}))
```

Two consequences follow, and they're the whole point. You can replace one module's implementation without the change cascading through the others — swap the store, swap the auth provider, and the modules that depend on those ports don't notice. And you add your own module the same way the nine built-ins are added — by declaring its ports and letting DI wire it in.

This is why "nine modules" isn't the claim. Nine CRUD modules wouldn't be a platform. The substrate is the tenant/auth/audit/admin boundary plus the compose-and-swap mechanism. The nine modules are the reference implementations that prove the mechanism works and give you a running app on the first command.

We use uber/fx for the dependency injection. It's a real tradeoff — DI adds indirection, and if you dislike that style this won't convert you. We think it's worth it because it's what makes compose-and-swap an actual property of the system rather than a slogan.

## Honest open core

PlatformKit is Apache-2.0, and the thing you clone and run is the whole substrate, not a trial slice.

Free is everything you need to build and run a multi-tenant SaaS backend on your own infrastructure: all the public contracts and ports, the default providers that make it run with zero setup (SQLite, in-memory, stdlib, file-based), the security baseline (CSRF, CORS, security headers, password hashing, signed cookies, rate-limiting and signature primitives), the reference admin UI, the starter app, the `pk` CLI, and the nine-module essentials pack.

Pro adds the operational and at-scale concerns: hosted and cloud-scale providers (NATS/JetStream/Kafka event buses, Postgres-cluster and read-replica backends, cloud secrets managers), enterprise identity (SCIM, SAML, SSO), vertical business modules, hosted observability, and a hosted control plane.

Here's the commitment, stated plainly because this is where open-core projects earn or lose trust: **the boundary is drawn at the provider, never at the contract.** Every public interface a module exposes stays in OSS. Pro plugs new implementations in behind those same interfaces — a Postgres-cluster store behind the store port, an enterprise SSO provider behind the auth port. Nothing in Pro requires re-typing your code against a closed API. The contracts you build against today do not move out of open source.

## What's not there yet

We'd rather you read this from us than write it in a GitHub issue.

It's not a no-code tool — it's a Go codebase, and you write Go to extend it. It's not a Rails or Django replacement — there's no ORM, no router opinion, no generator for everything; if you want batteries-included web MVC, this isn't that.

It's not production-hardened at scale on the default store. SQLite is the zero-setup local default, and it's great for development and small deployments; for production at scale you swap in your own store behind the store port. That's exactly what the port boundary is for.

And it's early. This is v0.1.0 — our first public release; expect APIs to move — verified on Linux/x86_64, Go 1.26, `modernc.org/sqlite v1.50.1`, on a fresh database. Things will move. Pin a commit if you need stability today.

## How to try it, and how to contribute

Clone it and run it:

```bash
git clone https://github.com/septagon-oss/platformkit
cd platformkit
go run .
```

Then poke at the boundary — that's the part we most want stress-tested. Add a module of your own. Swap the store. Try to make the port abstraction leak. If it holds, tell us; if it breaks, definitely tell us. Issues and discussions are open on the repo.

We're Septagon. We build PlatformKit and use it ourselves to ship multi-tenant products, which is why the substrate looks the way it does — it's the stuff we got tired of rebuilding. The OSS substrate is the same one our own work composes from.

Repo: https://github.com/septagon-oss/platformkit
