# PlatformKit — Narrative Spine

> This is the positioning source-of-truth for the PlatformKit OSS launch. Every
> other launch text (Show HN post, READMEs, docs, blog) quotes from here. Voice:
> a plain-spoken senior Go engineer explaining a tool to another tired senior Go
> engineer. No hype, no adjectives doing an engineer's job. State the fact.
>
> Authored by Septagon. We make PlatformKit and use it ourselves.

---

## 1. One-line definition (the handshake)

**PlatformKit is an open-source Go backend for multi-tenant SaaS. Clone it, run
`go run .`, and you get a seeded multi-tenant app — tenants, users, auth, an
admin UI, audit, API keys, content, and notifications — composed from nine
modules. Pure Go: no CGO, no npm, no Docker, no external database.**

It is the part of a SaaS backend you would otherwise rebuild from scratch in
every project.

---

## 2. The wedge — the backend, not a demo of one

Most SaaS starters hand you a CRUD demo. You spend the next month deleting their
opinions and bolting on the things every product actually needs — tenant
isolation, a login flow, an audit trail, an admin screen — and you wire all of it
by hand, again.

PlatformKit is the backend itself, not a demo of one. It ships nine modules that
compose into a running multi-tenant app on the first `go run .`: tenant, user,
auth, api_key, audit, content, notification, health, and admin. That is the
verified hero path — a fresh clone boots, seeds a tenant and an admin user, and
serves the admin UI at `http://localhost:8080/admin` in about two seconds on a
warm cache (about seventeen on the first cold build, while Go downloads modules).

Modules never import each other's implementations. They depend only on
interfaces — ports like `AdminRegistrar` and `HealthRegistrar`, or a provider's
published contract such as `audit.AuditEmitter` — and dependency injection
supplies the concrete type at startup. So you can replace one module's
implementation without the change cascading through the others, and you can add
your own module the same way the nine built-ins are added.

Multi-tenancy is there from the first line, not retrofitted. Tenant identity is a
first-class part of the data layer and the auth flow: the seeded login is scoped
to a tenant, and the tenant store is what the admin UI reads. You do not opt into
tenancy later; it is built in, not bolted on.

---

## 3. Honest open-core

PlatformKit is **Apache-2.0**. The thing you clone and run is the whole thing,
not a trial slice.

**What's free (the whole substrate):** all the public contracts and ports, the
default providers that make it run with zero setup (SQLite, in-memory, stdlib,
file-based), the security baseline (CSRF, CORS, security headers, password
hashing, signed cookies, rate-limiting and signature-verification primitives),
the reference admin UI, the starter app, the `pk` CLI, and the nine-module
essentials pack. That is enough to build and run a multi-tenant SaaS backend on
your own infrastructure.

**What Pro adds:** hosted and cloud-scale providers — NATS/JetStream/Kafka event
buses, Postgres-cluster and read-replica database backends, cloud secrets
managers — plus enterprise identity (SCIM, SAML, enterprise SSO), vertical
business modules, hosted observability backends, and a hosted control plane.
Pro is where the operational and at-scale concerns live.

**The commitment:** the boundary is drawn at the *provider*, never at the
*contract*. Every public interface a module exposes stays in OSS. Pro plugs new
implementations in behind those same interfaces — a Postgres store behind the
store port, an enterprise SSO provider behind the auth port. Nothing in Pro
requires re-typing your code against a closed API. The contracts you build
against today do not move out of open source.

---

## 4. AI-introspectable, de-hyped

PlatformKit exposes its own structure as data, so an AI agent can read it instead
of guessing. `pk explain modules --json` prints the module catalog — id, name,
description, version — sourced directly from each module's public constants, so it
stays in sync with the code. Every module carries a typed `module.Metadata`
descriptor, and the scaffolding generator emits MCP descriptor hooks
(`MCPToolName`, `MCPDescription`, `MCPSemanticTags`) on new entities, so code an
agent generates is already self-describing. You can see all of this in
`pk-tools/cmd/pk/explain.go` and the module packages under `pk-modules/pkg/`.
This is a convenience, not the headline: it means an agent can list what exists
and extend it through the same ports a human would, with less reverse-engineering.

---

## 5. What this is NOT (the anti-flame list)

Read this before you file an issue saying we oversold it. We agree with you in
advance.

- **Not a no-code tool.** It is a Go codebase. You write Go to extend it.
- **Not a Rails or Django replacement.** It is a backend substrate for
  multi-tenant SaaS, not a full-stack web framework with an ORM, a router opinion,
  and a generator for everything. If you want batteries-included web MVC, this is
  not that.
- **Not production-hardened at scale on the default store.** SQLite is the
  zero-setup local default so the first run needs no database. It is great for
  development and small deployments. For production at scale, swap in your own
  store behind the store port — that is exactly what the port boundary is for.
- **Not a framework you must adopt wholesale.** Modules compose; you can take the
  ones you want and ignore the rest, or add your own alongside them.
- **Early. v0.0.0.** This is a first public cut. Verified on Linux/x86_64, Go
  1.26, `modernc.org/sqlite v1.50.1`, fresh database. Things will move. Pin a
  commit if you need stability today.

---

### Scope note for downstream copy

Anything stated here is backed by the verified run log (`launch/VERIFIED_RUN.md`)
or by code in the OSS workspace. Two things on purpose left out, because they are
platform/Pro features and do not run in the OSS slice today: a REST
`/api/_platform` introspection API, and a running 55-tool MCP server. Do not
claim either for the OSS launch. The honest AI-introspection story is §4 above —
`pk explain --json`, typed module metadata, and MCP descriptor hooks on entities.

One scoping note on "no Docker": that describes the **starter app's runtime** —
`go run .` needs nothing but Go. The `pk scaffold` generator does emit a
`docker-compose.yml` (Postgres/Redis/NATS) for projects that want those backends,
so don't phrase "no Docker" near scaffolding copy in a way a reader could call a
contradiction. The starter runs on SQLite with zero containers; that is the claim.
