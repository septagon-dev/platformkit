# pk-core/pkg/resilience Implementation Plan (Phase A.3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Land three fault-tolerance primitive blocks in `pk-core/pkg/resilience/`: `retry` (configurable retry with exponential backoff + jitter), `circuitbreaker` (closed/open/half-open state machine), `bulkhead` (concurrency-limiting semaphore). Each is a Composable + Chainable Block.

**Architecture:** Each primitive exposes (a) an interface defining the contract, (b) a default implementation, (c) a wrapper function that decorates a `func(context.Context) error` callable. They chain — `retry(circuitbreaker(bulkhead(call)))` is a valid pattern — and they compose with logger/metrics from observability for emitted events.

**Tech Stack:** Stdlib only. NO new external deps.

**Source reference (read-only):** `platformkit-backend-kit/resilience/{interface,resiliencecontract,providers/{retry,circuitbreaker,bulkhead}}/...`

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`

---

## Block 1: `retry`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/resilience/retry` |
| Boundary | Internal scheduler hidden; only `Policy`, `Retrier` interface, default constructor exported |
| Contract | `Retrier` interface (Do method) + `Policy` config + `Do(ctx, op)` helper |
| Composition | Multiple Policies coexist (different retry profiles per call site) |
| Replacement | Any `Retrier` impl swaps in |
| Extension | Pro adds distributed retry coordinator, deadline-aware schedulers |
| Runtime binding | App composition (per-service / per-call retrier) |
| Evidence | Tests cover success/failure paths, backoff timing, context cancellation |

### Chainable laws
- Identity: Policy with MaxAttempts=1 and zero delay is effectively a single call (no-op composition element)
- Type compatibility: `Do(ctx, op)` shape composes with circuitbreaker/bulkhead wrappers
- Context preservation: `op` receives the same ctx; cancellation aborts retries
- Error algebra: `IsRetryable(err)` predicate decides whether to retry; non-retryable errors short-circuit
- Cancellation safety: ctx cancellation honored before each attempt; in-flight `op` allowed to finish

### Public API

```go
package retry

// Operation is a single retryable call.
type Operation func(ctx context.Context, attempt int) error

// Policy configures retry behavior.
type Policy struct {
    MaxAttempts   int           // total attempts including the first; default 3
    InitialDelay  time.Duration // base delay before first retry; default 100ms
    MaxDelay      time.Duration // upper bound for any single delay; default 30s
    Multiplier    float64       // exponential growth factor; default 2.0
    JitterFactor  float64       // 0.0 = no jitter, 1.0 = full +/- delay; default 0.25
    IsRetryable   func(err error) bool // predicate; default: any non-nil error
}

// DefaultPolicy returns a sensible Policy.
func DefaultPolicy() Policy

// Validate normalizes p in place and returns an error if any field is
// invalid (e.g. MaxAttempts < 1). Called by Do; callers can call it
// explicitly to surface config errors at construction.
func (p *Policy) Validate() error

// Retrier executes operations under a Policy.
type Retrier interface {
    Do(ctx context.Context, op Operation) error
}

// New returns a Retrier with the given Policy.
func New(p Policy) (Retrier, error)

// Do runs op under DefaultPolicy(). Convenience for one-off retries.
func Do(ctx context.Context, op Operation) error
```

### Tests
- TestDefaultPolicyValid
- TestPolicyValidateRejectsZeroMaxAttempts
- TestPolicyValidateRejectsNegativeMultiplier
- TestDoSucceedsOnFirstAttempt
- TestDoRetriesUntilSuccess
- TestDoStopsAtMaxAttempts
- TestDoRespectsNonRetryableError (custom IsRetryable returns false → no retry)
- TestDoHonorsContextCancellation
- TestDoExponentialBackoffGrows (assert delays approximately double)
- TestDoBackoffClampedAtMaxDelay
- TestDoJitterProducesVariance (multiple runs produce different delays)
- TestDoZeroJitterIsDeterministic
- TestDoZeroAttemptOperationGetsAttemptIndex

### Files
```
pk-core/pkg/resilience/retry/
├── doc.go
├── retry.go          # Operation, Policy, Validate, DefaultPolicy, Retrier interface, New, Do
├── backoff.go        # internal computeBackoff function
└── retry_test.go     # external
```

### Commit
`feat(pk-core/resilience/retry): exponential-backoff Retrier with jitter`

---

## Block 2: `circuitbreaker`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/resilience/circuitbreaker` |
| Boundary | State machine internal; only `Breaker` interface + constructor + state constants exported |
| Contract | `Breaker.Do(ctx, op)`; `State` enum (Closed/Open/HalfOpen); `Config` |
| Composition | Multiple Breakers (one per backend/service); each independent state |
| Replacement | Any `Breaker` impl swaps in |
| Extension | Pro adds distributed-state breakers (shared via Redis); custom failure predicates |
| Runtime binding | App composition: `breaker := circuitbreaker.New(cfg); breaker.Do(ctx, callBackend)` |
| Evidence | Tests cover all state transitions + timeout-based recovery |

### Public API

