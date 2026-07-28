# PlatformKit OSS — Launch Kit Design Spec

- **Status:** Draft, awaiting user review
- **Date:** 2026-06-02
- **Author:** Claude (ghost-writing for maxdiscite@gmail.com / Septagon)
- **Adversary:** Codex (gpt-5.5 xhigh) — red-teams every public claim and text
- **Related:**
  - `2026-05-17-platformkit-oss-v0.0.0-design.md` (the engineering extraction spec — the *code* this launch describes)
  - `OSS_OPEN_CORE_SPLIT.md`, `OSS_EXTRACTION_PLAN.md`, `OSS_QUALITY_GATE.md`, `PLATFORMKIT_FORMULA.md`
  - `platformkit-marketing/copy/{headline-variants,elevator-pitches}.md` (existing positioning to inherit and simplify)

## 0. North Star (read this before anything else)

**Dummy-proof developer experience. Clarity over cleverness. No fluff.**

Every artifact in this kit is judged by one test:

> A Go developer who has never heard of PlatformKit clicks a link from Show HN,
> and within **10 minutes** has it running locally and understands what it is,
> what it is *not*, and what to do next — **without asking anyone.**

If a sentence does not help that person succeed, it gets cut. We are not writing
marketing. We are writing the shortest honest path from "stranger" to "it works
on my machine and I get it."

Concrete style rules for all writing in this kit:

1. **Lead with the command, then explain.** Show `git clone … && make up` before prose.
2. **One canonical path.** Never offer three ways to do the same thing in the quickstart. (Alternatives go in a separate "other ways" section.)
3. **Copy-pasteable, real, and tested.** Every command block has been run by a human/agent and produces the output shown. No `# ...` hand-waving.
4. **Say what it is NOT.** A "Not for you if…" section near the top prevents the wrong people from bouncing angrily on HN.
5. **No adjectives doing an engineer's job.** Delete "powerful," "seamless," "blazing." State the fact instead ("boots in ~2s, zero external services").
6. **Short sentences. Plain words.** Aim for an 8th-grade reading level even for senior engineers — they are tired and skimming.

## 1. Scope

### In scope (what this engagement produces, written into the repos)

1. **Narrative spine** — one short positioning source-of-truth everything derives from.
2. **A verified, dummy-proof run path** — the exact `clone → run → see it work` sequence, *actually executed* and fixed before any doc claims it.
3. **READMEs** — the front-door repo README + right-sized READMEs for the public sub-repos.
4. **Docs** (`pk-docs`) — quickstart, 5-minute architecture, CONTRIBUTING, open-core boundary, FAQ, SECURITY, LICENSE/NOTICE hygiene.
5. **Channel texts** — Show HN (hero), r/golang, Lobsters, + adaptations for Product Hunt / X / LinkedIn; HN comment-seed answers; launch blog post.
6. **Image prompt-specs for fal.ai** — exact prompts + dimensions for OG/social card, hero, architecture diagram, powered-by lockup. *User generates; we spec and place.*
7. **Publish checklist + sequencing** — pre-flight, launch-hour timeline, day-after follow-up.
8. **Codex adversary loop** — woven through every step (Section 6).

### Out of scope

- Building or finishing the OSS *code* itself (that is the v0.0.0 engineering spec). This kit **describes and verifies** that code; if verification finds the path is broken, we report it and either (a) fix the minimal DX blocker or (b) flag it as a launch blocker — we do **not** silently write around it.
- Generating the actual images (user does this in fal.ai from our prompt-specs).
- Paid-tier / pricing pages, sales collateral, hosted-cloud signup flows.
- Video production (an asciinema cast is included as an optional, cheap DX win; full video is out).

## 2. Launch surface (the facts on the ground)

`platformkit-oss` = the **`github.com/septagon-oss`** org. Confirmed live, public, free plan, 10 public repos:

```
pk-core      composable core contracts / kernel
pk-shared    cross-repo vocabulary
pk-runtime   host, request, health, HTTP primitives
pk-design    tokens, themes, component contracts
pk-client    public client primitives
pk-tools     CLI / TUI / dev workflow
pk-modules   reference OSS module pack
pk-apps      runnable example compositions
pk-testkit   conformance + flow testing
pk-docs      public docs source
(pk-ui — still PRIVATE; not part of launch)
```

