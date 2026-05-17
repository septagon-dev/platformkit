# pk-core/pkg/observability Implementation Plan (Phase A.1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land `pk-core/pkg/observability` with five sub-packages — logger, metrics, tracing, health, guardrail — each exposing a public interface, a stdlib-only default implementation, and contract tests, so that downstream pk-core extractions and pk-modules can depend on a stable observability vocabulary.

**Architecture:** Each sub-package owns one observability concern. Public API is `interface` + helper functions; default implementations use only the Go stdlib (`log/slog`, `expvar`, `sync`, `context`). External adapters (OpenTelemetry, Prometheus) are intentionally deferred to v0.0.1 to keep `pk-core` dependency-free at v0.0.0. The guardrail sub-package is a near-verbatim port from `platformkit-backend-kit/observability/guardrail` because the existing API is already minimal and correct; everything else is rewritten clean against the OSS `Logger` interface.

**Tech Stack:** Go 1.22 stdlib only. No external dependencies introduced. Adheres to the existing pk-core C-14/ADR-0029 file-purpose-header convention.

**Source reference:** `septagon-dev/platformkit-backend-kit/observability/{logger,metrics,tracing,health,guardrail}` (read-only — used for behavior reference and test ideas; OSS implementations are rewritten clean against the simplified interfaces).

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`

---

## File Structure

```
pk-core/pkg/observability/
├── doc.go                                # package overview, C-14 header
├── logger/
│   ├── doc.go
│   ├── logger.go                         # Logger interface + Level + helper funcs
│   ├── noop.go                           # noop default
│   ├── slog.go                           # *slog.Logger-backed default
│   ├── slog_test.go
│   └── logger_test.go                    # contract test (interface conformance)
├── metrics/
│   ├── doc.go
│   ├── metrics.go                        # Metrics, Counter, Gauge, Histogram interfaces
│   ├── noop.go                           # noop default
│   ├── expvar.go                         # stdlib expvar-backed default
│   ├── expvar_test.go
│   └── metrics_test.go                   # contract test
├── tracing/
│   ├── doc.go
│   ├── tracing.go                        # Tracer, Span interfaces
│   ├── noop.go                           # noop default
│   └── tracing_test.go                   # contract test
├── health/
│   ├── doc.go
│   ├── health.go                         # Registrar, Checker, Result, Status, HTTPHandler
│   ├── registry.go                       # in-memory default Registrar
│   └── health_test.go
└── guardrail/
    ├── doc.go
    ├── guardrail.go                      # ported Warn helpers
    └── guardrail_test.go
```

Each file has a C-14 purpose header comment in the first 30 lines.

---

## Task 1: Create observability package skeleton

**Files:**
- Create: `septagon-oss-workspace/pk-core/pkg/observability/doc.go`

- [ ] **Step 1: Create the directory and doc.go**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability
```

Write `septagon-oss-workspace/pk-core/pkg/observability/doc.go`:

```go
// Package observability defines PlatformKit's provider-neutral observability
// contracts: logger, metrics, tracing, health, and guardrail.
//
// Sub-packages own one concern each and ship stdlib-only default
// implementations. External adapters (OpenTelemetry, Prometheus, Datadog)
// belong in downstream/Pro packages so the OSS kernel stays dependency-free.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package observability
```

- [ ] **Step 2: Verify it compiles**

Run from `septagon-oss-workspace/pk-core`:
```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go build ./pkg/observability/...
```
Expected: success, no output (the package has no .go files with code yet, just doc.go — that compiles fine).

- [ ] **Step 3: Commit**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
git add pkg/observability/doc.go
git commit -m "feat(pk-core): scaffold observability package"
```

---

## Task 2: Logger — contract test (failing)

**Files:**
- Create: `pk-core/pkg/observability/logger/logger_test.go`

- [ ] **Step 1: Create the logger sub-package directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability/logger
```

- [ ] **Step 2: Write the failing contract test**

Write `pk-core/pkg/observability/logger/logger_test.go`:

```go
package logger_test

// logger_test.go validates the Logger contract: levels record, With() returns
// a child that inherits attrs, Enabled() honors the threshold, and Noop never
// panics under any input.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"log/slog"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/logger"
)

func TestNoopAcceptsAllLevels(t *testing.T) {
	t.Parallel()
	l := logger.Noop()
	ctx := context.Background()
	l.Debug(ctx, "d", "k", "v")
	l.Info(ctx, "i")
	l.Warn(ctx, "w")
	l.Error(ctx, "e", "err", "boom")
}

func TestWithReturnsChildLogger(t *testing.T) {
	t.Parallel()
	l := logger.Noop()
	child := l.With("module", "user")
	if child == nil {
		t.Fatal("With() returned nil")
	}
}

func TestEnabledHonorsLevel(t *testing.T) {
	t.Parallel()
	l := logger.Noop()
	ctx := context.Background()
	// Noop reports disabled for everything; slog-backed reports honors its handler.
	if l.Enabled(ctx, slog.LevelError) {
		t.Fatal("Noop.Enabled should return false")
	}
}
```

- [ ] **Step 3: Run test, see it fail**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/logger/... 2>&1 | tail -15
```
Expected: build failure with "no Go files in pk-core/pkg/observability/logger" or "logger.Noop undefined".

---

## Task 3: Logger — interface and noop default

**Files:**
- Create: `pk-core/pkg/observability/logger/logger.go`
- Create: `pk-core/pkg/observability/logger/noop.go`

- [ ] **Step 1: Write the Logger interface**

Write `pk-core/pkg/observability/logger/logger.go`:

```go
// Package logger defines PlatformKit's structured logger interface.
//
// logger.go owns the public Logger contract: level-aware structured logging
// with parent/child relationships and context propagation.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package logger

import (
	"context"
	"log/slog"
)

