#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

cd "$repo_root"

failures=0

report_failure() {
	echo "oss-audit: $*" >&2
	failures=$((failures + 1))
}

require_file() {
	local path="$1"
	if [[ ! -f "$path" ]]; then
		report_failure "missing required public file: $path"
	fi
}

require_file README.md
require_file LICENSE
require_file CONTRIBUTING.md
require_file SECURITY.md
require_file docs/PRODUCT_CONTRACT.md
require_file docs/OSS_EXTRACTION_PLAN.md
require_file docs/WORKSPACE_AUTHORING_CONTRACT.md

for generated_path in \
	.gocache \
	.gotmp \
	.tmp-go-cache \
	.tmp-go-modcache \
	.tmp-go-path \
	.tmp-go-tmp \
	complete-saas-monolith/.gocache \
	node_modules \
	dist \
	build
do
	if [[ -e "$generated_path" ]]; then
		report_failure "generated artifact must not be present in public repo: $generated_path"
	fi
done

for pattern in \
	'192\.168\.' \
	'94\.61\.' \
	'synology\.internal' \
	'platformkit-gitea-tmp' \
	'\.tmp-release-workspace' \
	'GITEA_TOKEN' \
	'SEPTAGON_MODULES_TOKEN' \
	'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY'
do
	if matches="$(git grep -nE "$pattern" -- . ':(exclude)scripts/audit_oss_surface.sh' 2>/dev/null || true)" && [[ -n "$matches" ]]; then
		report_failure "forbidden private/deployment marker matched pattern: $pattern"
		echo "$matches" >&2
	fi
done

max_bytes=$((1024 * 1024))
while IFS= read -r -d '' file; do
	if [[ ! -f "$file" ]]; then
		continue
	fi
	size="$(wc -c < "$file")"
	if (( size > max_bytes )); then
		report_failure "tracked file exceeds 1 MiB public-surface limit: $file ($size bytes)"
	fi
done < <(git ls-files -z)

if (( failures > 0 )); then
	exit 1
fi

echo "oss-audit: public surface checks passed"
