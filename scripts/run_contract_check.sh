#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <product|federated>" >&2
	exit 2
fi

surface="$1"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
product_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=workspace_layout.sh
source "$script_dir/workspace_layout.sh"
if ! workspace_root="$(platformkit_find_workspace_root "$product_root")"; then
	echo "could not locate workspace root (no go.work above $product_root)" >&2
	exit 2
fi
if ! devtools_repo="$(platformkit_repo_path "$workspace_root" platformkit-devtools)"; then
	echo "missing required layered repository: platformkit-devtools" >&2
	exit 2
fi

cli_runtime_root="$workspace_root/.tmp/platformkit-contract-cli"
cli_go_tmp="$cli_runtime_root/gotmp"

mkdir -p "$cli_go_tmp"

(
	cd "$devtools_repo"
	env \
		GOWORK="$workspace_root/go.work" \
		GOTMPDIR="$cli_go_tmp" \
		TMPDIR="$cli_go_tmp" \
		go run ./cmd/platformkit verify contract "$surface" --dir "$workspace_root"
)