**The core DX problem:** a 10-repo org has *no front door*. A stranger who lands on
`github.com/septagon-oss` sees ten repos and bounces. The launch must give them
**one link** that immediately makes sense.

**Security posture gap (must fix before launch):** the org has no security scanning,
no Dependabot, no secret-scanning push protection enabled. Shipping a public Go OSS
org without these is an avoidable embarrassment. Enabling them is a pre-flight item.

## 3. The front-door decision (approved: A + B + C synthesis)

Create one canonical entry repo: **`septagon-oss/platformkit`** (the "meta" / front-door repo).

- **(A) Front door:** this repo *is* the Show HN link. It owns the killer README, the
  `go.work`, the one-command quickstart, the architecture story in 5 sentences, and a
  clean map to the 10 sub-repos. First impression lives here and nowhere else.
- **(B) CLI is the hero verb:** the README's quickstart leads with the `platformkit`
  binary (`pk-tools`) as the thing you *do* — `platformkit up`, etc. — IF and only if
  verification proves that path works today. If the binary path is not real yet, the
  hero verb falls back to `make up` / `go run .` against the starter app (see §5).
- **(C) Starter app is the proof:** `pk-apps` starter is what actually boots and shows a
  running admin in the browser, linked as "see it run" from the front door.

Sub-repos get **lean, focused READMEs** that each answer exactly three questions:
*what is this? how do I use it? what does it depend on?* — and link back to the front door.

> **Decided:** create the dedicated `septagon-oss/platformkit` meta repo as the front door
> (it lets the first impression be curated independent of any single component). Creating
> the repo + its initial commit is a pre-flight item in `CHECKLIST.md`.

## 4. Narrative spine (the source everything derives from)

A single file — `platformkit/launch/NARRATIVE.md` — that every other text quotes from,
so we never contradict ourselves across channels. It fixes:

- **One-line definition** (the handshake): plain, concrete, no jargon. Target shape:
  *"PlatformKit is an open-source Go substrate for building multi-tenant SaaS — auth,
  tenancy, admin, audit, billing-ready — composed as modules, running locally in one
  command."* (Final wording tuned during writing + Codex red-team.)
- **The wedge / "why this exists":** the substrate, not the scaffold. Most starters give
  you a CRUD demo; this gives you the reusable substrate (modules talk only through ports,
  per-tenant overlays, fx composition) — stated in plain words, proven by a running app.
- **Honest open-core framing:** Apache-2.0, genuinely useful on its own; a clearly-labeled
  commercial/Pro tier exists for hosted ops + pro modules. We say this *plainly and early*
  so HN cannot accuse us of a bait-and-switch. The open-core boundary doc (§5.4) is linked
  from the README, not buried.
- **The AI-introspectable angle, de-hyped:** machine-readable module manifests + an MCP
  server mean an AI agent can read and extend the codebase natively. Stated as a fact with
  a link to proof, not as a buzzword.
- **"What this is NOT" (the anti-flame list):** not a no-code tool; not a Rails/Django
  replacement; not production-hardened-at-scale on the SQLite default; not a framework you
  must adopt wholesale. Honesty here is the single best HN-survival investment.

Voice: **Septagon (the company) speaking as a technical peer** to a tired senior Go dev.
Substance-first, zero hype, mildly self-aware — the company voice stays warm and plain, not
corporate. The existing `elevator-pitches.md` is the raw material; this kit **simplifies and
de-jargons** it (e.g. drop "governed product substrate" → "reusable SaaS backend"). Same
voice across all channels (no individual-maker persona).

## 5. Deliverables in detail

### 5.1 Verified run path (gates everything else — do this FIRST)

Before a single README sentence is written, run the *actual* public path on a clean-ish
environment and record exactly what happens:

1. Clone the front-door surface fresh (or use the `septagon-oss-workspace` mirror) into a
   scratch dir.