// Logger is the provider-neutral structured logger contract.
//
// Implementations must accept any slog-compatible attr arguments (alternating
// key/value pairs or pre-built slog.Attr values). Implementations must be safe
// for concurrent use.
type Logger interface {
	Debug(ctx context.Context, msg string, args ...any)
	Info(ctx context.Context, msg string, args ...any)
	Warn(ctx context.Context, msg string, args ...any)
	Error(ctx context.Context, msg string, args ...any)

	// With returns a child Logger that inherits the given attrs on every record.
	With(args ...any) Logger

	// Enabled reports whether the Logger will emit at the given level.
	// Implementations may use this to short-circuit expensive arg construction.
	Enabled(ctx context.Context, level slog.Level) bool
}
```

- [ ] **Step 2: Write the Noop implementation**

Write `pk-core/pkg/observability/logger/noop.go`:

```go
package logger

// noop.go provides a zero-allocation, always-disabled Logger for tests and
// callers that intentionally want logging off.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"log/slog"
)

type noopLogger struct{}

// Noop returns a Logger that discards every record. Safe for concurrent use.
func Noop() Logger { return noopLogger{} }

func (noopLogger) Debug(context.Context, string, ...any)         {}
func (noopLogger) Info(context.Context, string, ...any)          {}
func (noopLogger) Warn(context.Context, string, ...any)          {}
func (noopLogger) Error(context.Context, string, ...any)         {}
func (noopLogger) With(...any) Logger                            { return noopLogger{} }
func (noopLogger) Enabled(context.Context, slog.Level) bool      { return false }
```

- [ ] **Step 3: Run test, see it pass**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/logger/... -run '^Test(Noop|With|Enabled)' -v
```
Expected: 3 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add pkg/observability/logger/{logger.go,noop.go,logger_test.go}
git commit -m "feat(pk-core/observability): logger interface + noop default"
```

---

## Task 4: Logger — slog-backed default implementation

**Files:**
- Create: `pk-core/pkg/observability/logger/slog.go`
- Create: `pk-core/pkg/observability/logger/slog_test.go`

- [ ] **Step 1: Write the slog test**

Write `pk-core/pkg/observability/logger/slog_test.go`:

```go
package logger_test

// slog_test.go validates the slog-backed Logger: records appear in the buffer,
// attrs propagate via With(), and the level threshold is enforced.
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

	"github.com/septagon-oss/pk-core/pkg/observability/logger"
)

func TestSlogLoggerEmitsInfo(t *testing.T) {
	t.Parallel()
	var buf bytes.Buffer
	l := logger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	l.Info(context.Background(), "hello", "k", "v")

	var record map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buf.Bytes()), &record); err != nil {
		t.Fatalf("unmarshal: %v; buf=%q", err, buf.String())
	}
	if record["msg"] != "hello" {
		t.Fatalf("msg = %v", record["msg"])
	}
	if record["k"] != "v" {
		t.Fatalf("k = %v", record["k"])
	}
}

func TestSlogLoggerWithInheritsAttrs(t *testing.T) {
	t.Parallel()
	var buf bytes.Buffer
	l := logger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug}))
	child := l.With("module", "user")
	child.Info(context.Background(), "did the thing")

	if !strings.Contains(buf.String(), `"module":"user"`) {
		t.Fatalf("missing inherited attr: %s", buf.String())
	}
}

func TestSlogLoggerHonorsLevel(t *testing.T) {
	t.Parallel()
	var buf bytes.Buffer
	l := logger.NewSlog(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelWarn}))
	l.Debug(context.Background(), "should not appear")
	if buf.Len() != 0 {
		t.Fatalf("expected zero output, got %q", buf.String())
	}
}
```

- [ ] **Step 2: Run test, see it fail**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/logger/... -run TestSlog -v 2>&1 | tail -10
```
Expected: build failure "logger.NewSlog undefined".

- [ ] **Step 3: Implement the slog adapter**

Write `pk-core/pkg/observability/logger/slog.go`:

```go
package logger

// slog.go wraps *slog.Logger to satisfy the OSS Logger contract using only the
// standard library.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"log/slog"
)

type slogLogger struct {
	inner *slog.Logger
}

// NewSlog returns a Logger backed by *slog.Logger.
// Passing a nil handler is invalid; callers must supply a handler explicitly
// to make the destination and level threshold a deliberate choice.
func NewSlog(handler slog.Handler) Logger {
	if handler == nil {
		panic("logger.NewSlog: handler must not be nil")
	}
	return &slogLogger{inner: slog.New(handler)}
}

// NewSlogFromLogger adapts an already-constructed *slog.Logger.
func NewSlogFromLogger(l *slog.Logger) Logger {
	if l == nil {
		panic("logger.NewSlogFromLogger: l must not be nil")
	}
	return &slogLogger{inner: l}
}

func (s *slogLogger) Debug(ctx context.Context, msg string, args ...any) {
	s.inner.DebugContext(ctx, msg, args...)
}
func (s *slogLogger) Info(ctx context.Context, msg string, args ...any) {
	s.inner.InfoContext(ctx, msg, args...)
}
func (s *slogLogger) Warn(ctx context.Context, msg string, args ...any) {
	s.inner.WarnContext(ctx, msg, args...)
}
func (s *slogLogger) Error(ctx context.Context, msg string, args ...any) {
	s.inner.ErrorContext(ctx, msg, args...)
}
func (s *slogLogger) With(args ...any) Logger {
	return &slogLogger{inner: s.inner.With(args...)}
}
func (s *slogLogger) Enabled(ctx context.Context, level slog.Level) bool {
	return s.inner.Enabled(ctx, level)
}
```

- [ ] **Step 4: Run test, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/logger/... -v
```
Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add pkg/observability/logger/{slog.go,slog_test.go}
git commit -m "feat(pk-core/observability/logger): slog-backed default implementation"
```

