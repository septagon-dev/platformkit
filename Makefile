SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help audit-oss validate-oss-split validate-open-core-workspace scaffold-oss-repos verify-product verify-federated-platform precommit

help:
	@echo "Available commands:"
	@echo "  make audit-oss - Check that this repo stays safe as the public OSS surface"
	@echo "  make validate-oss-split - Validate the septagon-oss repository split manifest"
	@echo "  make validate-open-core-workspace - Validate local OSS repos and go.work wiring"
	@echo "  make scaffold-oss-repos - Create local septagon-oss repo skeletons from the split manifest"
	@echo "  make verify-product  - Verify the curated flagship product contract across sibling platformkit repos"
	@echo "  make verify-federated-platform - Verify the federated platform contract across sibling platformkit repos"

audit-oss:
	@./scripts/audit_oss_surface.sh

validate-oss-split:
	@./scripts/validate_oss_repository_manifest.sh

validate-open-core-workspace:
	@./scripts/validate_open_core_workspace.sh

scaffold-oss-repos:
	@./scripts/scaffold_septagon_oss_repos.sh

verify-product:
	@./scripts/verify_product_contract.sh

verify-federated-platform:
	@./scripts/verify_federated_platform_contract.sh

precommit: audit-oss validate-oss-split validate-open-core-workspace verify-product verify-federated-platform
