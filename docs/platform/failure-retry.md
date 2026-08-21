# Failure, Retry, Dispute, Retention, and Accessibility Rules

Status: Proposed (Phase 0).

## 1. Idempotency and resumability (normative)

Every automated/integration write carries a deterministic idempotency key
`(tenant_id, workflow_run_id, step)` recorded in `WorkflowRun` before side effects (ADR-0006).

Guarantees:

- **Issues/branches/PRs**: created only after intent row exists; creation calls pass the key
  to the provider where supported, else check `TicketWorkLink` for prior success before retry.
- **Time entries**: `idempotency_key UNIQUE`; retries collapse onto the same entry.
- **Invoices**: one open invoice per tenant per period; issuance is guarded by unique
  `(tenant_id, period)` constraint; retries reuse the draft.
- **Payments/webhooks**: provider event id dedup; effects applied once.
- **Deployments/releases**: release id pre-created in `pending` state; deploy step is a
  transition, so replays cannot double-deploy.

Resumability: steps checkpoint into `WorkflowRun.checkpoint`; crash recovery continues from
last completed checkpoint; workflows stuck > SLA threshold alert humans.

Failure classification:

| Failure class | Automatic behavior |
| --- | --- |
| Transient provider error | Exponential backoff retry with cap; then park run as `awaiting_human` |
| Validation/guard failure | No retry; state stays; reason recorded; notify owner role |
| Security-relevant anomaly (signature fail, injection hit, scan positive) | Halt + security queue + audit; no auto-remediation |
| Kill switch active | All affected orchestration halts within one tick |

## 2. Retry budgets

Default: 5 attempts / 15 minutes exponential backoff for transient classes, then human handoff.
Money-touching operations (charge attempts, payouts) never exceed provider-mandated retry
policies and always re-validate current authorization state before each attempt (INV-1).

## 3. Invoice dispute handling

1. Customer disputes an invoice during the dispute window (`Invoice.dispute_window_ends_at`)
   via dashboard → invoice state `disputed` (state machine §2).
2. Platform freezes collection actions on that invoice automatically.
3. Human reviews against durable records: verified time entries, approvals, snapshots
   ([durable-records.md](durable-records.md)).
4. Outcomes: uphold (resume collection), adjust (credit note/reversing entries — human-approved),
   or void per state machine.
5. Chargebacks follow OD-PAY-1 defaults: contest with evidence pack (contract mandate,
   approvals, delivery evidence); commission accruals tied to that payment are moved to
   `withheld` until resolution ([data-model.md §6](data-model.md)).

## 4. Deletion/retention rules (defaults pending OD-DATA-1)

| Record class | Retention default | Deletion method |
| --- | --- | --- |
| Contracts, invoices, payments, time entries, approvals, audit logs | 7 years post-term | Never deleted inside window; then archive+crypto-shred PII fields |
| Ticket content & attachments metadata | Contract term + 24 months | Row retention expiry; object purge (`purged_at`), metadata+hash retained |
| Upload objects (intake/ticket) | Cleaned uploads: term + 90 days; infected: quarantine 30 days then destroy | Object deletion; metadata immutable record remains |
| Marketing prospect data (no conversion) | 12 months from last activity | Hard delete + backup expiry note |
| Backups | Rolling 35 daily / 12 monthly per plan snapshot | Automated expiry |
| Logs (operational) | 90 days hot, 1 year cold | Automated |

Deletion requests (client/export rights) trigger the export → verify obligations (tax law may
require keeping invoices) → targeted purge/crypto-shred flow, all audited.

## 5. Accessibility requirements

- Target: WCAG 2.2 AA for intake portal, client dashboard, invoicing views, staging previews,
  delivered sites (ADR-0010).
- CI: automated axe-core-style checks block merges on new serious/critical violations.
- R410 review includes accessibility findings; blocking severity follows the same gate as
  security blockers ([state-machines.md T16](state-machines.md)).
- Delivered-site acceptance checklist includes keyboard navigation, contrast, alt text,
  form labeling, and reduced-motion respect; failures return work to development rather than
  shipping.

## 6. Observability hooks

Each subsystem emits structured events for: workflow state changes, gate evaluations,
webhook verification outcomes, scan results, rate-limit hits, kill-switch toggles. Alerts:
workflow stuck, gate bypass attempt, webhook verification failure spike, scan-positive upload,
dispute filed, delinquency entered.