---

## Task 5: Logger — doc.go

**Files:**
- Create: `pk-core/pkg/observability/logger/doc.go`

- [ ] **Step 1: Write doc.go**

Write `pk-core/pkg/observability/logger/doc.go`:

```go
// Package logger defines the PlatformKit OSS structured logger contract.
//
// Usage:
//
//	import "log/slog"
//	import "github.com/septagon-oss/pk-core/pkg/observability/logger"
//
//	l := logger.NewSlog(slog.NewJSONHandler(os.Stderr, nil))
//	l.Info(ctx, "user signed in", "user_id", uid)
//
// For tests: logger.Noop().
//
// External adapters (OpenTelemetry, Datadog, Honeycomb) live in downstream
// packages; the OSS core depends only on the Go standard library.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package logger
```

- [ ] **Step 2: Verify build + tests still pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/logger/...
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go vet ./pkg/observability/logger/...
```
Expected: both green.

- [ ] **Step 3: Commit**

```bash
git add pkg/observability/logger/doc.go
git commit -m "docs(pk-core/observability/logger): package documentation"
```

---

## Task 6: Metrics — contract test (failing)

**Files:**
- Create: `pk-core/pkg/observability/metrics/metrics_test.go`

- [ ] **Step 1: Create directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability/metrics
```

- [ ] **Step 2: Write the failing test**

Write `pk-core/pkg/observability/metrics/metrics_test.go`:

```go
package metrics_test

// metrics_test.go validates the Metrics contract: Counter increments, Gauge
// sets, Histogram observes, and Noop never panics.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/metrics"
)

func TestNoopAcceptsAllOperations(t *testing.T) {
	t.Parallel()
	m := metrics.Noop()
	m.Counter("requests_total", "method", "GET").Add(1)
	m.Gauge("queue_depth").Set(42)
	m.Histogram("latency_ms").Observe(12.3)
}

func TestCounterRequiresNameNotEmpty(t *testing.T) {
	t.Parallel()
	defer func() {
		if recover() == nil {
			t.Fatal("expected panic on empty name")
		}
	}()
	metrics.Noop().Counter("")
}
```

- [ ] **Step 3: Run, see it fail**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/metrics/... 2>&1 | tail -10
```
Expected: build error "metrics.Noop undefined".

---

## Task 7: Metrics — interface + noop default

**Files:**
- Create: `pk-core/pkg/observability/metrics/metrics.go`
- Create: `pk-core/pkg/observability/metrics/noop.go`

- [ ] **Step 1: Write the interface**

Write `pk-core/pkg/observability/metrics/metrics.go`:

```go
// Package metrics defines PlatformKit's provider-neutral metrics interface.
//
// metrics.go owns the public Metrics contract and the three primitive types:
// Counter (monotonic add), Gauge (settable), Histogram (observable
// distribution).
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package metrics

// Metrics is the provider-neutral metrics contract. Implementations must be
// safe for concurrent use and must panic on empty metric names so misuse is
// caught at registration time, not runtime.
type Metrics interface {
	Counter(name string, labels ...string) Counter
	Gauge(name string, labels ...string) Gauge
	Histogram(name string, labels ...string) Histogram
}

// Counter is a monotonically-increasing scalar metric.
type Counter interface {
	Add(delta float64)
}

// Gauge is a settable scalar metric.
type Gauge interface {
	Set(value float64)
}

// Histogram observes value distributions.
type Histogram interface {
	Observe(value float64)
}
```

- [ ] **Step 2: Write the noop default**

Write `pk-core/pkg/observability/metrics/noop.go`:

```go
package metrics

// noop.go provides a zero-allocation Metrics for tests and disabled paths.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

type noopMetrics struct{}
type noopCounter struct{}
type noopGauge struct{}
type noopHistogram struct{}

// Noop returns a Metrics whose Counter/Gauge/Histogram operations are no-ops.
// Calls with empty names still panic so misuse is caught early.
func Noop() Metrics { return noopMetrics{} }

func (noopMetrics) Counter(name string, _ ...string) Counter {
	mustName(name)
	return noopCounter{}
}

func (noopMetrics) Gauge(name string, _ ...string) Gauge {
	mustName(name)
	return noopGauge{}
}

func (noopMetrics) Histogram(name string, _ ...string) Histogram {
	mustName(name)
	return noopHistogram{}
}

func (noopCounter) Add(float64)        {}
func (noopGauge) Set(float64)          {}
func (noopHistogram) Observe(float64)  {}

func mustName(name string) {
	if name == "" {
		panic("metrics: name must not be empty")
	}
}
```

- [ ] **Step 3: Run, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/metrics/... -v
```
Expected: 2 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add pkg/observability/metrics/{metrics.go,noop.go,metrics_test.go}
git commit -m "feat(pk-core/observability/metrics): Metrics interface + noop default"
```

---

## Task 8: Metrics — expvar default

**Files:**
- Create: `pk-core/pkg/observability/metrics/expvar.go`
- Create: `pk-core/pkg/observability/metrics/expvar_test.go`

- [ ] **Step 1: Write the expvar test**

Write `pk-core/pkg/observability/metrics/expvar_test.go`:

```go
package metrics_test

// expvar_test.go validates the expvar-backed Metrics: counters survive
// repeated lookups, values increment, and metric names are exported on the
// configured Map.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"expvar"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/metrics"
)

func TestExpvarCounterIncrements(t *testing.T) {
	t.Parallel()
	m := metrics.NewExpvar(new(expvar.Map).Init())
	c := m.Counter("requests_total")
	c.Add(1)
	c.Add(2)

	c2 := m.Counter("requests_total")
	c2.Add(1)

	// Both handles must point to the same underlying expvar.Float.
	if c == nil || c2 == nil {
		t.Fatal("counter handles must not be nil")
	}
}

