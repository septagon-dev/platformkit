#!/usr/bin/env bash
# check_ui_stack_consistency.sh — fail CI when canonical OSS/ADR docs regress to
# incorrect Vue/React admin SPA claims. Product runtime is gomponents + HTMX
# (ADR-0000); public docs may use Astro Starlight (ADR-0027) separately.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
workspace_root="$(cd "$repo_root/.." && pwd)"

failures=0
scan_roots=(
	"$repo_root/docs"
	"$workspace_root/platformkit-docs/adr"
	"$workspace_root/septagon-oss-workspace/pk-modules/pkg/admin"
	"$workspace_root/platformkit-frontend-kit/docs"
)

# Patterns that indicate stale mischaracterization of the product admin UI.
# Intentional comparisons (e.g. "smaller than React/Vue") and Slidev course
# decks are excluded via path globs below.
bad_patterns=(
	'Vue / registry'
	'Vue/registry'
	'Vue admin UI'
	'vue admin UI'
	'React admin UI'
	'SPA admin UI'
	'PKDS is React'
	'React-based PKDS'
)

# Lines containing these negations are allowed (they document what we are NOT).
negation_markers=(
	'no Vue'
	'not use Vue'
	'no React'
	'not React'
	'no Vue/React'
	'no client-side admin SPA'
	'no Vue, React'
)

report_failure() {
	echo "ui-stack-consistency: $*" >&2
	failures=$((failures + 1))
}

line_is_negated() {
	local line="$1"
	for marker in "${negation_markers[@]}"; do
		if [[ "$line" == *"$marker"* ]]; then
			return 0
		fi
	done
	return 1
}

if ! command -v rg >/dev/null 2>&1; then
	echo "ui-stack-consistency: ripgrep (rg) is required" >&2
	exit 1
fi

for root in "${scan_roots[@]}"; do
	[[ -d "$root" ]] || continue
	for pattern in "${bad_patterns[@]}"; do
		while IFS= read -r match; do
			[[ -z "$match" ]] && continue
			line="${match#*:}"
			line="${line#*:}"
			if line_is_negated "$line"; then
				continue
			fi
			report_failure "forbidden phrase '$pattern' under $root:"
			echo "$match" >&2
		done < <(rg -n --fixed-strings "$pattern" "$root" \
			--glob '!**/platformkit-courses/**' \
			--glob '!**/decisions/0001-component-model-with-typed-slots.md' \
			--glob '!**/node_modules/**' \
			--glob '!.git/**' 2>/dev/null || true)
	done
done

# Canonical docs must cite ADR-0000 for product UI stack.
canonical="$repo_root/docs/OSS_OPEN_CORE_SPLIT.md"
if [[ -f "$canonical" ]] && ! rg -q 'ADR-0000' "$canonical"; then
	report_failure "$canonical must reference ADR-0000 as the product UI authority"
fi

if (( failures > 0 )); then
	exit 1
fi

echo "ui-stack-consistency: product UI docs aligned with ADR-0000 (gomponents + HTMX)"
