# Backend-Kit Bridge PoC — observability/logger

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development.

**Goal:** Prove that `platformkit-backend-kit` can be refactored to **consume** `pk-core` (rather than maintain a parallel implementation) by bridging ONE package end-to-end: `observability/logger`. This is the smoke test for the open-core extension model on already-shipped pk-core packages. If this bridge works, the same pattern scales to the other 15 packages (metrics, tracing, health, guardrail, plus 11 security + 3 resilience).

**The bar (user-explicit):** Pro extends OSS. Backend-kit must demonstrably consume pk-core internally — not just call it as a peer library. The bridge proves the Composable contract holds across the boundary.

**Non-goals for this PoC:**
- Migrating the 575 importer files to use `pk-core/pkg/observability/logger` directly
- Bridging the other 4 observability packages
- Touching `platformkit-shared/observability` (will be addressed in v0.1.0 unification)

---

## Architecture: how the bridge works

```
platformkit-shared/observability.Logger     (legacy interface, 575 callers depend on it)
    │
    │   has: Debug/Info/Warn/Error/Fatal + WithFields(Fields)
    │
    ▼
platformkit-backend-kit/observability/logger
    │
    │   Currently: standalone implementations
    │
    │   After bridge:
    │     - Keeps the same public API for backwards compat
    │     - Default implementation is `pkCoreAdapter` which embeds
    │       pk-core/pkg/observability/logger.Logger and ADDS Fatal +
    │       WithFields by translating Fields ↔ slog-style args
    │     - Pro adapters (Datadog, Honeycomb, etc.) continue to
    │       implement the legacy shared.Logger interface directly
    │
    ▼
pk-core/pkg/observability/logger.Logger     (OSS contract)
    │
    │   has: Debug/Info/Warn/Error + With(args ...any) + Enabled(ctx, level)
    │
    └─ pkg/observability/logger.NewSlog(handler, extractors...)
```

### What the bridge changes

1. **Add a new file** `platformkit-backend-kit/observability/logger/oss_adapter.go`:
   - Defines `pkCoreAdapter` struct wrapping `*osslogger.Logger`
   - Implements the full `shared.Logger` interface (Debug/Info/Warn/Error/Fatal/WithFields) by translating to OSS Logger methods
   - `Fatal` is implemented as `Error(...)` followed by `os.Exit(1)` (the OSS contract intentionally doesn't have Fatal; this is the bridge's responsibility)
   - `WithFields(fields)` translates the `Fields` map into slog-style args and calls `osslogger.With(args...)`
   - Exposes `FromOSS(osslogger.Logger) shared.Logger` and `ToOSS(shared.Logger) osslogger.Logger` boundary helpers

2. **Update** `platformkit-backend-kit/observability/logger/logger.go`:
   - The default logger constructor returns a `pkCoreAdapter` over a real OSS slog logger
   - Existing call sites continue to work because the returned type satisfies `shared.Logger`

3. **Add** `replace github.com/septagon-oss/pk-core => ../septagon-oss-workspace/pk-core` to `platformkit-backend-kit/go.mod`

