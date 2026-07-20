#!/usr/bin/env bash

# Shared resolver for the layered septagon-dev workspace. Release scripts use
# this authority instead of assuming that repositories are flat siblings.

platformkit_find_workspace_root() {
	if [[ $# -ne 1 || ! -d "$1" ]]; then
		return 2
	fi

	local cursor
	cursor="$(cd "$1" && pwd)"
	while [[ "$cursor" != "/" ]]; do
		if [[ -f "$cursor/go.work" ]]; then
			printf '%s\n' "$cursor"
			return 0
		fi
		cursor="$(cd "$cursor/.." && pwd)"
	done
	return 1
}

platformkit_repo_path() {
	if [[ $# -ne 2 || ! -d "$1" ]]; then
		return 2
	fi

	local workspace_root="$1"
	local repo_name="$2"
	case "$repo_name" in
		""|*/*|*".."*) return 2 ;;
	esac

	local layer candidate match=""
	local count=0
	for layer in core modules apps frontend runtime tooling infrastructure product overlays; do
		candidate="$workspace_root/$layer/$repo_name"
		if [[ -d "$candidate" ]]; then
			match="$candidate"
			count=$((count + 1))
		fi
	done

	if (( count != 1 )); then
		return 1
	fi
	printf '%s\n' "$match"
}

platformkit_oss_root() {
	if [[ $# -ne 1 || ! -d "$1" ]]; then
		return 2
	fi
	printf '%s/overlays/septagon-oss-workspace\n' "$1"
}
