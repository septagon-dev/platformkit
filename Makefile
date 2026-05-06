SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help audit-oss verify-product verify-federated-platform precommit

help:
	@echo "Available commands:"
	@echo "  make audit-oss - Check that this repo stays safe as the public OSS surface"
	@echo "  make verify-product  - Verify the curated flagship product contract across sibling platformkit repos"
	@echo "  make verify-federated-platform - Verify the federated platform contract across sibling platformkit repos"

audit-oss:
	@./scripts/audit_oss_surface.sh

verify-product:
	@./scripts/verify_product_contract.sh

verify-federated-platform:
	@./scripts/verify_federated_platform_contract.sh

precommit: audit-oss verify-product verify-federated-platform
