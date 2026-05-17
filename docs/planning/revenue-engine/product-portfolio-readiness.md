# Product Portfolio Readiness

Updated: `2026-05-13`

## Positioning

PlatformKit is the flagship commercial product.

Septagon is the parent company that develops, operates, and supports
PlatformKit. The named brands built on top of it are not throwaway demos. They
are product lines and reference customers that must work end to end:

- `COMUM` — coworking and flex-space operations.
- `Incomum` — Saturday coding school and guardian portal.
- `Apex` — smart-building portfolio operations.
- `Velora` — premium aesthetic-care membership operations.

The commercial site should make this hierarchy clear:

1. `platformkit.dev` sells PlatformKit.
2. Septagon is the maker and support organization.
3. Each product proves PlatformKit in a real operating domain.

## Product Readiness Contract

A brand is not ready to appear as a full product until it satisfies every gate
below.

| Gate | Requirement |
|------|-------------|
| Product thesis | Public page names the customer, buyer, use case, pricing, and non-goals. |
| Runtime composition | App composition resolves without private hand edits and lists all modules used. |
| Owned data model | Seeds create realistic tenants, users, roles, core records, and one complete operating day. |
| Primary workflows | Public, customer/member, and operator/admin paths are runnable in the browser. |
| Revenue path | At least one payment, subscription, booking, or order path is wired through the standard billing/payment boundary. |
| Notifications | Email or in-app notifications exist for the primary workflow and use product voice. |
| Trust posture | Compliance, privacy, support, and incident/runbook docs exist for the product's actual risk profile. |
| Local onboarding | A new evaluator can run the product locally and complete the main flow in under 30 minutes. |
| Deployment path | Staging or production deployment path is documented, repeatable, and smoke-tested. |
| E2E proof | Automated smoke covers login, primary workflow, operator review, and one revenue event. |
| Commercial proof | Product page links to live URL, screenshots/video, case study or launch notes, and support contact. |

If any gate is missing, the brand can still be shown internally, but the public
page must not imply that it is production-ready.

## Portfolio Status

| Product | Commercial role | Readiness focus |
|---------|-----------------|-----------------|
| COMUM | First real customer/product proof for PlatformKit. | Keep as the highest-priority end-to-end reference: live site, coworking flows, billing/booking, operator admin, case study. |
| Incomum | Education product proving guardian consent, cohort operations, curriculum, and child-data handling. | Promote guardian/program/task workflows from prose into runnable product flows with consent and weekly digest smoke coverage. |
| Apex | Enterprise product proving smart-building portfolio operations and ESG/audit workflows. | Close the gap between the strong product story and runtime modules: assets, anomalies, contractor SLA, ESG, sensor adapters, evidence export. |
| Velora | Healthcare-adjacent membership product proving booking, treatment planning, media consent, and regulated records. | Wire booking, membership, file/consent, task SLA, and treatment-plan flows into one smokeable patient-to-plan path. |

## Commercial Site Structure

The site should branch from PlatformKit, not from Septagon:

1. Home: PlatformKit commercial promise, proof products, and primary CTA.
2. Product pages: `COMUM`, `Incomum`, `Apex`, `Velora` as full products built on PlatformKit.
3. Customers/case studies: real consent-cleared deployments and measurable outcomes.
4. Courses: education funnel for builders and partners.
5. Partners: certified builders and implementation partners.
6. Docs: developer path, module catalog, quickstart, and architecture.

Septagon can have a small maker/footer presence, but it should not compete with
PlatformKit as the flagship commercial surface.

## Operating Rule

Do not add another product line until the four named products each have an
explicit readiness score and at least one has passed every gate.
