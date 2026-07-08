#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <product|federated>" >&2
	exit 2
fi

surface="$1"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
product_root="$(cd "$script_dir/.." && pwd)"

# The workspace root is the directory holding go.work (the layered layout
# puts this repo at <root>/product/platformkit, so walk upward rather than
# assuming a flat sibling topology).
workspace_root="$product_root"
while [[ "$workspace_root" != "/" && ! -f "$workspace_root/go.work" ]]; do
	workspace_root="$(cd "$workspace_root/.." && pwd)"
done
if [[ ! -f "$workspace_root/go.work" ]]; then
	echo "could not locate workspace root (no go.work above $product_root)" >&2
	exit 2
fi

devtools_repo="$workspace_root/tooling/platformkit-devtools"
if [[ ! -d "$devtools_repo" ]]; then
	# pre-layered flat layout fallback
	devtools_repo="$workspace_root/platformkit-devtools"
fi

require_dir() {
	local dir="$1"
	if [[ ! -d "$dir" ]]; then
		echo "missing required sibling repo: $dir" >&2
		exit 2
	fi
}

require_dir "$devtools_repo"

cli_runtime_root="$workspace_root/.tmp/platformkit-contract-cli"
cli_go_cache="$cli_runtime_root/gocache"
cli_go_modcache="$cli_runtime_root/gomodcache"
cli_go_tmp="$cli_runtime_root/gotmp"
cli_go_path="$cli_runtime_root/gopath"

mkdir -p "$cli_go_cache" "$cli_go_modcache" "$cli_go_tmp" "$cli_go_path"

(
	cd "$devtools_repo"
	env \
		GOWORK="$workspace_root/go.work" \
		GOPATH="$cli_go_path" \
		GOCACHE="$cli_go_cache" \
		GOMODCACHE="$cli_go_modcache" \
		GOTMPDIR="$cli_go_tmp" \
		go run ./cmd/platformkit verify contract "$surface" --dir "$workspace_root"
)
