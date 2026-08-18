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

# Developer-machine paths must not leak into the public surface: /home/<user>
# and /Users/<user> absolute paths, plus $HOME / ${HOME}-shaped paths. These
# get their own check (not the pattern loop above) because generic
# documentation placeholders (/home/user, /home/USER, /home/username,
# /home/you, /home/example and their /Users/ equivalents) are tolerated.
# Caveat: the filter drops whole matching LINES, so keep placeholder examples
# on their own lines. Legitimate $HOME usage in docs should be reworded (or
# this placeholder filter extended) rather than shipped as a false positive.
devpath_pattern='(/home|/Users)/[A-Za-z0-9._-]+|\$(HOME|\{HOME\})'
devpath_placeholder='(/home|/Users)/(user|USER|username|you|example)([^A-Za-z0-9._-]|$)'
devpath_matches="$(git grep -nE "$devpath_pattern" -- . ':(exclude)scripts/audit_oss_surface.sh' 2>/dev/null | grep -vE "$devpath_placeholder" || true)"
if [[ -n "$devpath_matches" ]]; then
	report_failure "developer-machine path leaked into public surface (pattern: $devpath_pattern)"
	echo "$devpath_matches" >&2
fi

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