2. Run the intended first command (`make up`, `go run .`, or `platformkit up` — whichever
   is real).
3. Record: every command, every output line, time-to-first-success, time-to-admin-in-browser,
   the seeded login, and **every place a stranger would get stuck** (missing Go version,
   port in use, CGO, missing seed, confusing error).
4. Codex independently attempts the same path with fresh eyes (§6) and logs its own friction.
5. Fix only the *minimal DX blockers* needed to make the canonical path work (e.g. a missing
   `make up` target, a bad default, an unclear error message). Anything bigger is escalated
   as a launch blocker, not silently patched.

**Output:** `platformkit/launch/VERIFIED_RUN.md` — the ground truth. Every command shown in
any README/doc/post is copied from here verbatim. This is the anti-lying mechanism.

Acceptance: a human (or fresh agent) following `VERIFIED_RUN.md` top to bottom reaches a
working admin login in ≤10 minutes with zero outside help.

### 5.2 READMEs

**Front-door `septagon-oss/platformkit/README.md`** — the make-or-break artifact. Structure:

1. One-line definition + a single hero image (from §5.6) + badges (CI, license, Go version).
2. **Quickstart** — the verified command block, copy-paste, ≤5 lines, producing a browser
   admin. The literal first thing below the fold.
3. **What you get** — 5–8 bullet capabilities in plain nouns (tenants, users, auth, admin
   UI, audit log, API keys, notifications, content).
4. **What this is NOT** — the anti-flame list.
5. **How it fits together** — the formula in 3 sentences + the architecture diagram image.
6. **The repos** — a table mapping the 10 sub-repos to one-line purposes (so the org page
   stops being a maze).
7. **Open core** — one short honest paragraph + link to the boundary doc.
8. **Docs / Contributing / Security / License / Community** — clear links, nothing buried.

**Sub-repo READMEs** (`pk-core`, `pk-shared`, `pk-runtime`, `pk-design`, `pk-client`,
`pk-tools`, `pk-modules`, `pk-apps`, `pk-testkit`, `pk-docs`): each ≤1 screen, same 3-question
template (what / how / depends-on), a single example, and a "← part of PlatformKit" link
home. Right-sized: `pk-core` and `pk-modules` get more; `pk-shared` gets less.

Acceptance: each README passes the "stranger test" — someone landing cold knows in 30
seconds whether this repo is what they want.

### 5.3 Docs (`pk-docs`)

Plain-Markdown, task-oriented, each page answers one question:

| File | The one question it answers |
|---|---|
| `quickstart.md` | "How do I run it right now?" (mirrors VERIFIED_RUN, expanded) |
| `architecture.md` | "How does it fit together?" (core → modules → clients, with the diagram) |
| `add-a-module.md` | "How do I build my own thing on it?" (the smallest end-to-end add) |
| `open-core.md` | "What's free vs paid, and will you rug-pull me?" |
| `faq.md` | The 10 skeptical HN questions, answered honestly up front |
| `CONTRIBUTING.md` | "How do I send a PR and not get ignored?" |
| `SECURITY.md` | "How do I report a vuln?" (private path) |

The FAQ is pre-loaded from the predicted HN comment seeds (§5.5) so the answer exists
*before* the question is asked.

Acceptance: no page requires reading another page first to make sense; each is self-contained
and links siblings.

### 5.4 Open-core boundary doc

`open-core.md` (in `pk-docs`, linked from every front door). One table: **OSS owns X / Pro
adds Y**, sourced from the engineering spec §3. One promise paragraph: what we will never
move out of OSS (the core contracts). This is the trust artifact; it must read as a
commitment, not a teaser.

### 5.5 Channel texts (`platformkit/launch/channels/`)

Hero channel = **Show HN**. Everything else is an adaptation of the narrative spine.

