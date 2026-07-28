#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=workspace_layout.sh
source "$script_dir/workspace_layout.sh"
if ! workspace_root="$(platformkit_find_workspace_root "$repo_root")"; then
	echo "open-core-workspace: could not locate layered workspace root above $repo_root" >&2
	exit 2
fi
oss_root="$(platformkit_oss_root "$workspace_root")"
manifest="${1:-$repo_root/docs/OSS_REPOSITORY_MANIFEST.tsv}"
go_work="$oss_root/go.work"
rg_output="$(mktemp)"
trap 'rm -f "$rg_output"' EXIT

failures=0

report_failure() {
	echo "open-core-workspace: $*" >&2
	failures=$((failures + 1))
}

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

required_repo_files=(README.md LICENSE SECURITY.md CONTRIBUTING.md .github/CODEOWNERS)

if [[ ! -f "$manifest" ]]; then
	report_failure "missing manifest: $manifest"
fi
if [[ ! -f "$go_work" ]]; then
	report_failure "missing go.work: $go_work"
fi

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
	line="${raw_line//$'\t'/|}"
	IFS='|' read -r repo stage source_repo source_paths visibility role depends_on pro_extension extra <<< "$line"
	[[ -z "${repo:-}" || "${repo:0:1}" == "#" ]] && continue

	repo="$(trim "$repo")"
	repo_dir="$oss_root/$repo"
	if [[ ! -d "$repo_dir" ]]; then
		report_failure "missing OSS repo directory: $repo_dir"
		continue
	fi

	for required in "${required_repo_files[@]}"; do
		if [[ ! -f "$repo_dir/$required" ]]; then
			report_failure "$repo missing required file: $required"
		fi
	done

	if [[ -f "$repo_dir/go.mod" ]]; then
		module_path="$(awk '/^module / { print $2; exit }' "$repo_dir/go.mod")"
		if [[ "$module_path" != "github.com/septagon-oss/$repo" ]]; then
			report_failure "$repo has unexpected module path: ${module_path:-<missing>}"
		fi
		if [[ -f "$go_work" ]] && ! grep -Fq "./$repo" "$go_work"; then
			report_failure "OSS go.work does not include ./$repo"
		fi
	fi

done < "$manifest"

# The whole OSS workspace tree is swept for private references — every file,
# hidden dirs included, ignore files bypassed so a committed .ignore cannot
# blind the sweep. Links to the two public septagon-dev repos (platformkit,
# platformkit-community) are the only allowed matches. The architecture test
# and repository charter must name the forbidden prefix in order to enforce and
# document it; isolated module verification still covers their dependencies.
# go.sum records hashes of public modules only; go.work.sum stays in scope
# deliberately.
if command -v rg >/dev/null 2>&1; then
	if rg -nP --hidden --no-ignore \
		'github\.com/septagon-dev/(?!(platformkit|platformkit-community)([^A-Za-z0-9_-]|$))' \
		"$oss_root" \
		--glob '!**/.git/**' \
		--glob '!**/node_modules/**' \
		--glob '!**/.tmp-*/**' \
		--glob '!**/.generated/**' \
		--glob '!**/architecture_test.go' \
		--glob '!**/REPO_CHARTER.md' \
		--glob '!**/go.sum' >"$rg_output"; then
		report_failure "OSS workspace contains private github.com/septagon-dev references:"
		cat "$rg_output" >&2
	fi
fi

# The OSS workspace go.work must not resolve modules from outside its own
# tree: no parent traversal anywhere, no absolute use/replace targets.
oss_go_work="$oss_root/go.work"
if [[ -f "$oss_go_work" ]] && grep -nE '\.\./|(use|=>)[[:space:]]+(\.\.$|/|[A-Za-z]:)' "$oss_go_work" >"$rg_output"; then
	report_failure "OSS go.work resolves paths outside the workspace:"
	cat "$rg_output" >&2
fi

# A nested go.work would silently override the root one for builds below it.
if nested="$(find "$oss_root" -mindepth 2 -name 'go.work' -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.tmp-*/*' 2>/dev/null)" && [[ -n "$nested" ]]; then
	report_failure "nested go.work files may bypass workspace resolution: $nested"
fi

if (( failures > 0 )); then
	exit 1
fi

echo "open-core-workspace: validated OSS repos under $oss_root"
