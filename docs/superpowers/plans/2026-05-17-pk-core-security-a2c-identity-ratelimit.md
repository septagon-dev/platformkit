# pk-core/pkg/security Phase A.2c — Identity + Ratelimit

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Land two request-scoped state primitive blocks: `identity` (the Principal context plumbing every authentication module uses) and `ratelimit` (token-bucket primitive + HTTP middleware). Both must be Composable + Chainable per `pk-core/docs/COMPOSABILITY.md` and `pk-core/docs/BLOCKS_AND_CHAINS.md`. Stdlib only.

**Architecture:** `identity` is a tiny primitive — a `Principal` struct + context plumbing + an `IdentityResolver` interface so middleware/modules can plug in cookie-based, token-based, OAuth, SAML, or SCIM resolvers without touching core. `ratelimit` is a small token bucket + HTTP middleware that integrates with anything implementing the `Limiter` interface (Redis, distributed, etc., as downstream).

**Source reference (read-only — for behavior only; OSS rewrites smaller and cleaner):**
- `platformkit-backend-kit/security/identity/*` (large, 23 files) — extract ONLY the Principal/context bits; drop SCIM/SAML/OAuth/directory/connection
- `platformkit-backend-kit/security/ratelimit/{middleware,middleware_test}.go` — rewrite without `resilience.RateLimiter` dep

---

## Block 1: `identity`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/identity` |
| Boundary | `Principal` fields exported (value type); context key private |
| Contract | `Principal` struct, `ContextWithPrincipal/PrincipalFromContext`, `IdentityResolver` interface |
| Composition | Multiple resolvers can chain (try cookie → fallback to bearer token → fallback to anonymous) via composition function |
| Replacement | Any `IdentityResolver` impl swaps in |
| Extension | Pro adds OAuth/SAML/SCIM/JWT/Magic-link resolvers as separate types implementing `IdentityResolver` |
| Runtime binding | App composition: middleware accepts a resolver; downstream modules read principal from context |
| Evidence | Tests for context round-trip, nil/anonymous fallback, resolver chain |

### Chainable scorecard (for `MiddlewareWithResolver`)
| Law | Realization |
|---|---|
| Identity | Resolver returning anonymous principal is a no-op composition element |
| Type compatibility | Standard `func(http.Handler) http.Handler` |
| Context preservation | `Principal` attached to `r.Context()`; downstream handlers read it |
| Error algebra | Resolver errors short-circuit with 401; other errors flow through |
| Cancellation safety | Resolver respects `r.Context().Done()` |
| Evidence | Test asserts principal is retrievable by downstream handler |

### Public API

```go
package identity

// Principal identifies the authenticated subject for a request. The zero
// value represents an anonymous (unauthenticated) caller.
type Principal struct {
    Subject    string   // stable subject ID (user ID, service ID, etc.); "" for anonymous
    TenantID   string   // tenant context, "" for cross-tenant or anonymous requests
    Scopes     []string // OAuth-style scope strings; nil for anonymous
    AuthMethod string   // "cookie"|"bearer"|"api_key"|"oauth"|"saml"|"anonymous" etc.
}

// IsAnonymous reports whether the principal represents an unauthenticated
// caller (Subject == "").
func (p Principal) IsAnonymous() bool { return p.Subject == "" }

// HasScope reports whether the principal carries the named scope.
func (p Principal) HasScope(scope string) bool

// ContextWithPrincipal returns ctx with p attached. Used by resolvers and
// rarely by callers directly.
func ContextWithPrincipal(ctx context.Context, p Principal) context.Context

// PrincipalFromContext returns the Principal attached to ctx, or the zero
// (anonymous) Principal if none. Never returns the zero value's "absent"
// state separately — anonymous is a first-class state.
func PrincipalFromContext(ctx context.Context) Principal

// IdentityResolver determines the principal for a request. Implementations
// inspect cookies, headers, tokens, etc. Returning an anonymous principal
// (Principal{}) with nil error means "no credentials presented" — the
// request continues unauthenticated. Returning a non-nil error means
// "credentials presented but invalid" — the middleware writes 401.
type IdentityResolver interface {
    Resolve(r *http.Request) (Principal, error)
}

// ResolverFunc adapts an ordinary function to the IdentityResolver interface.
type ResolverFunc func(r *http.Request) (Principal, error)

func (f ResolverFunc) Resolve(r *http.Request) (Principal, error) { return f(r) }

// Chain composes multiple IdentityResolvers. The chain returns the first
// non-anonymous Principal from any resolver. If all resolvers return
// anonymous, the chain returns anonymous + nil. Any resolver returning an
// error short-circuits the chain with that error.
func Chain(resolvers ...IdentityResolver) IdentityResolver

// Middleware returns HTTP middleware that runs resolver against each request
// and attaches the resulting Principal to the request context.
// On error from resolver, the middleware writes 401 Unauthorized and returns
// without calling next.
func Middleware(resolver IdentityResolver) func(http.Handler) http.Handler
```

