#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=workspace_layout.sh
source "$script_dir/workspace_layout.sh"

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -p \
	"$fixture/product/platformkit/scripts" \
	"$fixture/core/platformkit-shared" \
	"$fixture/modules/platformkit-business-modules" \
	"$fixture/overlays/septagon-oss-workspace"
touch "$fixture/go.work"

assert_equal() {
	local got="$1"
	local want="$2"
	local label="$3"
	if [[ "$got" != "$want" ]]; then
		echo "workspace-layout-test: $label: got $got, want $want" >&2
		exit 1
	fi
}

assert_equal \
	"$(platformkit_find_workspace_root "$fixture/product/platformkit/scripts")" \
	"$fixture" \
	"nested workspace discovery"
assert_equal \
	"$(platformkit_repo_path "$fixture" platformkit-shared)" \
	"$fixture/core/platformkit-shared" \
	"core repository resolution"
assert_equal \
	"$(platformkit_repo_path "$fixture" platformkit-business-modules)" \
	"$fixture/modules/platformkit-business-modules" \
	"module repository resolution"
assert_equal \
	"$(platformkit_oss_root "$fixture")" \
	"$fixture/overlays/septagon-oss-workspace" \
	"OSS overlay resolution"

if platformkit_repo_path "$fixture" missing-repository >/dev/null; then
	echo "workspace-layout-test: missing repository unexpectedly resolved" >&2
	exit 1
fi

mkdir -p "$fixture/frontend/platformkit-shared"
if platformkit_repo_path "$fixture" platformkit-shared >/dev/null; then
	echo "workspace-layout-test: ambiguous repository unexpectedly resolved" >&2
	exit 1
fi

echo "workspace-layout-test: layered workspace resolution passed"
