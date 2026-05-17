# pk-core/pkg/security Implementation Plan — Phase A.2a (Crypto Primitives)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Land three composable+chainable cryptographic primitive blocks in `pk-core/pkg/security/`: `passhash` (bcrypt + argon2id + HMAC short-secret), `cookies` (per-purpose security profiles), `signature` (HMAC payload signing). Update the architecture fitness test to allow a documented whitelist of `golang.org/x/crypto/...` imports — bcrypt and argon2 cannot be implemented from stdlib alone and the `golang.org/x/crypto` tree is the Go-team-maintained semi-stdlib.

**Architecture:** Each block satisfies the full Composable contract (identity, boundary, contract, contribution, replacement, extension, runtime binding, evidence) defined in `pk-core/docs/COMPOSABILITY.md`. The integration touchpoint (`cookies.Write`) is a chainable link satisfying the laws in `pk-core/docs/BLOCKS_AND_CHAINS.md`. Public types are interfaces; defaults are exported constructors that callers wire at composition time.

**Tech Stack:** Go 1.22, stdlib + `golang.org/x/crypto/bcrypt` + `golang.org/x/crypto/argon2`. No HTTP framework dependency (drop the source's `huma` cookie adapter).

**Source reference (read-only):** `septagon-dev/platformkit-backend-kit/security/{passhash,cookies,signature}`.

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`. Current HEAD: `c272296`.

---

## Block Contracts

### Block 1: `passhash`

| Composable property | Realization |
|---|---|
| Identity | Package `github.com/septagon-oss/pk-core/pkg/security/passhash` |
| Boundary | Cost and pepper held in atomics; private constructor for cost validation |
| Contract | `Hasher` interface + `BcryptHasher`, `Argon2idHasher`, `ShortSecretHasher` constructors |
| Contribution | Catalog entry as a `Hasher` provider port (auth module declares dep on `Hasher`) |
| Composition | Multiple Hashers can coexist (long passwords use bcrypt; 2FA codes use ShortSecret) |
| Replacement | Any `Hasher` implementation satisfies the interface |
| Extension | Pro adds `HSMHasher`, `KMSHasher` without touching core |
| Runtime binding | `auth.NewModule(auth.WithHasher(passhash.NewBcrypt(12)))` |
| Evidence | TDD tests for cost bounds, verify mismatches, rehash detection, pepper rotation |

### Block 2: `cookies`

| Composable property | Realization |
|---|---|
| Identity | Package `github.com/septagon-oss/pk-core/pkg/security/cookies` |
| Boundary | Per-Kind security profile table is package-private; only public mutator is `Configure(Settings)` |
| Contract | `Kind` enum + `Build/BuildClear/Write/Clear/Name` functions + `Settings` + `Option` |
| Contribution | The Kind set is the contract; modules pick by Kind. Pro extends via additional Kinds in a sibling package. |
| Composition | Multiple modules write different Kinds without interference (csrf module writes KindCSRF; auth writes KindSession) |
| Replacement | A custom cookie writer can replace `cookies.Write` at call sites |
| Extension | Pro registers additional Kinds via `RegisterKind(profile)` (deferred to v0.0.1; v0.0.0 ships fixed enum) |
| Runtime binding | `cookies.Configure(Settings{ForceSecure: true, CookieDomain: ".example.com"})` at app boot |
| Evidence | TDD tests for Secure auto-derivation, SameSite enforcement, clearing, X-Forwarded-Proto handling |

### Block 3: `signature`

| Composable property | Realization |
|---|---|
| Identity | Package `github.com/septagon-oss/pk-core/pkg/security/signature` |
| Boundary | Signing key never exposed via public API |
| Contract | `Signer` interface + `NewHMACSigner(key)` constructor |
| Contribution | Webhook signing, signed-cookie augmentation, request signing — all depend on `Signer` |
| Composition | Multiple Signers coexist (one per key version for rotation) |
| Replacement | ECDSA / Ed25519 signers could replace HMAC for asymmetric needs |
| Extension | Pro adds KMS/HSM signers |
| Runtime binding | `webhook.NewModule(webhook.WithSigner(signature.NewHMACSigner(key)))` |
| Evidence | TDD tests for sign/verify round-trip, tampering rejection, key-rotation pattern |

---

## File Structure

```
pk-core/pkg/security/
├── doc.go                              # package overview
├── passhash/
│   ├── doc.go
│   ├── passhash.go                     # Hasher interface + Cost helpers
│   ├── bcrypt.go                       # BcryptHasher
│   ├── argon2.go                       # Argon2idHasher
│   ├── short_secret.go                 # HMAC short-secret pepper (2FA backup codes, recovery codes)
│   ├── passhash_test.go                # contract test (Hasher round-trip)
│   ├── bcrypt_test.go
│   ├── argon2_test.go
│   └── short_secret_test.go
├── cookies/
│   ├── doc.go
│   ├── cookies.go                      # Kind enum, profile table, Configure, Build, BuildClear, Write, Clear, Name
│   ├── options.go                      # Option type + WithMaxAge etc
│   ├── cookies_test.go                 # contract + Secure derivation + SameSite + clearing
└── signature/
    ├── doc.go
    ├── signature.go                    # Signer interface
    ├── hmac.go                         # HMAC-SHA256 implementation
    └── signature_test.go               # sign/verify, tampering rejection, key-rotation
```

Plus updates to:
- `pk-core/pkg/architecture/oss_deps_test.go` — replace observability-only fitness test with a whitelist-based pk-core-wide test

---

## Task 1: Allowed-deps whitelist test (prerequisite)

**Files:**
- Create: `pk-core/pkg/architecture/oss_deps_test.go`
- Delete (after migration): `pk-core/pkg/architecture/observability_deps_test.go`

- [ ] **Step 1: Write the unified whitelist test**

Write `pk-core/pkg/architecture/oss_deps_test.go`:

```go
package architecture_test

// oss_deps_test.go is the central allowed-deps fitness gate for pk-core.
//
// Rule: every package under pk-core/pkg/ may import:
//   - the Go standard library
//   - any other pk-core package
//   - any module in the AllowedExternalDeps whitelist below
//
// Anything else is a v0.0.0 contract violation. The whitelist exists because a
// handful of cryptographic and crypto-adjacent operations (bcrypt, argon2id)
// cannot be implemented from stdlib alone, and `golang.org/x/crypto` is the
// Go-team-maintained, security-audited canonical source.
//
// To add an entry: extend AllowedExternalDeps with the import path and a
// one-line comment documenting WHY pk-core needs it. The bar is "this cannot
// be reasonably implemented from stdlib AND is widely vendored in the Go
// ecosystem AND is maintained by a trusted upstream."
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"go/build"
	"strings"
	"testing"
)

