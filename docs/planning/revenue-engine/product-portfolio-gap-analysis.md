# Product Portfolio Gap Analysis

Updated: `2026-05-13`

## Scope

This is a client-by-client and SaaS-by-SaaS gap analysis for the four products
that must become complete PlatformKit proof points:

- `COMUM` in `septagon-clients/comumcowork`
- `Incomum` in `septagon-clients/incomum`
- `Apex` in `septagon-demos/apex`
- `Velora` in `septagon-demos/velora`

The standard is not "nice demo." Each product already has a runnable
PlatformKit baseline overlay. To be product-complete, each one also needs the
vertical modules, realistic data, operator and customer surfaces, revenue flow,
support/compliance posture, and automated proof for its specific industry.

## External Bar Checked

The product requirements below are benchmarked against current category leaders
and official regulatory or industry references:

- Coworking/flex operations: Nexudus and OfficeRnD emphasize member
  management, desk/room booking, billing, access control, white-label member
  apps, multi-location administration, reporting, and integrations.
  - <https://nexudus.com/>
  - <https://nexudus.com/member-management/>
  - <https://www.officernd.com/manage-coworking/>
- Education/class operations: Jackrabbit and Spark emphasize online
  registration, scheduling, attendance, parent/guardian portals, policies,
  assignments, billing, staff portals, and parent communication.
  - <https://www.jackrabbitclass.com/>
  - <https://www.jackrabbitclass.com/features/class-management/>
  - <https://www.sparkyourschool.com/>
- Smart buildings/facilities: Siemens Building X, IBM TRIRIGA, ServiceNow
  Workplace Service Delivery, Johnson Controls OpenBlue, and Facilio emphasize
  energy, sustainability, space utilization, work orders, maintenance,
  reservations, sensor/building data, vendor collaboration, compliance, and
  portfolio reporting.
  - <https://www.siemens.com/global/en/products/buildings/smart-buildings.html>
  - <https://www.ibm.com/products/tririga>
  - <https://www.servicenow.com/products/workplace-service-delivery.html>
  - <https://www.johnsoncontrols.com/openblue>
  - <https://facilio.com/product/connected-cmms/>
- Aesthetic clinic operations: Pabau, Aesthetic Record, Delam, and Centi Clinic
  emphasize booking, EMR/client records, treatment plans, before/after media,
  consent forms, memberships/packages, payments, reminders, aftercare,
  inventory, and compliance posture.
  - <https://pabau.com/go-emr/>
  - <https://pabau.com/industry/medical-spa-software/>
  - <https://www.aestheticrecord.com/complete-emr/>
  - <https://www.aestheticrecord.com/before-after-photo-video-managment/>
  - <https://delam.ai/>
  - <https://www.centiclinic.com/>
- Relevant trust references for the product bar:
  - GDPR child consent expectations: <https://gdpr.eu/article-8-childs-consent/>
  - GDPR special-category health data: <https://www.clarip.com/data-privacy/gdpr-article-9/>
  - PSD2/SCA payment expectations: <https://www.eba.europa.eu/publications-and-media/press-releases/eba-clarifies-application-strong-customer-authentication>
  - CSRD sustainability reporting context: <https://finance.ec.europa.eu/financial-markets/company-reporting-and-auditing/company-reporting/corporate-sustainability-reporting_en>
  - EU building smart-readiness context: <https://energy.ec.europa.eu/topics/energy-efficiency/energy-performance-buildings/smart-readiness-indicator_en>

## Portfolio-Wide Findings

| Finding | Impact |
|---------|--------|
| All four `apps/complete-saas/modules.yaml` files currently use the same baseline SaaS composition. | The products can run as baseline PlatformKit apps, but the active module set does not prove each vertical thesis. |
| Product docs describe rich vertical flows that are not represented in active module composition. | Public positioning risks over-claiming until the vertical runtime catches up. |
| Several seeds use guarded `to_regclass(...)` checks or comments stating vertical intent remains docs-only. | Critical product data silently no-ops when required tables/modules are absent. |
| Onboarding docs link to how-to files that do not exist. | A new evaluator can run the baseline app, but cannot follow the repo docs to complete the claimed vertical flows. |
| Smoke coverage is shell-level or missing. | There is no automated proof for primary workflows, revenue events, or compliance-sensitive flows. |
| Compliance and runbook docs are empty or missing for most products. | The products are not ready for regulated buyers or operational handoff. |

