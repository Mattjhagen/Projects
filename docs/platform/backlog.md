# Phased Backlog with Acceptance Criteria

Status: Proposed (Phase 0). Each phase lists deliverables and acceptance criteria. No phase
below Phase 0 is authorized to start until its dependencies exist and the consent gate design
is ratified by the human owner. Agents never merge/deploy/release in any phase.

## Phase 0 — Design & backlog (this pull request)

Deliverables: the 11 document groups in [README.md](README.md), in one PR targeting
`Mattjhagen/Projects`, with linked security child per [../AUTOMATED_WORKFLOW.md](../AUTOMATED_WORKFLOW.md).

### Phase 0 acceptance criteria

1. All 11 deliverable groups exist as reviewable documents in one pull request.
2. The entitlement decision table below covers every classification × plan-state combination
   with explicit outcomes.
3. The ticket state machine matches exactly:
   `submitted → validated → classified → entitled / approval-required / blocked → planned →
   in-development → security-review → human-release-approval → released → monitoring → closed`
   ([state-machines.md §3](state-machines.md)).
4. Billing and affiliate-commission ledgers are modeled as separate stores with no shared
   write path ([data-model.md §4, §6](data-model.md); ADR-0003).
5. Every unresolved decision from #13 appears in [open-decisions.md](open-decisions.md) with
   owner = human; proposed defaults are marked non-authoritative.
6. Documents contain no secrets, tokens, host addresses, or private user data.
7. CI `validate` passes and `agent/security-review` succeeds on the PR head before human
   merge; agents do not merge.

### Entitlement decision table (normative)

Outcomes: **E** = entitled (autonomous pipeline allowed for low-risk work; included hours/
credits consumed), **A** = approval-required (written scope + estimate at contracted rate;
chargeable work only after recorded customer/human approval), **B** = blocked (human triage;
no automatic chargeable work). Global overrides apply after the table:

- Ambiguous classification at any plan state → **B**.
- High-risk request at any cell → **B** (expedited if incident/security).
- Included allowance exhausted at any cell where outcome would be E → **A**.
- Security incidents/outages always take the expedited path with immediate human notification
  regardless of cell ([state-machines.md T24](state-machines.md)).

| Classification ↓ / Plan state → | active | suspended | delinquent | canceled | expired |
| --- | --- | --- | --- | --- | --- |
| **incident** | E — expedited, included hours first | B → expedited human-supervised triage (safety work proceeds; no autonomous prod action) | E during grace, expedited; after grace B → human-supervised safety-only | B → report accepted, human-triaged only while hosting/data persists | B → same as canceled during export window |
| **security issue** | E — expedited + immediate human notification | B → expedited human-supervised; platform security-critical patching continues | B → same as suspended | B → accepted and human-triaged (platform obligation while any tenant asset remains) | B → same as canceled during export window |
| **defect** | E — included under warranty/scope, low risk | B — paused, resumable on reinstatement (T22/T23) | B — paused pending cure; resume after payment confirmed | B — not actionable → close unless security-linked | B — same as canceled |
| **maintenance** | E — included upkeep per plan | B — except platform-side security-critical patching (never ticket-billed, never stops) | E during grace for SLA-critical items; otherwise B | B — security patches only via platform obligation | B — same as canceled |
| **content change** | E while content allowance remains; else A at USD 25/hr | B — paused | B — paused pending cure | B — closed as out-of-service | B — requires reactivation/renewal first |
| **implementation** | A — scope + estimate at contracted rate required before work | B — paused | B — paused pending cure | B | B — requires renewal/reactivation |
| **new feature** | A — change order mandatory | B — paused | B — paused pending cure | B | B — requires renewal/reactivation |

Every row/column combination above has an explicit outcome; no cell is undefined.

## Phase A — Platform foundations

Deliverables: tenancy model implementation (ADR-0002 policies), authentication/authorization,
private object storage with scanning pipeline, append-only audit log, durable workflow engine
(ADR-0006), kill switches (ADR-0011), secrets management layout.

Acceptance:

