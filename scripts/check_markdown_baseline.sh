#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
baseline="$repo_root/.markdownlint-baseline.tsv"
output="$(mktemp)"
counts="$(mktemp)"
npm_cache="$(mktemp -d)"
trap 'rm -f "$output" "$counts"; rm -rf "$npm_cache"' EXIT

if [[ ! -f "$baseline" ]]; then
	echo "markdownlint-ratchet: missing baseline: $baseline" >&2
	exit 2
fi

set +e
(
	cd "$repo_root"
	NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-$npm_cache}" \
		npx --yes markdownlint-cli2@0.23.2 \
			README.md \
			CONTRIBUTING.md \
			CODE_OF_CONDUCT.md \
			SECURITY.md \
			SUPPORT.md \
			REPO_CHARTER.md \
			ROADMAP.md \
			'docs/**/*.md'
) >"$output" 2>&1
status=$?
set -e

if (( status != 0 && status != 1 )); then
	cat "$output" >&2
	exit "$status"
fi
if ! grep -Eq '^Summary: [0-9]+ issues? in [0-9]+ files?$|^Summary: 0 error' "$output"; then
	echo "markdownlint-ratchet: markdownlint did not produce a valid summary" >&2
	cat "$output" >&2
	exit 2
fi

if rg -o 'MD[0-9]{3}' "$output" >/dev/null; then
	rg -o 'MD[0-9]{3}' "$output" |
		sort |
		uniq -c |
		awk '{ print $2 "\t" $1 }' >"$counts"
else
	: >"$counts"
fi

declare -A allowed=()
declare -A current=()
while IFS=$'\t' read -r rule maximum; do
	[[ -z "$rule" || "${rule:0:1}" == "#" ]] && continue
	allowed["$rule"]="$maximum"
done <"$baseline"
while IFS=$'\t' read -r rule count; do
	[[ -z "$rule" ]] && continue
	current["$rule"]="$count"
done <"$counts"

failures=0
for rule in "${!current[@]}"; do
	count="${current[$rule]}"
	maximum="${allowed[$rule]:-0}"
	if (( count > maximum )); then
		echo "markdownlint-ratchet: $rule has $count issues; maximum is $maximum" >&2
		rg -m 10 "$rule/" "$output" >&2 || true
		failures=$((failures + 1))
	fi
done

if (( failures > 0 )); then
	exit 1
fi

total="$(awk '{ sum += $2 } END { print sum + 0 }' "$counts")"
maximum_total="$(awk -F '\t' '$1 !~ /^#/ { sum += $2 } END { print sum + 0 }' "$baseline")"
echo "markdownlint-ratchet: PASS ($total issues; baseline maximum $maximum_total)"
