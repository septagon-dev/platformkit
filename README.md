# platformkit

Flagship platformkit product surface and integrated release distribution.

## Purpose

Act as the public flagship for platformkit releases, launch
documentation, integrated developer experience, and curated code brought
over intentionally from the legacy monorepo.

This repo now also owns the curated product contract for the split-repo
workspace: the smallest cross-repo surface we are willing to stand behind as
one product.

## Current Status

This repository starts with a clean Septagon-native history. Code and
assets will be introduced intentionally rather than ported with the
legacy monorepo history.

## Boundaries

- Ownership contract: [REPO_CHARTER.md](REPO_CHARTER.md)
- Migration boundary: [docs/MIGRATION_BOUNDARY.md](docs/MIGRATION_BOUNDARY.md)
- Execution sequence: [ROADMAP.md](ROADMAP.md)

## Dependencies

For integrated flagship verification in the Septagon workspace, this repo expects
the sibling repositories referenced by [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md)
to exist next to it.

To validate the current curated product surface:

```bash
make verify-product
```

## First Milestones

1. Bootstrap the Septagon-native public repository with clean history.
2. Define and enforce a curated flagship product contract across the split repos.
3. Cut the first tagged release with release notes and artifacts.
4. Reintroduce product code in curated batches with explicit boundaries.