func TestExpvarGaugeSets(t *testing.T) {
	t.Parallel()
	m := metrics.NewExpvar(new(expvar.Map).Init())
	g := m.Gauge("queue_depth")
	g.Set(7)
	g.Set(3)
}
```

- [ ] **Step 2: Run, see it fail**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/metrics/... -run TestExpvar -v 2>&1 | tail -10
```
Expected: build failure "metrics.NewExpvar undefined".

- [ ] **Step 3: Implement the expvar adapter**

Write `pk-core/pkg/observability/metrics/expvar.go`:

```go
package metrics

// expvar.go provides a stdlib expvar-backed Metrics implementation.
// Metric handles are cached by name on the configured *expvar.Map so repeated
// lookups return the same underlying expvar.Float. Histograms are recorded as
// running sums and counts under "<name>_sum" / "<name>_count" keys to avoid
// pulling in a histogram dependency.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"expvar"
	"sync"
)

type expvarMetrics struct {
	mu  sync.Mutex
	m   *expvar.Map
	cnt map[string]*expvar.Float
}

// NewExpvar returns a Metrics that records into the given expvar.Map.
// Callers typically pass expvar.NewMap("pk") at process start so the metrics
// surface at /debug/vars.
func NewExpvar(m *expvar.Map) Metrics {
	if m == nil {
		panic("metrics.NewExpvar: map must not be nil")
	}
	return &expvarMetrics{m: m, cnt: make(map[string]*expvar.Float)}
}

func (e *expvarMetrics) Counter(name string, _ ...string) Counter {
	mustName(name)
	return &expvarCounter{f: e.float(name)}
}

func (e *expvarMetrics) Gauge(name string, _ ...string) Gauge {
	mustName(name)
	return &expvarGauge{f: e.float(name)}
}

func (e *expvarMetrics) Histogram(name string, _ ...string) Histogram {
	mustName(name)
	return &expvarHistogram{
		sum:   e.float(name + "_sum"),
		count: e.float(name + "_count"),
	}
}

func (e *expvarMetrics) float(name string) *expvar.Float {
	e.mu.Lock()
	defer e.mu.Unlock()
	if f, ok := e.cnt[name]; ok {
		return f
	}
	f := new(expvar.Float)
	e.m.Set(name, f)
	e.cnt[name] = f
	return f
}

type expvarCounter struct{ f *expvar.Float }
type expvarGauge struct{ f *expvar.Float }
type expvarHistogram struct{ sum, count *expvar.Float }

func (c *expvarCounter) Add(delta float64) { c.f.Add(delta) }
func (g *expvarGauge) Set(value float64)   { g.f.Set(value) }
func (h *expvarHistogram) Observe(v float64) {
	h.sum.Add(v)
	h.count.Add(1)
}
```

- [ ] **Step 4: Run, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/metrics/... -v
```
Expected: 4 PASS lines.

- [ ] **Step 5: Commit**

```bash
git add pkg/observability/metrics/{expvar.go,expvar_test.go}
git commit -m "feat(pk-core/observability/metrics): expvar-backed default implementation"
```

---

## Task 9: Metrics — doc.go

**Files:**
- Create: `pk-core/pkg/observability/metrics/doc.go`

- [ ] **Step 1: Write doc.go**

```go
// Package metrics defines the PlatformKit OSS metrics contract.
//
// Three primitives — Counter, Gauge, Histogram — keyed by name and optional
// labels. The default implementations are Noop (for tests) and expvar (for
// /debug/vars). Prometheus, OpenTelemetry, and StatsD adapters live in
// downstream packages so the OSS kernel stays dependency-free.
//
// Usage:
//
//	import "expvar"
//	import "github.com/septagon-oss/pk-core/pkg/observability/metrics"
//
//	m := metrics.NewExpvar(expvar.NewMap("pk"))
//	requests := m.Counter("http_requests_total", "method", "GET")
//	requests.Add(1)
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package metrics
```

- [ ] **Step 2: Commit**

```bash
git add pkg/observability/metrics/doc.go
git commit -m "docs(pk-core/observability/metrics): package documentation"
```

---

## Task 10: Tracing — contract test (failing)

**Files:**
- Create: `pk-core/pkg/observability/tracing/tracing_test.go`

- [ ] **Step 1: Create the tracing sub-package directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability/tracing
```

- [ ] **Step 2: Write the failing test**

Write `pk-core/pkg/observability/tracing/tracing_test.go`:

```go
package tracing_test

// tracing_test.go validates the Tracer contract: Start returns a child
// context that carries the active span and a non-nil Span that can record
// attrs, set status, and End without panicking under Noop.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"errors"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/tracing"
)

func TestNoopStartReturnsUsableSpan(t *testing.T) {
	t.Parallel()
	tr := tracing.Noop()
	ctx, span := tr.Start(context.Background(), "op")
	if ctx == nil {
		t.Fatal("nil ctx")
	}
	if span == nil {
		t.Fatal("nil span")
	}
	span.SetAttr("k", "v")
	span.SetStatus(tracing.StatusError, "boom")
	span.RecordError(errors.New("x"))
	span.End()
}

func TestSpanFromContextDefaultsToNoop(t *testing.T) {
	t.Parallel()
	span := tracing.SpanFromContext(context.Background())
	if span == nil {
		t.Fatal("nil span")
	}
	span.End() // must not panic
}
```

- [ ] **Step 3: Run, see it fail**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/tracing/... 2>&1 | tail -10
```
Expected: build failure.

---

## Task 11: Tracing — interface + noop default

**Files:**
- Create: `pk-core/pkg/observability/tracing/tracing.go`
- Create: `pk-core/pkg/observability/tracing/noop.go`

- [ ] **Step 1: Write the interfaces**

Write `pk-core/pkg/observability/tracing/tracing.go`:

```go
// Package tracing defines PlatformKit's provider-neutral tracing contract.
//
// tracing.go owns the Tracer and Span interfaces and the context-key plumbing
// used to thread the active span through call chains.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package tracing

