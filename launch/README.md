# PlatformKit OSS — Launch Kit Index

This directory is the complete launch kit for the PlatformKit OSS public
launch. Everything you need to publish — positioning, READMEs, docs, channel
posts, images, and the publish process — lives here.

> **State (2026-07-29):** the code has been **public since 2026-07-22**
> (17 repos; front door at v0.14.1, 20 GitHub Releases; docs live at
> <https://septagon-oss.github.io/pk-docs>) but **nothing has been announced**.
> The kit's remaining job is the announcement.

> **Do not publish until [`CHECKLIST.md`](./CHECKLIST.md) §A pre-flight is fully
> green.** §A is the gate; nothing goes public before every box is checked.

**Repo set (canonical — use these terms everywhere):**

- **11 module repos** (Go modules, first tagged `v0.1.0`; versions have since
  iterated): `pk-shared`, `pk-core`, `pk-runtime`, `pk-design`, `pk-client`,
  `pk-registry`, `pk-testkit`, `pk-modules`, `pk-tools`, `pk-apps`, `pk-ui`.
- **1 front-door repo**: `platformkit` — created + tagged at the 2026-07-22
  flip, the public entry point
  (`go run github.com/septagon-oss/platformkit@latest`), now at v0.14.1.
- **1 docs repo**: `pk-docs` — published but **not** a Go module and not on the
  build train.
- **Excluded** from the launch train: `pk-deploy` and the internal-only repos.
  (The public org has since grown to 17 repos — see CHECKLIST §A3.)

`pk-registry` and `pk-ui` are module repos and keep their own existing
READMEs if no draft exists in `drafts/readmes/`.

## Order to use this kit

1. **Read the foundation** — `NARRATIVE.md` (positioning), `VERIFIED_RUN.md`
   (what's true), `RELEASE_AND_RUN_MODEL.md` (how it ships).
2. **Execute the release** — follow `RELEASE_AND_RUN_MODEL.md` §8 + `FLIP_RUNBOOK.md` §A.
3. **Place the files** — copy `drafts/readmes/*` and `drafts/docs/*` into their
   repos (CHECKLIST §A4 / launch task T14).
4. **Generate the images** — per `images/IMAGE_PROMPTS.md`.
5. **Work the checklist** — `CHECKLIST.md` §A → §B → §C.

---

## Foundation (read first — the source of truth)

| File | What it is | When to use it |
|------|-----------|----------------|
| [`NARRATIVE.md`](./NARRATIVE.md) | Positioning source-of-truth. Every other launch text quotes from here. | Before writing or editing any copy. Settle "what do we claim" here. |
| [`VERIFIED_RUN.md`](./VERIFIED_RUN.md) | Ground-truth run log. No command appears in any text unless it's verified here. | When you need to confirm a claim, command, port, credential, or HTTP code is real. |
| [`RELEASE_AND_RUN_MODEL.md`](./RELEASE_AND_RUN_MODEL.md) | The gated release runbook: run model, no-replace decision, clean `v0.1.0` tags, retract `v0.0.0`, leaf-first push order, front-door repo, post-push verification. **§8 GATED PUSH STEPS is authoritative.** | When you actually release. The CHECKLIST references it; do not duplicate its steps. |
| [`FLIP_RUNBOOK.md`](./FLIP_RUNBOOK.md) | Launch-mechanics blockers (A1–A6): CI CODEOWNERS, docs version labels, README links, visibility flip, proxy/sumdb post-checks. | Alongside the release runbook — clear §A blockers before push. |

## READMEs (`drafts/readmes/`)

Drafted READMEs awaiting placement into their repos (CHECKLIST §A4).

| File | Target repo |
|------|-------------|
| [`drafts/readmes/platformkit-frontdoor.md`](./drafts/readmes/platformkit-frontdoor.md) | `septagon-oss/platformkit` (front door) |
| [`drafts/readmes/pk-core.md`](./drafts/readmes/pk-core.md) | `pk-core` |
| [`drafts/readmes/pk-modules.md`](./drafts/readmes/pk-modules.md) | `pk-modules` |
| [`drafts/readmes/pk-runtime.md`](./drafts/readmes/pk-runtime.md) | `pk-runtime` |
| [`drafts/readmes/pk-apps.md`](./drafts/readmes/pk-apps.md) | `pk-apps` |
| [`drafts/readmes/pk-shared.md`](./drafts/readmes/pk-shared.md) | `pk-shared` |
| [`drafts/readmes/pk-client.md`](./drafts/readmes/pk-client.md) | `pk-client` |
| [`drafts/readmes/pk-design.md`](./drafts/readmes/pk-design.md) | `pk-design` |
| [`drafts/readmes/pk-tools.md`](./drafts/readmes/pk-tools.md) | `pk-tools` |
| [`drafts/readmes/pk-testkit.md`](./drafts/readmes/pk-testkit.md) | `pk-testkit` |
| [`drafts/readmes/pk-docs.md`](./drafts/readmes/pk-docs.md) | `pk-docs` |

## Docs (`drafts/docs/` → `pk-docs`)

Drafted documentation pages awaiting placement into `pk-docs` (CHECKLIST §A4).

| File | What it is |
|------|-----------|
| [`drafts/docs/quickstart.md`](./drafts/docs/quickstart.md) | One-command quickstart — clone, `go run .`, first login. |
| [`drafts/docs/architecture.md`](./drafts/docs/architecture.md) | How an app composes: ports/contracts → core → modules → clients. |
| [`drafts/docs/add-a-module.md`](./drafts/docs/add-a-module.md) | How to add your own module the way the built-ins are added. |
| [`drafts/docs/open-core.md`](./drafts/docs/open-core.md) | The open-core line: free substrate vs Pro, drawn at the provider. |
| [`drafts/docs/faq.md`](./drafts/docs/faq.md) | FAQ. Fold the real launch-thread questions in here (CHECKLIST §C). |
| [`drafts/docs/SECURITY.md`](./drafts/docs/SECURITY.md) | Security policy / disclosure (also per-repo `SECURITY.md`). |
| [`drafts/docs/CONTRIBUTING.md`](./drafts/docs/CONTRIBUTING.md) | Contribution guide (also per-repo `CONTRIBUTING.md`). |

## Channels (`channels/`)

Per-channel launch copy. Post in the order CHECKLIST §B prescribes (blog first;
HN; then r/golang + Lobsters; X; Product Hunt; LinkedIn).

| File | What it is |
|------|-----------|
| [`channels/blog-post.md`](./channels/blog-post.md) | The canonical launch post; publish **first** — other channels link to it. |
| [`channels/show-hn.md`](./channels/show-hn.md) | Show HN title (use exactly) + body + URL. |
| [`channels/hn-comment-seeds.md`](./channels/hn-comment-seeds.md) | Prepared honest answers to likely HN questions. Keep open during launch hour. **Not** fake plants. |
| [`channels/r-golang.md`](./channels/r-golang.md) | r/golang adaptation. |
| [`channels/lobsters.md`](./channels/lobsters.md) | Lobsters adaptation. |
| [`channels/x-thread.md`](./channels/x-thread.md) | X/Twitter thread. |
| [`channels/product-hunt.md`](./channels/product-hunt.md) | Product Hunt copy (if launching same day). |
| [`channels/linkedin.md`](./channels/linkedin.md) | LinkedIn post. |

## Images (`images/`)

| File | What it is |
|------|-----------|
| [`images/IMAGE_PROMPTS.md`](./images/IMAGE_PROMPTS.md) | Copy-paste specs for all four assets: **hero** via fal.ai; **OG card** via HTML/CSS (screenshot 1200×630); **architecture** via Mermaid; **built-with badge** via SVG. All load-bearing text is deterministic (HTML/SVG/Mermaid), never AI-rendered. |

## Process

| File | What it is |
|------|-----------|
| [`CHECKLIST.md`](./CHECKLIST.md) | The publish checklist: §A pre-flight (the gate) → §B launch hour → §C day-after. **Work this last, and do not publish until §A is green.** |

Spec + plan behind this kit live under the repo's `docs/superpowers/`:
- `docs/superpowers/specs/2026-06-02-platformkit-oss-launch-kit-design.md`
- `docs/superpowers/plans/2026-06-02-platformkit-oss-launch-kit.md`

---

## Review gates that ran

- **Claude adversarial passes:** G2 (narrative red-team), G3 (hostile pass on
  launch texts), G4 (READMEs-vs-reality).
- **Codex:** ran the **code-fix review** (the cold-DB first-run fix in
  `VERIFIED_RUN.md` §9).
- **Codex was usage-capped for the text gates** (G2/G3/G4 ran on Claude alone) —
  noted so the gap is explicit, not hidden.
