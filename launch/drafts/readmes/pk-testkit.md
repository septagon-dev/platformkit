# pk-testkit
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** Adapter-neutral testing primitives for the family. It lets module authors and app teams prove public claims with conformance checks, run API flows, and validate requirement-to-flow coverage — without binding to a specific browser, database, or CI service. Downstream distributions adapt the same contracts to Playwright, Kubernetes, or private E2E harnesses.

**How to use it.** Assemble checks into a suite and run it.

```go
import "github.com/septagon-oss/pk-testkit/pkg/conformance"

suite, _ := conformance.NewSuite(conformance.Check{
    ID:            "runtime.ready",
    RequirementID: "REQ-READY",
    Description:   "runtime reports ready",
    Run: func(ctx context.Context) (conformance.Result, error) {
        return conformance.Pass("runtime is ready"), nil
    },
})
report := suite.Run(ctx)
// report.Status == "pass"; report.OK() == true
```

**Depends on.** `pk-shared` only. Nothing else in PlatformKit.

**Packages.**

| Package | Purpose |
|---|---|
| `pkg/conformance` | Requirement-keyed conformance suites and reports |
| `pkg/apitest` | API test helpers |
| `pkg/flowtest` | Flow-coverage validation |

License: Apache-2.0.
