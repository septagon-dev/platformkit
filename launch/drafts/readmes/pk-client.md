# pk-client
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** A small, dependency-free Go client for PlatformKit-style CRUD APIs. It pairs a generic, transport-agnostic `Client[T]` with a standard-library HTTP transport, covering single-item CRUD, partial updates, bulk operations, export, and import over typed request/response envelopes. It stays transport-focused, so downstream SDKs can wrap it with auth, telemetry, or hosted defaults.

**How to use it.** Point a typed client at an HTTP endpoint and call CRUD.

```go
import client "github.com/septagon-oss/pk-client"

type Widget struct {
    ID   string `json:"id"`
    Name string `json:"name"`
}

cfg := client.NewHTTPConfig("https://api.example.com", "/widgets",
    client.WithBearerToken(token))
c, err := client.NewHTTP[Widget](cfg)
created, err := c.Create(ctx, client.CreateInput[Widget]{Body: Widget{Name: "gadget"}})
```

**Depends on.** Nothing else in PlatformKit. Standard library only.

License: Apache-2.0.