| File | Channel | Notes |
|---|---|---|
| `show-hn.md` | Show HN | Title (≤80 char, no hype, format "Show HN: PlatformKit – open-source Go substrate for multi-tenant SaaS") + body. The single most-polished text. |
| `hn-comment-seeds.md` | HN (you, in comments) | Pre-written honest answers to the 10 hardest questions: "why not just X?", "open-core rug-pull?", "SQLite in prod?", "why Go DI?", "what's actually Pro?", license, maturity, who's behind it, why now, how it compares to Supabase/Encore/Backstage. |
| `r-golang.md` | r/golang | More technical, code-forward, community-norms-aware (no logos, no marketing tone). |
| `lobsters.md` | Lobsters | Short, tagged, technical. |
| `product-hunt.md` | Product Hunt | Outcome-first tagline + first comment. |
| `x-thread.md` | X / Twitter | 5–7 post thread, one idea each, demo gif/asciinema. |
| `linkedin.md` | LinkedIn | Open-core + EU/sovereign angle, professional voice. |
| `blog-post.md` | Septagon blog | The long-form "why we built this" — the canonical link the posts point to. |

Each post: (1) inherits the narrative spine, (2) uses only commands from `VERIFIED_RUN.md`,
(3) gets a Codex hostile pass for overclaim/hype before it's considered done.

Acceptance: the Show HN title + first paragraph survive a Codex "tear this apart as a cynical
HN reader" review with no factual overreach remaining.

### 5.6 Image prompt-specs for fal.ai (`platformkit/launch/images/`)

We don't generate; we spec precisely so the user's fal.ai run is one-shot. `IMAGE_PROMPTS.md`
contains, per asset: purpose, exact dimensions, the full prompt, negative prompt, suggested
model, and where the file lands. DX-first aesthetic: **clean, calm, technical — not a glossy
SaaS hero with gradients and 3D blobs.** Assets:

1. **OG/social card** (1200×630) — used by HN/X/LinkedIn link unfurls. Wordmark + one-line
   definition on a calm background. The highest-leverage image (it's what people see before
   clicking).
2. **Architecture diagram** (clean, light + dark) — core → modules → clients. This may be
   better as hand-authored SVG/Mermaid than AI-generated; spec offers both, recommends
   diagram-as-code for accuracy. (DX: a wrong AI diagram is worse than none.)
3. **Hero image** (README top) — restrained, technical.
4. **Powered-by / wordmark lockup** — for the docs + community.

Acceptance: prompts are copy-paste into fal.ai with no editing; recommended fallbacks noted
where AI generation is risky (diagrams).

### 5.7 Publish checklist + sequencing (`platformkit/launch/CHECKLIST.md`)

- **Pre-flight:** all 10 repos green CI; security scanning + Dependabot + secret-scanning
  enabled org-wide; every repo has README/LICENSE/SECURITY/CONTRIBUTING/topics/description/
  social-preview image set; front-door repo created and verified; `VERIFIED_RUN.md` passes on
  a clean machine; all links resolve; tag/release notes ready.
