# pk-core/pkg/security Phase A.2b — HTTP Security Middleware

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Land three chainable HTTP-middleware blocks in `pk-core/pkg/security/`: `headers` (HSTS, X-Frame-Options, CSP with nonce, Referrer-Policy, X-Content-Type-Options, Permissions-Policy), `cors` (origin allowlist + preflight handling), `csrf` (double-submit token via cookies). Each is a Block (Contract + Contribution + Runtime Binding + Evidence) AND a Link in the request chain (`http.Handler → http.Handler`).

**Architecture:** Each middleware is a pure `func(http.Handler) http.Handler` factory parameterized by a `Config` struct. The Composable contract is satisfied at the *factory* level — Configs are descriptors that downstream Pro can extend (via new fields with sane zero-values). The Chainable contract is satisfied at the *runtime* level — the returned `http.Handler` chains by composition (`mw1(mw2(mw3(h)))`) under Go's stdlib net/http rules: context propagates through `r.Context()`, errors flow via the response, panics in inner handlers do not leak.

**Tech Stack:** Go 1.22+, stdlib only. No external deps.

**Source reference (read-only):** `septagon-dev/platformkit-backend-kit/security/{headers,cors,csrf}/middleware*.go`.

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`.

---

## Block contracts

### Block 1: `headers`

| Composable | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/headers` |
| Boundary | CSP nonce stored in `*http.Request.Context()` only; managed header names in package-level slice |
| Contract | `Config` struct + `Middleware(...Config) func(http.Handler) http.Handler` + `NonceFromContext(ctx) string` + `ManagedResponseHeaderNames() []string` + `ClearManagedResponseHeaders(h http.Header)` |
| Contribution | Pro extends by passing additional `Config` instances (variadic merge) or by adding custom Config fields downstream |
| Composition | Multiple Configs merge (later wins for scalar fields; CSPDirectives merge by key) |
| Replacement | Any `func(http.Handler) http.Handler` chain entry can replace this |
| Extension | Pro/per-app provides custom CSP directives, sandboxes, Permissions-Policy via Config |
| Runtime binding | App composition: `mux.Use(headers.Middleware(cfg))` |
| Evidence | Tests prove each header is set correctly under various Configs |

**Chainable laws**:
- Identity: `Middleware(Config{})` is a no-op-ish (no headers added)
- Context preservation: nonce attached via `r = r.WithContext(...)`, downstream handlers see it via `NonceFromContext`
- Type compatibility: `func(http.Handler) http.Handler` → composes with any peer
- Error algebra: handler writes 500 or downstream-determined status; middleware never short-circuits
- Cancellation safety: deferred header writes happen before WriteHeader; context cancellation propagates through r.Context()

### Block 2: `cors`

| Composable | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/cors` |
| Boundary | Allowed origin list copied defensively at Middleware construction |
| Contract | `Config` struct + `Middleware(cfg Config) func(http.Handler) http.Handler` |
| Composition | Single Config per Middleware; multiple Middlewares chain naturally |
| Replacement | Standard middleware shape |
| Extension | Pro adds custom origin-matching (regex, wildcard subdomains) via OriginAllowed func field |
| Runtime binding | App composition |
| Evidence | Tests for preflight, simple requests, origin allowlisting |

**Chainable**: standard HTTP middleware contract.

### Block 3: `csrf`

| Composable | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/security/csrf` |
| Boundary | Token random source seeded at init; comparison constant-time |
| Contract | `Config` struct + `Middleware(...Config) func(http.Handler) http.Handler` + `ClearResponseCookie(h http.Header)` |
| Composition | Variadic Config merge (last wins for scalar fields; ExemptPaths concat) |
| Replacement | Standard middleware shape |
| Extension | Pro plugs a custom `TokenStore` interface (deferred to v0.0.1; v0.0.0 uses cookie-only double-submit) |
| Runtime binding | App composition; uses `pk-core/pkg/security/cookies.Write` for the CSRF cookie |
| Evidence | Tests for GET no-op, POST without token rejected, POST with valid token accepted, POST with mismatched token rejected |

**Chainable**: standard HTTP middleware contract; rejects unsafe methods that fail token check.

---

## File structure

```
pk-core/pkg/security/headers/
├── doc.go
├── headers.go                # Config, Middleware, nonce context plumbing
├── headers_test.go           # contract tests
pk-core/pkg/security/cors/
├── doc.go
├── cors.go                   # Config, Middleware
├── cors_test.go              # contract tests (NEW — source had no tests)
pk-core/pkg/security/csrf/
├── doc.go
├── csrf.go                   # Config, Middleware, double-submit logic
└── csrf_test.go              # contract tests
```

---

## Implementation directives (executor-facing)

The implementer should read the source middleware files at:
- `septagon-dev/platformkit-backend-kit/security/headers/middleware.go` (298 LOC)
- `septagon-dev/platformkit-backend-kit/security/headers/middleware_test.go` (375 LOC)
- `septagon-dev/platformkit-backend-kit/security/cors/middleware.go` (153 LOC)
- `septagon-dev/platformkit-backend-kit/security/csrf/middleware.go` (408 LOC)
- `septagon-dev/platformkit-backend-kit/security/csrf/middleware_test.go` (334 LOC)

