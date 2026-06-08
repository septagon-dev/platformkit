# pk-shared
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The smallest repo in the family: the cross-repo vocabulary that has no single natural owner — application composition descriptors, stable identifiers, neutral flow definitions, and a portable state-machine model. If a contract has a real home, it lives there instead; only the genuinely shared types land here.

**How to use it.** Import the package you need and build against the type.

```go
import "github.com/septagon-oss/pk-shared/pkg/contract"
```

**Depends on.** Nothing else in PlatformKit. It is a leaf of the dependency graph, so anything in the family can depend on it without creating a cycle.

**Packages.**

| Package | Purpose |
|---|---|
| `pkg/composition` | Application composition descriptors |
| `pkg/contract` | Stable shared identifiers and contract types |
| `pkg/flowdef` | Provider-neutral flow definitions |

License: Apache-2.0.
