SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help verify-product precommit

help:
	@echo "Available commands:"
	@echo "  make verify-product  - Verify the curated flagship product contract across sibling platformkit repos"

verify-product:
	@./scripts/verify_product_contract.sh

precommit: verify-product
