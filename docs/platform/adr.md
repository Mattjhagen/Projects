# Architecture Decision Records

Statuses: `Proposed` (needs human ratification) or `Accepted`. Phase 0 ADRs are Proposed until
the human owner ratifies them; none authorize implementation by themselves.

## ADR-0001 — Documentation-first delivery in a single design repository

- Status: Proposed
- Context: Phase 0 must produce reviewable, diffable design artifacts without touching the
  future implementation surface (`purepulse-admin` and related services).
- Decision: All Phase 0 deliverables live under `docs/platform/` in `Mattjhagen/Projects` and
  are delivered by one pull request. No code, repositories, environments, credentials, or
  infrastructure are created.
- Consequences: Design review happens in one PR; later phases copy authoritative sections into
  implementation repos as those repos exist.

## ADR-0002 — Tenant isolation enforced below the application layer

- Status: Proposed
- Context: The platform holds contracts, financial records, intake assets, and ticket history
  for many unrelated clients; browser-supplied claims must never be trusted (#13 DECISION).
- Decision: Every tenant-owned table carries `tenant_id`; storage policies (row-level security
  or equivalent) enforce tenant scoping in addition to application checks. Object storage keys
  are prefixed by tenant and access is via short-lived, tenant-scoped URLs only. Integration
  tokens and agent credentials are minted per tenant and per task with expiry.
- Consequences: Slightly higher setup cost per tenant; eliminates whole classes of IDOR and
  cross-tenant leakage bugs.

## ADR-0003 — Separate commission ledger store

- Status: Proposed
- Context: Affiliate commissions and client billing must not mix ledgers; a single write path
  would let either side corrupt the other and complicates audit scope.
- Decision: Client billing (time entries, invoices, payments, credit notes) lives in the
  billing service/store. Affiliate commissions live in a physically separate commission
  store/service with its own append-only event log. The only permitted interaction is
  settlement-time, one-way publication of minimal, non-PII facts from billing events to a
  commission accrual queue (invoice ID, amount, currency, status) — no shared database,
  no bidirectional writes ([data-model.md §6](data-model.md)).
- Consequences: Reconciliation is an explicit, auditable process; payout logic cannot read or
  mutate client billing data.

## ADR-0004 — Deterministic entitlement classification before any agent work

- Status: Proposed
- Context: #13 DECISION requires deterministic classification (incident, security issue,
  defect, maintenance, content change, implementation, new feature) and plan-based entitlement
  decided server-side.
- Decision: Classification is a pure function of structured ticket inputs (category, impact,
  desired outcome, snapshot) with all rules versioned (`policy_version` on every decision).
  Ambiguity resolves to `blocked` (human triage), never to billable work. Entitlement outcome
  is one of `entitled`, `approval-required`, or `blocked`.
- Consequences: Auditable, testable decisions; ambiguous requests pause rather than bill.

## ADR-0005 — Human-only irreversible actions with recorded approvals

- Status: Proposed
- Context: Agents must never sign, approve time, charge payment methods, merge, release, or
  deploy; cutover additionally requires explicit human approval after a confirmed payment
  webhook (#14 objective).
- Decision: Every irreversible action requires an `ApprovalRecord` referencing the acting
  human identity, scope, and time. Platform enforces these gates server-side; agent
  credentials structurally lack merge/deploy/charge permissions.
- Consequences: Clear accountability; automation cannot bypass gates even if misconfigured.

## ADR-0006 — Idempotent, resumable automation with durable workflow state

- Status: Proposed
- Context: Retries after partial failure must never duplicate issues, branches, time entries,
  invoices, or deployments (#13 DECISION).
- Decision: Each automated step writes intent (idempotency key + input hash) to durable
  workflow state before side effects; integrations pass idempotency keys through; steps are
  resumable from last completed checkpoint. Duplicate deliveries collapse onto the same key
  ([failure-retry.md](failure-retry.md)).
- Consequences: At-least-once delivery becomes safe; replay is a first-class operation.

## ADR-0007 — Untrusted-data boundary around tickets and uploads

- Status: Proposed
- Context: Ticket text and attachments are attacker-controllable and reach both humans and
  agents (#13 DECISION prompt-injection requirement).
- Decision: Ticket text/attachments are treated as untrusted data, never instructions. Agent
  prompts wrap content in clearly delimited, escaped blocks with standing rules that ignore
  embedded directives. Uploads are scanned, type/size-restricted, stored privately, and served
  via expiring URLs; they are never rendered inline un-sanitized or executed.
- Consequences: Prompt-injection and malicious-file risk reduced to defense-in-depth residual;
  some UX friction for power users.

## ADR-0008 — Webhook verification and idempotency for money-touching integrations

- Status: Proposed
- Context: Stripe and e-sign webhooks drive billing gates; forged or duplicated events could
  trigger releases or charges.
- Decision: Signature verification against provider secrets, timestamp tolerance windows,
  provider event IDs used as idempotency keys, and out-of-band confirmation of critical state
  (e.g., invoice status re-fetched from the API) before gate evaluation.
- Consequences: Slight latency at gates in exchange for fraud resistance.

## ADR-0009 — Append-only financial and audit records

- Status: Proposed
- Context: Disputes, audits, and commission calculations need immutable history.
- Decision: Time entries, invoices, payments, commission events, entitlement snapshots, and
  audit logs are append-only. Corrections use reversing entries or supersession records that
  reference their predecessor; nothing is updated or deleted within retention.
- Consequences: Storage growth is accepted; deletion happens only per retention policy with
  documented crypto-shredding where full row deletion is impossible.

## ADR-0010 — Accessibility target WCAG 2.2 AA for client-facing surfaces

- Status: Proposed
- Context: Portals (intake, client dashboard) and delivered sites serve the general public.
- Decision: WCAG 2.2 AA applies to intake, dashboard, invoicing views, staging previews, and
  delivered sites; automated checks run in CI and R410 reviews accessibility per release.
- Consequences: Accessibility defects block acceptance/review gates like security findings.

## ADR-0011 — Emergency stops are manual, scoped, and audited

- Status: Proposed
- Context: Humans need to halt charging, agent work, deployments, or outbound e-sign quickly.
- Decision: Four independent kill switches (charges, orchestration, deployments, e-sign).
  Activation requires human action, takes effect immediately platform-wide, is logged with
  actor and reason, and deactivation requires a second human action.
- Consequences: Brief operational pauses possible without engineering involvement.

## ADR-0012 — Plan snapshots freeze entitlements at decision time

- Status: Proposed
- Context: Plans change over a 12-month term; disputes require knowing exactly which terms
  applied when a decision was made (#13 DECISION durable-record list).
- Decision: Every classification/entitlement/billing decision references an immutable
  `EntitlementSnapshot` capturing contract, plan version, enabled features, SLA, included
  hours/credits, maintenance term, and approval/spend limits at that moment.
- Consequences: Retroactive plan changes cannot rewrite history; snapshots add storage but
  make disputes decidable.