### Tests
- `TestPrincipalIsAnonymousByDefault`
- `TestPrincipalIsAnonymousReturnsFalseWhenSubjectSet`
- `TestPrincipalHasScopeFindsScope`
- `TestPrincipalHasScopeReturnsFalseForMissing`
- `TestContextWithPrincipalRoundTrip`
- `TestPrincipalFromContextReturnsAnonymousByDefault`
- `TestResolverFuncSatisfiesInterface`
- `TestChainReturnsFirstNonAnonymous`
- `TestChainReturnsAnonymousIfAllAnonymous`
- `TestChainShortCircuitsOnError`
- `TestMiddlewareAttachesPrincipal`
- `TestMiddlewareWrites401OnResolverError`
- `TestMiddlewareAllowsAnonymousThrough`

### Implementation files
```
pk-core/pkg/security/identity/
├── doc.go
├── identity.go              # Principal, context plumbing, Resolver interface, ResolverFunc
├── chain.go                 # Chain helper
├── middleware.go            # HTTP middleware
└── identity_test.go         # all tests (external package)
```

### Commit
`feat(pk-core/security/identity): Principal context + IdentityResolver chain + middleware`

---

## Block 2: `ratelimit`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/ratelimit` |
| Boundary | Token bucket state private; key extraction logic private; only `Limiter` interface + `TokenBucket` constructor + `Middleware` factory exposed |
| Contract | `Limiter` interface (Allow), `TokenBucket` default impl, `Config` for middleware, `Middleware()` factory |
| Composition | Multiple Limiters in different paths (login vs. API vs. expensive endpoints); skip func for whitelisted clients |
| Replacement | Any `Limiter` implementation swaps in (Redis-backed, distributed, in-memory, etc.) |
| Extension | Pro adds `RedisLimiter`, `LeakyBucketLimiter`, distributed limiters via the same interface |
| Runtime binding | App composition: middleware created with a Limiter implementation; multiple middlewares for different rate classes |
| Evidence | Tests for token consumption, refill, key extraction, skip func, distinct keys |

### Chainable scorecard
Standard middleware chain semantics. Errors flow as 429 responses. Context propagated.

### Public API

