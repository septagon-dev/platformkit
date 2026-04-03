# Revenue Engine Testing Remediation

Updated: `2026-03-21`

## Purpose

Turn the current test inventory into a truthful testing strategy that supports a
solo-founder, AI-augmented commercialization path.

This plan is intentionally narrow.

It does not try to perfect every repo.
It fixes the parts that currently overstate confidence or block a credible
launch motion.

## 30-Day Objective

At the end of the next `30 days`, PlatformKit should have:

1. one truthful verification entrypoint per core repo
2. frontend JS tests running in the normal path
3. module E2E wiring that actually executes when called
4. one executable flagship smoke lane that is required both locally and in CI
5. one revenue-critical product path under executable coverage

If those five things are not true, green builds will still overstate product
readiness.

## Guardrails

1. do not broaden this into generic coverage work
2. do not add big new test frameworks unless an existing tool is clearly
   insufficient
3. prefer fixing the command people already run over inventing a new command
4. prefer one real executable flow over many shallow metadata checks
5. keep smaller repos stable, but do not let them preempt flagship confidence

## Current Status

Completed:

1. `TEST-001` completed on `2026-03-21`
   Result:
   - removed the stray merge marker blocking backend Makefile parsing
   - restored a valid `verify-interoperability` and `verify-ci` target graph
   - confirmed the remaining verification blockers are module-resolution and
     environment issues, not Makefile syntax
2. `TEST-002` completed on `2026-03-21`
   Result:
   - `platformkit test --all` now resolves current repo roots from `go.work`
     instead of hardcoded legacy paths
   - `platformkit test --all` groups nested app modules back to the owning repo
     root so `platformkit-apps` keeps its repo-level test contract
   - `platformkit test --e2e` now targets `platformkit-tests` and the current
     flagship app suites under `platformkit-apps`
   - unit tests now lock the workspace-root and e2e target resolution behavior
3. `TEST-003` completed on `2026-03-21`
   Result:
   - `platformkit-frontend-kit` now exposes `make test` as the canonical
     frontend verification path
   - `make test` runs both `make test-go` and `make test-js`
   - the repo README now documents the combined Go plus JS test contract
   - the existing Node-based JS runner remains in place because the tests still
     require `--experimental-vm-modules` with the current controller harness
4. `TEST-004` completed on `2026-03-21`
   Result:
   - `admin_management/tests/run_e2e.sh` now resolves the tagged E2E suites
     before executing them
   - the runner now invokes `go test -tags e2e` against the resolved package
     list instead of issuing package globs that match nothing
   - the script now fails clearly if no tagged E2E packages are found
   - the runner prints the suite patterns, resolved packages, and exact `go`
     command it is about to execute
5. `TEST-005` completed on `2026-03-22`
   Result:
   - `check-tags` now runs through a dedicated repo-owned scanner that covers
     `tests/e2e`, `tests/bdd`, and feature-level `e2e.go` files
   - `verify-modules` now includes both `check-tags` and the interoperability
     contract check, so the repo has one truthful module-verification path
   - CI now calls `make verify-modules` directly instead of stitching together
     side commands around it
   - a broken `//go:build e2e` header now fails the checker against a fixture
     root instead of silently disappearing from the build

## Ordered Ticket Board

### Wave 0: Unblock Broken Entry Points

These tickets must land first.

1. `TEST-001` Restore backend `verify-ci`
   Repo: `platformkit-backend-kit`
   Why now: the documented CI-grade entrypoint is broken, so backend confidence
   is currently overstated.
   Exit criteria:
   - unresolved conflict markers are removed from the Makefile
   - `make verify-ci` parses and reaches its intended commands
   - README verification instructions still match the actual command

2. `TEST-002` Fix devtools test-runner workspace roots
   Repo: `platformkit-devtools`
   Why now: the shared CLI runner points at the wrong repo layout, so it cannot
   be trusted as the orchestration layer.
   Exit criteria:
   - `platformkit test --all` resolves current repo roots from `go.work`
   - `platformkit test --e2e` points at `platformkit-tests` and current app
     suites instead of legacy paths
   - one automated test locks the workspace-root resolution behavior