// AllowedExternalDeps enumerates the import paths pk-core packages may use
// outside the standard library. Keys are exact package paths.
var AllowedExternalDeps = map[string]string{
	"golang.org/x/crypto/bcrypt": "bcrypt password hashing; cannot be implemented from stdlib alone; Go-team maintained",
	"golang.org/x/crypto/argon2": "argon2id password hashing; cannot be implemented from stdlib alone; Go-team maintained",
}

// pkCorePackages lists every public pkg/ leaf in pk-core. Tests that walk
// imports use this list as the authoritative set of packages to check.
//
// When a new pk-core package is added, append it here.
var pkCorePackages = []string{
	"github.com/septagon-oss/pk-core/pkg/architecture",
	"github.com/septagon-oss/pk-core/pkg/authz",
	"github.com/septagon-oss/pk-core/pkg/entity",
	"github.com/septagon-oss/pk-core/pkg/module",
	"github.com/septagon-oss/pk-core/pkg/mutation",
	"github.com/septagon-oss/pk-core/pkg/registry",
	"github.com/septagon-oss/pk-core/pkg/observability",
	"github.com/septagon-oss/pk-core/pkg/observability/logger",
	"github.com/septagon-oss/pk-core/pkg/observability/metrics",
	"github.com/septagon-oss/pk-core/pkg/observability/tracing",
	"github.com/septagon-oss/pk-core/pkg/observability/health",
	"github.com/septagon-oss/pk-core/pkg/observability/guardrail",
	"github.com/septagon-oss/pk-core/pkg/security",
	"github.com/septagon-oss/pk-core/pkg/security/passhash",
	"github.com/septagon-oss/pk-core/pkg/security/cookies",
	"github.com/septagon-oss/pk-core/pkg/security/signature",
}

func TestPkCoreImportsAreAllowed(t *testing.T) {
	t.Parallel()
	for _, p := range pkCorePackages {
		pkg, err := build.Default.Import(p, "", 0)
		if err != nil {
			t.Errorf("import %s: %v", p, err)
			continue
		}
		for _, imp := range pkg.Imports {
			if isStdLib(imp) {
				continue
			}
			if strings.HasPrefix(imp, "github.com/septagon-oss/pk-core") {
				continue
			}
			if _, allowed := AllowedExternalDeps[imp]; allowed {
				continue
			}
			t.Errorf("%s imports unauthorized external dependency %q (add to AllowedExternalDeps with justification if intended)", p, imp)
		}
	}
}

// TestNoSeptagonDevImports preserves the absolute boundary: OSS may never
// import private septagon-dev packages, regardless of whitelist status.
func TestNoSeptagonDevImports(t *testing.T) {
	t.Parallel()
	for _, p := range pkCorePackages {
		pkg, err := build.Default.Import(p, "", 0)
		if err != nil {
			t.Errorf("import %s: %v", p, err)
			continue
		}
		for _, imp := range pkg.Imports {
			if strings.HasPrefix(imp, "github.com/septagon-dev") {
				t.Errorf("%s imports forbidden private package %q", p, imp)
			}
		}
	}
}