and **adapt** them (don't copy verbatim) so the OSS version:

1. **Drops any septagon-dev imports.** Replace internal logger/identity/cookies imports with `pk-core/pkg/observability/logger.Logger` (passed via Config) and `pk-core/pkg/security/cookies.Write/Build` where applicable.

2. **Drops any framework dependency** (no huma, no chi, no gorilla). Pure `net/http`.

3. **Drops any preview/staging-specific logic.** OSS is platform-neutral.

4. **Per-package: file at `<name>.go` instead of `middleware.go`** to match the rest of pk-core's naming convention.

5. **External test packages** (`headers_test`, `cors_test`, `csrf_test`).

6. **C-14/ADR-0029 header on every .go file.**

7. **For `csrf`, ensure the cookie write uses `pk-core/pkg/security/cookies.Write(w, r, cookies.KindCSRF, token)`** — this is the chainable composition with the cookies block from A.2a.

8. **For `headers`, the CSP nonce must be a fresh value per request**, base64-encoded, attached to context via a private key, retrievable via `NonceFromContext`. Use `crypto/rand` to generate 16 bytes per request.

---

## Tests to land (minimum)

### headers
- `TestMiddlewareSetsAllDefaultHeaders` — empty Config produces sane defaults (HSTS, X-Frame-Options, Referrer-Policy, X-Content-Type-Options)
- `TestNonceIsFreshPerRequest` — two requests through the middleware get different nonces
- `TestNonceFromContextReturnsNonceInsideHandler` — downstream handler retrieves the nonce
- `TestCSPDirectivesMerge` — multiple Configs with CSPDirectives map merge correctly
- `TestPermissionsPolicyHeaderRespectsConfig` — opt-in directives appear when set
- `TestClearManagedResponseHeadersRemovesAll` — ClearManagedResponseHeaders strips only the managed set
- `TestManagedResponseHeaderNamesIsStable` — returns the same names across calls

### cors
- `TestPreflightReturns204WithAllowOrigin` — OPTIONS with valid origin gets 204 + Access-Control-Allow-Origin
- `TestSimpleRequestPassesThrough` — non-OPTIONS request reaches the inner handler
- `TestPreflightRejectsDisallowedOrigin` — OPTIONS from a non-allowed origin omits Access-Control-Allow-Origin
- `TestCredentialsHeaderOnlyWhenEnabled` — Config.AllowCredentials=true sets Access-Control-Allow-Credentials
- `TestExposeHeadersAppearsInPreflight` — Config.ExposeHeaders → Access-Control-Expose-Headers
- `TestOriginAllowedFuncOverridesList` — custom OriginAllowed func bypasses the static list

### csrf
- `TestGetIsExempt` — GET requests bypass token check
- `TestPostWithoutTokenRejected` — POST without token returns 403
- `TestPostWithValidTokenAccepted` — POST with matching cookie+header succeeds
- `TestPostWithMismatchedTokenRejected` — POST with cookie≠header returns 403
- `TestTokenRotatesAfterPost` — successful POST writes a new CSRF cookie
- `TestExemptPathBypassesCheck` — Config.ExemptPaths skip CSRF
- `TestClearResponseCookieRemovesIt` — ClearResponseCookie writes a clearing cookie
- `TestUsesCookiesKindCSRF` — verify the CSRF cookie has the KindCSRF profile (Path=/, HttpOnly=false, SameSite=Strict)

---

## Workspace updates

1. **Update `pkg/architecture/oss_deps_test.go`** to append three new packages:
   ```go
   "github.com/septagon-oss/pk-core/pkg/security/headers",
   "github.com/septagon-oss/pk-core/pkg/security/cors",
   "github.com/septagon-oss/pk-core/pkg/security/csrf",
   ```

2. Fitness target already covers `./pkg/security/...` from Phase A.2a fix.

---

## Commits

Produce 3 conventional commits, one per package:

1. `feat(pk-core/security/headers): security header middleware with CSP nonce`
2. `feat(pk-core/security/cors): origin-allowlist CORS middleware`
3. `feat(pk-core/security/csrf): double-submit CSRF middleware`

The `oss_deps_test.go` update goes in the LAST of the three commits (csrf), so each intermediate commit's tests pass.

---

## Acceptance criteria

- `make verify` green (includes race coverage on security via fitness target)
- 3 new sub-packages: headers, cors, csrf
- Each has C-14/ADR-0029 headers, external test packages, doc.go
- No new external deps; no septagon-dev imports
- `TestPkCoreImportsAreAllowed` and `TestNoSeptagonDevImports` pass
- 3 workspace OSS validators (`audit-oss`, `validate-oss-split`, `validate-open-core-workspace`) all green
- ≥21 tests total across the three packages (7 + 6 + 8 from the minimum list above)
- Each block satisfies the Composable scorecard at the property level
- The csrf cookie write goes through `pk-core/pkg/security/cookies.Write(KindCSRF)` (proves cross-block composition works)