```go
package ratelimit

// Limiter is the provider-neutral rate-limit contract.
type Limiter interface {
    // Allow checks whether one request for key may proceed now. Returns
    // (true, 0) if allowed; (false, retryAfter) if rate-limited. Implementations
    // must be safe for concurrent use.
    Allow(key string) (allowed bool, retryAfter time.Duration)
}

// LimiterFunc adapts an ordinary function to Limiter.
type LimiterFunc func(key string) (bool, time.Duration)

func (f LimiterFunc) Allow(key string) (bool, time.Duration) { return f(key) }

// TokenBucket is an in-memory token-bucket Limiter. Each key gets its own
// bucket holding up to Burst tokens, refilling at Rate tokens per second.
// Buckets are reaped from memory after IdleTTL of inactivity to bound memory.
type TokenBucket struct { /* private */ }

// TokenBucketConfig configures a TokenBucket.
type TokenBucketConfig struct {
    // Rate is tokens added per second. Must be > 0.
    Rate float64
    // Burst is the maximum bucket capacity (and the initial token count). Must be > 0.
    Burst int
    // IdleTTL controls how long an inactive bucket stays in memory.
    // Default 10 minutes if zero. Setting <= 0 disables reaping.
    IdleTTL time.Duration
}

// NewTokenBucket constructs an in-memory token-bucket Limiter.
func NewTokenBucket(cfg TokenBucketConfig) (*TokenBucket, error)

// Allow satisfies Limiter.
func (b *TokenBucket) Allow(key string) (bool, time.Duration)

// Config configures the HTTP rate-limit middleware.
type Config struct {
    // KeyFunc extracts the rate-limit key from a request.
    // Default: ClientIPKey.
    KeyFunc func(r *http.Request) string
    // SkipFunc, if non-nil, returns true to bypass the limiter for this request.
    SkipFunc func(r *http.Request) bool
    // OnLimited, if non-nil, is invoked when a request is rate-limited (after
    // the response is written). Useful for logging/metrics.
    OnLimited func(r *http.Request, retryAfter time.Duration)
}

// Middleware returns rate-limit middleware backed by limiter.
// Limited requests get HTTP 429 + Retry-After header.
func Middleware(limiter Limiter, cfg Config) func(http.Handler) http.Handler

// ClientIPKey extracts the client IP from a request, preferring
// X-Forwarded-For (first hop) then X-Real-IP then r.RemoteAddr.
// Returns "" if no IP can be determined.
func ClientIPKey(r *http.Request) string
```

### Tests
- `TestNewTokenBucketRejectsZeroRate`
- `TestNewTokenBucketRejectsZeroBurst`
- `TestTokenBucketAllowsBurstThenLimits` — N requests allowed in quick succession (= burst); next is denied
- `TestTokenBucketRefillsOverTime`
- `TestTokenBucketIsolatesKeys` — two keys get independent buckets
- `TestTokenBucketReportsRetryAfter`
- `TestTokenBucketConcurrentSafe` — `-race`
- `TestClientIPKeyPrefersXForwardedFor`
- `TestClientIPKeyFallsBackToXRealIP`
- `TestClientIPKeyFallsBackToRemoteAddr`
- `TestClientIPKeyHandlesIPv6`
- `TestMiddlewareAllowsUnderLimit`
- `TestMiddlewareReturns429AndRetryAfterOverLimit`
- `TestMiddlewareSkipFuncBypassesLimiter`
- `TestMiddlewareOnLimitedCallbackFires`
- `TestMiddlewareDefaultKeyFuncIsClientIP`
- `TestLimiterFuncSatisfiesInterface`

### Implementation files
```
pk-core/pkg/security/ratelimit/
├── doc.go
├── ratelimit.go             # Limiter interface, LimiterFunc, ClientIPKey
├── tokenbucket.go           # TokenBucket implementation
├── middleware.go            # HTTP middleware
└── ratelimit_test.go        # all tests (external package)
```

### Commit
`feat(pk-core/security/ratelimit): token-bucket Limiter + HTTP middleware`

---

## Workspace updates (in the LAST of the two commits — ratelimit)

Update `pkg/architecture/oss_deps_test.go` to append:
```go
"github.com/septagon-oss/pk-core/pkg/security/identity",
"github.com/septagon-oss/pk-core/pkg/security/ratelimit",
```

## Acceptance criteria

- `make verify` green (includes race coverage on security from A.2a fix)
- 2 new sub-packages: `identity`, `ratelimit`
- Each has C-14/ADR-0029 headers, external test packages, doc.go
- Zero new external deps (stdlib only)
- `TestPkCoreImportsAreAllowed` and `TestNoSeptagonDevImports` pass
- 3 workspace OSS validators green
- ≥30 tests total across the two packages
- Each block satisfies the Composable scorecard
- The `identity.Middleware` chain works end-to-end (cookie-resolver test demonstrates real usage)
- The `ratelimit.Middleware` chain works end-to-end (under-limit + over-limit tests)

## Cross-block composition opportunity (proof point)

Add ONE integration test in `identity_test.go` that constructs a cookie-based resolver using `pk-core/pkg/security/cookies.Build` and `r.Cookie(cookies.Name(KindSession))`, demonstrating cross-block use. This proves identity composes with cookies the same way csrf does.