## Triple-Check Notes

These findings were re-checked after distinguishing "runnable baseline app"
from "complete vertical product":

- The four `complete-saas` overlays are structurally present and use public OSS
  module IDs.
- Their active `modules.yaml` files list the baseline PlatformKit modules:
  admin, API keys, audit, auth, billing, chat, content, entitlement, health,
  mail, notifications, site, tenant, translation, and users.
- `platformkit-business-modules/modules.go` keeps legacy vertical helpers such
  as `WithBookingManagement`, `WithMembershipManagement`,
  `WithDeviceManagement`, `WithGuardianManagement`, and `WithTaskManagement` as
  no-op compatibility aliases in OSS builds.
- The named vertical module directories are not present in
  `platformkit-business-modules`, and the retained module contract catalog does
  not list them as supported modules.
- Generated NATS proxy bindings exist for some vertical ports, but those
  bindings do not by themselves make the vertical modules active in the
  products.
- `platformkit-apps/scripts/validate-overlay-layout.sh` did not flag the four
  `modules.yaml` files. It did flag an Incomum metadata mismatch:
  `docs/SOLUTION.cue` says `homepageRenderer: "incomum"`, while the app
  homepage JSON expects `overlay_experience`. It also flagged Cutout, which is
  outside this four-product scope.

## Gap Matrix

| Product | Runtime modules | Seed data | Product workflows | Trust/runbooks | Smoke proof | Overall gap |
|---------|-----------------|-----------|-------------------|----------------|-------------|-------------|
| COMUM | Runnable baseline only | Tenant/operator only | Vertical coworking flow claimed in docs, not proven by active modules or smoke | Directories exist but are empty | Shell only | High |
| Incomum | Runnable baseline only | Richer guarded school seed, inactive without missing tables | Vertical education flow claimed in docs, not proven by active modules or smoke | Missing | Placeholder only | High |
| Apex | Runnable baseline only | Tenant/operator/domain only | Vertical smart-building flow claimed in docs, not proven by active modules or smoke | Missing | Missing | Critical |
| Velora | Runnable baseline only | Richer guarded clinic seed, inactive without missing tables | Vertical clinic flow claimed in docs, not proven by active modules or smoke | Missing | Missing | High |

## Shared Requirements

Every product must satisfy these before it can be called end-to-end ready:

1. The `complete-saas` composition includes every vertical module required by
   the product story.
2. Any required module is present in catalog/contracts and can be resolved
   without private hand edits.
3. Seeds create a realistic tenant, users, roles, product records, and one
   complete operating day.
4. The public, customer/member, and operator/admin surfaces are runnable in the
   browser.
5. At least one revenue event is wired through the standard billing/payment
   boundary.
6. Notifications exist for the main workflow and use the product's voice.
7. Compliance, privacy, incident, and support runbooks match the product's real
   data risk.
8. Local onboarding can be completed by a new evaluator in under 30 minutes.
9. Automated smoke covers login, primary workflow, operator review, and one
   revenue event.
10. The commercial page links to live URL, screenshots or video, launch notes,
    support contact, and current readiness score.

## COMUM

### Current State

COMUM has the clearest real-customer story and a runnable PlatformKit baseline
overlay. The active runtime is still the baseline SaaS composition. The
`tenant.sql` seed creates the tenant, operator user, and membership record only.
The onboarding doc claims members, bookings, invoices, events, and a
coworking-specific admin surface, but the linked how-to files are missing.

### Top 10 Requirements