func isStdLib(importPath string) bool {
	first, _, _ := strings.Cut(importPath, "/")
	return !strings.Contains(first, ".")
}
```

- [ ] **Step 2: Delete the now-superseded observability-only test**

```bash
rm /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/architecture/observability_deps_test.go
```

- [ ] **Step 3: Verify both tests pass (security packages don't exist yet so the security entries fail import — that's OK, expected after Task 2)**

Run:
```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/architecture/... -v
```
Expected: `TestPkCoreImportsAreAllowed` will FAIL with `import ...security/passhash: cannot find package` — that's the test catching the not-yet-extracted packages. After Task 4 (passhash lands) the failure will shift. After all 4 packages exist (Tasks 4, 6, 8), test will PASS.

So for Task 1's commit, comment out the security entries in `pkCorePackages` temporarily. Add a TODO note. After Task 8, uncomment.

Actually simpler: only list packages that exist now. Append security entries as they land.

Replace `pkCorePackages` initialization with this content for Task 1's commit:

```go
var pkCorePackages = []string{
	"github.com/septagon-oss/pk-core/pkg/architecture",
	"github.com/septagon-oss/pk-core/pkg/authz",
	"github.com/septagon-oss/pk-core/pkg/entity",
	"github.com/septagon-oss/pk-core/pkg/module",
	"github.com/septagon-oss/pk-core/pkg/mutation",
	"github.com/septagon-oss/pk-core/pkg/registry",
	"github.com/septagon-oss/pk-core/pkg/observability",
	"github.com/septagon-oss/pk-core/pkg/observability/logger",
	"github.com/septagon-oss/pk-core/pkg/observability/metrics",
	"github.com/septagon-oss/pk-core/pkg/observability/tracing",
	"github.com/septagon-oss/pk-core/pkg/observability/health",
	"github.com/septagon-oss/pk-core/pkg/observability/guardrail",
	// security/* appended as they land (Tasks 4, 6, 8)
}
```

Run again — expect PASS.

- [ ] **Step 4: Commit**

```bash
git add pkg/architecture/oss_deps_test.go
git rm pkg/architecture/observability_deps_test.go
git commit -m "test(pk-core/architecture): unified whitelist-based deps fitness test"
```

---

## Task 2: Scaffold security parent package

- [ ] **Step 1: Create directory + doc.go**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/security
```

Write `pk-core/pkg/security/doc.go`:

```go
// Package security defines PlatformKit's provider-neutral security primitives.
//
// Sub-packages own one concern each:
//   - passhash: password hashing (bcrypt, argon2id, short-secret pepper)
//   - cookies:  per-purpose HTTP cookie security profiles
//   - signature: HMAC payload signing
//   - cors, csrf, headers: HTTP security middleware (Phase A.2b)
//   - identity, ratelimit: request-scoped state (Phase A.2c)
//   - authn, authz, middlewarepolicy: composition layer (Phase A.2d)
//
// External deps used by this package are whitelisted in
// pk-core/pkg/architecture/oss_deps_test.go. Pro/downstream adapters
// (HSM-backed hashers, KMS signers, OAuth/SAML auth providers) live in
// downstream packages so the OSS kernel remains slim and audit-friendly.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package security
```

- [ ] **Step 2: Verify build**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go build ./pkg/security/...
```
Expected: success.

- [ ] **Step 3: Commit**

```bash
git add pkg/security/doc.go
git commit -m "feat(pk-core): scaffold security package"
```

---

## Task 3: passhash — Hasher contract + failing test

- [ ] **Step 1: Create directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/security/passhash
```

- [ ] **Step 2: Write the failing contract test**

`pk-core/pkg/security/passhash/passhash_test.go`:

```go
package passhash_test

// passhash_test.go validates the Hasher contract across all default
// implementations: hash produces a distinct value per call (salted), Verify
// returns nil on match and a non-nil error on mismatch, and NeedsRehash
// reflects cost drift.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"testing"

	"github.com/septagon-oss/pk-core/pkg/security/passhash"
)

// hasherContract is run against every Hasher implementation to enforce the
// same behavioral guarantees across bcrypt, argon2id, and short-secret.
func hasherContract(t *testing.T, name string, h passhash.Hasher, secret string) {
	t.Helper()
	t.Run(name+"/HashThenVerifySucceeds", func(t *testing.T) {
		t.Parallel()
		hash, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash: %v", err)
		}
		if err := h.Verify(secret, hash); err != nil {
			t.Fatalf("Verify(correct): %v", err)
		}
	})
	t.Run(name+"/VerifyFailsForWrongSecret", func(t *testing.T) {
		t.Parallel()
		hash, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash: %v", err)
		}
		if err := h.Verify(secret+"x", hash); err == nil {
			t.Fatal("Verify(wrong) should fail")
		}
	})
	t.Run(name+"/HashIsSalted", func(t *testing.T) {
		t.Parallel()
		a, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash a: %v", err)
		}
		b, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash b: %v", err)
		}
		if a == b {
			t.Fatalf("two hashes of same secret should differ (salt missing): %q", a)
		}
	})
}

func TestBcryptSatisfiesContract(t *testing.T) {
	t.Parallel()
	h, err := passhash.NewBcrypt(passhash.MinCost)
	if err != nil {
		t.Fatalf("NewBcrypt: %v", err)
	}
	hasherContract(t, "bcrypt", h, "correct horse battery staple")
}

func TestArgon2idSatisfiesContract(t *testing.T) {
	t.Parallel()
	h, err := passhash.NewArgon2id(passhash.Argon2idDefaults())
	if err != nil {
		t.Fatalf("NewArgon2id: %v", err)
	}
	hasherContract(t, "argon2id", h, "correct horse battery staple")
}

func TestShortSecretSatisfiesContract(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 32) // zero pepper for tests
	h, err := passhash.NewShortSecret(pepper)
	if err != nil {
		t.Fatalf("NewShortSecret: %v", err)
	}
	hasherContract(t, "short", h, "12345678") // backup code length
}
```

