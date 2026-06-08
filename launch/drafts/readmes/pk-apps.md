# pk-apps
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** Runnable example compositions. Apps are where modules become a product: they pick a module set, provider options, and a runtime host without changing the modules underneath. The flagship is `apps/starter-saas` — the "clone and `go run .`" demo that composes all nine OSS modules over one SQLite database and serves them through a single HTTP listener. Two smaller demos live under `examples/`.

**How to use it.** The canonical one-command run lives at the front door — see **[PlatformKit](https://github.com/septagon-oss/platformkit)** for the verified quickstart. In short:

```bash
cd apps/starter-saas
go run .
# serves http://localhost:8080  (admin UI at /admin, health at /healthz)
```

First build downloads modules and takes ~15-20 s; subsequent starts ~2 s. No CGO, no npm, no Docker, no external database.

**Depends on.** `pk-core`, `pk-modules`, `pk-runtime`, `pk-shared`, and `pk-testkit`. It sits at the top of the graph and pulls the family together.

**Apps and examples.**

| Path | Purpose |
|---|---|
| `apps/starter-saas` | Hero app: all nine modules, SQLite, one listener |
| `apps/platformkit-page` | Static landing/page example |
| `examples/minimal` | Smallest catalog composition |
| `examples/runtime` | Composing a bundle into a `pk-runtime` host |

License: Apache-2.0.
