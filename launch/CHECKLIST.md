# PlatformKit OSS — Launch Checklist

A dummy-proof, ordered checklist for publishing the PlatformKit OSS v0.1.0
launch. Work it top to bottom. Three phases: **A. Pre-flight**, **B. Launch
hour**, **C. Day-after**.

> **Hard rule: do not post anything publicly until every box in §A is checked.**
> §A is the gate. §B and §C assume §A is fully green.

Release mechanics (push order, tags, retract, guards, front-door creation,
post-push verification) are **not** restated here — they live in
[`RELEASE_AND_RUN_MODEL.md`](./RELEASE_AND_RUN_MODEL.md) (authoritative §8 GATED
PUSH STEPS) and the launch-mechanics blockers live in
[`FLIP_RUNBOOK.md`](./FLIP_RUNBOOK.md) §A. This checklist references them and
lists the gates you must confirm green.

---

## A. Pre-flight (ALL must be green before posting)

> **Order matters.** Everything that can be staged *before* touching a remote —
> file placement, image generation, repo hygiene, security settings, and the
> link-check — comes first (A1–A4). The tag/push/visibility-flip release step
> comes **last** (A5), because pushing a tag to the Go proxy is irreversible.

### A1. Place the kit's final files into the repos (launch task **T14**)

This is launch task **T14**. Copy the drafted kit files into their target repos:

- [ ] Front-door `README.md` ← `launch/drafts/readmes/platformkit-frontdoor.md`
      → `septagon-oss/platformkit`. The README uses relative `docs/` links
      (`docs/hero.png`, `docs/architecture.svg`, `docs/open-core.md`), so the
      front-door repo must carry a `docs/` dir containing: A2's generated
      `hero.png` + `architecture.svg`, **and** a copy of `open-core.md` (from
      `launch/drafts/docs/open-core.md`). Verify every `docs/*` link resolves
      before launch.
- [ ] The 11 module-repo READMEs ← `launch/drafts/readmes/pk-*.md` /
      `platformkit-ui` → each matching repo. (`pk-registry` and `platformkit-ui`
      keep their own existing READMEs if no draft exists.)
- [ ] The docs pages ← `launch/drafts/docs/*.md`
      (`quickstart, architecture, add-a-module, open-core, faq, SECURITY,
      CONTRIBUTING`) → `pk-docs`.

### A2. Images

Generate and place per [`images/IMAGE_PROMPTS.md`](./images/IMAGE_PROMPTS.md):

- [ ] **Hero** (`hero.png`, 1280×640) via fal.ai (`fal-ai/flux/dev`). Also place
      at `docs/hero.png` in the front-door repo (the README references it).
- [ ] **OG card** (`og-card.png`, 1200×630) rendered from the HTML snippet —
      open `og-card.html` and screenshot at 1200×630 (headless Chrome one-liner
      in the prompt-spec).
- [ ] **Architecture diagram** — embed the Mermaid fence in the README and/or
      export `architecture.svg` (the front-door README references
      `docs/architecture.svg`).
- [ ] **Badges** — `built-with-platformkit-{dark,light}.svg` (deterministic SVG).
- [ ] OG card set as each repo's **social preview** (A3) and as `og:image` meta
      (absolute HTTPS URL) where a rendered site/README applies.

### A3. Per-repo hygiene (11 module repos + pk-docs + front door)

Module repos: `pk-shared pk-core pk-design pk-client pk-registry platformkit-ui
pk-runtime pk-modules pk-testkit pk-tools pk-apps` (+ `pk-docs`, + front-door
`platformkit`). For **each**:

- [ ] `README.md` present.
- [ ] `LICENSE` present and Apache-2.0, consistent across all repos.
- [ ] `SECURITY.md` present.
- [ ] `CONTRIBUTING.md` present.
- [ ] `CODEOWNERS` present (FLIP §A1: workflow accepts `.github/CODEOWNERS`).
- [ ] One-line repo description set.
- [ ] Topics set.
- [ ] Social-preview image (the OG card) uploaded.

Description + topics via `gh` (example for one repo):

```bash
gh repo edit septagon-oss/pk-core \
  --description "PlatformKit core kernel: module system + DI graph (Apache-2.0)" \
  --add-topic go --add-topic saas --add-topic multi-tenant \
  --add-topic open-source --add-topic backend
```