3. `TEST-003` Add a canonical frontend JS test command
   Repo: `platformkit-frontend-kit`
   Why now: JS controller tests exist but are effectively optional.
   Exit criteria:
   - `package.json` runs the JS test files instead of exiting with a placeholder
   - the repo exposes one normal way to run Go plus JS tests
   - the command is documented in the repo README or Makefile help surface

4. `TEST-004` Fix business-modules E2E tag wiring
   Repo: `platformkit-business-modules`
   Why now: the current E2E runner claims to run browser tests but skips the
   `e2e` build-tag lane.
   Exit criteria:
   - `admin_management/tests/run_e2e.sh` invokes `go test -tags e2e`
   - the script fails if no tagged packages are found
   - the script output makes it obvious which suites are actually being run

### Wave 1: Make CI Honest

These tickets make green builds mean something.

5. `TEST-005` Enforce E2E tag checks in module verification
   Repo: `platformkit-business-modules`
   Depends on: `TEST-004`
   Exit criteria:
   - `check-tags` is part of `verify-modules`
   - CI uses that path without a side channel that bypasses it
   - a broken `//go:build e2e` header fails verification

6. `TEST-006` Align app `verify-ci`, release docs, and smoke contract
   Repo: `platformkit-apps`
   Why now: local “CI-grade” validation is weaker than the published release
   contract.
   Exit criteria:
   - either `verify-ci` includes flagship smoke, or it is renamed so it no
     longer claims that level of confidence
   - `Makefile`, release runbook, and GitHub workflow use the same language for
     what is required
   - there is exactly one documented answer to “what must pass before release?”

7. `TEST-007` Add one real executable suite to `platformkit-tests`
   Repo: `platformkit-tests`
   Why now: the harness repo currently reads as more mature than its runnable
   coverage.
   Exit criteria:
   - `go test -tags e2e ./...` runs at least one actual browser/harness flow
   - that flow is not an `Example_*` documentation test
   - the repo README distinguishes clearly between harness primitives and
     executable suites

8. `TEST-008` Add frontend JS tests to CI
   Repo: `platformkit-frontend-kit`
   Depends on: `TEST-003`
   Exit criteria:
   - GitHub CI runs the canonical JS test command
   - failures in controller tests fail the repo workflow
   - local and CI commands match closely enough that drift is unlikely

### Wave 2: Cover One Real Commercial Path

These tickets change the strategy from “tests exist” to “the sellable path is
protected.”

9. `TEST-009` Make module browser tests self-seeding and non-optional
   Repo: `platformkit-business-modules`
   Why now: current Rod suites can pass or effectively skip without proving the
   behavior.
   Exit criteria:
   - `auth_management/tests/e2e` and `user_management/tests/e2e` create or seed
     their own required data
   - missing preconditions fail loudly instead of returning early
   - success criteria are assertions, not log messages

10. `TEST-010` Expand flagship smoke to one revenue-critical operator flow
    Repo: `platformkit-apps`
    Supporting repos: `platformkit-tests`, `platformkit-business-modules`
    Why now: login plus users-list coverage is not enough for the product path
    tied to revenue.
    Scope rule:
    - choose exactly one currently runnable flow
    - preferred order: `membership`, then `booking`, then `invoicing`
    - do not start with a brand-new payment UI if the reference app does not
      already support it end to end
    Exit criteria:
    - the flagship smoke covers admin login plus one operator action that
      changes business state
    - the test asserts the expected end state, not only visibility and URL
    - the flow runs in the canonical monolith release lane

11. `TEST-011` Resolve microservices smoke parity honestly
    Repo: `platformkit-apps`
    Depends on: `TEST-010`
    Exit criteria:
    - either microservices gets equivalent smoke coverage for the chosen flow,
      or the repo explicitly documents that monolith is the only release-trust
      surface for now
    - MFA coverage parity is either implemented or deliberately scoped out in
      writing

12. `TEST-012` Add one real adapter-backed backend integration lane
    Repo: `platformkit-backend-kit`
    Why now: many “integration/e2e” tests are still in-process and mock-backed.
    Exit criteria:
    - one backend suite exercises a real adapter boundary with controlled
      dependencies
    - the suite is named and documented as integration, not unit
    - in-process orchestration tests are relabeled if they are not actually
      integration