```go
package circuitbreaker

// State identifies the breaker's current state.
type State int

const (
    StateClosed   State = iota // requests flow through normally
    StateOpen                  // requests short-circuit with ErrOpen
    StateHalfOpen              // limited probe requests allowed
)

func (s State) String() string

// ErrOpen is returned by Do when the breaker is open.
var ErrOpen = errors.New("circuitbreaker: open")

// Config configures a Breaker.
type Config struct {
    // FailureThreshold is the number of consecutive failures that trip the breaker.
    FailureThreshold int           // default 5
    // OpenTimeout is how long the breaker stays open before transitioning to half-open.
    OpenTimeout time.Duration      // default 30s
    // HalfOpenMaxProbes is the number of probe requests allowed in half-open.
    HalfOpenMaxProbes int          // default 1
    // IsFailure decides which errors count as failures. Default: any non-nil error.
    IsFailure func(err error) bool
    // Clock allows test injection. Default: time.Now.
    Clock func() time.Time
}

func DefaultConfig() Config

// Breaker is the circuit breaker contract.
type Breaker interface {
    Do(ctx context.Context, op func(ctx context.Context) error) error
    State() State
}

// New returns a Breaker with the given Config.
func New(cfg Config) (Breaker, error)
```

### Tests
- TestStateString
- TestDefaultConfigIsValid
- TestNewRejectsZeroFailureThreshold
- TestClosedBreakerAllowsCalls
- TestFailuresTripBreaker
- TestOpenBreakerReturnsErrOpen
- TestHalfOpenAfterTimeout
- TestHalfOpenSuccessClosesBreaker
- TestHalfOpenFailureReopens
- TestSuccessResetsFailureCount (consecutive failures count resets on success)
- TestCustomIsFailurePredicate
- TestBreakerConcurrentSafe (with -race)

### Files
```
pk-core/pkg/resilience/circuitbreaker/
├── doc.go
├── circuitbreaker.go   # Config, State, Breaker, New
└── circuitbreaker_test.go
```

### Commit
`feat(pk-core/resilience/circuitbreaker): closed/open/half-open state machine`

---

## Block 3: `bulkhead`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/resilience/bulkhead` |
| Boundary | Semaphore counter internal; only `Bulkhead` interface + constructor exported |
| Contract | `Bulkhead.Do(ctx, op)` |
| Composition | Multiple Bulkheads (different concurrency limits per backend) |
| Replacement | Any `Bulkhead` impl swaps in |
| Extension | Pro adds queue-aware bulkheads, dynamic-capacity bulkheads |
| Runtime binding | App composition |
| Evidence | Concurrent test verifies semaphore limits |

### Public API

```go
package bulkhead

// ErrFull is returned by Do when the bulkhead has no available slot AND
// MaxQueue is exceeded.
var ErrFull = errors.New("bulkhead: full")

// Config configures a Bulkhead.
type Config struct {
    // MaxConcurrent is the maximum number of in-flight operations. Required > 0.
    MaxConcurrent int
    // MaxQueue is the maximum number of operations waiting for a slot. 0 = no queue;
    // overflow returns ErrFull immediately.
    MaxQueue int
    // AcquireTimeout is the max wait for a slot when queuing. 0 = wait forever (until ctx done).
    AcquireTimeout time.Duration
}

// Bulkhead limits concurrent operations.
type Bulkhead interface {
    Do(ctx context.Context, op func(ctx context.Context) error) error
    InFlight() int
}

// New returns a Bulkhead with the given Config.
func New(cfg Config) (Bulkhead, error)
```

### Tests
- TestNewRejectsZeroMaxConcurrent
- TestNewAcceptsZeroMaxQueue
- TestDoAllowsUnderLimit
- TestDoBlocksOverLimit (concurrent N+1th call waits)
- TestDoReturnsErrFullOverQueue
- TestAcquireTimeoutRespectsContextCancellation
- TestInFlightTracksCorrectly
- TestBulkheadConcurrentSafe (with -race; spawn 100 ops, verify at most MaxConcurrent simultaneous)

### Files
```
pk-core/pkg/resilience/bulkhead/
├── doc.go
├── bulkhead.go
└── bulkhead_test.go
```

### Commit
`feat(pk-core/resilience/bulkhead): concurrency-limiting semaphore`

In this LAST commit, also update `pkg/architecture/oss_deps_test.go` to append:
```go
"github.com/septagon-oss/pk-core/pkg/resilience",
"github.com/septagon-oss/pk-core/pkg/resilience/retry",
"github.com/septagon-oss/pk-core/pkg/resilience/circuitbreaker",
"github.com/septagon-oss/pk-core/pkg/resilience/bulkhead",
```

Also create `pk-core/pkg/resilience/doc.go` (package overview) in the first commit.

---

## Acceptance criteria

- `make verify` green (fitness now includes resilience packages with -race)
- 3 new sub-packages + parent doc.go
- C-14/ADR-0029 headers everywhere
- External test packages
- Zero new external deps
- ≥30 leaf tests across the 3 packages
- 3 commits with exact subjects
- Workspace OSS validators all green
- No septagon-dev imports
- NO `Co-Authored-By` trailers

## Chain composition proof

In `retry_test.go` add a brief integration test: wrap a call with retry → circuitbreaker → success. Demonstrates the three primitives compose cleanly when used together.
