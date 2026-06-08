# pk-runtime
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The host layer. `pk-core` defines module contracts; `pk-runtime` hosts them. It turns a built catalog into a running HTTP host with route registration, readiness/liveness, request context, health, and fail-closed authorization gates — all as public contracts. Databases, queues, cloud SDKs, DI containers, and product workflows stay outside the runtime core.

**How to use it.** Build a catalog, then hand it to a host.

```go
import (
    "github.com/septagon-oss/pk-core/pkg/module"
    "github.com/septagon-oss/pk-runtime/pkg/host"
)

catalog := module.NewCatalog().Add(/* modules */).MustBuild()
h, err := host.New(ctx, host.Input{
    Config:  host.Config{Name: "my-app", Version: "0.1.0"},
    Catalog: catalog,
})
// h is an http.Handler.
```

**Depends on.** `pk-core` (and, transitively, `pk-shared`). Nothing else in PlatformKit.

**Packages.**

| Package | Purpose |
|---|---|
| `pkg/host` | Compose a catalog into a running HTTP host |
| `pkg/httpx` | Route types and guarded HTTP wiring |
| `pkg/request` | Request context |
| `pkg/health` | Health/readiness registry |

License: Apache-2.0.