13. `TEST-013` Make the NATS transport lane deterministic
    Repo: `platformkit-backend-kit`
    Depends on: `TEST-012`
    Exit criteria:
    - there is a test target or CI profile where transport coverage is expected
      and must not silently skip
    - skip behavior remains acceptable only for clearly documented restricted
      environments

14. `TEST-014` Add a real `client smoke` integration contract
    Repo: `platformkit-devtools`
    Why now: the client smoke tests mostly validate generated command specs, not
    the actual end-to-end launch path.
    Exit criteria:
    - at least one test exercises `platformkit client smoke` or the underlying
      launch path against a controlled fixture bundle
    - the test proves materialize -> boot -> ready -> seed -> smoke wiring
    - failures produce usable artifacts or logs

### Wave 3: Tighten the Strategy

These are the first depth upgrades after the entrypoints are honest.

15. `TEST-015` Replace shallow test floors with critical-module obligations
    Repo: `platformkit-business-modules`
    Depends on: `TEST-009`, `TEST-010`
    Scope:
    - `booking_management`
    - `membership_management`
    - `payment_management`
    - `module_management`
    - `support_management`
    - `tenant_management`
    - `theme_management`
    Exit criteria:
    - each critical module has named behavioral obligations, not just “one test
      file”
    - breadth guards remain, but they stop being the primary confidence signal
    - allowlist debt for first-wedge modules is reduced or explicitly tracked as
      blocking risk

16. `TEST-016` Publish the test taxonomy and ownership contract
    Repo: `platformkit`
    Why now: naming drift across repos is part of the confusion.
    Exit criteria:
    - one document defines what `unit`, `integration`, `smoke`, `e2e`, and
      `contract` mean in this workspace
    - each core repo has an explicit owned lane
    - the document links the test lanes to the revenue-engine objective

## Repo Boards

### `platformkit-backend-kit`

1. `TEST-001` Restore backend `verify-ci`
2. `TEST-012` Add one real adapter-backed backend integration lane
3. `TEST-013` Make the NATS transport lane deterministic

### `platformkit-business-modules`

1. `TEST-004` Fix business-modules E2E tag wiring
2. `TEST-005` Enforce E2E tag checks in module verification
3. `TEST-009` Make module browser tests self-seeding and non-optional
4. `TEST-015` Replace shallow test floors with critical-module obligations

### `platformkit-frontend-kit`

1. `TEST-003` Add a canonical frontend JS test command
2. `TEST-008` Add frontend JS tests to CI

### `platformkit-apps`

1. `TEST-006` Align app `verify-ci`, release docs, and smoke contract
2. `TEST-010` Expand flagship smoke to one revenue-critical operator flow
3. `TEST-011` Resolve microservices smoke parity honestly

### `platformkit-tests`

1. `TEST-007` Add one real executable suite to `platformkit-tests`

### `platformkit-devtools`

1. `TEST-002` Fix devtools test-runner workspace roots
2. `TEST-014` Add a real `client smoke` integration contract

### `platformkit`

1. `TEST-016` Publish the test taxonomy and ownership contract

## Deferred for This 30-Day Window

These repos should stay healthy, but they are not first-leverage work for the
current objective:

1. `platformkit-design-system`
2. `platformkit-agent-runtime`
3. `infra`

Rule:

Only pull these into the remediation stream if a current ticket proves they are
blocking flagship trust or the reference launch flow.

## Recommended Execution Sequence

Week `1`

1. `TEST-001`
2. `TEST-002`
3. `TEST-003`
4. `TEST-004`

Week `2`

1. `TEST-005`
2. `TEST-006`
3. `TEST-007`
4. `TEST-008`

Week `3`

1. `TEST-009`
2. `TEST-010`
3. `TEST-011`

Week `4`

1. `TEST-012`
2. `TEST-013`
3. `TEST-014`
4. `TEST-016`

Week `5+`

1. `TEST-015`

## Success Condition

This remediation work is successful when the platform can answer these questions
cleanly:

1. what command should a developer run for truthful repo verification?
2. what command proves the flagship product still works?
3. what test protects the first commercial operator flow?
4. what repo owns each kind of test?
5. which failures block release versus which are advisory?

If those answers are still ambiguous, the strategy is still too loose.