- Cross-tenant access matrix tests fail closed for every object type.
- Upload of disallowed type / oversized file / malware sample is rejected or quarantined.
- Every audited action appears in `AuditLog` with actor, input hash, outcome.
- Workflow retry replay produces zero duplicate side effects (test harness).
- Kill switch halts each scoped action within one orchestration tick.

## Phase B — Attribution and intake

Deliverables: affiliate registration + tracked links, click/attribution records, plain-language
intake form (all fields from #13), upload flow to scanned private storage, ScopeProposal
drafting tools for PM.

Acceptance:

- Click token replay cannot create a second attribution session.
- Intake submission without verified attribution still works (attribution optional, recorded
  when valid).
- All intake fields persist per schema; uploads scan before processing.
- Prospect can view generated scope proposal; PM can edit before sharing.
- Accessibility checks pass on intake UI (AA).

## Phase C — Contracting and billing authorization

Deliverables: template lifecycle (legal review gate), e-sign integration (least privilege),
Stripe customer/payment-method setup, mandate capture, consent gate service.

Acceptance:

- Unapproved template versions cannot render contracts (enforced, tested).
- Contract reaches `active` only after signed envelope evidence AND active billing
  authorization (state machine §1 tests).
- Mandate text is immutable post-approval and matches contract terms verbatim.
- Gate refuses planning start without both conditions; refusal is audited.

## Phase D — Delivery orchestration and invoicing

Deliverables: isolated client repo/environment provisioning runbooks (human-approved),
T310 planning artifacts, R510 execution with idempotency keys, R410 review integration,
staging preview + acceptance recording, time-entry verification flow, invoice generation from
verified entries, webhook verification/idempotency, release gate.

Acceptance:

- Retry storm simulation duplicates nothing (issues/branches/time/invoices/releases).
- Invoice issues only from fully verified entries; estimates never auto-invoice.
- Release gate evaluates acceptance + issued invoice + confirmed payment webhook + explicit
  human approval; each alone is insufficient (INV-2 test).
- Forged/duplicate webhooks collapse to one effect and are logged.

## Phase E — Support tickets and client dashboard

Deliverables: authenticated submission, snapshotting, deterministic classifier + entitlement
engine (policy-versioned), autonomous pipeline for entitled low-risk work, expedited security/
outage path, dashboard views with exposure rules.

Acceptance:

- Entitlement engine reproduces the decision table for all 35 cells (table-driven tests).
- Ambiguous/high-risk inputs resolve to blocked with human notification.
- Expedited path notifies humans immediately (measured) and blocks autonomous production
  actions structurally.
- Dashboard exposes none of: secrets, prompts, infra details, sensitive logs (review +
  automated redaction tests).

## Phase F — Managed hosting, maintenance, renewal

Deliverables: monitoring/backups/patching automation per plan snapshot, maintenance history,
renewal offers/flows, suspension/delinquency/expiry propagation (plan-lifecycle tables),
data export tooling, domain/source handover runbooks.

Acceptance:

- Lifecycle transitions propagate to open tickets correctly (T22/T23 tests).
- Incident/security reporting works in every plan state (carve-out test).
- Backups restore-verified on schedule; monitoring alerts page humans per SLA matrix.
- Export archive completes and is audited.

## Phase G — Affiliate commission ledger

Deliverables: separate commission store/service, settlement-fact ingestion, accrual
computation per agreement version, withholding on refund/chargeback, payout batches with
human approval, reconciliation.

Acceptance:

- Commission service holds no credentials against billing stores and vice versa (config test).
- Accruals derive only from paid settlement facts; dedup prevents double-count.
- Refund/chargeback moves related accruals to withheld automatically.
- Payout executes only after recorded human approval.

## Phase H — Hardening, audits, legal completion

Deliverables: threat-model control tests executed ([threat-model.md §4](threat-model.md)),
disaster-recovery drill, accessibility audit of delivered-site templates, final human legal
sign-off on contract templates and mandates.

Acceptance:

- All AS-1…AS-12 mitigations have passing tests.
- DR drill restores a tenant site from backup within SLA targets.
- Templates carry `legal_review_status = approved` with named reviewer.
