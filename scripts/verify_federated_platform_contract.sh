#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
platform_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$platform_root/.." && pwd)"

devtools_repo="$workspace_root/platformkit-devtools"
backend_repo="$workspace_root/platformkit-backend-kit"
business_repo="$workspace_root/platformkit-business-modules"
frontend_repo="$workspace_root/platformkit-frontend-kit"

require_dir() {
	local dir="$1"
	if [[ ! -d "$dir" ]]; then
		echo "missing required sibling repo: $dir" >&2
		exit 2
	fi
}

run_go_in_repo() {
	local title="$1"
	local repo="$2"
	local scope="$3"
	local go_work_mode="${4:-off}"
	shift 4

	local go_work="$go_work_mode"
	if [[ "$go_work_mode" == "workspace" ]]; then
		go_work="$workspace_root/go.work"
	fi

	local go_cache="${PLATFORMKIT_GOCACHE:-$repo/.tmp-go-cache/$scope}"
	local go_tmp="${PLATFORMKIT_GOTMPDIR:-$repo/.tmp-go-tmp/$scope}"
	local go_modcache="${PLATFORMKIT_GOMODCACHE:-$repo/.tmp-go-modcache/$scope}"
	local tmpdir="${PLATFORMKIT_TMPDIR:-$repo/.tmp-tmp/$scope}"

	mkdir -p "$go_cache" "$go_tmp" "$go_modcache" "$tmpdir"

	echo "==> $title"
	(
		cd "$repo"
		env \
			CGO_ENABLED=0 \
			GOWORK="$go_work" \
			GOPRIVATE=github.com/septagon-dev/* \
			GONOSUMDB=github.com/septagon-dev/* \
			GONOPROXY=github.com/septagon-dev/* \
			GOCACHE="$go_cache" \
			GOTMPDIR="$go_tmp" \
			GOMODCACHE="$go_modcache" \
			TMPDIR="$tmpdir" \
			"$@"
	)
}

run_make_in_repo() {
	local title="$1"
	local repo="$2"
	local scope="$3"
	local go_work_mode="${4:-off}"
	shift 4

	local go_work="$go_work_mode"
	if [[ "$go_work_mode" == "workspace" ]]; then
		go_work="$workspace_root/go.work"
	fi

	local go_cache="${PLATFORMKIT_GOCACHE:-$repo/.tmp-go-cache/$scope}"
	local go_tmp="${PLATFORMKIT_GOTMPDIR:-$repo/.tmp-go-tmp/$scope}"
	local go_modcache="${PLATFORMKIT_GOMODCACHE:-$repo/.tmp-go-modcache/$scope}"
	local tmpdir="${PLATFORMKIT_TMPDIR:-$repo/.tmp-tmp/$scope}"

	mkdir -p "$go_cache" "$go_tmp" "$go_modcache" "$tmpdir"

	echo "==> $title"
	env \
		CGO_ENABLED=0 \
		GOWORK="$go_work" \
		GOPRIVATE=github.com/septagon-dev/* \
		GONOSUMDB=github.com/septagon-dev/* \
		GONOPROXY=github.com/septagon-dev/* \
		GOCACHE="$go_cache" \
		GOTMPDIR="$go_tmp" \
		GOMODCACHE="$go_modcache" \
		TMPDIR="$tmpdir" \
		make -C "$repo" "$@"
}

run_in_repo() {
	local title="$1"
	local repo="$2"
	shift 2
	echo "==> $title"
	(
		cd "$repo"
		"$@"
	)
}

require_dir "$devtools_repo"
require_dir "$backend_repo"
require_dir "$business_repo"
require_dir "$frontend_repo"

run_go_in_repo \
	"Build orchestration contract" \
	"$devtools_repo" \
	"federated-platform" \
	off \
	go test ./platformkit/ops

run_make_in_repo \
	"Runtime boundary contract" \
	"$backend_repo" \
	"federated-platform" \
	off \
	verify-runtime-boundary

run_make_in_repo \
	"Runtime capability manifest contract" \
	"$backend_repo" \
	"federated-platform" \
	off \
	verify-runtime-capabilities

run_go_in_repo \
	"Admin surface contract" \
	"$business_repo" \
	"federated-platform" \
	workspace \
	go test ./admin_management/... -run 'TestBuildAdminAreasIncludesPlainModuleAdminSurfaceContracts|TestBuildAdminAreasIncludesFeatureDiscoverySurfaceContribution|TestBuildAdminAreasIncludesVisitManagementWhenTenantEnablesModule|TestBuildAdminSurfaceRoutesUsesExplicitContributionsOnly|TestBuildSurfaceContributionFromPlansUsesExplicitSurfaceContracts'

run_go_in_repo \
	"Business-module UI contract" \
	"$business_repo" \
	"federated-platform" \
	workspace \
	go test ./tests/ui_contract -run 'TestModuleAdminDefinitionsDoNotUseRawSections|TestSectionRenderersUseSharedPageContainer|TestAllSectionRenderersUseAtomicPrimitives|TestPortsNoRouteAliases'

run_make_in_repo \
	"Business-module authz contract" \
	"$business_repo" \
	"federated-platform" \
	off \
	check-access-contracts

run_make_in_repo \
	"Business-module i18n contract" \
	"$business_repo" \
	"federated-platform" \
	off \
	check-i18n-contracts

run_make_in_repo \
	"Business-module docs contract" \
	"$business_repo" \
	"federated-platform" \
	off \
	check-module-doc-contract

run_go_in_repo \
	"Business-module observability contract" \
	"$business_repo" \
	"federated-platform" \
	workspace \
	go test . -run 'TestNoRawInternal5xxErrorLeaks|TestCriticalVerticalHandlersUseBaseHandlerTracing|TestCriticalVerticalServicesUseTracerSpans'

run_go_in_repo \
	"Frontend composition contract" \
	"$frontend_repo" \
	"federated-platform" \
	workspace \
	go test . -run 'TestComponentDefinitionsCoverTierPackagesOrHaveTrackedExceptions|TestDefinitionFilesExposeStableRegistryContracts|TestSharedFrontendAvoidsNewInlineBehaviorExceptions'
