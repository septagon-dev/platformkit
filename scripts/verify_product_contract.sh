#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
product_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$product_root/.." && pwd)"

backend_repo="$workspace_root/platformkit-backend-kit"
frontend_repo="$workspace_root/platformkit-frontend-kit"
apps_repo="$workspace_root/platformkit-apps"
agent_repo="$workspace_root/platformkit-agent-runtime"

backend_go_cache="$backend_repo/.tmp-go-cache/product"
backend_go_tmp="$backend_repo/.tmp-go-tmp/product"
backend_go_modcache="$backend_repo/.tmp-go-modcache/product"
backend_tmpdir="$backend_repo/.tmp-tmp/product"

frontend_go_cache="$frontend_repo/.tmp-go-cache/product"
frontend_go_tmp="$frontend_repo/.tmp-go-tmp/product"
frontend_go_modcache="$frontend_repo/.tmp-go-modcache/product"
frontend_tmpdir="$frontend_repo/.tmp-tmp/product"

agent_go_cache="$agent_repo/.tmp-go-cache/product"
agent_go_tmp="$agent_repo/.tmp-go-tmp/product"
agent_go_modcache="$agent_repo/.tmp-go-modcache/product"
agent_tmpdir="$agent_repo/.tmp-tmp/product"

apps_go_cache="$apps_repo/.tmp-go-cache/product-root"
apps_go_tmp="$apps_repo/.tmp-go-tmp/product-root"
apps_go_modcache="$apps_repo/.tmp-go-modcache/product-root"
apps_tmpdir="$apps_repo/.tmp-tmp/product-root"

require_dir() {
	local dir="$1"
	if [[ ! -d "$dir" ]]; then
		echo "missing required sibling repo: $dir" >&2
		exit 2
	fi
}

run_step() {
	local title="$1"
	shift
	echo "==> $title"
	"$@"
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

mkdir -p \
	"$backend_go_cache" \
	"$backend_go_tmp" \
	"$backend_go_modcache" \
	"$backend_tmpdir" \
	"$frontend_go_cache" \
	"$frontend_go_tmp" \
	"$frontend_go_modcache" \
	"$frontend_tmpdir" \
	"$agent_go_cache" \
	"$agent_go_tmp" \
	"$agent_go_modcache" \
	"$agent_tmpdir" \
	"$apps_go_cache" \
	"$apps_go_tmp" \
	"$apps_go_modcache" \
	"$apps_tmpdir"

require_dir "$backend_repo"
require_dir "$frontend_repo"
require_dir "$apps_repo"
require_dir "$agent_repo"

run_step "Backend runtime boundary contract" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$backend_go_cache" \
		GOTMPDIR="$backend_go_tmp" \
		GOMODCACHE="$backend_go_modcache" \
		TMPDIR="$backend_tmpdir" \
		make -C "$backend_repo" verify-runtime-boundary

run_step "Backend interoperability contract" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$backend_go_cache" \
		GOTMPDIR="$backend_go_tmp" \
		GOMODCACHE="$backend_go_modcache" \
		TMPDIR="$backend_tmpdir" \
		make -C "$backend_repo" verify-interoperability

run_step "Backend capability manifest contract" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$backend_go_cache" \
		GOTMPDIR="$backend_go_tmp" \
		GOMODCACHE="$backend_go_modcache" \
		TMPDIR="$backend_tmpdir" \
		make -C "$backend_repo" verify-runtime-capabilities

run_step "Backend release policy contract" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$backend_go_cache" \
		GOTMPDIR="$backend_go_tmp" \
		GOMODCACHE="$backend_go_modcache" \
		TMPDIR="$backend_tmpdir" \
		make -C "$backend_repo" verify-runtime-release-policy

run_in_repo "Frontend AI surface contract" "$frontend_repo" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$frontend_go_cache" \
		GOTMPDIR="$frontend_go_tmp" \
		GOMODCACHE="$frontend_go_modcache" \
		TMPDIR="$frontend_tmpdir" \
		go test \
			./registry \
			./presentation \
			./components/molecules/workbench_header \
			./components/molecules/workbench_message \
			./components/molecules/workbench_trace

run_in_repo "Agent runtime governance contract" "$agent_repo" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$agent_go_cache" \
		GOTMPDIR="$agent_go_tmp" \
		GOMODCACHE="$agent_go_modcache" \
		TMPDIR="$agent_tmpdir" \
		go test ./...

run_in_repo "Flagship app lean/runtime contract" "$apps_repo" \
	env \
		CGO_ENABLED=0 \
		GOCACHE="$apps_go_cache" \
		GOTMPDIR="$apps_go_tmp" \
		GOMODCACHE="$apps_go_modcache" \
		TMPDIR="$apps_tmpdir" \
		go test . ./internal/bootstrap

run_in_repo "Flagship app composed deployment contract" "$apps_repo" \
	env \
		CGO_ENABLED=0 \
		GOMODCACHE="$apps_go_modcache" \
		TMPDIR="$apps_tmpdir" \
		make verify
