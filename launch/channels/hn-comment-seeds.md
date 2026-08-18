# HN Comment Seeds

> **⚠️ WARNING — this file must NOT exist in any publicly readable repo at
> announcement time.** These are the author's prepared answers, and a fetchable
> "comment seeds" file reads as astroturfing even though it isn't. The
> `septagon-dev/platformkit` repo that contains this file is **currently
> public**, so this file is fetchable today. Before posting anywhere, the owner
> must either make that repo private or purge this file (including from git
> history) from everything publicly readable. Do not launch until resolved.

Pre-written, honest, non-defensive replies to the ten hardest questions. Post these as replies when the matching question shows up — don't paste them all at once. Each is ≤5 sentences with a proof link or path. The canonical polished form lives in `launch/drafts/docs/faq.md`.

---

### 1. Why not just use Supabase / Encore?

Supabase is a hosted Postgres + auth + storage product; Encore is a Go framework with its own cloud and infra provisioning. PlatformKit is narrower and more local: it's the multi-tenant SaaS substrate (tenants, users, auth, audit, admin) as composable Go modules you run with one command (`go run github.com/septagon-oss/platformkit@latest`), no account, no cloud, no Docker. If you want a managed backend-as-a-service or opinionated infra provisioning, those fit better. If you want the tenant/auth/admin layer as code you own, on your own infra, that's this. (See `What this is NOT` in the README.)

### 2. Why not just plain net/http + sqlc, or Buffalo?

You absolutely can, and for a single-tenant CRUD app you probably should. What you end up rebuilding by hand each time is the substrate: tenant isolation in the data layer, a login flow, an audit trail, an admin screen, and the wiring between them. PlatformKit is that substrate already composed, with a port boundary so you can swap any piece. It's not a web MVC framework like Buffalo — no router opinion, no asset pipeline, no generators-for-everything.

### 3. Is this an open-core rug-pull waiting to happen?

Fair question to ask up front. The commitment is explicit: the boundary is drawn at the *provider*, never at the *contract* — every public interface a module exposes stays in OSS (Apache-2.0), and Pro only plugs new implementations in behind those same interfaces. So a Postgres-cluster store or enterprise SSO is a Pro provider behind the store/auth ports you already build against; nothing you write today gets re-typed against a closed API. See the open-core section of the README and `docs/open-core.md`.

### 4. SQLite in production? Really?

No — SQLite is the zero-setup *local default* so the first run needs no database, and it's genuinely fine for development and small deployments. Postgres has been a supported driver since v0.13.0, and beyond that you swap your own store in behind the relevant module store interfaces (auth uses `WithSessionStore`); that's exactly what the port boundary is for. We say this plainly in the `What this is NOT` list rather than hiding it. (Pro adds Postgres-cluster/read-replica providers, but the interfaces are OSS and you can write your own.)

### 5. Why dependency injection? That's a lot of magic for Go.

It's there so modules can depend on interfaces (ports) and have the concrete type supplied at startup, instead of importing each other. That's what lets you replace one module's implementation without the change cascading, and add your own module the same way the ten built-ins are added. It's a real tradeoff — DI adds indirection, and if you dislike that this won't convert you — but it's what makes the compose-and-swap story work rather than just being a slogan. You can read the wiring in `pk-apps/pkg/starterapp/app.go`.

### 6. What's actually in Pro, concretely?

Hosted and cloud-scale providers: NATS/JetStream/Kafka event buses, Postgres-cluster and read-replica backends, cloud secrets managers; plus enterprise identity (SCIM, SAML, SSO), vertical business modules, hosted observability, and a hosted control plane. All of it plugs in behind interfaces that live in OSS. Pro is where the operational and at-scale concerns are — not where the contracts are.

### 7. What's the license, really?

Apache-2.0 for everything you clone and run: the contracts and ports, the default providers (SQLite, in-memory, stdlib, file-based), the security baseline, the reference admin UI, the starter app, the `pk` CLI, and the ten-module essentials pack. That's enough to build and run a multi-tenant SaaS backend on your own infrastructure with no further purchase. The license file is in the repo.

### 8. How mature is this? It's at v0.15 with no stars.

It's early and we're saying so — the code has been public since 2026-07-22 and iterated to v0.15 across 20-plus releases before we announced anything, which is why the version is ahead of the visibility. Expect APIs to move; pin a version if you need stability today (verified on Linux/x86_64, Go 1.26, `modernc.org/sqlite v1.54.0`, fresh database). Known limits right now: rate limiting and login lockout are in-memory and per-process, access control is coarse role-based, and the audit log is unsigned. The hero path (`go run github.com/septagon-oss/platformkit@latest` → seeded, auth-gated admin + healthy data layer) is the thing we verify; we're not going to pretend the surrounding surface is battle-tested. Tell us where it breaks.

### 9. Who's behind it, and do you actually use it?

Septagon — we build PlatformKit and use it ourselves to ship multi-tenant products, which is why the substrate looks the way it does (the stuff we got tired of rebuilding). The OSS substrate is the same one our own work composes from; Pro is the hosted/at-scale layer on top. We're posting as a plain technical peer, not a marketing account, and we'll answer hard questions in this thread directly.

### 10. Nine CRUD modules isn't a "platform."

Agreed that nine CRUD modules wouldn't be — the claim isn't the count, it's the composition. Modules import *interfaces*, not each other's implementations (ports like `AdminRegistrar`, or a provider's published contract), and DI supplies the concrete type at startup, so you can swap or add modules without edits cascading. The substrate is the tenant/auth/audit/admin boundary plus that compose-and-swap mechanism, not the ten bundled examples. We just proved it on ourselves: the tenth module (tenant branding) landed this week through the same ports the other nine use. If the boundary doesn't hold when you add your own, that's the feedback we most want.

### 11. Is the admin UI a real login? (likely follow-up)

Yes. `/admin` is auth-gated: anonymous requests get redirected (303) to `/admin/login`, and the console requires the `admin` role plus the `console:access` scope. The seeded development login `operator@local.test` / `local-development-only` (tenant `tenant_local`) satisfies both; the same credentials work against the auth API (`POST /api/v1/auth/sessions`), which is multi-tenant — the request body must include `tenant_id` or you'll get a 400. The seeded password is development-mode only; production makes you set your own.
