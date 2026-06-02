# PlatformKit OSS Launch Kit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a complete, dummy-proof, DX-first launch kit for the `septagon-oss` OSS org — verified run path, front-door + sub-repo READMEs, docs, channel texts, fal.ai image prompt-specs, and a publish checklist — so a cold Go dev goes from a Show HN link to "running locally + understands it" in ≤10 minutes.

**Architecture:** Front-door = a new `septagon-oss/platformkit` meta repo (approach A) with the CLI as the hero verb (B) and the starter app as the proof (C). Every command in every artifact is copied verbatim from a ground-truth run log (`VERIFIED_RUN.md`) — the anti-lying mechanism. Codex (gpt-5.5 xhigh) is the hostile reviewer at four gates: run path, narrative, public texts, READMEs-vs-reality.

**Tech Stack:** Markdown (all artifacts), Go 1.26 workspace (`septagon-oss-workspace/`), `make`/`go run` for the run path, GitHub CLI (`gh`) for repo metadata + security settings, fal.ai (user-operated) for images, Mermaid/SVG for diagrams, Codex CLI via `/codex:*` slash commands.

**Voice:** Septagon (company) as a plain-spoken technical peer. Zero hype. Same voice across all channels.

**Spec:** `docs/superpowers/specs/2026-06-02-platformkit-oss-launch-kit-design.md`

---

## Conventions used in every task

- **Working repo:** unless stated otherwise, files land in `/home/jplr/gitrepos/septagon-dev/platformkit/launch/` (drafts/spine/verification) on branch `launch/oss-launch-kit-spec`. Final user-facing files are written into their **target** repos (front-door repo, sub-repos, `pk-docs`) in their own branches.
- **Acceptance gate types:**
  - **STRANGER TEST** — re-read as a cold Go dev; if anything is unclear, unproven, or hype, fix it.
  - **CODEX Gx** — run the named Codex adversary pass (Section "Codex gates" below) and resolve findings before marking done.
  - **LINKCHECK** — every link/command in the file resolves / has been run.
- **Commit cadence:** one commit per task minimum. Conventional commits, repo as scope.
- **Ground truth:** no command appears in any artifact unless it exists verbatim in `launch/VERIFIED_RUN.md`.

### Codex gates (invoked from the platformkit repo)

- **G1 (run path):** `/codex:rescue --background` — "Independently clone the septagon-oss public surface cold and run it; log every friction point and every assumption you had to make. Do not trust my run log."
- **G2 (narrative):** `/codex:adversarial-review` on `launch/NARRATIVE.md` — "Red-team as a cynical Show HN reader. Flag every claim not provable by a link and every hype word."
- **G3 (public texts):** `/codex:adversarial-review` on `launch/channels/*` — "For each post: overclaim, tone-misfit for the channel, and the single top dunk comment it invites."
- **G4 (READMEs vs reality):** `/pk-second-opinion` on the README diffs — "Verify every command and capability claim against actual code + launch/VERIFIED_RUN.md. Flag drift."

---

## File Structure (decomposition lock-in)

**In `platformkit/launch/` (planning + drafts + machinery):**
- `launch/README.md` — index of the kit + how to use it
- `launch/NARRATIVE.md` — the positioning spine (single source of truth)
- `launch/VERIFIED_RUN.md` — ground-truth run log
- `launch/CHECKLIST.md` — pre-flight + launch-hour + day-after
- `launch/channels/{show-hn,hn-comment-seeds,r-golang,lobsters,product-hunt,x-thread,linkedin,blog-post}.md`
- `launch/images/IMAGE_PROMPTS.md` — fal.ai prompt-specs
- `launch/drafts/readmes/` — README drafts before they're placed into target repos

