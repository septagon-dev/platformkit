# platformkit

The public flagship repository for the platformkit product.

This is the repo we use to present the product to the community, publish the
curated cross-repo contract we are willing to stand behind, and ship the
integrated release surface of the platform.

## Start here

- Product contract: [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md)
- Roadmap: [ROADMAP.md](ROADMAP.md)
- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Support paths: [SUPPORT.md](SUPPORT.md)
- Security reporting: [SECURITY.md](SECURITY.md)
- Community discussions: [septagon-dev/platformkit-community](https://github.com/septagon-dev/platformkit-community)

## What belongs in this repository

- The public flagship product contract
- Launch-facing documentation and release guidance
- Cross-repo verification for the curated product surface
- The smallest integrated surface we are willing to support as one product

## What does not belong here

- Module-local implementation work that should live in the owning repo
- Broad workspace experiments that are not part of the flagship product surface
- Internal-only agent instructions or contributor metadata that do not help the community

## Repository map

- [README.md](README.md): public entry point
- [REPO_CHARTER.md](REPO_CHARTER.md): ownership and scope
- [ROADMAP.md](ROADMAP.md): execution sequence and launch priorities
- [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md): curated cross-repo contract
- [docs/FEDERATED_PLATFORM_AUDIT.md](docs/FEDERATED_PLATFORM_AUDIT.md): federated platform checks
- [docs/MIGRATION_BOUNDARY.md](docs/MIGRATION_BOUNDARY.md): migration rules

## Verification

For integrated flagship verification in the Septagon workspace, this repo expects
the sibling repositories referenced by
[docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md) to exist next to it.

Validate the curated product surface:

```bash
make verify-product
```

Validate the broader federated platform contract:

```bash
make verify-federated-platform
```

## Community workflow

- Questions, launch feedback, and roadmap discussion belong in
  [platformkit-community](https://github.com/septagon-dev/platformkit-community).
- Bugs and product-surface gaps belong in this repository.
- Security issues must not be reported publicly. Use the process in
  [SECURITY.md](SECURITY.md).

## Current status

This repository keeps a clean Septagon-native history. Code and assets are only
introduced intentionally, with explicit repository boundaries and launch-facing
documentation.
