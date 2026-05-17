#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$repo_root/.." && pwd)"
manifest="${1:-$repo_root/docs/OSS_REPOSITORY_MANIFEST.tsv}"

if [[ ! -f "$manifest" ]]; then
	echo "oss-split-manifest: missing manifest: $manifest" >&2
	exit 1
fi

failures=0
declare -A repos=()
declare -A stages=()

report_failure() {
	echo "oss-split-manifest: $*" >&2
	failures=$((failures + 1))
}

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

line_number=0
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
	line_number=$((line_number + 1))
	line="${raw_line//$'\t'/|}"
	IFS='|' read -r repo stage source_repo source_paths visibility role depends_on pro_extension extra <<< "$line"
	[[ -z "${repo:-}" || "${repo:0:1}" == "#" ]] && continue

	if [[ -n "${extra:-}" ]]; then
		report_failure "line $line_number has too many columns"
		continue
	fi

	for field in repo stage source_repo source_paths visibility role; do
		if [[ -z "${!field:-}" ]]; then
			report_failure "line $line_number missing required field: $field"
		fi
	done

	if [[ ! "$repo" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
		report_failure "line $line_number repo name is not kebab-case: $repo"
	fi
	if [[ ! "$stage" =~ ^[0-9]+$ ]]; then
		report_failure "line $line_number stage is not numeric for $repo: $stage"
	fi
	case "$visibility" in
		public|public-later) ;;
		*) report_failure "line $line_number visibility must be public or public-later for $repo: $visibility" ;;
	esac

	if [[ -n "${repos[$repo]:-}" ]]; then
		report_failure "duplicate repo entry: $repo"
	fi
	repos[$repo]=1
	stages[$repo]="$stage"

	source_dir="$workspace_root/$source_repo"
	if [[ ! -d "$source_dir" ]]; then
		report_failure "source repo for $repo does not exist: $source_repo"
		continue
	fi

	IFS=',' read -r -a paths <<< "$source_paths"
	for raw_path in "${paths[@]}"; do
		path="$(trim "$raw_path")"
		[[ -z "$path" ]] && continue
		if [[ "$path" == "." ]]; then
			continue
		fi
		if [[ "$path" == *".."* || "$path" == /* ]]; then
			report_failure "unsafe source path for $repo: $path"
			continue
		fi
		if [[ ! -e "$source_dir/$path" ]]; then
			report_failure "source path for $repo does not exist: $source_repo/$path"
		fi
	done
done < "$manifest"

line_number=0
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
	line_number=$((line_number + 1))
	line="${raw_line//$'\t'/|}"
	IFS='|' read -r repo stage source_repo source_paths visibility role depends_on pro_extension extra <<< "$line"
	[[ -z "${repo:-}" || "${repo:0:1}" == "#" ]] && continue
	[[ -z "${depends_on:-}" ]] && continue

	IFS=',' read -r -a deps <<< "$depends_on"
	for raw_dep in "${deps[@]}"; do
		dep="$(trim "$raw_dep")"
		[[ -z "$dep" ]] && continue
		if [[ -z "${repos[$dep]:-}" ]]; then
			report_failure "line $line_number dependency for $repo is not declared in manifest: $dep"
		fi
		if [[ -n "${stages[$dep]:-}" && -n "${stages[$repo]:-}" && "${stages[$dep]}" =~ ^[0-9]+$ && "${stages[$repo]}" =~ ^[0-9]+$ ]]; then
			if (( stages[$dep] > stages[$repo] )); then
				report_failure "line $line_number dependency $dep is staged after dependent $repo"
			fi
		fi
	done
done < "$manifest"

if (( failures > 0 )); then
	exit 1
fi

echo "oss-split-manifest: validated $((${#repos[@]})) repository entries"
printf 'oss-split-manifest: publish order:\n'
for repo in "${!repos[@]}"; do
	printf '%s\t%s\n' "${stages[$repo]}" "$repo"
done | sort -n -k1,1 -k2,2 | while IFS=$'\t' read -r stage repo; do
	printf '  stage %s: %s\n' "$stage" "$repo"
done
