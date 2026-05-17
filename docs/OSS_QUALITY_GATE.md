# OSS Quality Gate

This is the release gate for moving PlatformKit code into `septagon-oss`.
No migration step should proceed unless the current OSS foundation satisfies
both the architecture gate and the execution gate.

## Architecture Gate

The architecture score is 10/10 only when every public package satisfies all
of these checks:

1. **Layer ownership is obvious.** Shared vocabulary lives in `pk-shared`;
   platform rules live in `pk-core`; modules, tools, design, apps, and Pro
   behavior stay out of the kernel.
2. **The public contract is minimal.** A type or function exists only when it
   is needed by at least two layers or by the core extension model.
3. **Extension happens through contracts.** Pro and downstream code extend by
   embedding, typed ports, registries, manifests, policies, descriptors, or
   adapters. They do not require private forks of core semantics.
4. **Errors surface at the composition boundary.** Human-authored invalid
   versions, descriptors, overlays, policies, and registry contributions return
   structured errors or reports. Panics are reserved for `Must*` helpers and
   impossible type-parameter misuse.
5. **No private dependency leaks.** OSS repos never import `septagon-dev` or
   private runtime packages.
6. **Compatibility is honest.** Private adapters are thin pass-throughs over
   OSS contracts and carry no divergent behavior.
7. **The formula remains intact.** Core defines rules, modules add
   capabilities, and clients compose capabilities into products and flows.

## Execution Gate

The execution score is 10/10 only when every touched repo satisfies all of
these checks:

1. **Every owned Go file declares purpose.** C-14/ADR-0029 references are in
   the first 30 lines of non-generated Go files.
2. **Tests cover the contract, not just happy paths.** Public APIs have success,
   invalid input, duplicate/conflict, nil/zero-value where supported,
   deterministic ordering, and copy/aliasing tests.
3. **Validation is machine-runnable.** `go test ./...`, `go vet ./...`, and
   repo-specific contract checks pass without private infrastructure.
4. **Working trees stay clean of generated build artifacts.** Make targets do
   not create repo-local caches by default; local overrides are opt-in.
5. **Docs match behavior.** README and contract docs describe the actual API
   semantics and validation commands.
6. **Downstream smoke passes.** Private compatibility adapters and the first
   consuming packages compile/test against the OSS packages.
7. **No silent failure paths in public helpers.** Public helpers either return
   structured results/errors or document why best-effort behavior is safe.

## Required Commands

Run these before continuing a migration step:

```bash
cd septagon-oss-workspace/pk-shared
go test ./...
go vet ./...

cd ../pk-core
go test ./...
go vet ./...
make fitness

cd ../../platformkit
make validate-oss-split
make validate-open-core-workspace
```

Then run focused downstream smoke from the workspace root for every private
package touched by the migration:

```bash
go test -p=1 -count=1 ./platformkit-frontend-kit/registry \
  ./platformkit-apps/modulecatalog \
  ./platformkit-apps/surfacecatalog \
  ./platformkit-devtools/internal/modulechecks \
  ./platformkit-infra-pulumi/internal/catalog \
  ./platformkit-business-modules/catalog/moduledefs
```

## Current Gate Decision

The current OSS foundation is not considered final until this gate is green
after each hardening pass. A passing gate means we may continue migration; a
failed gate means the next work item is the failing contract itself.