4. **Add tests** in `platformkit-backend-kit/observability/logger/oss_adapter_test.go`:
   - `TestPkCoreAdapterSatisfiesSharedLogger` (compile-time check)
   - `TestPkCoreAdapterEmitsViaOSSBackend` (build a buffer-backed OSS slog logger; wrap with adapter; call adapter.Info(...); assert record appears in buffer)
   - `TestPkCoreAdapterFatalCallsExit` (use a hook or subprocess test to verify Fatal exits with status 1)
   - `TestWithFieldsTranslatesToSlogArgs` (call adapter.WithFields(Fields{"k":"v"}); the child logger's emitted record contains "k":"v")
   - `TestFromOSSToOSSRoundTrip` (boundary conversion stability)

5. **Verify**:
   - `cd platformkit-backend-kit && go test ./observability/logger/...` — green
   - `cd platformkit-backend-kit && go build ./...` — entire module builds (proves the 575 importers still compile)

---

## File-by-file directive

### `platformkit-backend-kit/observability/logger/oss_adapter.go` (NEW)

```go
// Package logger — oss_adapter.go bridges the legacy shared.Logger interface
// to pk-core's Logger contract. Adapter callers continue to depend on the
// shared.Logger surface (Debug/Info/Warn/Error/Fatal/WithFields); the
// adapter delegates everything except Fatal to pk-core, and implements
// Fatal locally as Error + os.Exit(1) because the OSS contract
// intentionally does not include Fatal (modules should not call os.Exit
// from library code).
//
// This file is the proof point that backend-kit consumes pk-core
// rather than maintaining a parallel logger implementation.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package logger

import (
	"context"
	"log/slog"
	"os"

	osslogger "github.com/septagon-oss/pk-core/pkg/observability/logger"
	"github.com/septagon-dev/platformkit-shared/observability"
)

// pkCoreAdapter wraps an OSS logger.Logger so it satisfies the legacy
// shared.Logger interface (which carries Fatal and WithFields).
type pkCoreAdapter struct {
	oss osslogger.Logger
}

// FromOSS wraps an OSS logger.Logger as a shared.Logger.
func FromOSS(l osslogger.Logger) observability.Logger {
	if l == nil {
		l = osslogger.Noop()
	}
	return &pkCoreAdapter{oss: l}
}

// ToOSS extracts the underlying OSS logger.Logger if l is a pkCoreAdapter,
// otherwise wraps l in an OSS adapter that delegates back to its
// Debug/Info/Warn/Error methods.
func ToOSS(l observability.Logger) osslogger.Logger {
	if l == nil {
		return osslogger.Noop()
	}
	if a, ok := l.(*pkCoreAdapter); ok {
		return a.oss
	}
	return &sharedToOSSAdapter{shared: l}
}

func (a *pkCoreAdapter) Debug(ctx context.Context, msg string, args ...any) {
	a.oss.Debug(ctx, msg, args...)
}
func (a *pkCoreAdapter) Info(ctx context.Context, msg string, args ...any) {
	a.oss.Info(ctx, msg, args...)
}
func (a *pkCoreAdapter) Warn(ctx context.Context, msg string, args ...any) {
	a.oss.Warn(ctx, msg, args...)
}
func (a *pkCoreAdapter) Error(ctx context.Context, msg string, args ...any) {
	a.oss.Error(ctx, msg, args...)
}

// Fatal logs at Error level then exits with status 1. The pk-core OSS
// Logger contract intentionally lacks Fatal; this adapter provides Fatal
// at the backend-kit boundary so legacy callers (575 importers) continue
// to work. New code SHOULD avoid Fatal in library packages.
func (a *pkCoreAdapter) Fatal(ctx context.Context, msg string, args ...any) {
	a.oss.Error(ctx, msg, args...)
	exitFunc(1)
}

// WithFields returns a child adapter whose log records inherit fields.
// Fields are translated into slog-style alternating key/value args.
func (a *pkCoreAdapter) WithFields(fields observability.Fields) observability.Logger {
	if len(fields) == 0 {
		return a
	}
	args := make([]any, 0, len(fields)*2)
	for k, v := range fields {
		args = append(args, k, v)
	}
	return &pkCoreAdapter{oss: a.oss.With(args...)}
}

// sharedToOSSAdapter wraps a legacy shared.Logger as an OSS logger.Logger.
// Loses Fatal and WithFields semantics on the OSS side.
type sharedToOSSAdapter struct {
	shared observability.Logger
}

func (a *sharedToOSSAdapter) Debug(ctx context.Context, msg string, args ...any) {
	a.shared.Debug(ctx, msg, args...)
}
func (a *sharedToOSSAdapter) Info(ctx context.Context, msg string, args ...any) {
	a.shared.Info(ctx, msg, args...)
}
func (a *sharedToOSSAdapter) Warn(ctx context.Context, msg string, args ...any) {
	a.shared.Warn(ctx, msg, args...)
}
func (a *sharedToOSSAdapter) Error(ctx context.Context, msg string, args ...any) {
	a.shared.Error(ctx, msg, args...)
}
func (a *sharedToOSSAdapter) With(args ...any) osslogger.Logger {
	return &sharedToOSSAdapter{shared: a.shared.WithFields(observability.ArgsToFields(args...))}
}
func (a *sharedToOSSAdapter) Enabled(ctx context.Context, level slog.Level) bool {
	// Legacy shared.Logger has no Enabled equivalent; assume always enabled.
	return true
}

// exitFunc is a test seam for Fatal. Tests override it to avoid exiting.
var exitFunc = os.Exit
```

### `platformkit-backend-kit/observability/logger/oss_adapter_test.go` (NEW)

```go
package logger

// oss_adapter_test.go validates the backend-kit ↔ pk-core logger bridge:
// adapter satisfies shared.Logger, emits through the OSS backend, translates
// Fatal/WithFields correctly, and round-trips through the boundary.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"strings"
	"testing"

	osslogger "github.com/septagon-oss/pk-core/pkg/observability/logger"
	"github.com/septagon-dev/platformkit-shared/observability"
)

// Compile-time: pkCoreAdapter satisfies the legacy shared.Logger.
var _ observability.Logger = (*pkCoreAdapter)(nil)

func TestPkCoreAdapterEmitsViaOSSBackend(t *testing.T) {
	var buf bytes.Buffer
	oss := osslogger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	adapter := FromOSS(oss)

	adapter.Info(context.Background(), "test message", "k", "v")

	var record map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buf.Bytes()), &record); err != nil {
		t.Fatalf("unmarshal: %v; buf=%q", err, buf.String())
	}
	if record["msg"] != "test message" {
		t.Fatalf("msg = %v", record["msg"])
	}
	if record["k"] != "v" {
		t.Fatalf("k = %v", record["k"])
	}
}

func TestPkCoreAdapterFatalCallsExit(t *testing.T) {
	prev := exitFunc
	defer func() { exitFunc = prev }()
	exited := false
	exitFunc = func(code int) {
		if code != 1 {
			t.Fatalf("exit code = %d, want 1", code)
		}
		exited = true
	}

	var buf bytes.Buffer
	oss := osslogger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	adapter := FromOSS(oss)
	adapter.Fatal(context.Background(), "fatal", "reason", "test")

	if !exited {
		t.Fatal("expected exitFunc to have been called")
	}
	if !strings.Contains(buf.String(), "fatal") {
		t.Fatalf("Fatal should write at Error level before exit: %s", buf.String())
	}
}

func TestWithFieldsTranslatesToSlogArgs(t *testing.T) {
	var buf bytes.Buffer
	oss := osslogger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	adapter := FromOSS(oss)

	child := adapter.WithFields(observability.Fields{"module": "user", "tenant": "t1"})
	child.Info(context.Background(), "did the thing")

	s := buf.String()
	if !strings.Contains(s, `"module":"user"`) {
		t.Fatalf("missing module field: %s", s)
	}
	if !strings.Contains(s, `"tenant":"t1"`) {
		t.Fatalf("missing tenant field: %s", s)
	}
}

func TestFromOSSToOSSRoundTrip(t *testing.T) {
	oss := osslogger.Noop()
	shared := FromOSS(oss)
	again := ToOSS(shared)
	// Concrete identity preserved: ToOSS extracts the underlying OSS logger.
	if again != oss {
		t.Fatalf("round-trip lost identity: got %v, want %v", again, oss)
	}
}

func TestFromOSSNilWrapsNoop(t *testing.T) {
	adapter := FromOSS(nil)
	// Must not panic.
	adapter.Info(context.Background(), "ping")
}

func TestToOSSNilWrapsNoop(t *testing.T) {
	oss := ToOSS(nil)
	oss.Info(context.Background(), "ping")
}

func TestSharedToOSSAdapterWith(t *testing.T) {
	var buf bytes.Buffer
	oss := osslogger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	// Wrap an OSS logger as shared, then back as OSS — exercise the
	// sharedToOSSAdapter (not the pass-through) by going shared first.
	innerShared := FromOSS(oss)
	wrappedAsOSS := &sharedToOSSAdapter{shared: innerShared}
	child := wrappedAsOSS.With("module", "demo")
	child.Info(context.Background(), "hello")

	if !strings.Contains(buf.String(), `"module":"demo"`) {
		t.Fatalf("sharedToOSSAdapter.With did not propagate field: %s", buf.String())
	}
}
```

### `platformkit-backend-kit/go.mod`

Add (next to existing replace directives):

```
replace github.com/septagon-oss/pk-core => ../septagon-oss-workspace/pk-core
```

And add to `require`:
```
require github.com/septagon-oss/pk-core v0.0.0
```

Run `go mod tidy` after.

### `platformkit-backend-kit/observability/logger/logger.go`

Locate the default logger constructor (likely `New()` or similar). Replace its body to construct a `pkCoreAdapter` over a `osslogger.NewSlog(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))`. Keep the function signature unchanged so callers don't see a difference.

Locate any `LoggingConfig` builder that constructs slog handlers — keep those, just funnel the constructed handler into `osslogger.NewSlog(handler)` and then `FromOSS(ossLogger)`.

---

## Acceptance criteria

1. `platformkit-backend-kit/go.mod` contains the new `replace` + `require` for `pk-core`
2. `cd platformkit-backend-kit && go build ./...` succeeds — the 575 importers still compile
3. `cd platformkit-backend-kit && go test ./observability/logger/...` — green (existing tests + new adapter tests)
4. `cd platformkit-backend-kit && go test ./...` — green (all existing tests still pass)
5. No `Co-Authored-By` trailers
6. Atomic commit: `feat(platformkit-backend-kit/observability/logger): bridge to pk-core via adapter`

## What this proves

If acceptance passes:
- backend-kit imports and consumes pk-core internally ✅
- The 575 callers don't need migration — the bridge preserves their API ✅
- The pattern scales: same approach works for metrics/tracing/health/guardrail, then security, then resilience
- The Composable contract holds across the boundary

If acceptance fails:
- The pk-core Logger contract is wrong somewhere; we fix it before continuing other bridges
- This is the early warning system Option C is designed to surface
