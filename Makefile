SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help audit-oss check-workspace-layout validate-oss-split validate-open-core-workspace check-ui-stack-docs check-markdown scaffold-oss-repos verify-product verify-federated-platform precommit

help:
	@echo "Available commands:"
	@echo "  make audit-oss - Check that this repo stays safe as the public OSS surface"
	@echo "  make check-workspace-layout - Verify layered workspace repository resolution"
	@echo "  make validate-oss-split - Validate the septagon-oss repository split manifest"
	@echo "  make validate-open-core-workspace - Validate local OSS repos and go.work wiring"
	@echo "  make check-ui-stack-docs - Reject stale Vue/React admin SPA doc claims"
	@echo "  make check-markdown - Enforce the non-increasing markdown debt ratchet"
	@echo "  make scaffold-oss-repos - Create local septagon-oss repo skeletons from the split manifest"
	@echo "  make verify-product  - Verify the curated flagship product contract across sibling platformkit repos"
	@echo "  make verify-federated-platform - Verify the federated platform contract across sibling platformkit repos"

audit-oss:
	@./scripts/audit_oss_surface.sh

check-workspace-layout:
	@bash ./scripts/workspace_layout_test.sh

validate-oss-split:
	@./scripts/validate_oss_repository_manifest.sh

validate-open-core-workspace:
	@./scripts/validate_open_core_workspace.sh

check-ui-stack-docs:
	@chmod +x ./scripts/check_ui_stack_consistency.sh
	@./scripts/check_ui_stack_consistency.sh

check-markdown:
	@./scripts/check_markdown_baseline.sh

scaffold-oss-repos:
	@./scripts/scaffold_septagon_oss_repos.sh

verify-product:
	@./scripts/verify_product_contract.sh

verify-federated-platform:
	@./scripts/verify_federated_platform_contract.sh

precommit: audit-oss check-workspace-layout validate-oss-split validate-open-core-workspace check-ui-stack-docs check-markdown verify-product verify-federated-platform