import "context"

// Tracer creates spans.
type Tracer interface {
	// Start begins a new span. The returned context carries the span so it
	// can be retrieved by SpanFromContext deeper in the call chain. Callers
	// must call span.End() exactly once, typically via defer.
	Start(ctx context.Context, name string, attrs ...Attr) (context.Context, Span)
}

// Span is an in-flight operation record.
type Span interface {
	SetAttr(key string, value any)
	SetStatus(code StatusCode, description string)
	RecordError(err error)
	End()
}

// Attr is an initial span attribute provided at Start.
type Attr struct {
	Key   string
	Value any
}

// StatusCode describes a span's final status.
type StatusCode int

const (
	StatusUnset StatusCode = iota
	StatusOK
	StatusError
)

type spanKey struct{}

// ContextWithSpan returns ctx with span attached. Used by Tracer
// implementations; rarely needed by callers.
func ContextWithSpan(ctx context.Context, span Span) context.Context {
	return context.WithValue(ctx, spanKey{}, span)
}

// SpanFromContext returns the active Span from ctx, or a noop Span if none.
// Never returns nil.
func SpanFromContext(ctx context.Context) Span {
	if v, ok := ctx.Value(spanKey{}).(Span); ok && v != nil {
		return v
	}
	return noopSpan{}
}
```

- [ ] **Step 2: Write the noop implementation**

Write `pk-core/pkg/observability/tracing/noop.go`:

```go
package tracing

// noop.go provides a zero-allocation Tracer for tests and disabled paths.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import "context"

type noopTracer struct{}
type noopSpan struct{}

// Noop returns a Tracer whose spans record nothing.
func Noop() Tracer { return noopTracer{} }

func (noopTracer) Start(ctx context.Context, _ string, _ ...Attr) (context.Context, Span) {
	span := noopSpan{}
	return ContextWithSpan(ctx, span), span
}

func (noopSpan) SetAttr(string, any)              {}
func (noopSpan) SetStatus(StatusCode, string)     {}
func (noopSpan) RecordError(error)                {}
func (noopSpan) End()                             {}
```

- [ ] **Step 3: Run, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/tracing/... -v
```
Expected: 2 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add pkg/observability/tracing/{tracing.go,noop.go,tracing_test.go}
git commit -m "feat(pk-core/observability/tracing): Tracer/Span interfaces + noop default"
```

---

## Task 12: Tracing — doc.go

**Files:**
- Create: `pk-core/pkg/observability/tracing/doc.go`

- [ ] **Step 1: Write doc.go**

```go
// Package tracing defines the PlatformKit OSS tracing contract.
//
// The default Tracer is Noop. OpenTelemetry, Jaeger, and Zipkin adapters live
// in downstream packages so the OSS kernel stays dependency-free; callers wire
// the adapter they want at composition time.
//
// Usage:
//
//	tr := tracing.Noop() // or an external adapter
//	ctx, span := tr.Start(ctx, "user.create",
//	    tracing.Attr{Key: "tenant_id", Value: tid})
//	defer span.End()
//	if err := doWork(ctx); err != nil {
//	    span.RecordError(err)
//	    span.SetStatus(tracing.StatusError, err.Error())
//	}
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package tracing
```

- [ ] **Step 2: Commit**

```bash
git add pkg/observability/tracing/doc.go
git commit -m "docs(pk-core/observability/tracing): package documentation"
```

---

## Task 13: Health — contract test (failing)

**Files:**
- Create: `pk-core/pkg/observability/health/health_test.go`

- [ ] **Step 1: Create directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability/health
```

- [ ] **Step 2: Write the failing test**

Write `pk-core/pkg/observability/health/health_test.go`:

```go
package health_test

// health_test.go validates the Registry: registering checkers, aggregating
// results, and producing a usable HTTP /healthz response.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/health"
)

func TestRegistryReportsAllChecks(t *testing.T) {
	t.Parallel()
	r := health.NewRegistry()
	r.Register("db", health.CheckerFunc(func(context.Context) error { return nil }))
	r.Register("cache", health.CheckerFunc(func(context.Context) error { return errors.New("down") }))

	res := r.Check(context.Background())
	if res.Status != health.StatusUnhealthy {
		t.Fatalf("Status = %v, want Unhealthy", res.Status)
	}
	if len(res.Components) != 2 {
		t.Fatalf("Components len = %d", len(res.Components))
	}
}

func TestRegistryHealthyWhenAllPass(t *testing.T) {
	t.Parallel()
	r := health.NewRegistry()
	r.Register("db", health.CheckerFunc(func(context.Context) error { return nil }))

	res := r.Check(context.Background())
	if res.Status != health.StatusHealthy {
		t.Fatalf("Status = %v, want Healthy", res.Status)
	}
}

func TestHTTPHandlerReturnsJSON(t *testing.T) {
	t.Parallel()
	r := health.NewRegistry()
	r.Register("db", health.CheckerFunc(func(context.Context) error { return nil }))

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()
	r.HTTPHandler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	if got := rec.Header().Get("Content-Type"); got != "application/json" {
		t.Fatalf("Content-Type = %q", got)
	}
}

func TestHTTPHandlerReturns503WhenUnhealthy(t *testing.T) {
	t.Parallel()
	r := health.NewRegistry()
	r.Register("db", health.CheckerFunc(func(context.Context) error { return errors.New("down") }))

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()
	r.HTTPHandler().ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}
}
```

