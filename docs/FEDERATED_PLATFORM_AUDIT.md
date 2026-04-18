# Federated Platform Audit

This audit tracks how far PlatformKit has moved from "shared code with local
special cases" toward a federated platform model:

- declarations owned close to the domain
- shared platform contracts for composition
- centralized interpreters and orchestrators
- ratchets that prevent drift back to legacy or duplicate paths

This is intentionally different from the curated flagship product contract in
[PRODUCT_CONTRACT.md](PRODUCT_CONTRACT.md).

The product contract asks, "what are we willing to stand behind as one
integrated product?"

This audit asks, "how far have we pushed the whole platform toward federated
contract ownership?"

## Current Snapshot

| Layer | Status | Evidence | Main Gap | Guarded |
| --- | --- | --- | --- | --- |
| Build orchestration | Partial | [platformkit-devtools/platformkit/ops/go_workspace.go](../../platformkit-devtools/platformkit/ops/go_workspace.go), [platformkit-devtools/platformkit/cmd/deps.go](../../platformkit-devtools/platformkit/cmd/deps.go) | Root and CI still rely on mixed shell and repo-local command ownership instead of repo manifests plus one CLI interpreter | Yes |
| Runtime boundaries | Strong | [platformkit-backend-kit/docs/architecture/runtime_capability_manifest.yaml](../../platformkit-backend-kit/docs/architecture/runtime_capability_manifest.yaml), backend runtime boundary/capability checks | Runtime surfaces are well declared, but apps and downstream repos still consume some higher-level behavior through bespoke assembly | Yes |
| Admin surfaces | Strong | [platformkit-backend-kit/app/module/helpers/module_admin.go](../../platformkit-backend-kit/app/module/helpers/module_admin.go), [platformkit-business-modules/admin_management/admin_surface_manifest.go](../../platformkit-business-modules/admin_management/admin_surface_manifest.go), [platformkit-business-modules/tests/ui_contract/module_admin_authoring_contract_test.go](../../platformkit-business-modules/tests/ui_contract/module_admin_authoring_contract_test.go) | Most module admins are on canonical page/surface contracts, but not every higher-level admin concern is yet driven from one universal manifest | Yes |
| Authz | Partial | [platformkit-business-modules/scripts/check_module_access_contracts.sh](../../platformkit-business-modules/scripts/check_module_access_contracts.sh), admin permission gating in [platformkit-business-modules/admin_management/admin_surface_manifest.go](../../platformkit-business-modules/admin_management/admin_surface_manifest.go) | Feature/page authz contracts exist, but the platform still lacks one end-to-end resource/action graph shared by runtime, admin, and docs | Yes |
| i18n | Partial | [platformkit-business-modules/scripts/check_module_i18n_contracts.sh](../../platformkit-business-modules/scripts/check_module_i18n_contracts.sh), localized admin shell copy in [platformkit-business-modules/admin_management/admin_surface_manifest.go](../../platformkit-business-modules/admin_management/admin_surface_manifest.go) | Contract enforcement is still partly heuristic and allowlist-based instead of fully manifest-driven | Yes |
| UI composition | Strong | [platformkit-frontend-kit/component_definition_contract_test.go](../../platformkit-frontend-kit/component_definition_contract_test.go), [platformkit-business-modules/tests/ui_contract/page_container_contract_test.go](../../platformkit-business-modules/tests/ui_contract/page_container_contract_test.go) | Shared primitives and registry coverage are strong, but app-level composition still has some bespoke rendering seams | Yes |
| Observability | Partial | [platformkit-business-modules/observability_contract_test.go](../../platformkit-business-modules/observability_contract_test.go), stable observability runtime capabilities in [platformkit-backend-kit/docs/architecture/runtime_capability_manifest.yaml](../../platformkit-backend-kit/docs/architecture/runtime_capability_manifest.yaml) | Modules consume tracing/logging contracts, but there is no per-module observability manifest equivalent to admin or module metadata yet | Yes |
| Docs and governance | Partial | [platformkit-business-modules/catalog/module_contracts.yaml](../../platformkit-business-modules/catalog/module_contracts.yaml), [FEDERATED_DOCS_CONTRACT.md](FEDERATED_DOCS_CONTRACT.md), [PRODUCT_CONTRACT.md](PRODUCT_CONTRACT.md), repository baseline workflows | The contract now exists and the first repo pilot is guarded, but most repos and modules have not adopted the typed docs bundle yet | Yes |

## What This Means

PlatformKit is already strong in runtime boundaries, admin/page composition, and
web component standardization.

The weakest layers are the ones that still rely on mixed ownership:

- build orchestration
- authz semantics
- i18n semantics
- observability declarations
- docs/governance assembly

Those layers are not missing. They are present, but they are not yet expressed
through one explicit platform-wide contract language.

## Guard

Run the workspace-level federated contract guard from the flagship repo:

```bash
make verify-federated-platform
```

Or invoke the typed devtools checker directly:

```bash
platformkit verify contract federated --dir <workspace-root>
```

This guard verifies the current ratcheted floor across sibling repos:

1. devtools workspace Go environment and dependency orchestration
2. backend runtime boundary and capability manifests
3. business-module admin surface contracts
4. business-module authz and i18n contracts
5. business-module docs and observability contracts
6. frontend component and interaction composition contracts

The guard is intentionally surgical. It does not try to prove every repo is
fully green; it proves the current federated contract floor has not regressed.

## Next Ratchets

1. Introduce repo-level build manifests and migrate root/CI orchestration onto them.
2. Replace heuristic authz and i18n enforcement with first-class declarative manifests.
3. Add a per-module observability declaration surface.
4. Promote the strongest parts of this guard into the curated flagship product contract once they are stable enough to version.
