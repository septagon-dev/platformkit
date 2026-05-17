#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
manifest="${MANIFEST:-$repo_root/docs/OSS_REPOSITORY_MANIFEST.tsv}"
target_root="${1:-$repo_root/../septagon-oss-workspace}"
org="${OSS_ORG:-septagon-oss}"
init_git="${INIT_GIT:-0}"

"$script_dir/validate_oss_repository_manifest.sh" "$manifest" >/dev/null

mkdir -p "$target_root"

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

write_if_missing() {
	local path="$1"
	shift
	if [[ -e "$path" ]]; then
		return
	fi
	mkdir -p "$(dirname "$path")"
	printf '%s\n' "$@" > "$path"
}

copy_if_present() {
	local src="$1"
	local dst="$2"
	if [[ -f "$src" && ! -e "$dst" ]]; then
		cp "$src" "$dst"
	fi
}

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
	line="${raw_line//$'\t'/|}"
	IFS='|' read -r repo stage source_repo source_paths visibility role depends_on pro_extension extra <<< "$line"
	[[ -z "${repo:-}" || "${repo:0:1}" == "#" ]] && continue

	repo_dir="$target_root/$repo"
	mkdir -p "$repo_dir/docs"

	write_if_missing "$repo_dir/README.md" \
		"# $repo" \
		"" \
		"$role" \
		"" \
		"## Status" \
		"" \
		"This repository is part of the PlatformKit OSS split under \`$org\`." \
		"" \
		"- Stage: $stage" \
		"- Visibility: $visibility" \
		"- Source workspace repo: \`$source_repo\`" \
		"- Source paths: \`$source_paths\`" \
		"" \
		"## Verification" \
		"" \
		"Verification commands are added when curated source is imported."

	write_if_missing "$repo_dir/docs/SOURCE_BOUNDARY.md" \
		"# Source Boundary" \
		"" \
		"- OSS repo: \`$org/$repo\`" \
		"- Source workspace repo: \`$source_repo\`" \
		"- Source paths: \`$source_paths\`" \
		"- Depends on: \`${depends_on:-none}\`" \
		"- Pro extension: \`${pro_extension:-none}\`" \
		"" \
		"Curated source must be copied in intentionally. Do not bulk-copy client, demo, staging, generated, cache, or private deployment state."

	write_if_missing "$repo_dir/.gitignore" \
		".DS_Store" \
		".env" \
		".env.*" \
		"!.env.example" \
		".tmp*" \
		".cache*" \
		".gocache" \
		".gotmp" \
		"node_modules/" \
		"dist/" \
		"build/" \
		"coverage.out" \
		"playwright-report/" \
		"test-results/"

	write_if_missing "$repo_dir/.github/CODEOWNERS" \
		"* @$org/maintainers"

	copy_if_present "$repo_root/LICENSE" "$repo_dir/LICENSE"
	copy_if_present "$repo_root/SECURITY.md" "$repo_dir/SECURITY.md"
	copy_if_present "$repo_root/CONTRIBUTING.md" "$repo_dir/CONTRIBUTING.md"
	copy_if_present "$repo_root/CODE_OF_CONDUCT.md" "$repo_dir/CODE_OF_CONDUCT.md"

	if [[ "$init_git" == "1" && ! -d "$repo_dir/.git" ]]; then
		git -C "$repo_dir" init -b main >/dev/null
		git -C "$repo_dir" remote add origin "git@github.com:$org/$repo.git"
	fi

	printf 'scaffolded %s\n' "$repo_dir"
done < "$manifest"

printf 'septagon-oss scaffold complete: %s\n' "$target_root"
printf 'set INIT_GIT=1 to initialize repos and add git@github.com:%s/<repo>.git remotes\n' "$org"