| ID | Requirement | Gap today | Acceptance condition |
|----|-------------|-----------|----------------------|
| COMUM-01 | Promote or implement coworking modules: `space_management`, `booking_management`, `membership_management`, `event_management`, `support_management`, and invoice/payment flows. | `modules.yaml` lists only the baseline SaaS modules. | `complete-saas` boots with the coworking modules and dependency validation passes. |
| COMUM-02 | Model coworking spaces, resources, access rules, and capacity. | No desks, rooms, office units, day passes, or capacity rules are seeded. | Seed includes shared desks, meeting room, private offices, event space, pricing, and availability. |
| COMUM-03 | Build public lead and conversion paths. | Public site exists, but tour/day-pass/application flow is not wired to operations. | Visitor can request a tour, buy a day pass, or apply for membership from the public surface. |
| COMUM-04 | Build member onboarding and approval. | Onboarding doc links `approve-member.md`, but the file and flow are absent. | Operator approves an applicant, assigns plan/access, and member receives confirmation. |
| COMUM-05 | Build booking and access workflow. | No active booking module or seeded booking records. | Member books a room/resource, availability changes, and operator can view/check in booking. |
| COMUM-06 | Build recurring billing and invoice batch. | Billing module is present, but no coworking invoice path is seeded or smoke-tested. | Monthly invoice batch charges memberships, room credits, add-ons, and produces customer-visible invoices. |
| COMUM-07 | Build events and community publishing. | Onboarding links `publish-event.md`, but the file and flow are absent. | Operator publishes event; member can register; notifications are sent. |
| COMUM-08 | Add support/mail/package operational workflows. | Coworking competitor baseline includes support and member messaging; current app only has generic modules. | Member can open support request; operator triages it; notification history is retained. |
| COMUM-09 | Fill compliance and runbook docs. | `docs/compliance` and `docs/runbooks` exist but are empty. | GDPR, payment/SCA, failed payment, booking conflict, member offboarding, data export, and incident runbooks exist. |
| COMUM-10 | Add product E2E smoke. | Smoke only checks `/ready`, login, and admin shell. | E2E covers homepage, application, approval, booking, invoice/payment, and admin metrics. |

### Priority

COMUM should be closed first. It is the strongest first commercial proof because
it is a real client/product surface and maps directly to high-demand coworking
software categories.

## Incomum

### Current State

Incomum has a strong education thesis, a runnable PlatformKit baseline overlay,
and a richer seed file. That seed is guarded by table-existence checks. The
current runtime composition still uses baseline SaaS modules, so program,
project, task, guardian, and consent data can silently no-op unless those
modules exist. Onboarding links seven how-to files that are not present.

### Top 10 Requirements

| ID | Requirement | Gap today | Acceptance condition |
|----|-------------|-----------|----------------------|
| INC-01 | Promote or implement education modules: `guardian_management`, `program_management`, `cohort_management`, `task_management`, `project_workspace_management`, `event_management`, `file_management`, and digest notifications. | `modules.yaml` lists only baseline SaaS modules. | `complete-saas` boots with education modules and validates dependencies. |
| INC-02 | Make guardian consent a first-class workflow. | Docs claim Article 8-style consent, but no active guardian module is in composition. | Guardian creates account, verifies relationship, accepts policies, and consent is audit logged. |
| INC-03 | Build cohort and program operations. | `z-school.sql` seeds programs only if program tables exist. | Operator creates cohort, schedules sessions, assigns instructor/mentor, and manages capacity. |
| INC-04 | Build student/kid portal. | Docs claim `/kid`, but runtime proof is absent. | Student logs in, sees assignments, submits project work, and receives feedback safely. |
| INC-05 | Build teacher review and rubric scoring. | Seed includes rubric/task concepts only if tables exist. | Teacher reviews submission, scores rubric, comments, and awards progression. |
| INC-06 | Build belt/progression credentialing. | Docs claim belt awards, but no runnable flow exists. | Belt/progression award appears in student and guardian views with audit trail. |
| INC-07 | Build weekly guardian digest. | Generic notification module exists, but product digest is not wired. | Guardian receives weekly summary of attendance, assignment progress, and upcoming sessions. |
| INC-08 | Build billing/subscription or tuition path. | No education revenue path is evident in seed or smoke. | Guardian can pay tuition, subscription, workshop fee, or camp booking through standard billing. |
| INC-09 | Fill safeguarding, privacy, and runbook docs. | There is no `docs/compliance` or `docs/runbooks` directory. | Child-data handling, safeguarding incident, parent request, data erasure, attendance issue, and breach runbooks exist. |
| INC-10 | Add product E2E smoke. | Smoke README is a placeholder. | E2E covers guardian enrollment, consent, cohort enrollment, student assignment, teacher scoring, digest, and payment. |