- [ ] **Step 3: Run, see it fail**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/health/... 2>&1 | tail -10
```
Expected: build failure.

---

## Task 14: Health — types and Registry

**Files:**
- Create: `pk-core/pkg/observability/health/health.go`
- Create: `pk-core/pkg/observability/health/registry.go`

- [ ] **Step 1: Write the types**

Write `pk-core/pkg/observability/health/health.go`:

```go
// Package health defines PlatformKit's provider-neutral health-check contract.
//
// health.go owns the public types: Status, Checker, ComponentResult, Result,
// Registrar. The default implementation lives in registry.go.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package health

import (
	"context"
	"net/http"
)

// Status is the aggregate or per-component health state.
type Status string

const (
	StatusHealthy   Status = "healthy"
	StatusDegraded  Status = "degraded"
	StatusUnhealthy Status = "unhealthy"
)

// Checker is a single health probe.
type Checker interface {
	Check(ctx context.Context) error
}

// CheckerFunc adapts an ordinary function to the Checker interface.
type CheckerFunc func(ctx context.Context) error

// Check satisfies Checker.
func (f CheckerFunc) Check(ctx context.Context) error { return f(ctx) }

// ComponentResult is the outcome of a single component's health check.
type ComponentResult struct {
	Name   string `json:"name"`
	Status Status `json:"status"`
	Error  string `json:"error,omitempty"`
}

// Result is the aggregate health report.
type Result struct {
	Status     Status            `json:"status"`
	Components []ComponentResult `json:"components"`
}

// Registrar registers health checkers and produces aggregate reports.
type Registrar interface {
	Register(name string, checker Checker)
	Check(ctx context.Context) Result
	HTTPHandler() http.Handler
}
```

- [ ] **Step 2: Write the registry**

Write `pk-core/pkg/observability/health/registry.go`:

```go
package health

// registry.go provides the default in-memory Registrar. Component results are
// emitted in registration order for deterministic output. Aggregate status is
// the worst component status: any Unhealthy → Unhealthy; otherwise any
// Degraded → Degraded; otherwise Healthy.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"
)

type entry struct {
	name    string
	checker Checker
}

type registry struct {
	mu       sync.Mutex
	entries  []entry
	indexed  map[string]int
}

// NewRegistry returns a default in-memory Registrar.
func NewRegistry() Registrar {
	return &registry{indexed: make(map[string]int)}
}

func (r *registry) Register(name string, checker Checker) {
	if name == "" {
		panic("health: name must not be empty")
	}
	if checker == nil {
		panic("health: checker must not be nil")
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if i, ok := r.indexed[name]; ok {
		r.entries[i].checker = checker
		return
	}
	r.indexed[name] = len(r.entries)
	r.entries = append(r.entries, entry{name: name, checker: checker})
}

func (r *registry) Check(ctx context.Context) Result {
	r.mu.Lock()
	snapshot := make([]entry, len(r.entries))
	copy(snapshot, r.entries)
	r.mu.Unlock()

	out := Result{Status: StatusHealthy, Components: make([]ComponentResult, 0, len(snapshot))}
	for _, e := range snapshot {
		cr := ComponentResult{Name: e.name, Status: StatusHealthy}
		if err := e.checker.Check(ctx); err != nil {
			cr.Status = StatusUnhealthy
			cr.Error = err.Error()
			out.Status = StatusUnhealthy
		}
		out.Components = append(out.Components, cr)
	}
	return out
}

func (r *registry) HTTPHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		res := r.Check(req.Context())
		w.Header().Set("Content-Type", "application/json")
		if res.Status == StatusUnhealthy {
			w.WriteHeader(http.StatusServiceUnavailable)
		} else {
			w.WriteHeader(http.StatusOK)
		}
		_ = json.NewEncoder(w).Encode(res)
	})
}
```

- [ ] **Step 3: Run, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/health/... -v
```
Expected: 4 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add pkg/observability/health/{health.go,registry.go,health_test.go}
git commit -m "feat(pk-core/observability/health): registry + HTTP handler"
```

---

## Task 15: Health — doc.go

**Files:**
- Create: `pk-core/pkg/observability/health/doc.go`

- [ ] **Step 1: Write doc.go**

```go
// Package health defines the PlatformKit OSS health-check contract.
//
// Usage:
//
//	r := health.NewRegistry()
//	r.Register("db", health.CheckerFunc(func(ctx context.Context) error {
//	    return db.PingContext(ctx)
//	}))
//	http.Handle("/healthz", r.HTTPHandler())
//
// Aggregate status is the worst component status: any Unhealthy → Unhealthy;
// otherwise any Degraded → Degraded; otherwise Healthy.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package health
```

- [ ] **Step 2: Commit**

```bash
git add pkg/observability/health/doc.go
git commit -m "docs(pk-core/observability/health): package documentation"
```

---

## Task 16: Guardrail — port from source

**Files:**
- Create: `pk-core/pkg/observability/guardrail/guardrail.go`
- Create: `pk-core/pkg/observability/guardrail/guardrail_test.go`
- Create: `pk-core/pkg/observability/guardrail/doc.go`

- [ ] **Step 1: Create directory**

```bash
mkdir -p /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/observability/guardrail
```

- [ ] **Step 2: Write the OSS guardrail.go (adapted from source)**

The source uses its own `logger.ArgsToFields` helper and `logger.Fields` map type. The OSS Logger uses the slog-style `args ...any` alternating key/value model. The OSS guardrail mirrors the source's behavior but emits using the new Logger contract.

Write `pk-core/pkg/observability/guardrail/guardrail.go`:

```go
// Package guardrail standardizes warning logs emitted when PlatformKit takes a
// safe fallback or degraded execution path to keep the system operating.
//
// guardrail.go provides the Warn family of helpers; every emitted record
// carries a stable schema (Standard) and a Mode tag so monitoring systems can
// aggregate guardrail events independently of business logs.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package guardrail

import (
	"context"
	"strings"

	"github.com/septagon-oss/pk-core/pkg/observability/logger"
)

// Standard identifies the current PlatformKit guardrail-warning schema.
const Standard = "platformkit.guardrail.v1"