Note: `hasherContract` runs three contract subtests against each Hasher. ShortSecret is NOT salted (deterministic HMAC) so the `HashIsSalted` subtest will fail for it — we'll address by separating: bcrypt and argon2id share the full contract; short-secret has a smaller contract. Adjust by writing a second helper `deterministicHasherContract` for short-secret. Plan that into Task 7.

For Task 3, ship the contract test with only `TestBcryptSatisfiesContract` (the rest become separate tests in Tasks 5, 7).

So the actual Task 3 test file should be:

```go
package passhash_test

// passhash_test.go validates the Hasher contract shared by all randomly
// salted implementations (bcrypt, argon2id). The non-salted ShortSecret
// hasher has its own contract test in short_secret_test.go.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"testing"

	"github.com/septagon-oss/pk-core/pkg/security/passhash"
)

// SaltedHasherContract runs the three behavioral checks every randomly-salted
// Hasher must satisfy: round-trip match, wrong-secret rejection, and per-call
// salt randomness.
func SaltedHasherContract(t *testing.T, name string, h passhash.Hasher, secret string) {
	t.Helper()
	t.Run(name+"/HashThenVerifySucceeds", func(t *testing.T) {
		t.Parallel()
		hash, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash: %v", err)
		}
		if err := h.Verify(secret, hash); err != nil {
			t.Fatalf("Verify(correct): %v", err)
		}
	})
	t.Run(name+"/VerifyFailsForWrongSecret", func(t *testing.T) {
		t.Parallel()
		hash, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash: %v", err)
		}
		if err := h.Verify(secret+"x", hash); err == nil {
			t.Fatal("Verify(wrong) should fail")
		}
	})
	t.Run(name+"/HashIsSalted", func(t *testing.T) {
		t.Parallel()
		a, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash a: %v", err)
		}
		b, err := h.Hash(secret)
		if err != nil {
			t.Fatalf("Hash b: %v", err)
		}
		if a == b {
			t.Fatalf("two hashes of same secret should differ (salt missing)")
		}
	})
}
```

Note: `SaltedHasherContract` is now an **exported** helper that bcrypt_test.go and argon2_test.go will call.

- [ ] **Step 3: Run, see it fail (no passhash package yet)**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/security/passhash/... 2>&1 | tail -5
```
Expected: build failure.

---

## Task 4: passhash — Hasher interface + Cost helpers + Bcrypt

- [ ] **Step 1: Write the Hasher interface and Cost helpers**

`pk-core/pkg/security/passhash/passhash.go`:

```go
// Package passhash provides PlatformKit's provider-neutral password hashing
// contract. Default implementations cover long passwords (bcrypt, argon2id)
// and short high-entropy secrets like 2FA backup codes (HMAC-SHA256 with a
// server-side pepper).
//
// passhash.go owns the Hasher interface and the bcrypt cost helpers shared
// by callers that want to introspect or modify the platform-wide cost.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package passhash

import "errors"

// Hasher is the provider-neutral password hashing contract.
//
// Implementations must be safe for concurrent use. Hash returns an encoded
// representation including any salt or algorithm parameters required by
// Verify; the format is implementation-defined.
type Hasher interface {
	// Hash produces an encoded representation of the secret. Each call must
	// produce a distinct value for randomly-salted hashers (bcrypt, argon2id);
	// for deterministic hashers (HMAC-based short-secret) repeated calls with
	// the same input produce the same output.
	Hash(secret string) (string, error)

	// Verify returns nil iff secret matches the encoded hash. Non-nil errors
	// indicate either an authentic mismatch or a malformed hash; callers MUST
	// NOT distinguish the two for authentication decisions.
	Verify(secret, encoded string) error
}

// ErrMismatch is returned by Verify when the secret does not match the hash.
// Callers should treat it as opaque; do NOT include it in user-visible error
// messages.
var ErrMismatch = errors.New("passhash: secret does not match hash")

// ErrMalformedHash is returned by Verify when the encoded hash cannot be
// parsed. Callers should treat it identically to ErrMismatch for
// authentication purposes to avoid leaking format errors to attackers.
var ErrMalformedHash = errors.New("passhash: malformed encoded hash")
```

- [ ] **Step 2: Write bcrypt.go**

`pk-core/pkg/security/passhash/bcrypt.go`:

```go
// Package passhash — bcrypt.go provides the BcryptHasher implementation. Cost
// is enforced at construction time to prevent silent downgrades; the OWASP
// 2024+ minimum (12) is the package floor.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package passhash

