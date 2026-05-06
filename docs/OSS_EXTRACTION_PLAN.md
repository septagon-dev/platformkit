# OSS Extraction Plan

This is the removal-first plan for turning PlatformKit into a clean public
developer product.

## Objective

Open source the smallest useful PlatformKit surface:

- a CLI that can scaffold, run, verify, and explain a project
- backend runtime contracts that are stable enough to build against
- frontend and design-system contracts that map to Storybook and Figma
- the essential SaaS modules needed for AI SaaS products
- one starter app that demonstrates the whole path without private deployment
  assumptions

Everything else should be deleted, moved private, or split into separately
versioned packages.

## Immediate Findings

The current workspace is large for the wrong reasons:

- tracked source for the major repos is modest
- local Go caches, Node dependencies, E2E artifacts, and release workspaces
  dominate disk usage
- staging/GitOps/Synology state is mixed into the working workspace
- `platformkit-business-modules` has 50 modules, but the public core only needs
  a much smaller essentials pack
- `platformkit-apps` currently carries product composition, staging recovery,
  vertical demos, and test artifacts in one mental bucket

The first extraction rule is therefore simple: do not move everything into the
public product. Move only the surfaces that improve the first developer hour.

## Public Core

Keep these as first-class public surfaces.

| Surface | Keep because | Reduction rule |
| --- | --- | --- |
| `platformkit` | Public contract, quickstart, contributor entry point | No runtime code beyond scripts/docs unless it improves first-run DevX |
| `platformkit-devtools` | CLI, doctor, scaffold, verify, contract checks | Remove private staging/release assumptions from public commands |
| `platformkit-backend-kit` | Runtime, tenancy, auth, config, modules, observability | Delete duplicate middleware/config paths as soon as a canonical path exists |
| `platformkit-frontend-kit` | Renderer, components, Storybook, A2UI bridge | Keep only tokenized, registry-backed primitives and public previews |
| `platformkit-design-system` | Tokens, themes, provider contracts, parity checks | Provider adapters must be optional and target-neutral first |
| `platformkit-business-modules` | Essential SaaS domain pack | Split non-essential modules out of the OSS core |
| `platformkit-apps` | Starter app and composed example | Delete or move staging, private verticals, and release recovery code |
| `platformkit-shared` | Stable shared schemas | Shrink continuously; prefer moving packages back to owning repos |

## OSS Essentials Pack

Keep these modules in the public core first:

- `tenant_management`
- `user_management`
- `auth_management`
- `admin_management`
- `api_key_management`
- `audit_management`
- `entitlement_management`
- `notification_management`
- `mail_management`
- `chat_management`
- `billing_management`
- `content_management`
- `site_management`

These are enough to build credible AI SaaS products with tenancy, identity,
admin, billing, email, messaging, content, and auditability.

Everything else should be moved to a private/pro modules repo or released later
as independent packs. A module can return to OSS only when it has:

- a public README
- append-only migrations
- explicit ports/contracts
- working local tests
- no private tenant, staging, or customer assumptions
- a generated manifest that passes module contract checks

## Removal Backlog

### Phase 0: Delete Non-Source Weight

- Remove local `.tmp-*`, `.gocache`, `.gotmp`, `node_modules`, E2E videos,
  release workspaces, and generated probe files from worktrees.
- Tighten `.gitignore` across repos so these paths do not reappear.
- Keep this separate from source deletion so reviews stay safe.

### Phase 1: Move Private Operations Out

- Move GitOps mirrors, staging release requests, Synology routing notes, private
  registry references, and manual release recovery scripts out of the public
  OSS surface.
- Keep public deployment docs provider-neutral: Docker Compose, Kubernetes
  manifests, and documented env vars only.

### Phase 2: Split Modules

- Create an OSS essentials module set.
- Move vertical or specialized modules to private/pro packs.
- Replace "all modules" examples with explicit packs:
  `core`, `commerce`, `operations`, `community`, `ai`.

### Phase 3: Collapse Apps

- Keep one `starter` app optimized for first-run DevX.
- Keep one `flagship` app that demonstrates composition.
- Move demo verticals and staging-specific seed data out of public repos.

### Phase 4: Shrink Shared

- For every package in `platformkit-shared`, assign an owner repo.
- Move anything frontend-only, backend-only, or design-only back to its owner.
- Leave only stable wire schemas and cross-runtime vocabulary.

## DevX Standard

The public path should feel like this:

```bash
platformkit doctor
platformkit new my-saas --pack core
cd my-saas
platformkit up
platformkit verify
platformkit explain modules
```

The public repo must not require private GitHub access, private Gitea access,
local Synology routing, staging DNS, or unpublished tokens.

## Guardrails

Before code is added to the public surface, check:

- Does this improve the first developer hour?
- Is there one canonical path?
- Is the owner repo obvious?
- Can it run without private infrastructure?
- Does it have a small, documented contract?
- Can it be verified by a CLI command?
- Can it be deleted later without breaking unrelated surfaces?

If the answer is no, it stays private or waits.
