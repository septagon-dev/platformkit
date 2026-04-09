SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help verify-product verify-federated-platform precommit

help:
	@echo "Available commands:"
	@echo "  make verify-product  - Verify the curated flagship product contract across sibling platformkit repos"
	@echo "  make verify-federated-platform - Verify the federated platform contract across sibling platformkit repos"

verify-product:
	@./scripts/verify_product_contract.sh

verify-federated-platform:
	@./scripts/verify_federated_platform_contract.sh

precommit: verify-product verify-federated-platform