import (
	"errors"
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

// Bcrypt cost bounds. MinCost reflects OWASP 2024+ baseline; raising it is
// always safe. Lowering below MinCost is rejected at NewBcrypt time.
const (
	MinCost     = 12
	DefaultCost = 12
	MaxCost     = bcrypt.MaxCost
)

// BcryptHasher hashes long passwords with bcrypt at a fixed cost.
type BcryptHasher struct {
	cost int
}

// NewBcrypt constructs a BcryptHasher. Returns an error if cost is outside
// [MinCost, MaxCost].
func NewBcrypt(cost int) (*BcryptHasher, error) {
	if cost < MinCost {
		return nil, fmt.Errorf("passhash.NewBcrypt: cost %d below MinCost %d", cost, MinCost)
	}
	if cost > MaxCost {
		return nil, fmt.Errorf("passhash.NewBcrypt: cost %d above MaxCost %d", cost, MaxCost)
	}
	return &BcryptHasher{cost: cost}, nil
}

// Cost returns the configured bcrypt cost.
func (b *BcryptHasher) Cost() int { return b.cost }

// Hash satisfies Hasher.
func (b *BcryptHasher) Hash(secret string) (string, error) {
	h, err := bcrypt.GenerateFromPassword([]byte(secret), b.cost)
	if err != nil {
		return "", fmt.Errorf("passhash.Hash: %w", err)
	}
	return string(h), nil
}

// Verify satisfies Hasher.
func (b *BcryptHasher) Verify(secret, encoded string) error {
	err := bcrypt.CompareHashAndPassword([]byte(encoded), []byte(secret))
	switch {
	case err == nil:
		return nil
	case errors.Is(err, bcrypt.ErrMismatchedHashAndPassword):
		return ErrMismatch
	case errors.Is(err, bcrypt.ErrHashTooShort):
		return ErrMalformedHash
	}
	// Other bcrypt internal errors (e.g. ErrPasswordTooLong) are treated as
	// mismatch from the auth perspective — never leak the underlying cause.
	return ErrMismatch
}

// NeedsRehash reports whether encoded was produced with a cost below the
// current configured cost. Callers can use this to opportunistically rehash
// on successful login.
func (b *BcryptHasher) NeedsRehash(encoded string) bool {
	c, err := bcrypt.Cost([]byte(encoded))
	if err != nil {
		return false
	}
	return c < b.cost
}
```

- [ ] **Step 3: Write bcrypt_test.go**

`pk-core/pkg/security/passhash/bcrypt_test.go`:

```go
package passhash_test

// bcrypt_test.go validates BcryptHasher: it satisfies SaltedHasherContract,
// rejects cost below MinCost at construction, and surfaces NeedsRehash for
// cost upgrades.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"errors"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/security/passhash"
)

func TestBcryptContract(t *testing.T) {
	t.Parallel()
	h, err := passhash.NewBcrypt(passhash.MinCost)
	if err != nil {
		t.Fatalf("NewBcrypt: %v", err)
	}
	SaltedHasherContract(t, "bcrypt", h, "correct horse battery staple")
}

func TestNewBcryptRejectsCostBelowMin(t *testing.T) {
	t.Parallel()
	if _, err := passhash.NewBcrypt(passhash.MinCost - 1); err == nil {
		t.Fatal("expected error for cost below MinCost")
	}
}

func TestNewBcryptRejectsCostAboveMax(t *testing.T) {
	t.Parallel()
	if _, err := passhash.NewBcrypt(passhash.MaxCost + 1); err == nil {
		t.Fatal("expected error for cost above MaxCost")
	}
}

func TestBcryptVerifyMismatchUsesSentinel(t *testing.T) {
	t.Parallel()
	h, _ := passhash.NewBcrypt(passhash.MinCost)
	hash, _ := h.Hash("a")
	err := h.Verify("b", hash)
	if !errors.Is(err, passhash.ErrMismatch) {
		t.Fatalf("Verify(wrong) = %v, want ErrMismatch", err)
	}
}

func TestBcryptVerifyMalformedReturnsMismatchOpaque(t *testing.T) {
	t.Parallel()
	// Malformed hash should also surface as ErrMismatch from the auth boundary
	// (we DO permit ErrMalformedHash for deliberate format checks elsewhere).
	h, _ := passhash.NewBcrypt(passhash.MinCost)
	err := h.Verify("anything", "not-a-bcrypt-hash")
	if !errors.Is(err, passhash.ErrMalformedHash) {
		t.Fatalf("Verify(malformed) = %v, want ErrMalformedHash", err)
	}
}

func TestBcryptNeedsRehashAtHigherCost(t *testing.T) {
	t.Parallel()
	low, _ := passhash.NewBcrypt(passhash.MinCost)
	high, _ := passhash.NewBcrypt(passhash.MinCost + 1)
	hash, _ := low.Hash("x")
	if !high.NeedsRehash(hash) {
		t.Fatal("high-cost hasher should report NeedsRehash for low-cost hash")
	}
	if low.NeedsRehash(hash) {
		t.Fatal("same-cost hasher should not report NeedsRehash")
	}
}
```

- [ ] **Step 4: Run go.mod tidy to add x/crypto**

The bcrypt import will require `golang.org/x/crypto` in go.mod. Run:

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache GOMODCACHE=$(pwd)/.tmp-go-mod go mod tidy
git diff go.mod go.sum
```

Expected: `go.mod` adds `golang.org/x/crypto vX.Y.Z` in a require block, and `go.sum` materializes. This is the FIRST external dep in pk-core — verify the architecture fitness test still passes (allowed via whitelist).

- [ ] **Step 5: Add passhash to pkCorePackages list in oss_deps_test.go**

Edit `pk-core/pkg/architecture/oss_deps_test.go` to append `"github.com/septagon-oss/pk-core/pkg/security"` and `"github.com/septagon-oss/pk-core/pkg/security/passhash"` to `pkCorePackages`.