- **Launch hour:** the ordered timeline (post Show HN at the right time-of-day; seed the FAQ
  answers; have comment-seeds ready; cross-post sequencing so channels don't cannibalize).
- **Day-after:** monitor + respond playbook; capture the real FAQ that emerges; follow-up post.

### 5.8 Kit home / layout

```
platformkit/launch/
├── NARRATIVE.md            # the spine (§4)
├── VERIFIED_RUN.md         # ground-truth run log (§5.1)
├── CHECKLIST.md            # publish checklist + sequencing (§5.7)
├── channels/               # all the posts (§5.5)
├── images/IMAGE_PROMPTS.md # fal.ai prompt-specs (§5.6)
└── README.md               # index of the kit + how to use it
```

Final user-facing files (front-door README, sub-repo READMEs, `pk-docs/*`) are written into
their **target repos**; `launch/` holds the drafts, the spine, the verification log, and the
publish machinery. This keeps planning artifacts out of the public repos while the final
prose lands where it belongs.

## 6. Codex adversary loop (woven, not bolted on)

Codex is the hostile reviewer at four gates. Per `CLAUDE.md` reviewer-by-default rules, using
`/codex:review`, `/codex:adversarial-review`, and `/pk-second-opinion`.

| Gate | What Claude does | What Codex attacks |
|---|---|---|
| **G1 — Run path** (§5.1) | Run + log the canonical path | Independently attempt clone→run cold; log every friction Claude rationalized away |
| **G2 — Narrative** (§4) | Draft the spine | Red-team as a cynical HN reader: every claim that can't be proven by a link gets flagged; every hype word gets cut |
| **G3 — Public texts** (§5.5) | Draft each post | Hostile pass for overclaim, tone-misfit per channel, and "what's the top dunk comment this invites?" |
| **G4 — READMEs vs reality** (§5.2) | Write READMEs | Verify every command/claim against actual code + `VERIFIED_RUN.md`; flag drift |

Loop per artifact: **Claude drafts → Codex attacks → Claude fixes → re-verify → only then "done."**
Trivial files (a 1-screen sub-repo README) may skip the formal pass with a one-line note; the
Show HN post, narrative, and front-door README never skip.

## 7. Sequencing

1. **Verify the run path** (§5.1) + Codex G1. *Nothing else starts until we know what's true.*
2. **Write the narrative spine** (§4) + Codex G2.
3. **Front-door + sub-repo READMEs** (§5.2) + Codex G4.
4. **Docs + open-core + FAQ** (§5.3–5.4).
5. **Channel texts + comment seeds** (§5.5) + Codex G3.
6. **Image prompt-specs** (§5.6).
7. **Checklist + sequencing + pre-flight fixes** (§5.7: enable security scanning, set repo
   metadata, create front-door repo).
8. Hand back a ready-to-launch kit; user generates images, does the final human read, posts.

Each step ends with the relevant repo(s) green and the Codex gate passed.

## 8. Open questions

**Resolved:**

- **Front-door repo** → create the dedicated `septagon-oss/platformkit` meta repo.
- **Attribution voice** → Septagon (company), same voice across all channels.
- **Launch timing** → ready-when-green; no fixed date. Quality is the gate.

**Still open (non-blocking; resolved during execution):**

1. **CLI vs make for the hero verb:** does the `platformkit`/`pk` binary path actually work
   today, or does §5.1 verification show we must lead with `make up`/`go run .`? (Resolved by
   running it — do not assume.)
2. **Blog host:** where does `blog-post.md` actually publish (Septagon site, dev.to,
   Medium, GitHub Pages)? Affects the canonical URL the posts link to. Default assumption:
   Septagon site; confirm before the post links go live.
3. **Apache-2.0 confirmed** across all 10 repos? (`pk-*` LICENSE files must match the README
   claim — verified in pre-flight.)

## 9. Risks

| Risk | Mitigation |
|---|---|
| README promises a path the code can't deliver | §5.1 verify-first + Codex G1/G4; every command sourced from `VERIFIED_RUN.md`. The whole kit is built to make this impossible. |
| HN torches the open-core framing as a rug-pull | Honest framing early (§4), the commitment paragraph in `open-core.md`, and pre-written comment seeds. |
| 10-repo maze loses people before they read anything | Dedicated front-door repo (§3) is the entire point of approach A. |
| AI-generated architecture diagram is subtly wrong → erodes trust | Recommend diagram-as-code (Mermaid/SVG) over AI generation for anything load-bearing (§5.6). |
| Security-scanning gap noticed publicly | Pre-flight checklist enables it before launch (§5.7). |
| We drift into marketing voice | The North Star test (§0) and Codex G2/G3 hostile passes are the guardrail. |
| Scope creep into finishing the OSS code | Explicit out-of-scope (§1); DX blockers fixed minimally, bigger gaps escalated as launch blockers, not silently absorbed. |

## 10. Definition of done

The kit is done when:

1. `VERIFIED_RUN.md` reproduces a working admin login in ≤10 min on a clean machine.
2. Front-door README + all sub-repo READMEs written, Codex-passed, links resolve.
3. `pk-docs` quickstart/architecture/add-a-module/open-core/faq/contributing/security written.
4. All channel texts + comment seeds drafted and Codex-passed; Show HN text is launch-ready.
5. `IMAGE_PROMPTS.md` is copy-paste-ready for fal.ai.
6. `CHECKLIST.md` lists every pre-flight item, with security scanning + repo metadata called out.
7. User has done the final human read and approved.