> **Social preview has no stable `gh` flag.** Set it manually per repo:
> **Settings → General → Social preview → Upload an image** → use
> `launch/images/og-card.png` (1200×630). Do this for every repo above.

#### A3b. Org + per-repo security (septagon-oss)

Enable before going public. The org-level block sets defaults for **new** repos;
the per-repo block must run only over repos that **already exist** (so it must
run *after* the front-door repo is created in A5 — do not include `platformkit`
in this pre-creation loop, or run this step again post-creation for it).

```bash
# Org-wide defaults for NEW repos: Dependabot alerts, security updates,
# dependency graph, secret scanning, and secret-scanning push protection.
gh api -X PATCH orgs/septagon-oss \
  -F dependabot_alerts_enabled_for_new_repositories=true \
  -F dependabot_security_updates_enabled_for_new_repositories=true \
  -F dependency_graph_enabled_for_new_repositories=true \
  -F secret_scanning_enabled_for_new_repositories=true \
  -F secret_scanning_push_protection_enabled_for_new_repositories=true

# Per EXISTING repo (existing repos do not inherit the "new repo" org defaults).
# security_and_analysis must use NESTED -F fields, not a JSON string.
for r in pk-shared pk-core pk-design pk-client pk-registry platformkit-ui \
         pk-runtime pk-modules pk-testkit pk-tools pk-apps pk-docs; do
  gh api -X PATCH repos/septagon-oss/$r \
    -F 'security_and_analysis[secret_scanning][status]=enabled' \
    -F 'security_and_analysis[secret_scanning_push_protection][status]=enabled' \
    -F 'security_and_analysis[dependency_graph][status]=enabled'
  gh api -X PUT repos/septagon-oss/$r/vulnerability-alerts          # Dependabot alerts
  gh api -X PUT repos/septagon-oss/$r/automated-security-fixes      # Dependabot security PRs
done
# After the front-door repo exists (A5), run the per-repo block again for `platformkit`.
```

- [ ] Dependabot alerts enabled (org default + each existing repo).
- [ ] Dependabot security updates enabled.
- [ ] Dependency graph enabled.
- [ ] Secret scanning + push protection enabled.
- [ ] Re-ran the per-repo security block for `platformkit` after A5 created it.

### A4. Links — everything resolves, nothing 404s

Run a real link-checker over the kit + draft docs, not just eyeball them. Either:

```bash
# Option A — lychee (https://github.com/lycheeverse/lychee):
lychee --no-progress launch/README.md launch/drafts/**/*.md launch/channels/*.md

# Option B — markdown-link-check (npx, per file):
find launch -name '*.md' -print0 | xargs -0 -n1 npx --yes markdown-link-check -q

# Option C — grep-based relative-link existence check (no network):
grep -rhoE '\]\(\.{1,2}/[^)]+\)' launch --include='*.md' \
  | sed -E 's/^\]\(([^)]+)\)$/\1/' | sort -u \
  | while read -r p; do [ -e "launch/$p" ] || echo "MISSING: $p"; done
```

- [ ] Every link in the **front-door README** resolves.
- [ ] Every link in the **channel posts** (`launch/channels/*`) resolves.
- [ ] Every link in the **docs** (`pk-docs`) resolves.
- [ ] Relative links resolve to files that exist (Option C clean).
- [ ] After A5: the front-door repo **actually exists** publicly and
      `git clone …/platformkit && GOWORK=off go run .` works on a **truly clean
      clone** (no workspace, default `GOPROXY`) — confirm A5's smoke from a
      fresh machine/container.

### A5. Release execution — run the gated runbook (LAST: irreversible push)

Execute the release via [`RELEASE_AND_RUN_MODEL.md`](./RELEASE_AND_RUN_MODEL.md)
**§8 GATED PUSH STEPS** and clear the launch-mechanics blockers in
[`FLIP_RUNBOOK.md`](./FLIP_RUNBOOK.md) **§A (A1–A6)**. Do not re-derive the
sub-steps here — follow the runbook. The run-model branches are already merged
to `main` locally with local `v0.1.0` tags cut; this step pushes them. Confirm
these high-level gates landed:

- [ ] **§8.1** Tag messages normalized on the same `main` commits (real release
      message) immediately before push. **`v0.0.0` never reused or moved.**