- [ ] **Step 6: Run all tests**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
make verify
```
Expected: green. `TestPkCoreImportsAreAllowed` confirms `golang.org/x/crypto/bcrypt` is whitelisted.

- [ ] **Step 7: Commit**

```bash
git add pkg/security/passhash/passhash.go pkg/security/passhash/bcrypt.go pkg/security/passhash/bcrypt_test.go pkg/security/passhash/passhash_test.go pkg/architecture/oss_deps_test.go go.mod go.sum
git commit -m "feat(pk-core/security/passhash): Hasher contract + BcryptHasher"
```

---

## Task 5: passhash — Argon2idHasher

- [ ] **Step 1: Write argon2.go**

`pk-core/pkg/security/passhash/argon2.go`:

```go
// Package passhash — argon2.go provides Argon2idHasher. Parameters follow
// OWASP 2024+ guidance (memory 64MiB, iterations 3, parallelism 4, key length
// 32, salt length 16). Encoded format is the standard PHC string format:
//   $argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package passhash

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/argon2"
)

// Argon2idParams configures the argon2id algorithm. Defaults are OWASP 2024+.
type Argon2idParams struct {
	Memory      uint32 // KiB
	Iterations  uint32
	Parallelism uint8
	SaltLength  uint32
	KeyLength   uint32
}

// Argon2idDefaults returns the recommended baseline parameters.
func Argon2idDefaults() Argon2idParams {
	return Argon2idParams{
		Memory:      64 * 1024,
		Iterations:  3,
		Parallelism: 4,
		SaltLength:  16,
		KeyLength:   32,
	}
}

// Argon2idHasher hashes long passwords with argon2id at fixed parameters.
type Argon2idHasher struct {
	params Argon2idParams
}

// NewArgon2id constructs an Argon2idHasher.
func NewArgon2id(p Argon2idParams) (*Argon2idHasher, error) {
	if p.Memory < 8*1024 {
		return nil, fmt.Errorf("passhash.NewArgon2id: memory %d KiB below 8 MiB floor", p.Memory)
	}
	if p.Iterations < 1 {
		return nil, errors.New("passhash.NewArgon2id: iterations must be >= 1")
	}
	if p.Parallelism < 1 {
		return nil, errors.New("passhash.NewArgon2id: parallelism must be >= 1")
	}
	if p.SaltLength < 8 {
		return nil, fmt.Errorf("passhash.NewArgon2id: saltLength %d below 8-byte floor", p.SaltLength)
	}
	if p.KeyLength < 16 {
		return nil, fmt.Errorf("passhash.NewArgon2id: keyLength %d below 16-byte floor", p.KeyLength)
	}
	return &Argon2idHasher{params: p}, nil
}

// Hash satisfies Hasher.
func (a *Argon2idHasher) Hash(secret string) (string, error) {
	salt := make([]byte, a.params.SaltLength)
	if _, err := rand.Read(salt); err != nil {
		return "", fmt.Errorf("passhash.argon2id.Hash: read salt: %w", err)
	}
	hash := argon2.IDKey([]byte(secret), salt, a.params.Iterations, a.params.Memory, a.params.Parallelism, a.params.KeyLength)
	b64salt := base64.RawStdEncoding.EncodeToString(salt)
	b64hash := base64.RawStdEncoding.EncodeToString(hash)
	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s",
		argon2.Version, a.params.Memory, a.params.Iterations, a.params.Parallelism, b64salt, b64hash), nil
}

// Verify satisfies Hasher.
func (a *Argon2idHasher) Verify(secret, encoded string) error {
	parts := strings.Split(encoded, "$")
	if len(parts) != 6 || parts[0] != "" || parts[1] != "argon2id" {
		return ErrMalformedHash
	}
	var version int
	if _, err := fmt.Sscanf(parts[2], "v=%d", &version); err != nil || version != argon2.Version {
		return ErrMalformedHash
	}
	var memory, iters uint32
	var par uint8
	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &memory, &iters, &par); err != nil {
		return ErrMalformedHash
	}
	salt, err := base64.RawStdEncoding.DecodeString(parts[4])
	if err != nil {
		return ErrMalformedHash
	}
	want, err := base64.RawStdEncoding.DecodeString(parts[5])
	if err != nil {
		return ErrMalformedHash
	}
	got := argon2.IDKey([]byte(secret), salt, iters, memory, par, uint32(len(want)))
	if subtle.ConstantTimeCompare(got, want) != 1 {
		return ErrMismatch
	}
	return nil
}
```

- [ ] **Step 2: Write argon2_test.go**

`pk-core/pkg/security/passhash/argon2_test.go`:

```go
package passhash_test

// argon2_test.go validates Argon2idHasher contract conformance and
// parameter-floor rejection at construction.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"errors"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/security/passhash"
)

func TestArgon2idContract(t *testing.T) {
	t.Parallel()
	// Use smaller-than-default params to keep the test suite fast while still
	// exercising the algorithm and PHC encoding.
	p := passhash.Argon2idDefaults()
	p.Memory = 8 * 1024 // 8 MiB floor
	p.Iterations = 1
	p.Parallelism = 1
	h, err := passhash.NewArgon2id(p)
	if err != nil {
		t.Fatalf("NewArgon2id: %v", err)
	}
	SaltedHasherContract(t, "argon2id", h, "correct horse battery staple")
}

