# pk-core/pkg/infrastructure Implementation Plan (Phase A.6)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Land minimal infrastructure provider contracts in `pk-core/pkg/infrastructure/`. Four primitive blocks: `cache`, `database`, `router`, `config`. The Logger contract already lives in `pk-core/pkg/observability/logger` and is not re-extracted here.

**Architecture:** Each block exposes an interface + stdlib default + extension hook for Pro adapters (Redis/Postgres/chi/etc.). The blocks compose into an `InfrastructureProvider` struct that a starter app can pass to `module.NewApp(...)`.

**Stdlib only.** NO new external deps.

**Source reference:** `platformkit-backend-kit/infrastructure/config` — but extract only the minimal provider-neutral contracts. Drop FX-specific code, openfeature, generic config builder, env validation (those go in Pro or starter-saas).

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`.

---

## Block 1: `pk-core/pkg/infrastructure/cache`

### Public API

```go
package cache

// Cache is the provider-neutral key-value cache contract.
type Cache interface {
    Get(ctx context.Context, key string) (value []byte, ok bool, err error)
    Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
    Delete(ctx context.Context, key string) error
}

// NewMemory returns an in-process Cache backed by sync.Map with per-entry
// TTL. Expired entries are reaped lazily on Get + by a background sweep.
func NewMemory(opts ...MemoryOption) Cache

type MemoryOption func(*memoryConfig)
func WithMaxEntries(n int) MemoryOption       // bounded LRU (default 10000)
func WithSweepInterval(d time.Duration) MemoryOption  // default 1 min
```

Tests: round-trip, TTL expiration, Delete, max-entries eviction, concurrent access (-race).

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/infrastructure/cache` |
| Contract | `Cache` interface (3 methods) |
| Replacement | Any Cache impl swaps in (Redis, Memcached) |
| Extension | Pro provides RedisCache, RistrettoCache via the same interface |
| Runtime binding | App composition: `app.WithCache(redis.New(addr))` |
| Evidence | Tests + doc.go |

---

## Block 2: `pk-core/pkg/infrastructure/database`

### Public API

```go
package database

// Database wraps *sql.DB with a Driver-agnostic boundary so OSS callers can
// keep the same construction pattern across sqlite/postgres/mysql.
type Database interface {
    DB() *sql.DB
    Ping(ctx context.Context) error
    Close() error
}

// Open returns a Database backed by sql.Open(driverName, dsn). The driver must
// be imported separately by the caller (e.g., _ "modernc.org/sqlite").
func Open(driverName, dsn string, opts ...Option) (Database, error)

type Option func(*config)
func WithMaxOpenConns(n int) Option
func WithMaxIdleConns(n int) Option
func WithConnMaxLifetime(d time.Duration) Option
```

Tests use `database/sql` mock driver or skip with comment (no driver dep).

---

## Block 3: `pk-core/pkg/infrastructure/router`

### Public API

```go
package router

// Router is the provider-neutral HTTP router contract. The OSS default is
// stdlib net/http.ServeMux; Pro adapters can plug chi, gorilla/mux, gin, etc.
type Router interface {
    http.Handler
    Method(method, pattern string, handler http.HandlerFunc)
    Use(middlewares ...func(http.Handler) http.Handler)
}

// NewServeMux returns a Router backed by stdlib http.ServeMux (Go 1.22+ pattern syntax).
func NewServeMux() Router
```

Tests: GET/POST/PUT/DELETE routing, middleware chaining, method-mismatched 405 response.

---

## Block 4: `pk-core/pkg/infrastructure/config`

### Public API

```go
package config

// Config is the canonical OSS app config. Fields cover the four infrastructure
// primitives + lifecycle hints. Callers can extend by embedding Config in
// their own app config struct.
type Config struct {
    AppName     string
    AppVersion  string
    Environment string  // "development" | "staging" | "production"

    HTTP struct {
        Addr            string        // ":8080"
        ReadTimeout     time.Duration
        WriteTimeout    time.Duration
        ShutdownTimeout time.Duration
    }

    Database struct {
        Driver string  // "sqlite", "postgres", etc.
        DSN    string
    }

    Cache struct {
        Provider string  // "memory", "redis"
        Addr     string  // for redis
    }
}

// DefaultConfig returns a Config with sane defaults (sqlite in-memory + memory cache + :8080).
func DefaultConfig() Config

// LoadFromYAML reads a YAML file into a Config. The YAML loader uses encoding/json
// after a YAML→JSON transform via the included yaml-to-json conversion helper,
// avoiding a yaml.v3 dependency.
// Actually — let's keep this stdlib only. LoadFromJSON is the OSS default;
// YAML support is a Pro adapter.
func LoadFromJSON(path string) (Config, error)

// LoadFromEnv applies environment-variable overrides to cfg in place.
// Variable naming: PK_HTTP_ADDR, PK_DATABASE_DSN, etc.
func (cfg *Config) LoadFromEnv()

// Validate normalizes cfg and returns an error if any field is invalid.
func (cfg *Config) Validate() error
```

Tests: defaults, JSON load, env overrides, validation.

---

## Acceptance criteria

- `make verify` green
- 4 sub-packages: cache, database, router, config (parent infrastructure has only doc.go)
- All C-14/ADR-0029 headers
- External test packages
- Zero new external deps
- ≥25 leaf tests
- 5 commits (4 packages + 1 architecture deps fitness update)
- NO Co-Authored-By trailers

## Commits

1. `feat(pk-core/infrastructure/cache): Cache interface + in-memory default`
2. `feat(pk-core/infrastructure/database): Database wrapper around sql.DB`
3. `feat(pk-core/infrastructure/router): Router interface + ServeMux default`
4. `feat(pk-core/infrastructure/config): Config struct + JSON loader + env overrides`
5. `test(pk-core/architecture): enroll infrastructure packages in deps fitness gate`
