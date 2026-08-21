# Support-Ticket Subsystem

Status: Proposed (Phase 0). Implements the `[supervisor-codex]` DECISION on #13 verbatim in
design form. Companions: [state-machines.md §3](state-machines.md),
[durable-records.md](durable-records.md), [threat-model.md](threat-model.md).

## 1. Submission (authenticated, dashboard-only)

- Only authenticated `ClientUser`s of the tenant may submit; anonymous intake is not a ticket
  channel. Rate limits per user/tenant/IP apply ([threat-model.md §4](threat-model.md)).
- Required inputs: **category** (free-text guided by prompts), **impact** (structured: none /
  minor / major / outage + affected pages), **desired outcome** (text), **optional
  attachments**.
- Attachments: direct-to-object-storage presigned upload, type/size restricted, scanned before
  processing; metadata immutable ([data-model.md §3](data-model.md), ADR-0007).
- On submit the server resolves tenant and captures an `EntitlementSnapshot` (contract, plan
  version, enabled features, SLA, included hours/credits, maintenance term, approval/spend
  limits). Browser-supplied plan or price claims are ignored by design.

## 2. Deterministic classification

Pure function over `(category_input, impact_input, desired_outcome, snapshot,
policy_version)` → one of:

| Class | Definition (rule sketch) |
| --- | --- |
| incident | Site/functionality down or materially degraded for the client's users |
| security issue | Suspected compromise, vulnerability, malware, data exposure |
| defect | Behavior contradicting accepted scope/spec without external cause |
| maintenance | Included upkeep: patches, certificate renewal, backups restore checks |
| content change | Text/image/menu-level edits within included content allowance |
| implementation | New page/feature work inside plan scope but beyond content edits |
| new feature | Work outside current scope → change order territory |

- Output also includes `priority` (SLA matrix) and `risk_level` (low|medium|high) from rule
  tables versioned as `policy_version`; every decision persists `TicketDecision` with
  reason and rule refs (ADR-0004).
- Ambiguity never defaults to billable work: it yields `blocked` for human triage.

## 3. Entitlement outcomes

Given class × snapshot:

1. **Included, low-risk** → `entitled`: enters autonomous pipeline PM → developer → security
   review. Human merge/deploy/release always required. Consumes included hours/credits first;
   consumption is recorded on time entries (`classification = included`).
2. **Billable/out-of-plan/over-allowance/medium-risk** → `approval-required`: platform writes
   scope + estimate at contracted rate (USD 25/hour) and required change order; chargeable
   work begins only after recorded customer approval (T8).
3. **Ambiguous/high-risk/security-incident-triage/blocked category** → `blocked`: human triage
   with immediate notification where severity warrants; agents prepare but do not act.

The complete classification × plan-state outcome table lives in
[backlog.md §Phase 0 acceptance](backlog.md#phase-0-acceptance-criteria) (entitlement decision
table) and is the normative Phase 0 artifact for this mapping.

## 4. Autonomous pipeline constraints

- Pipeline runs only for `entitled` tickets with risk = low (ADR-0004).
- Every automated step uses durable workflow state + idempotency keys (ADR-0006): retries
  never duplicate issues, branches, PRs, time entries, or deployments.
- Agent credentials are per-tenant, task-scoped, expiring, and structurally lack merge/deploy/
  charge permissions (ADR-0005).
- Security incidents/outages: expedited path, immediate human notification; agents diagnose
  and prepare fixes only.

## 5. Customer dashboard (plain-language surface)

Shows per ticket:

- Current status in plain language (mapped from state machine states; e.g.,
  `human-release-approval` → "Waiting for our team lead's release sign-off").
- Estimates and approvals needed (with what will be charged and why).
- Work performed (issue/PR titles, plain summaries — no raw logs).
- Completion evidence (review results summary, staging link, release note).

Never exposes: secrets, internal agent prompts, infrastructure details, sensitive logs,
internal host names, or other tenants' existence. Exposure rules are enforced server-side via
view models + `DashboardViewLog` audit ([data-model.md §5](data-model.md)).

## 6. Interaction with billing

Time entries attach to tickets with idempotency keys; included vs billable classification is
decided at entry creation from the ticket's entitlement decision, then verified by a human
before invoicing ([state-machines.md §2](state-machines.md)). Ticket-driven charges can never
exceed active caps without a recorded overage approval (`ApprovalRecord.kind =
estimate_overage`).