// Mode classifies why a guardrail warning was emitted.
type Mode string

const (
	ModeFallback         Mode = "fallback"
	ModeDegraded         Mode = "degraded"
	ModeUnsupported      Mode = "unsupported"
	ModeConfigurationGap Mode = "configuration_gap"
	ModeSoftEmpty        Mode = "soft_empty"
)

// Warn emits a standardized guardrail warning. extraArgs follow the slog
// alternating key/value convention.
func Warn(ctx context.Context, log logger.Logger, mode Mode, code, message string, extraArgs ...any) {
	if log == nil {
		return
	}
	args := []any{
		"guardrail", true,
		"guardrail_standard", Standard,
		"guardrail_mode", strings.TrimSpace(string(mode)),
	}
	if trimmed := strings.TrimSpace(code); trimmed != "" {
		args = append(args, "guardrail_code", trimmed)
	}
	args = append(args, extraArgs...)
	log.Warn(ctx, message, args...)
}

// WarnFallback is a shorthand for Warn with ModeFallback.
func WarnFallback(ctx context.Context, log logger.Logger, code, message string, extraArgs ...any) {
	Warn(ctx, log, ModeFallback, code, message, extraArgs...)
}

// WarnDegraded is a shorthand for Warn with ModeDegraded.
func WarnDegraded(ctx context.Context, log logger.Logger, code, message string, extraArgs ...any) {
	Warn(ctx, log, ModeDegraded, code, message, extraArgs...)
}

// WarnUnsupported is a shorthand for Warn with ModeUnsupported.
func WarnUnsupported(ctx context.Context, log logger.Logger, code, message string, extraArgs ...any) {
	Warn(ctx, log, ModeUnsupported, code, message, extraArgs...)
}

// WarnConfigurationGap is a shorthand for Warn with ModeConfigurationGap.
func WarnConfigurationGap(ctx context.Context, log logger.Logger, code, message string, extraArgs ...any) {
	Warn(ctx, log, ModeConfigurationGap, code, message, extraArgs...)
}

// WarnSoftEmpty is a shorthand for Warn with ModeSoftEmpty.
func WarnSoftEmpty(ctx context.Context, log logger.Logger, code, message string, extraArgs ...any) {
	Warn(ctx, log, ModeSoftEmpty, code, message, extraArgs...)
}
```

- [ ] **Step 3: Write the test**

Write `pk-core/pkg/observability/guardrail/guardrail_test.go`:

```go
package guardrail_test

// guardrail_test.go validates that every Warn call emits the standard
// metadata (guardrail=true, schema id, mode, code) plus the caller-supplied
// extra args, via a capturing Logger.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"context"
	"log/slog"
	"testing"

	"github.com/septagon-oss/pk-core/pkg/observability/guardrail"
	"github.com/septagon-oss/pk-core/pkg/observability/logger"
)

type captureLogger struct {
	gotMessage string
	gotArgs    []any
}

func (c *captureLogger) Debug(context.Context, string, ...any) {}
func (c *captureLogger) Info(context.Context, string, ...any)  {}
func (c *captureLogger) Error(context.Context, string, ...any) {}
func (c *captureLogger) With(...any) logger.Logger             { return c }
func (c *captureLogger) Enabled(context.Context, slog.Level) bool {
	return true
}
func (c *captureLogger) Warn(_ context.Context, message string, args ...any) {
	c.gotMessage = message
	c.gotArgs = args
}

func TestWarnFallbackAddsMetadata(t *testing.T) {
	t.Parallel()
	log := &captureLogger{}
	guardrail.WarnFallback(context.Background(), log,
		"auth.lookup_email_fallback",
		"falling back to email lookup",
		"tenant_id", "t1",
	)
	if log.gotMessage != "falling back to email lookup" {
		t.Fatalf("message = %q", log.gotMessage)
	}
	expected := []any{
		"guardrail", true,
		"guardrail_standard", guardrail.Standard,
		"guardrail_mode", string(guardrail.ModeFallback),
		"guardrail_code", "auth.lookup_email_fallback",
		"tenant_id", "t1",
	}
	if len(log.gotArgs) != len(expected) {
		t.Fatalf("len(args) = %d, want %d; args=%v", len(log.gotArgs), len(expected), log.gotArgs)
	}
	for i := range expected {
		if log.gotArgs[i] != expected[i] {
			t.Fatalf("args[%d] = %#v, want %#v", i, log.gotArgs[i], expected[i])
		}
	}
}

func TestWarnNilLoggerIsNoop(t *testing.T) {
	t.Parallel()
	// Must not panic.
	guardrail.Warn(context.Background(), nil, guardrail.ModeDegraded, "x", "msg")
}
```

- [ ] **Step 4: Write doc.go**

Write `pk-core/pkg/observability/guardrail/doc.go`:

```go
// Package guardrail emits standardized warnings when PlatformKit takes a
// fallback or degraded path. Monitoring systems can scrape on
// guardrail=true to surface "I kept working but something is wrong"
// events independent of regular warnings.
//
// Usage:
//
//	guardrail.WarnFallback(ctx, log,
//	    "user.lookup_email_fallback",
//	    "primary identity lookup failed; falling back to email match",
//	    "tenant_id", tid,
//	    "identity_id", iid,
//	)
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).
package guardrail
```

- [ ] **Step 5: Run, see it pass**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/observability/guardrail/... -v
```
Expected: 2 PASS lines.

- [ ] **Step 6: Commit**

```bash
git add pkg/observability/guardrail/
git commit -m "feat(pk-core/observability/guardrail): port Warn helpers"
```

---

## Task 17: Wire observability into pk-core Makefile fitness target

**Files:**
- Modify: `septagon-oss-workspace/pk-core/Makefile`

- [ ] **Step 1: Read the current Makefile**

