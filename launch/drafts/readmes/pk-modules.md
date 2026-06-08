# pk-modules
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The reference module pack — nine small, self-contained business modules that compose into the running starter app. Each one demonstrates the public module contract end to end: an entity, a `store.Store` persistence port with a SQLite reference implementation, a service, and an HTTP handler. They communicate only through ports, never by importing each other, so your own modules can follow the same pattern.

**How to use it.** For a first taste, compose the minimal demo bundle; for the real thing, run the starter app, which wires all nine modules.

```go
import (
    "github.com/septagon-oss/pk-core/pkg/module"
    "github.com/septagon-oss/pk-modules/pkg/coremodules"
)

// coremodules.Bundle() is a minimal 3-module demo bundle (tenant, audit,
// content) — the smallest thing that composes. It is what examples/minimal runs.
catalog := module.NewCatalog().Add(coremodules.Bundle()).MustBuild()
```

The full nine-module composition is **not** `coremodules.Bundle()`. Each real
module is constructed via its own `NewModule(...)` and wired together by the
starter app (`pk-apps/apps/starter-saas`). To see all nine running, clone the
workspace and from `pk-apps/apps/starter-saas/` run `go run .`.

**Depends on.** `pk-core` (and, transitively, `pk-shared`). It does not depend on `pk-runtime` — an app supplies the host.

**Packages.** The nine modules under `pkg/` (plus `coremodules`, the bundle that wires them, and `portslib`, the shared module-to-module ports):

| Module | Purpose |
|---|---|
| `pkg/tenant` | Tenants — the multi-tenancy root |
| `pkg/user` | Users |
| `pkg/auth` | Authentication / sessions |
| `pkg/apikey` | API keys |
| `pkg/audit` | Audit trail |
| `pkg/content` | Content entities |
| `pkg/notification` | Notifications |
| `pkg/health` | Per-module health checks |
| `pkg/admin` | Admin UI shell and entity registration |

License: Apache-2.0.
