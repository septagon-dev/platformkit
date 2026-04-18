#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <product|federated>" >&2
	exit 2
fi

surface="$1"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
product_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$product_root/.." && pwd)"
devtools_repo="$workspace_root/platformkit-devtools"

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

mkdir -p "$cli_go_cache" "$cli_go_modcache" "$cli_go_tmp"

(
	cd "$devtools_repo"
	env \
		GOWORK=off \
		GOCACHE="$cli_go_cache" \
		GOMODCACHE="$cli_go_modcache" \
		GOTMPDIR="$cli_go_tmp" \
		go run ./cmd/platformkit verify contract "$surface" --dir "$workspace_root"
)