**In target repos (final placement):**
- `septagon-oss/platformkit` (new repo): `README.md`, `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, `go.work`, architecture diagram, `.github/`
- `septagon-oss/pk-*` (10 repos): `README.md` each
- `septagon-oss/pk-docs`: `quickstart.md`, `architecture.md`, `add-a-module.md`, `open-core.md`, `faq.md`, `CONTRIBUTING.md`, `SECURITY.md`

---

## Phase 1 — Verify the run path (gates everything)

### Task 1: Capture the ground-truth run log

**Files:**
- Create: `platformkit/launch/VERIFIED_RUN.md`

- [ ] **Step 1: Inventory what "run it" even means today.** Inspect the real entry points; do not assume the CLI works.

Run:
```bash
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace
ls pk-apps/apps 2>/dev/null; ls pk-apps/examples 2>/dev/null
grep -rn "func main" pk-apps --include=*.go | head
find . -maxdepth 2 -name Makefile | xargs grep -l "up\|run\|showroom" 2>/dev/null
ls pk-tools/cmd 2>/dev/null
```
Expected: a list of runnable mains / make targets. Note which exist. This decides the hero verb (open question §8.1 of the spec).

- [ ] **Step 2: Run the canonical path cold.** In a scratch dir, execute the most-likely "first command" found in Step 1 (try in order: `platformkit up` / `go run .` in the starter app / `make up`). Capture *everything*.

Run (example — adapt to what Step 1 found):
```bash
export GOCACHE="$PWD/.tmp-go-cache" GOMODCACHE="$PWD/.tmp-go-mod" GOTMPDIR="$PWD/.tmp-go-tmp" TMPDIR="$PWD/.tmp-go-tmp"
mkdir -p "$GOCACHE" "$GOMODCACHE" "$GOTMPDIR"
cd /home/jplr/gitrepos/septagon-dev/septagon-oss-workspace/pk-apps
time go run ./apps/starter-saas 2>&1 | tee /tmp/pk-firstrun.log &
sleep 8
curl -fsS http://localhost:8080/healthz; echo
curl -fsS -i http://localhost:8080/admin | head -5
```
Expected: server listens, `/healthz` returns 200, `/admin` serves a login. Record the actual seeded login and the time-to-first-success.

- [ ] **Step 3: Write `VERIFIED_RUN.md`** documenting the EXACT working sequence and every friction point.

Content (real values, not placeholders): prerequisites actually needed (Go version from `go.work`, no CGO, no npm), the verbatim command block that worked, the exact startup banner, the admin URL + seeded creds, time-to-admin, and a "Gotchas a stranger hits" list (port 8080 busy, Go too old, first-build compile time, etc.). If the path does NOT work, write the failure precisely and STOP — escalate as a launch blocker (do not write around it).

- [ ] **Step 4: LINKCHECK / self-verify.** Re-run the exact block from `VERIFIED_RUN.md` in a fresh shell. It must reproduce.

Run: re-execute the recorded block. Expected: identical success.

- [ ] **Step 5: Commit.**
```bash
cd /home/jplr/gitrepos/septagon-dev/platformkit
git add launch/VERIFIED_RUN.md
git commit -m "docs(platformkit): capture ground-truth OSS run log"
```

### Task 2: Codex G1 — independent cold-run

**Files:** Modify: `platformkit/launch/VERIFIED_RUN.md` (append "Codex friction" section)

- [ ] **Step 1: Dispatch Codex G1.** From the platformkit repo, run `/codex:rescue --background` with the G1 prompt (see Codex gates above). Wait for the report.

- [ ] **Step 2: Reconcile.** Append a "Codex friction findings" section to `VERIFIED_RUN.md`. For each friction Codex hit that a stranger would also hit, either (a) fix the minimal DX blocker in the relevant OSS repo, or (b) record it as a documented gotcha. Anything large → launch blocker list in `CHECKLIST.md` (created in Task 13).

- [ ] **Step 3: Commit.**
```bash
git add launch/VERIFIED_RUN.md
git commit -m "docs(platformkit): reconcile Codex cold-run friction into run log"
```

---

## Phase 2 — Narrative spine

### Task 3: Write the narrative spine

**Files:** Create: `platformkit/launch/NARRATIVE.md`

- [ ] **Step 1: Draft `NARRATIVE.md`** with exactly these sections, each pinned to a fact:

1. **One-line definition** (handshake) — plain, concrete. Starting point to refine: *"PlatformKit is an open-source Go substrate for building multi-tenant SaaS — auth, tenancy, admin, audit, API keys — composed as modules and running locally in one command."*
2. **The wedge** ("substrate, not scaffold") — 3 sentences, plain words, each provable by a link to running code.
3. **Honest open-core** — Apache-2.0; genuinely useful alone; a labeled Pro tier for hosted ops + pro modules; the commitment ("core contracts never leave OSS"). Stated early and plainly.
4. **AI-introspectable, de-hyped** — machine-readable module manifests + MCP server; one sentence, with a proof link.
5. **What this is NOT** — the anti-flame list: not no-code; not a Rails/Django replacement; not production-at-scale on the SQLite default; not adopt-wholesale.

Source material: `platformkit-marketing/copy/elevator-pitches.md` and `headline-variants.md`, simplified and de-jargoned (drop "governed product substrate" → "reusable SaaS backend"). Every capability claim must trace to something in `VERIFIED_RUN.md` or a real repo path.

- [ ] **Step 2: STRANGER TEST.** Re-read top-to-bottom as a tired senior Go dev who's never heard of this. Cut every adjective doing an engineer's job. Verify the one-liner is understandable with zero jargon.

- [ ] **Step 3: Commit.**
```bash
git add launch/NARRATIVE.md
git commit -m "docs(platformkit): add launch narrative spine"
```

### Task 4: Codex G2 — red-team the narrative

**Files:** Modify: `platformkit/launch/NARRATIVE.md`

- [ ] **Step 1: Dispatch Codex G2** (`/codex:adversarial-review` on `NARRATIVE.md`, cynical-HN-reader prompt).
- [ ] **Step 2: Fix every flagged unprovable claim and hype word.** For any claim Codex says "can't prove," either add the proof link or delete the claim.
- [ ] **Step 3: Commit.**
```bash
git add launch/NARRATIVE.md
git commit -m "docs(platformkit): harden narrative against adversarial HN read"
```

---

## Phase 3 — READMEs

### Task 5: Draft the front-door README

**Files:** Create: `platformkit/launch/drafts/readmes/platformkit-frontdoor.md`

- [ ] **Step 1: Draft the front-door README** with this exact section order (from spec §5.2):

1. One-line definition (from `NARRATIVE.md`) + hero image placeholder `![PlatformKit](docs/hero.png)` + badges (CI / Apache-2.0 / Go version from `go.work`).
2. **Quickstart** — the verbatim ≤5-line command block from `VERIFIED_RUN.md` that yields a browser admin, plus the seeded login. This is the first thing below the fold.
3. **What you get** — 5–8 capability bullets in plain nouns, only capabilities proven to exist (cross-check against `pk-modules` actual packages).
4. **What this is NOT** — the anti-flame list from `NARRATIVE.md`.
5. **How it fits together** — the formula in 3 sentences + `![Architecture](docs/architecture.svg)`.
6. **The repos** — a 10-row table: repo → one-line purpose (use the org descriptions already set on each repo as the seed, tightened).
7. **Open core** — one honest paragraph + link to `open-core.md`.
8. **Docs / Contributing / Security / License / Community** — link block.

- [ ] **Step 2: STRANGER TEST + LINKCHECK.** Every command runs (it's from the run log); every relative link target is listed in this plan; the "what you get" bullets match real `pk-modules` packages.
- [ ] **Step 3: Commit.**
```bash
git add launch/drafts/readmes/platformkit-frontdoor.md
git commit -m "docs(platformkit): draft front-door README"
```

### Task 6: Draft the 10 sub-repo READMEs

**Files:** Create: `platformkit/launch/drafts/readmes/{pk-core,pk-shared,pk-runtime,pk-design,pk-client,pk-tools,pk-modules,pk-apps,pk-testkit,pk-docs}.md`

- [ ] **Step 1: For each sub-repo, draft a ≤1-screen README** using the fixed 3-question template:

```markdown
# pk-<name>
> Part of **[PlatformKit](https://github.com/septagon-oss/platformkit)** — open-source Go substrate for multi-tenant SaaS.

**What this is.** <one sentence — the repo's single responsibility>

**How to use it.** <one minimal, real code/command example>

**Depends on.** <the pk-* repos it imports, from its go.mod>

See the [front door](https://github.com/septagon-oss/platformkit) to run the whole thing.
```

Right-size: `pk-core` and `pk-modules` get a short "Packages" table (real package list from the repo); `pk-shared` stays minimal. Pull the real dependency list from each repo's `go.mod`.

- [ ] **Step 2: STRANGER TEST per file.** Each answers what/how/depends-on in 30 seconds; the example is real.
- [ ] **Step 3: Commit.**
```bash
git add launch/drafts/readmes/
git commit -m "docs(platformkit): draft 10 sub-repo READMEs"
```

### Task 7: Codex G4 — READMEs vs reality

**Files:** Modify: `platformkit/launch/drafts/readmes/*`

- [ ] **Step 1: Dispatch Codex G4** (`/pk-second-opinion` on the README drafts, verify-against-code prompt).
- [ ] **Step 2: Fix drift.** Any command, package name, or capability that doesn't match actual code or `VERIFIED_RUN.md` is corrected. Re-run any corrected command.
- [ ] **Step 3: Commit.**
```bash
git add launch/drafts/readmes/
git commit -m "docs(platformkit): correct README drift flagged by Codex"
```

---

## Phase 4 — Docs (pk-docs)

### Task 8: Write the task-oriented docs

**Files (drafted in launch/, placed into pk-docs in Phase 7):**
- Create: `platformkit/launch/drafts/docs/{quickstart,architecture,add-a-module,open-core,faq}.md`

- [ ] **Step 1: `quickstart.md`** — the `VERIFIED_RUN.md` path expanded with "what just happened" after each command and "next: add-a-module.md".
- [ ] **Step 2: `architecture.md`** — core → modules → clients, plain words, with the diagram; one paragraph per layer; link to `PLATFORMKIT_FORMULA.md` concepts (re-explained, not just linked).
- [ ] **Step 3: `add-a-module.md`** — the smallest real end-to-end "build your own thing": scaffold/define a module, compose it, see it in admin. Commands sourced from real tooling found in Task 1. If scaffolding isn't in OSS yet, document the manual minimal path that actually works.
- [ ] **Step 4: `open-core.md`** — one OSS-owns / Pro-adds table sourced from engineering-spec §3 + the commitment paragraph.
- [ ] **Step 5: `faq.md`** — the 10 skeptical questions answered honestly (seeded from Task 11's comment seeds; if Task 11 not done yet, draft answers here first and reuse).
- [ ] **Step 6: STRANGER TEST.** Each page self-contained; no page requires another to make sense.
- [ ] **Step 7: Commit.**
```bash
git add launch/drafts/docs/
git commit -m "docs(platformkit): draft pk-docs quickstart/architecture/add-a-module/open-core/faq"
```

---

## Phase 5 — Channel texts

### Task 9: Write the Show HN hero text + comment seeds

**Files:**
- Create: `platformkit/launch/channels/show-hn.md`
- Create: `platformkit/launch/channels/hn-comment-seeds.md`

- [ ] **Step 1: `show-hn.md`** — Title (≤80 chars, no hype): `Show HN: PlatformKit – open-source Go substrate for multi-tenant SaaS`. Body: 2 short paragraphs (what it is from `NARRATIVE.md` + the one-command run from `VERIFIED_RUN.md`), the "what it is NOT" honesty, and the front-door link. No marketing tone.
- [ ] **Step 2: `hn-comment-seeds.md`** — pre-written honest answers to the 10 hardest questions: why-not-just-X (Supabase/Encore/Backstage/plain-Go), open-core rug-pull, SQLite-in-prod, why Go DI/fx, what's actually Pro, license, maturity/v0.0.0 honesty, who's behind it (Septagon), why now, how to extend. Each answer ≤5 sentences, links to proof.
- [ ] **Step 3: STRANGER/LINKCHECK.** Commands match run log; links resolve.
- [ ] **Step 4: Commit.**
```bash
git add launch/channels/show-hn.md launch/channels/hn-comment-seeds.md
git commit -m "docs(platformkit): write Show HN text + comment seeds"
```

### Task 10: Write the remaining channel adaptations

**Files:** Create: `platformkit/launch/channels/{r-golang,lobsters,product-hunt,x-thread,linkedin,blog-post}.md`

- [ ] **Step 1: `r-golang.md`** — technical, code-forward, no logos/marketing tone (community norms).
- [ ] **Step 2: `lobsters.md`** — short, technical, with suggested tags.
- [ ] **Step 3: `product-hunt.md`** — outcome-first tagline + maker's first comment.
- [ ] **Step 4: `x-thread.md`** — 5–7 posts, one idea each, note where the asciinema/gif goes.
- [ ] **Step 5: `linkedin.md`** — open-core + EU/sovereign angle, professional voice.
- [ ] **Step 6: `blog-post.md`** — the long-form "why we built this" canonical link the posts point to; assume Septagon-site host (open question §8.2).
- [ ] **Step 7: All inherit `NARRATIVE.md`; commands from run log.** STRANGER/LINKCHECK each.
- [ ] **Step 8: Commit.**
```bash
git add launch/channels/
git commit -m "docs(platformkit): write r/golang, Lobsters, PH, X, LinkedIn, blog adaptations"
```

### Task 11: Codex G3 — hostile pass on all public texts

**Files:** Modify: `platformkit/launch/channels/*`

- [ ] **Step 1: Dispatch Codex G3** (`/codex:adversarial-review` on `launch/channels/*`, overclaim + tone-misfit + top-dunk-comment prompt).
- [ ] **Step 2: Fix.** Resolve every overclaim; adjust tone per channel; for each "top dunk comment" Codex predicts, ensure `hn-comment-seeds.md`/`faq.md` already answers it (add if missing).
- [ ] **Step 3: Commit.**
```bash
git add launch/channels/ launch/drafts/docs/faq.md
git commit -m "docs(platformkit): harden public texts against adversarial review"
```

---

## Phase 6 — Images

### Task 12: Write fal.ai image prompt-specs

**Files:** Create: `platformkit/launch/images/IMAGE_PROMPTS.md`

- [ ] **Step 1: Draft `IMAGE_PROMPTS.md`** with one block per asset: purpose, exact dimensions, full prompt, negative prompt, suggested fal.ai model, output filename + target path. Assets:
  1. **OG/social card** 1200×630 — wordmark + one-liner on a calm technical background; the highest-leverage asset (link unfurls).
  2. **Hero image** (README top) — restrained, technical, no glossy gradients/3D blobs.
  3. **Powered-by / wordmark lockup**.
- [ ] **Step 2: Architecture diagram — recommend diagram-as-code.** Provide a ready-to-render **Mermaid** diagram (core → modules → clients) in this file as the recommended path (a wrong AI diagram erodes trust), with an AI-generation prompt as fallback only.
- [ ] **Step 3: Aesthetic guard.** Negative prompts explicitly exclude: generic-SaaS-gradient, 3D-blob, stock-photo people, fake-dashboard screenshots.
- [ ] **Step 4: Commit.**
```bash
git add launch/images/IMAGE_PROMPTS.md
git commit -m "docs(platformkit): add fal.ai image prompt-specs + Mermaid architecture diagram"
```

---

## Phase 7 — Checklist, placement, pre-flight

### Task 13: Write the publish checklist

**Files:** Create: `platformkit/launch/CHECKLIST.md` and `platformkit/launch/README.md`

- [ ] **Step 1: `CHECKLIST.md`** — three sections:
  - **Pre-flight:** create `septagon-oss/platformkit` repo; enable org security (Dependabot, secret-scanning push protection, code scanning) — provide the exact `gh` commands; each repo has README/LICENSE/SECURITY/CONTRIBUTING + description + topics + social-preview; confirm Apache-2.0 across all 10 (§8.3); `VERIFIED_RUN.md` passes on a clean machine; all links resolve; release notes ready; **launch-blocker list** (carried from Tasks 1–2).
  - **Launch hour:** ordered timeline (Show HN post time-of-day, seed FAQ, comment-seeds ready, cross-post sequencing).
  - **Day-after:** monitor/respond playbook; capture the real emergent FAQ.
- [ ] **Step 2: `launch/README.md`** — index of the kit: what each file is, the order to use them, and "do not publish until CHECKLIST pre-flight is all green."
- [ ] **Step 3: Provide exact `gh` security commands.** Include runnable examples, e.g.:
```bash
gh api -X PATCH orgs/septagon-oss -f secret_scanning_push_protection_enabled_for_new_repositories=true \
  -f dependabot_alerts_enabled_for_new_repositories=true \
  -f dependabot_security_updates_enabled_for_new_repositories=true \
  -f dependency_graph_enabled_for_new_repositories=true
```
- [ ] **Step 4: Commit.**
```bash
git add launch/CHECKLIST.md launch/README.md
git commit -m "docs(platformkit): add launch checklist + kit index"
```

### Task 14: Place final files into target repos

**Files:** Front-door repo + 10 sub-repos + `pk-docs` (each in its own branch/PR).

- [ ] **Step 1: Create `septagon-oss/platformkit`** (or confirm exists). Add `README.md` (from Task 5 draft, image links wired), `LICENSE` (Apache-2.0), `SECURITY.md`, `CONTRIBUTING.md`, `go.work`, `docs/architecture.svg` (rendered from Task 12 Mermaid), `.github/` CI badge targets.
- [ ] **Step 2: Open a PR per sub-repo** placing each README from Task 6 (10 PRs).
- [ ] **Step 3: Open a PR on `pk-docs`** placing the Task 8 docs + `open-core.md` + `faq.md` + `CONTRIBUTING.md` + `SECURITY.md`.
- [ ] **Step 4: LINKCHECK across repos.** Every front-door → sub-repo and sub-repo → front-door link resolves on GitHub.
- [ ] **Step 5: Commit/PR.** Use `gh pr create` per repo; do not merge until the user approves (ready-when-green).

### Task 15: Final human-read handoff

**Files:** Modify: `platformkit/launch/CHECKLIST.md` (mark verification state)

- [ ] **Step 1: Run the full pre-flight checklist** and record pass/fail per item.
- [ ] **Step 2: Summarize** the kit state for the user: what's green, what's blocked, what the user must do (generate images in fal.ai, final read, hit publish).
- [ ] **Step 3: Commit.**
```bash
git add launch/CHECKLIST.md
git commit -m "docs(platformkit): record pre-flight verification state for launch"
```

---

## Self-Review

**1. Spec coverage:**
- §0 North Star → enforced via STRANGER TEST gates in Tasks 3,5,6,8,9,10. ✓
- §3 front-door A+B+C → Tasks 1 (hero verb decision), 5 (front door), 14 (repo creation). ✓
- §4 narrative spine → Tasks 3–4. ✓
- §5.1 verified run path → Tasks 1–2. ✓
- §5.2 READMEs → Tasks 5–7, 14. ✓
- §5.3 docs → Task 8, 14. ✓
- §5.4 open-core → Task 8 (open-core.md), 14. ✓
- §5.5 channel texts + comment seeds → Tasks 9–11. ✓
- §5.6 images → Task 12. ✓
- §5.7 checklist + sequencing + security pre-flight → Tasks 13, 15. ✓
- §6 Codex gates G1–G4 → Tasks 2, 4, 7, 11. ✓
- §7 sequencing → phase order matches. ✓

**2. Placeholder scan:** No "TBD/implement later". The one-liner and post bodies carry concrete starting text + the rule that final wording is tuned under STRANGER/CODEX gates — that's a real instruction, not a placeholder. Image prompts are authored in Task 12 (the file's whole job), not deferred.

**3. Type/name consistency:** File paths consistent across tasks (`launch/drafts/readmes/*` → placed in Task 14; `launch/channels/*` named identically in Tasks 9,10,11; `VERIFIED_RUN.md` referenced by Tasks 1,2,3,5,8,9,13). Codex gate names G1–G4 consistent between the gates table and Tasks 2,4,7,11. ✓

**Note on TDD adaptation:** this is a content/launch plan; "tests" are the STRANGER TEST, CODEX Gx, and LINKCHECK acceptance gates plus the one executable check (Task 1 run-path reproduction). This is intentional and matches the spec's anti-lying / verify-first design.
