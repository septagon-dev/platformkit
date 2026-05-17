# pk-core/pkg/security Phase A.2d — authn + authz + middlewarepolicy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Land the composition layer that ties A.2a-c primitives into chainable security profiles. Three blocks:

- `authn` — HTTP middlewares that REQUIRE certain principal properties (auth, scopes, tenant) on top of `pk-core/pkg/security/identity`
- `authz` — HTTP middleware that runs `pk-core/pkg/authz.Evaluator` against a request and returns 403 on denial
- `middlewarepolicy` — declarative chain composition + path-based skip helpers

**Architecture:** All three are *chainable links* in the HTTP request flow. They sit AFTER `identity.Middleware` (which attaches the Principal) and BEFORE the route handler. They satisfy the chainable laws (identity, type compatibility, context preservation, error algebra). They're composable blocks (interfaces + extension points) so Pro can add OAuth-flow-aware middlewares, ABAC engines, etc., without forking core.

**Tech stack:** stdlib only.

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`.

---

## Block 1: `security/authn`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/authn` |
| Boundary | Status codes and error response shaping are package-private; only middleware factories exported |
| Contract | `RequireAuth`, `RequireScopes`, `RequireTenant`, `RequireAllOf` (compose multiple requirements) |
| Composition | Multiple requirements chain naturally; `RequireAllOf` is a Block-level composer |
| Replacement | Standard middleware signature; any compatible middleware can replace |
| Extension | `ErrorWriter` function field on `Options` lets Pro customize 401/403 responses (JSON vs HTML, telemetry hooks) |
| Runtime binding | App composition (route-by-route or global) |
| Evidence | Tests cover all four middlewares, error customization, composition |

### Public API

```go
package authn

// Options configures how authn middlewares respond to denial. ErrorWriter, if
// non-nil, fully owns the response (status + body); the default writes plain
// "401 Unauthorized" or "403 Forbidden".
type Options struct {
    ErrorWriter func(w http.ResponseWriter, r *http.Request, status int, reason string)
}

// RequireAuth returns middleware that rejects anonymous principals with 401.
// The identity.Middleware MUST run earlier in the chain to attach the principal.
func RequireAuth(opts ...Options) func(http.Handler) http.Handler

// RequireScopes returns middleware that rejects requests whose principal does
// not carry ALL of the given scopes with 403. An anonymous principal is
// always rejected (any scope check on an anonymous principal returns false).
func RequireScopes(scopes []string, opts ...Options) func(http.Handler) http.Handler

// RequireTenant returns middleware that rejects requests whose principal
// belongs to a different tenant than tenantID with 403. Empty tenantID on the
// principal is treated as "no tenant" and rejected.
func RequireTenant(tenantID string, opts ...Options) func(http.Handler) http.Handler

// RequireAllOf composes multiple require-middlewares into one. Order matters:
// the first middleware to reject short-circuits the chain.
func RequireAllOf(mws ...func(http.Handler) http.Handler) func(http.Handler) http.Handler
```

### Tests
- `TestRequireAuthRejectsAnonymous`
- `TestRequireAuthAllowsAuthenticated`
- `TestRequireScopesRejectsMissingScope`
- `TestRequireScopesAcceptsAllScopes`
- `TestRequireScopesAnonymousRejected`
- `TestRequireTenantRejectsMismatch`
- `TestRequireTenantAcceptsMatch`
- `TestRequireTenantAnonymousRejected`
- `TestRequireAllOfRejectsAtFirstFailure`
- `TestRequireAllOfPassesWhenAllPass`
- `TestErrorWriterOptionCustomizesResponse`

Cross-block proof: at least one test uses `identity.Middleware` + `authn.RequireScopes` in a chain to demonstrate end-to-end composition.

### Files
```
pk-core/pkg/security/authn/
├── doc.go
├── authn.go           # Options, RequireAuth
├── scopes.go          # RequireScopes
├── tenant.go          # RequireTenant
├── compose.go         # RequireAllOf
└── authn_test.go      # external; covers everything
```

### Commit
`feat(pk-core/security/authn): RequireAuth/Scopes/Tenant middleware + composer`

---

## Block 2: `security/authz`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/authz` |
| Boundary | Subject/Resource construction from the request is helper-driven; package exports the middleware + a `RequestBuilder` type |
| Contract | `Middleware(evaluator authz.Evaluator, builder RequestBuilder, opts ...Options)`; `RequestBuilder` interface for translating http.Request + identity.Principal → authz.Request |
| Composition | Multiple Middlewares chain for different resources; RequestBuilder is the extension point for application-specific resource extraction |
| Replacement | Any `authz.Evaluator` impl plugs in (single-policy, aggregate, OPA-backed, etc.) |
| Extension | Pro adds ABAC builders, attribute-fetching builders, async-policy evaluators |
| Runtime binding | App composition |
| Evidence | Tests cover allow/deny outcomes, evaluator-error handling, builder errors |

### Public API

