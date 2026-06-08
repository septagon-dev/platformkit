# pk-design
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** Provider-neutral design contracts: DTCG-native token sets, theme overlays, component descriptors, and contribution catalogs. It is intentionally small and defines the stable design primitives that modules, apps, and renderers extend — without importing a frontend runtime or any private product package.

**How to use it.** Build a token `Set` and render it to CSS variables.

```go
import "github.com/septagon-oss/pk-design/pkg/tokens"

css, err := tokens.CSSVars(set) // set is a tokens.Set
```

**Depends on.** Nothing else in PlatformKit. It is a standalone contracts repo.

**Packages.**

| Package | Purpose |
|---|---|
| `pkg/tokens` | DTCG-native design token model and CSS rendering |
| `pkg/themes` | Theme overlays |
| `pkg/components` | Component descriptors |
| `pkg/catalog` | Contribution catalogs |
| `pkg/architecture` | Design-layer contracts |

License: Apache-2.0.
