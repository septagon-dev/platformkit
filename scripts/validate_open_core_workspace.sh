#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$repo_root/.." && pwd)"
oss_root="$workspace_root/septagon-oss-workspace"
manifest="${1:-$repo_root/docs/OSS_REPOSITORY_MANIFEST.tsv}"
go_work="$workspace_root/go.work"
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
		if [[ -f "$go_work" ]] && ! grep -Fq "./septagon-oss-workspace/$repo" "$go_work"; then
			report_failure "go.work does not include ./septagon-oss-workspace/$repo"
		fi
	fi

	if command -v rg >/dev/null 2>&1; then
		if rg -n "github.com/septagon-dev/" "$repo_dir" \
			--glob '!/.git/**' \
			--glob '!node_modules/**' \
			--glob '!.tmp-*/**' \
			--glob '!.generated/**' \
			--glob '!go.sum' >"$rg_output"; then
			report_failure "$repo contains private github.com/septagon-dev imports or references"
			cat "$rg_output" >&2
		fi
	fi
done < "$manifest"

if (( failures > 0 )); then
	exit 1
fi

echo "open-core-workspace: validated OSS repos under $oss_root"