```go
package authz

import (
    "net/http"

    coreauthz "github.com/septagon-oss/pk-core/pkg/authz"
)

// Options configures the authz middleware response shape.
type Options struct {
    ErrorWriter func(w http.ResponseWriter, r *http.Request, status int, reason string)
}

// RequestBuilder translates an *http.Request into an authz.Request. It is the
// only application-aware piece of authz wiring — the policy evaluator itself
// is provider-neutral.
type RequestBuilder interface {
    Build(r *http.Request) (coreauthz.Request, error)
}

// RequestBuilderFunc adapts an ordinary function to RequestBuilder.
type RequestBuilderFunc func(r *http.Request) (coreauthz.Request, error)

func (f RequestBuilderFunc) Build(r *http.Request) (coreauthz.Request, error) { return f(r) }

// Middleware returns HTTP middleware that runs evaluator against the
// authz.Request produced by builder. Decisions:
//   - DecisionAllow → next handler runs
//   - DecisionDeny  → 403 Forbidden (ErrorWriter customizable)
//   - DecisionAbstain → 403 (treated as deny by default; Pro middlewares can wrap to change this)
// Builder errors → 400 Bad Request.
// Evaluator errors → 500 Internal Server Error.
func Middleware(evaluator coreauthz.Evaluator, builder RequestBuilder, opts ...Options) func(http.Handler) http.Handler

// PrincipalFromRequest is a convenience that maps security/identity.Principal
// into a coreauthz.Principal so RequestBuilders can compose easily.
func PrincipalFromRequest(r *http.Request) coreauthz.Principal
```

### Tests
- `TestMiddlewareAllowsOnAllow`
- `TestMiddlewareDeniesOnDeny403`
- `TestMiddlewareDeniesOnAbstain403ByDefault`
- `TestMiddleware400OnBuilderError`
- `TestMiddleware500OnEvaluatorError`
- `TestRequestBuilderFuncSatisfiesInterface`
- `TestPrincipalFromRequestMapsIdentityPrincipal`
- `TestErrorWriterOptionCustomizesResponse`

Cross-block proof: integration test uses `identity.Middleware` → `authz.Middleware` with a real `coreauthz.PolicyEvaluator`, demonstrating cross-package composition.

### Files
```
pk-core/pkg/security/authz/
├── doc.go
├── authz.go           # Options, RequestBuilder(Func), Middleware
├── principal.go       # PrincipalFromRequest helper
└── authz_test.go      # external
```

### Commit
`feat(pk-core/security/authz): HTTP authorization middleware wired to authz.Evaluator`

---

## Block 3: `security/middlewarepolicy`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/middlewarepolicy` |
| Boundary | Internal path-match helpers private |
| Contract | `Chain(...mw) func(http.Handler) http.Handler`; `SkipIf(predicate, mw)` wrapper; `PathPrefixSkip(prefixes...)` and `MethodSkip(methods...)` predicates |
| Composition | This package IS composition primitives |
| Replacement | n/a (utility) |
| Extension | Pro adds custom skip predicates |
| Runtime binding | App composition |
| Evidence | Tests cover chain ordering, skip behavior |

### Public API

```go
package middlewarepolicy

// Chain composes multiple middlewares into one. mws[0] runs outermost.
// Empty chain is identity (returns the inner handler unchanged).
func Chain(mws ...func(http.Handler) http.Handler) func(http.Handler) http.Handler

// Predicate returns true to skip the wrapped middleware for this request.
type Predicate func(r *http.Request) bool

// SkipIf wraps mw so that when predicate returns true, mw is skipped and the
// next handler is invoked directly.
func SkipIf(predicate Predicate, mw func(http.Handler) http.Handler) func(http.Handler) http.Handler

// PathPrefixSkip returns a Predicate that matches when r.URL.Path equals or
// is prefixed by any of paths (path or path/...). Useful for /health, /ready.
func PathPrefixSkip(prefixes ...string) Predicate

// MethodSkip returns a Predicate that matches when r.Method is in methods
// (case-insensitive). Useful for "skip CSRF on GET/HEAD/OPTIONS".
func MethodSkip(methods ...string) Predicate

// BearerAuthSkip returns a Predicate that matches when the Authorization
// header starts with "Bearer " (case-insensitive). Common pattern for
// browser-CSRF exemption on bearer-token API endpoints.
func BearerAuthSkip() Predicate
```

### Tests
- `TestChainAppliesMiddlewaresInOrder`
- `TestChainEmptyIsIdentity`
- `TestSkipIfSkipsWhenPredicateTrue`
- `TestSkipIfRunsMwWhenPredicateFalse`
- `TestPathPrefixSkipMatchesExact`
- `TestPathPrefixSkipMatchesPrefix`
- `TestPathPrefixSkipDoesNotMatchSuperset`
- `TestMethodSkipIsCaseInsensitive`
- `TestBearerAuthSkipDetectsBearer`
- `TestBearerAuthSkipIgnoresNonBearer`

### Files
```
pk-core/pkg/security/middlewarepolicy/
├── doc.go
├── chain.go               # Chain
├── predicates.go          # Predicate, SkipIf, PathPrefixSkip, MethodSkip, BearerAuthSkip
└── middlewarepolicy_test.go
```

### Commit
`feat(pk-core/security/middlewarepolicy): declarative middleware chain + skip predicates`

In this last commit, also update `pkg/architecture/oss_deps_test.go` to append:
```go
"github.com/septagon-oss/pk-core/pkg/security/authn",
"github.com/septagon-oss/pk-core/pkg/security/authz",
"github.com/septagon-oss/pk-core/pkg/security/middlewarepolicy",
```

---

## Acceptance criteria

- `make verify` green (fitness covers all 11 security packages with `-race`)
- 3 new sub-packages: `authn`, `authz`, `middlewarepolicy`
- Each: C-14/ADR-0029 headers, external test packages, doc.go
- Zero new external deps
- Cross-block proof: at least 2 integration tests demonstrating identity → authn → authz chain end-to-end
- ≥27 leaf tests across the 3 packages
- 3 commits with exact subjects
- All 3 OSS validators green
- Phase A.2 (security) ends with 11 sub-packages total covering the full security baseline