### Priority

Incomum should follow COMUM once the shared product-surface and smoke patterns
are reusable. It is important because it proves child-data, consent, education
operations, and multi-role portals.

## Apex

### Current State

Apex has the largest enterprise story, a runnable PlatformKit baseline overlay,
and the widest vertical-product gap. The docs describe smart-building portfolio
operations, anomalies, contractors, ESG, sensor adapters, and audit exports. The
runtime composition is still baseline SaaS, and the seed creates only
tenant/operator/domain aliases. The mobile pack appears aligned to traffic
operations rather than smart-building operations.

### Top 10 Requirements

| ID | Requirement | Gap today | Acceptance condition |
|----|-------------|-----------|----------------------|
| APX-01 | Promote or implement smart-building modules: `asset_management`, `building_management`, `device_management`, `sensor_adapter_management`, `anomaly_management`, `work_order_management`, `contractor_management`, `esg_reporting`, and `evidence_export`. | `modules.yaml` lists only baseline SaaS modules. | `complete-saas` boots with smart-building modules and dependency validation passes. |
| APX-02 | Seed the 30-building portfolio promised by onboarding. | Seed only creates tenant/operator/domain aliases. | Seed creates buildings, floors, systems, equipment, meters, sensors, contacts, contractors, and operating baselines. |
| APX-03 | Build sensor ingestion and adapter onboarding. | Docs link `onboard-sensor-adapter.md`, but the file and flow are absent. | Operator registers adapter, receives synthetic telemetry, validates mapping, and sees health status. |
| APX-04 | Build anomaly detection and triage. | No anomaly data or module is active. | Telemetry creates anomaly, operator triages it, assigns severity, and starts SLA timer. |
| APX-05 | Build contractor/work-order resolution. | No contractor or work-order module is active. | Anomaly creates work order, contractor updates status, evidence is attached, SLA closes. |
| APX-06 | Build portfolio map, asset detail, and operational dashboards. | Public/product docs describe these surfaces, but runtime proof is absent. | Operator can navigate portfolio, building, floor/system, asset, anomaly queue, and contractor SLA dashboards. |
| APX-07 | Build ESG/energy reporting. | Docs claim ESG reporting, but there is no active seeded energy or report path. | Monthly ESG report calculates energy, emissions assumptions, anomalies, actions, and export artifact. |
| APX-08 | Build audit/evidence export. | Docs link `export-iso-27001-audit.md`, but the file and flow are absent. | Operator exports evidence bundle containing changes, incidents, SLA, adapter health, and report hashes. |
| APX-09 | Correct or split the mobile product. | Mobile pack text says traffic operations, not smart buildings. | Mobile pack either becomes Apex smart-building field ops or is renamed into a separate traffic product. |
| APX-10 | Add enterprise runbooks and E2E smoke. | No compliance/runbook directories; no product smoke contract. | Runbooks cover adapter outage, paging failure, contractor breach, ESG restatement, incident, and disaster recovery; E2E covers ingestion to ESG/audit export. |

### Priority

Apex should not be marketed as complete until the module gap is closed. It can
remain a strategic enterprise target, but it requires the most backend/product
module work before public proof.

## Velora

### Current State