```bash
cat /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/Makefile
```

Confirm the current `fitness` target reads:
```
fitness:
	$(GO_ENV) go test -race -count=1 ./pkg/architecture ./pkg/authz ./pkg/entity ./pkg/mutation ./pkg/registry
```

- [ ] **Step 2: Update the fitness target to include observability**

Replace the `fitness` target body to:

```
fitness:
	$(GO_ENV) go test -race -count=1 ./pkg/architecture ./pkg/authz ./pkg/entity ./pkg/mutation ./pkg/registry ./pkg/observability/...
```

- [ ] **Step 3: Run the fitness target**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
make fitness
```
Expected: every package shows PASS or `ok`.

- [ ] **Step 4: Commit**

```bash
git add Makefile
git commit -m "build(pk-core): include observability in fitness target"
```

---

## Task 18: Architecture fitness — assert observability has no external deps

**Files:**
- Modify: `septagon-oss-workspace/pk-core/pkg/architecture/architecture_test.go` (or add a new file in `pkg/architecture/`)

- [ ] **Step 1: Read current architecture tests**

```bash
ls /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/architecture/
cat /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/pkg/architecture/*.go 2>&1 | head -60
```

(If no existing test asserts dep boundaries, add a new file. If one exists with a similar pattern, append a sub-test.)

- [ ] **Step 2: Add the fitness test**

Write or extend `pk-core/pkg/architecture/observability_deps_test.go`:

```go
package architecture_test

// observability_deps_test.go enforces that the observability sub-packages do
// not import anything outside the Go standard library and pk-core itself.
// External adapters belong downstream; the OSS kernel stays dependency-free.
//
// ADR: ADR-0029 (file purpose declaration).
// Convention: C-14 (every Go file declares its purpose).

import (
	"go/build"
	"strings"
	"testing"
)

func TestObservabilityHasNoExternalDeps(t *testing.T) {
	t.Parallel()
	packages := []string{
		"github.com/septagon-oss/pk-core/pkg/observability",
		"github.com/septagon-oss/pk-core/pkg/observability/logger",
		"github.com/septagon-oss/pk-core/pkg/observability/metrics",
		"github.com/septagon-oss/pk-core/pkg/observability/tracing",
		"github.com/septagon-oss/pk-core/pkg/observability/health",
		"github.com/septagon-oss/pk-core/pkg/observability/guardrail",
	}
	for _, p := range packages {
		pkg, err := build.Default.Import(p, "", 0)
		if err != nil {
			t.Fatalf("import %s: %v", p, err)
		}
		for _, imp := range pkg.Imports {
			if strings.HasPrefix(imp, "github.com/septagon-oss/pk-core") {
				continue
			}
			if isStdLib(imp) {
				continue
			}
			t.Errorf("%s imports forbidden external dependency %q", p, imp)
		}
	}
}

func isStdLib(importPath string) bool {
	// Standard library packages have no dot in their first path segment.
	first := importPath
	if idx := strings.Index(importPath, "/"); idx >= 0 {
		first = importPath[:idx]
	}
	return !strings.Contains(first, ".")
}
```

- [ ] **Step 3: Run the test**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go test ./pkg/architecture/... -run TestObservabilityHasNoExternalDeps -v
```
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add pkg/architecture/observability_deps_test.go
git commit -m "test(pk-core/architecture): observability has no external deps"
```

---

## Task 19: Final verification

- [ ] **Step 1: Run the full pk-core verify target**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
make verify
```
Expected: `test`, `vet`, `staticcheck`, `fitness` all green.

- [ ] **Step 2: Run go mod tidy and confirm no new deps were introduced**

```bash
GOWORK=off GOCACHE=$(pwd)/.tmp-go-cache go mod tidy
git diff go.mod go.sum
```
Expected: no diff. (If a diff appears, an external import sneaked in — revert it.)

- [ ] **Step 3: Run the workspace-level OSS validators**

```bash
cd /home/jplr/gitrepos/septagon-dev/platformkit
make audit-oss
make validate-oss-split
make validate-open-core-workspace
```
Expected: all three pass with their existing summary lines.

- [ ] **Step 4: Sanity-grep for forbidden private imports**

```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core
grep -rn 'septagon-dev' --include='*.go' pkg/observability/ || echo "no septagon-dev imports — good"
```
Expected: `no septagon-dev imports — good`.

- [ ] **Step 5: If any go.mod changes were needed, commit them**

```bash
git status
# If go.mod / go.sum changed in step 2 (they shouldn't), investigate first; otherwise:
git add -A && git commit -m "chore(pk-core): tidy after observability extraction"
```

---

## Acceptance Criteria

This plan is complete when **all** of the following are true:

1. `cd septagon-oss-workspace/pk-core && make verify` passes (test + vet + staticcheck + fitness).
2. `go mod tidy` produces no diff in `pk-core/go.mod` or `pk-core/go.sum` — no external deps introduced.
3. `pkg/observability/{logger,metrics,tracing,health,guardrail}/` each contain at minimum: a `doc.go`, the production file(s), and a `*_test.go`.
4. The architecture fitness test `TestObservabilityHasNoExternalDeps` passes.
5. `cd platformkit && make audit-oss && make validate-oss-split && make validate-open-core-workspace` all pass.
6. Per-task commits have landed on `main` of `septagon-oss-workspace/pk-core` (one logical commit per task block).
7. No file in `pkg/observability/` imports `github.com/septagon-dev/*`.

---

## Self-Review Notes (post-completion)

When this plan is executed, the engineer should briefly note in the final commit:
- Which task blocks needed any deviation from the recipe (and why)
- Anything in the source `platformkit-backend-kit/observability/*` that surprised us and should be tracked for a future v0.0.1 enrichment (e.g., correlation-id propagation, request log aggregation, log batching)

These notes seed the v0.0.1 backlog.
