# pk-docs
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — an open-source Go backend for multi-tenant SaaS.

**What this is.** The public documentation source for PlatformKit OSS, kept as docs-as-code. It holds the architecture decision records (ADRs), architecture and convention guides, requirements, proposals, and the schemas and templates the docs portal is built from. If you want to understand *why* the module boundaries, authorization model, and entity metadata are shaped the way they are, this is where it is written down.

**How to use it.** Read the source directly, or build the portal.

```bash
# Browse in place:
#   adr/            architecture decision records
#   architecture/   system architecture guides
#   conventions.md  coding conventions (e.g. C-14 file-purpose rule)
#   requirements/   requirement specs

# Or build the docs site (Antora + Node):
npm install
npx antora antora-playbook.yml
```

**Depends on.** Nothing else in PlatformKit. It is prose and schemas, not a Go module in the build graph.

License: Apache-2.0.