Velora has a strong vertical concept, a runnable PlatformKit baseline overlay,
and the richest seed intent, including booking catalog data guarded by
table-existence checks. The runtime composition still uses baseline SaaS
modules, so booking, worker, service catalog, treatment, consent, archive, and
membership paths are not guaranteed to exist. There are no compliance or
runbook directories, and onboarding links eight missing how-to files.

### Top 10 Requirements

| ID | Requirement | Gap today | Acceptance condition |
|----|-------------|-----------|----------------------|
| VEL-01 | Promote or implement clinic modules: `booking_management`, `worker_management`, `service_catalog`, `membership_management`, `treatment_plan_management`, `consent_management`, `file_management`, `task_management`, `device_management`, and payment flows. | `modules.yaml` lists only baseline SaaS modules. | `complete-saas` boots with clinic modules and dependency validation passes. |
| VEL-02 | Make booking catalog data active. | `booking_catalog.sql` no-ops if service/worker/booking tables are absent. | Seed creates rooms, practitioners, services, working hours, treatment durations, and availability. |
| VEL-03 | Build public consultation booking. | Public site exists, but consultation booking is not proven end to end. | Visitor books initial consultation, pays deposit if required, receives confirmation, and appears on staff calendar. |
| VEL-04 | Build consultation and treatment configurator. | Docs link `run-consultation-with-configurator.md`, but the file and flow are absent. | Clinician records assessment, recommends treatment plan, captures products/devices, and sends plan for approval. |
| VEL-05 | Build 72-hour plan delivery SLA. | Task/SLA path is described, but not wired. | Consultation creates plan-delivery task, deadline is tracked, escalation notification fires if late. |
| VEL-06 | Build before/after photo archive with consent. | Docs claim archive and consent, but no active media/consent module is in composition. | Staff captures media, links it to treatment, enforces consent scope, and revocation hides or purges eligible media. |
| VEL-07 | Build membership conversion and packages. | No active membership/package revenue path is proven. | Consultation converts to membership/package, charges through billing, and exposes benefits in member portal. |
| VEL-08 | Build device, room, and clinician scheduling constraints. | Seed intent includes rooms and workers, but runtime constraints are not active. | Booking prevents double-booking room, practitioner, device, and service duration. |
| VEL-09 | Fill health-data compliance and clinical runbooks. | There is no `docs/compliance` or `docs/runbooks` directory. | GDPR Article 9, Portuguese privacy posture, consent revoke, record export, breach, device calibration, and clinical escalation docs exist. |
| VEL-10 | Add product E2E smoke. | No product smoke contract under `apps/complete-saas`. | E2E covers booking, deposit/payment, consultation, treatment plan, media consent, membership conversion, schedule constraint, and GDPR export. |

### Priority

Velora should be the second product to close if the goal is commercial breadth:
it proves regulated data, appointments, membership revenue, media consent, and
premium service operations.

## Suggested Execution Order

1. Close shared module/catalog gaps that COMUM and Velora both need:
   booking, membership, service/resource catalog, invoice/payment, file/consent,
   notifications, and product smoke harness.
2. Finish COMUM first as the public reference customer.
3. Finish Velora second to prove regulated booking, consent, media, and
   recurring revenue.
4. Finish Incomum third using the same portal, consent, notification, and
   billing primitives.
5. Keep Apex as the enterprise track, but do not call it complete until the
   smart-building modules and mobile mismatch are resolved.

## Definition Of Done

A product is complete only when the following are true in the repo:

- `apps/complete-saas/modules.yaml` names the actual vertical modules.
- Required module contracts are present in the module catalog and pass
  validation.
- Critical seeds fail loudly if required tables are missing; they do not silently
  skip the main product data.
- Every onboarding link exists and can be executed against the local app.
- The main public/customer/operator workflow works in browser.
- One revenue event completes through billing/payment.
- Notifications, compliance docs, support docs, and runbooks exist.
- Product smoke is automated and covers the main workflow, operator review, and
  revenue event.
- Commercial page truthfully reflects readiness and links to proof.