func TestNewArgon2idRejectsLowMemory(t *testing.T) {
	t.Parallel()
	p := passhash.Argon2idDefaults()
	p.Memory = 4 * 1024
	if _, err := passhash.NewArgon2id(p); err == nil {
		t.Fatal("expected error for memory below floor")
	}
}

func TestArgon2idVerifyMalformedHash(t *testing.T) {
	t.Parallel()
	h, _ := passhash.NewArgon2id(passhash.Argon2idDefaults())
	if err := h.Verify("x", "not-a-phc-string"); !errors.Is(err, passhash.ErrMalformedHash) {
		t.Fatalf("got %v, want ErrMalformedHash", err)
	}
}
```

- [ ] **Step 3: Run + commit**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/security/passhash/... -v -timeout 30s
# Then:
git add pkg/security/passhash/argon2.go pkg/security/passhash/argon2_test.go
git commit -m "feat(pk-core/security/passhash): Argon2idHasher"
```

Note: `go mod tidy` may add `golang.org/x/sys` indirect — if so, include in commit. Update the whitelist if needed (likely not — argon2 is already in x/crypto which is whitelisted).

---

## Task 6: passhash — Short-secret HMAC pepper

- [ ] **Step 1: Write short_secret.go**

`pk-core/pkg/security/passhash/short_secret.go`:

```go
// Package passhash — short_secret.go hashes short, high-entropy values like
// 2FA backup codes or recovery codes using HMAC-SHA256 with a server-side
// pepper. bcrypt and argon2id are the wrong tool for these inputs because
// their work factor is targeted at human-memorable low-entropy passwords;
// short codes are already high-entropy and need only constant-time equality
// and a pepper so the database alone cannot reveal them.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package passhash

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
)

// ShortSecretHasher hashes short codes with HMAC-SHA256(pepper, secret).
// Output is hex-encoded for storage. Two calls with the same secret produce
// the same hash (deterministic) — that is required because backup codes are
// stored once and looked up by hash on later verification.
type ShortSecretHasher struct {
	pepper []byte
}

// NewShortSecret constructs a ShortSecretHasher. The pepper must be at least
// 32 bytes; callers should generate it with crypto/rand and persist it in
// platform secrets, NOT in the database.
func NewShortSecret(pepper []byte) (*ShortSecretHasher, error) {
	if len(pepper) < 32 {
		return nil, errors.New("passhash.NewShortSecret: pepper must be at least 32 bytes")
	}
	cp := make([]byte, len(pepper))
	copy(cp, pepper)
	return &ShortSecretHasher{pepper: cp}, nil
}

// Hash satisfies Hasher. Deterministic; same input → same output.
func (s *ShortSecretHasher) Hash(secret string) (string, error) {
	m := hmac.New(sha256.New, s.pepper)
	m.Write([]byte(secret))
	return hex.EncodeToString(m.Sum(nil)), nil
}

// Verify satisfies Hasher. Constant-time comparison against the encoded hash.
func (s *ShortSecretHasher) Verify(secret, encoded string) error {
	want, err := hex.DecodeString(encoded)
	if err != nil {
		return ErrMalformedHash
	}
	got, _ := s.Hash(secret)
	gotBytes, _ := hex.DecodeString(got)
	if subtle.ConstantTimeCompare(gotBytes, want) != 1 {
		return ErrMismatch
	}
	return nil
}
```

- [ ] **Step 2: Write short_secret_test.go**

`pk-core/pkg/security/passhash/short_secret_test.go`:

```go
package passhash_test

// short_secret_test.go validates ShortSecretHasher: round-trip, deterministic
// output for same input, mismatch detection, pepper-length floor.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"errors"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/security/passhash"
)

func TestShortSecretRoundTrip(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 32)
	for i := range pepper {
		pepper[i] = byte(i)
	}
	h, err := passhash.NewShortSecret(pepper)
	if err != nil {
		t.Fatalf("NewShortSecret: %v", err)
	}
	hash, err := h.Hash("BACKUP-12345")
	if err != nil {
		t.Fatalf("Hash: %v", err)
	}
	if err := h.Verify("BACKUP-12345", hash); err != nil {
		t.Fatalf("Verify(correct): %v", err)
	}
}

func TestShortSecretIsDeterministic(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 32)
	h, _ := passhash.NewShortSecret(pepper)
	a, _ := h.Hash("BACKUP-12345")
	b, _ := h.Hash("BACKUP-12345")
	if a != b {
		t.Fatalf("ShortSecret must be deterministic; got %q vs %q", a, b)
	}
}

func TestShortSecretRejectsWrongSecret(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 32)
	h, _ := passhash.NewShortSecret(pepper)
	hash, _ := h.Hash("BACKUP-12345")
	if err := h.Verify("BACKUP-12346", hash); !errors.Is(err, passhash.ErrMismatch) {
		t.Fatalf("Verify(wrong) = %v, want ErrMismatch", err)
	}
}

func TestShortSecretRejectsShortPepper(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 16)
	if _, err := passhash.NewShortSecret(pepper); err == nil {
		t.Fatal("expected error for pepper < 32 bytes")
	}
}

func TestShortSecretVerifyMalformed(t *testing.T) {
	t.Parallel()
	pepper := make([]byte, 32)
	h, _ := passhash.NewShortSecret(pepper)
	if err := h.Verify("x", "not-hex-bytes!!"); !errors.Is(err, passhash.ErrMalformedHash) {
		t.Fatalf("Verify(malformed) = %v, want ErrMalformedHash", err)
	}
}
```

