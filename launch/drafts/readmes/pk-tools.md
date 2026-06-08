# pk-tools
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The `pk` developer CLI plus the shared CLI/TUI primitives it is built from. `pk` helps you check your environment, run tests, and inspect the OSS module catalog. It is a dev-workflow tool — it is not how you run the app (for that, see the starter app in the front-door repo).

**How to use it.** From inside the workspace:

```bash
go run ./cmd/pk doctor              # verify your Go environment
go run ./cmd/pk verify              # run the test suite
go run ./cmd/pk explain modules      # list the 9-module OSS pack
go run ./cmd/pk explain modules --json
```

Those three subcommands — `doctor`, `verify`, `explain` — are the whole surface today. (A scaffold generator lives in `pkg/scaffold` as a library; it is not yet a `pk` subcommand.)

**Depends on.** `pk-core` and `pk-modules` (and, transitively, `pk-shared`). `explain` imports each module package directly so the catalog it prints is sourced from the modules' own constants.

**Packages.**

| Package | Purpose |
|---|---|
| `cmd/pk` | The `pk` binary: `doctor`, `verify`, `explain` |
| `pkg/cliapp` | Root-command assembly, JSON output, command visibility |
| `pkg/tui` | Terminal-aware status and table rendering |
| `pkg/scaffold` | Module/entity scaffolding helpers (library) |

License: Apache-2.0.
