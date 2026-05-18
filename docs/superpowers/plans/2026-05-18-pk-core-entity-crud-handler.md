# pk-core/pkg/entity/crud Implementation Plan (Phase A.7)

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Land a generic CRUD handler block in `pk-core/pkg/entity/crud/`. The handler is parameterized by an entity type `T` and bound to a `Store[T]` implementation + a `router.Router`. It auto-wires the 5 REST endpoints (GET list, GET id, POST, PUT id, DELETE id) using JSON encoding.

**Stdlib only.** Builds on `pk-core/pkg/entity` (Descriptor) + `pk-core/pkg/infrastructure/router` (Router interface).

**Source reference:** `platformkit-backend-kit/api/handler.go`, `api/generic/`. Adapt — don't copy.

**Work location:** `/home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-core/`.

---

## Block: `pk-core/pkg/entity/crud`

### Composable scorecard
| Property | Realization |
|---|---|
| Identity | `github.com/septagon-oss/pk-core/pkg/entity/crud` |
| Boundary | Encoding/decoding helpers private; only Store interface + Handler factory exported |
| Contract | `Store[T]` interface + `Handler[T]` struct + `Mount(router, basePath)` method |
| Composition | Multiple Handler[T] instances on the same router for different entity types |
| Replacement | Any `Store[T]` impl swaps in (sqlite, postgres, in-memory) |
| Extension | `Options` field for `WithBeforeCreate(hook)`, `WithAfterCreate(hook)`, `WithListFilter(fn)`, `WithIDExtractor(fn)`, custom error renderer |
| Runtime binding | App composition: `crud.New[*User](store).Mount(router, "/api/v1/users")` |
| Evidence | Tests cover all 5 endpoints + hooks + error paths |

### Chainable laws
- Identity: a no-op hook is a valid composition element
- Type compatibility: Store/Handler are typed by T
- Context preservation: request ctx flows through handlers into Store calls
- Error algebra: Store errors map to HTTP status codes; ErrNotFound → 404, ErrValidation → 400, others → 500
- Cancellation safety: ctx cancellation aborts Store ops

### Public API

```go
package crud

import (
    "context"
    "net/http"

    "github.com/septagon-oss/pk-core/pkg/infrastructure/router"
)

// Store is the persistence contract for entities of type T.
type Store[T any] interface {
    Create(ctx context.Context, entity *T) error
    Get(ctx context.Context, id string) (*T, error)
    List(ctx context.Context, filter ListFilter) ([]*T, error)
    Update(ctx context.Context, id string, entity *T) error
    Delete(ctx context.Context, id string) error
}

// ListFilter is the canonical query shape for List.
type ListFilter struct {
    Limit  int
    Offset int
    SortBy string
    SortDesc bool
    Q      string  // free-text query; Store may ignore
}

// Sentinel errors. Stores return these (or wrap them) to drive HTTP status.
var (
    ErrNotFound   = errors.New("crud: not found")
    ErrValidation = errors.New("crud: validation failed")
    ErrConflict   = errors.New("crud: conflict")
)

// Options configures a Handler.
type Options[T any] struct {
    // IDExtractor pulls the path-parameter id from the request. Default:
    // r.PathValue("id") (Go 1.22+ ServeMux pattern).
    IDExtractor func(*http.Request) string

    // BeforeCreate runs before Store.Create. Return non-nil error to short-circuit.
    BeforeCreate func(ctx context.Context, entity *T) error
    AfterCreate  func(ctx context.Context, entity *T)
    BeforeUpdate func(ctx context.Context, id string, entity *T) error
    AfterUpdate  func(ctx context.Context, id string, entity *T)
    BeforeDelete func(ctx context.Context, id string) error
    AfterDelete  func(ctx context.Context, id string)

    // ListFilterParser overrides default query-string parsing.
    ListFilterParser func(*http.Request) ListFilter

    // ErrorRenderer writes the HTTP response for an error from a hook or store call.
    // Default: ErrNotFound → 404, ErrValidation → 400, ErrConflict → 409, else 500.
    ErrorRenderer func(w http.ResponseWriter, err error)
}

// Handler is the generic CRUD HTTP handler for entities of type T.
type Handler[T any] struct { /* private */ }

// New constructs a Handler bound to store with the given options.
func New[T any](store Store[T], opts ...Options[T]) *Handler[T]

// Mount registers the 5 REST routes under basePath on r.
//   GET    {basePath}      → List
//   POST   {basePath}      → Create
//   GET    {basePath}/{id} → Get
//   PUT    {basePath}/{id} → Update
//   DELETE {basePath}/{id} → Delete
func (h *Handler[T]) Mount(r router.Router, basePath string)
```

### Tests

In-memory test Store[*Widget] with a simple `Widget struct { ID string; Name string }`.

Tests (≥14):
- TestCreatePOSTReturns201
- TestCreatePOSTInvalidJSON400
- TestCreateBeforeHookCanReject
- TestGetExistingReturns200
- TestGetNotFoundReturns404
- TestListReturnsAllEntities
- TestListWithLimitOffset
- TestUpdatePUTReturns200
- TestUpdateNotFoundReturns404
- TestDeleteReturns204
- TestDeleteNotFoundReturns404
- TestCustomErrorRendererInvoked
- TestCustomIDExtractor
- TestListFilterParserOverride

### Files
```
pk-core/pkg/entity/crud/
├── doc.go
├── crud.go                 # Store interface, ListFilter, sentinels, Options, Handler, New, Mount
├── encoding.go             # private JSON encode/decode helpers
└── crud_test.go            # external; in-memory test Store + 14+ tests
```

### Commit
`feat(pk-core/entity/crud): generic CRUD HTTP handler with Store interface`

In the same commit, update `pkg/architecture/oss_deps_test.go` to append the new package.

---

## Acceptance criteria

- `make verify` green
- Stdlib only (zero new deps)
- C-14/ADR-0029 headers
- External test package
- ≥14 leaf tests
- NO Co-Authored-By trailers
- 1 atomic commit