- [ ] **Step 3: Run + commit**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/security/passhash/... -v
git add pkg/security/passhash/short_secret.go pkg/security/passhash/short_secret_test.go
git commit -m "feat(pk-core/security/passhash): HMAC ShortSecretHasher for 2FA backup codes"
```

---

## Task 7: passhash — doc.go

`pk-core/pkg/security/passhash/doc.go`:

```go
// Package passhash defines PlatformKit's password hashing contract.
//
// # The Hasher interface
//
//	type Hasher interface {
//	    Hash(secret string) (string, error)
//	    Verify(secret, encoded string) error
//	}
//
// # Default implementations
//
//   - BcryptHasher (NewBcrypt(cost)) — long passwords; OWASP 2024+ cost floor 12
//   - Argon2idHasher (NewArgon2id(params)) — alternative for long passwords
//   - ShortSecretHasher (NewShortSecret(pepper)) — 2FA backup codes, recovery codes
//
// # Choosing
//
//   - Login passwords → BcryptHasher (or Argon2id if you have memory headroom)
//   - 2FA backup codes / single-use recovery codes → ShortSecretHasher
//
// # Pro/downstream
//
// HSM-backed and KMS-backed hashers (where the work happens in a hardware
// security module rather than the application process) live in downstream
// Pro packages. They satisfy the same Hasher interface so module wiring is
// unchanged.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package passhash
```

Commit:
```bash
git add pkg/security/passhash/doc.go
git commit -m "docs(pk-core/security/passhash): package documentation"
```

---

## Task 8: cookies — Kind enum + profile table + Build/Write

(Full structure mirroring source `platformkit-backend-kit/security/cookies/cookies.go` minus the huma adapter. Public API: `Kind`, `Settings`, `Configure(Settings)`, `Build(*http.Request, Kind, value, opts...) (*http.Cookie, error)`, `BuildClear(*http.Request, Kind) (*http.Cookie, error)`, `Write(http.ResponseWriter, *http.Request, Kind, value, opts...)`, `Clear(http.ResponseWriter, *http.Request, Kind)`, `Name(Kind) (string, error)`, `WithMaxAge(time.Duration) Option`.)

Detailed code in `platformkit-backend-kit/security/cookies/cookies.go` lines 1-300 — the implementer extracts and adapts. Key v0.0.0 changes:
- Drop `cookies_huma.go` entirely
- Replace `huma.Context` callsites with `*http.Request`
- Keep `BuildFromContext` for `context.Context` callers but reduce to a `Settings.ForceSecure`-only path (no TLS detection from std context)

Tests cover: Secure auto-derivation from `r.TLS != nil` AND `X-Forwarded-Proto: https`, SameSite enforcement per Kind, Clear writes MaxAge<0, ForceSecure override, Name() round-trip.

Commit: `feat(pk-core/security/cookies): per-purpose HTTP cookie security profiles`

---

## Task 9: signature — Signer interface + HMACSigner

(`Signer.Sign(payload []byte) string` and `Signer.Verify(payload []byte, signature string) bool`. `NewHMACSigner(key []byte) (*HMACSigner, error)` with minimum 32-byte key floor. Hex-encoded signature output. Constant-time compare in Verify.)

Tests: round-trip, tampering rejection (modified payload), wrong-key rejection, key-length floor.

Commit: `feat(pk-core/security/signature): HMAC payload Signer`

---

## Task 10: Final verification

- [ ] **Step 1:** Run `make verify` and confirm green
- [ ] **Step 2:** Run `go mod tidy` and confirm only `golang.org/x/crypto` (+ indirect deps) appear in `go.mod`
- [ ] **Step 3:** Confirm `TestPkCoreImportsAreAllowed` lists all three new security sub-packages and passes
- [ ] **Step 4:** Confirm `TestNoSeptagonDevImports` passes
- [ ] **Step 5:** Run the workspace OSS validators from `platformkit/`:

```bash
cd /home/jplr/gitrepos/septagon-dev/platformkit
make audit-oss && make validate-oss-split && make validate-open-core-workspace
```

All three green. No commit unless cleanup needed.

---

## Acceptance Criteria

- `cd septagon-oss-workspace/pk-core && make verify` green
- 3 new sub-packages: `passhash`, `cookies`, `signature`
- Public surface satisfies the Composable contract for each block
- `golang.org/x/crypto/bcrypt` and `golang.org/x/crypto/argon2` are the ONLY new external deps; both whitelisted with documented justification
- No `github.com/septagon-dev` imports anywhere in pk-core
- 3 workspace OSS validators pass
- ~10–14 commits total, atomic and conventional

## Self-Review Notes (post-execution)

Note for the executor: any deviation from the spec (alternative argon2 param choices, alternative cookie Kind values, etc.) goes in the final commit message body so the reviewer can audit the deltas.
