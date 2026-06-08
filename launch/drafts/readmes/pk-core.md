# pk-core
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The kernel. It defines the shared semantics every PlatformKit module, app, and distribution builds on: the module/catalog composition system, registry, entity descriptors, provider-neutral authorization and observability, an event model, governed mutation boundaries, and a reusable security baseline (CSRF, CORS, security headers, password hashing, signed cookies, rate-limiting, signature verification). It is a contract layer, not a feature catalog — modules cooperate through declared ports without importing each other.

**How to use it.** Build a catalog from composable modules, or reach for a single primitive.

```go
import (
    "github.com/septagon-oss/pk-core/pkg/module"
    "github.com/septagon-oss/pk-core/pkg/security/passhash"
)

catalog := module.NewCatalog().Add(/* a module.Bundle */).MustBuild()

hasher, _ := passhash.NewBcrypt(12)
```

**Depends on.** Nothing else in PlatformKit. With `pk-shared`, it sits at the bottom of the dependency graph; its only external requirement is `golang.org/x/crypto`.

**Packages.**

| Package | Purpose |
|---|---|
| `pkg/module` | Module contract, catalog, composition, bundles |
| `pkg/registry` | Module/catalog registries |
| `pkg/entity` | Entity descriptors and metadata |
| `pkg/authz` | Provider-neutral authorization contracts |
| `pkg/event` | Event model |
| `pkg/mutation` | Governed mutation boundaries |
| `pkg/observability` | Tracing/observability contracts |
| `pkg/resilience` | Resilience primitives |
| `pkg/security` | CSRF, CORS, headers, passhash, cookies, ratelimit, signature, authn/authz, identity |
| `pkg/infrastructure` | Shared infrastructure contracts |
| `pkg/architecture` | Architecture/layering contracts |

License: Apache-2.0.
