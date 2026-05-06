# Roadmap

## Stage

Bootstrap.

## Near-Term Milestones

1. Keep the public repo clean with `make audit-oss`.
2. Remove local/generated weight from all source repos before moving code.
3. Split private operations, staging, and customer-specific deployment state out
   of the public product surface.
4. Reduce the public module set to the OSS essentials pack defined in
   `docs/OSS_EXTRACTION_PLAN.md`.
5. Collapse app compositions into one starter app and one flagship example.
6. Cut the first tagged release with release notes and artifacts.

## Definition of Ready for Code Migration

1. Boundary documents are explicit and stable.
2. Baseline validation is green on `main`.
3. Remote repository exists in `septagon-dev`.
4. Code migration happens in curated commits, not history-preserving
   imports.
5. The surface passes `make audit-oss`.