- [ ] **§8.2 / FLIP §A** Launch-mechanics blockers cleared: CI CODEOWNERS
      baseline (A1), docs version labels (A4), README links (A3).
- [ ] **§8.3** Pushed `main` + `v0.1.0` **leaf-first**, layer by layer, each
      layer settling on the proxy before the next.
- [ ] **§8.4** Front-door repo `github.com/septagon-oss/platformkit` created
      from the §2.2/§2.3 layout (AFTER pk-apps), pushed, then tagged `v0.1.0`.

**Release-blocking checks (must pass before you push — see runbook §5):**

- [ ] `GOWORK=off go build ./...` and `GOWORK=off go test ./...` are green from
      a **clean clone** (no workspace rescue).
- [ ] **Block-aware replace guard passes** (Runbook §5.2): `go mod edit -json |
      jq` finds no `replace` of any `github.com/septagon-oss/*` module and no
      local-path (`./`, `../`, absolute) replace, in single-line **or**
      `replace ( … )` block form.
- [ ] **Real clone smoke:** `git clone …/platformkit && cd platformkit &&
      GOWORK=off go run .` boots, and:
  - [ ] `GET /healthz` → **200**
  - [ ] `GET /api/v1/tenants` → **200**
  - [ ] `POST /api/v1/auth/sessions` with a `tenant_id` in the body → **201**

> **Version namespaces:** the release is the git tag **`v0.1.0`**; per-module
> `ModuleVersion` (the port contract) stays **`0.0.0`** and is **not** bumped.
> See [`RELEASE_AND_RUN_MODEL.md`](./RELEASE_AND_RUN_MODEL.md) intro.

> **Known parked item:** the local dev-workspace `go.sum` / `v0.1.0` mismatch is
> *not* a launch blocker. It is resolved by the runbook's regenerate-`go.sum` +
> clean-tag step — see [`RELEASE_AND_RUN_MODEL.md`](./RELEASE_AND_RUN_MODEL.md)
> §8 and §6. Do not hand-fix it here.

---

## B. Launch hour (ordered timeline)

> Publish the **blog post first** — it is the canonical link the other channels
> point to, so its URL must resolve before you post anywhere else.

1. [ ] **Publish the blog post** (`launch/channels/blog-post.md`). Confirm its
       URL is live. This is the canonical reference link.
2. [ ] **Pick the slot.** Common wisdom for Show HN is **US morning, Pacific
       time, on a weekday** — but you decide the exact slot. Block the next
       2–3 hours to be present.
3. [ ] **Post Show HN.** Use the **exact title** from
       `launch/channels/show-hn.md`:
       `Show HN: PlatformKit – open-source Go backend for multi-tenant SaaS`.
       URL: `https://github.com/septagon-oss/platformkit`.
4. [ ] **Be present to answer.** Keep `launch/channels/hn-comment-seeds.md` open
       to respond fast and honestly. **Seed nothing fake** — no sock-puppet
       comments, no fake upvotes. The seeds are *your* prepared honest answers,
       not plants.
5. [ ] **Cross-post in sequence** (so channels don't cannibalize each other):
   - [ ] HN first (step 3, already up).
   - [ ] Shortly after: **r/golang** (`launch/channels/r-golang.md`) +
         **Lobsters** (`launch/channels/lobsters.md`).
   - [ ] **X thread** (`launch/channels/x-thread.md`).
   - [ ] **Product Hunt** (`launch/channels/product-hunt.md`) if same day.
   - [ ] **LinkedIn** (`launch/channels/linkedin.md`).
   - All point back to the blog post / front-door repo (both already live).

---

## C. Day-after / follow-up

- [ ] **Monitor + respond** across HN, Reddit, Lobsters, X, PH. Stay honest;
      concede the anti-flame points already in the narrative (§5 of
      `NARRATIVE.md`).
- [ ] **Capture the REAL FAQ** that emerges from the threads and fold it into
      `launch/drafts/docs/faq.md` (then into `pk-docs`).
- [ ] **Thank contributors** — anyone who filed a good issue, PR, or thoughtful
      critique.
- [ ] **Triage issues** opened against any repo; label, acknowledge, and route.
- [ ] **Short follow-up note** (blog/X) if the launch warrants it (notable
      feedback, a quick fix shipped, a clarification).
