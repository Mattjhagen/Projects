# Durable-Record Specification

Status: Proposed (Phase 0). Normative list of what must be persisted, where it lives
([data-model.md](data-model.md)), and its immutability class. Storage classes: **immutable**
(append-only; corrections by reversal/supersession), **versioned** (new row supersedes old,
old retained), or **mutable-audited** (updates allowed, every change audited).

| # | Record (from #13 DECISION / #14 deliverable 5) | Entity | Class | Notes |
| --- | --- | --- | --- | --- |
| 1 | Original ticket as submitted (text + inputs) | `Ticket` + `TicketDecision(stage=validation)` snapshot of raw input hash | immutable | Edits create linked follow-up tickets, never rewrite history |
| 2 | Attachment metadata | `IntakeUpload` / ticket attachment rows | immutable metadata | Object contents may be purged per retention (`purged_at`); metadata remains with hash |
| 3 | Plan snapshot used for each decision | `EntitlementSnapshot` (+`TicketSnapshotLink`) | immutable | Frozen JSON copy incl. SLA, hours/credits, approval/spend limits (ADR-0012) |
| 4 | Classification result | `TicketDecision(stage=classification)` | immutable | Includes rule refs + `policy_version` |
| 5 | Entitlement decision + reason | `TicketDecision(stage=entitlement)` | immutable | Outcome ∈ entitled/approval-required/blocked |
| 6 | SLA, priority, risk level at decision time | inside `EntitlementSnapshot.frozen_json` + `TicketDecision` | immutable | Later changes never retro-apply |
| 7 | Estimated billable/included time | `ChangeOrder`, plan/task records, `WorkflowRun.checkpoint` | versioned | Estimate revisions supersede, prior kept |
| 8 | Actual billable/included time | `TimeEntry` (append-only) + reversing entries | immutable | Human verification flips nothing — adds `verified_status` event rows? No: status column is mutable-audited until invoiced lock |
| 9 | Customer approvals | `ApprovalRecord(kind ∈ change_order, estimate_overage, acceptance)` | immutable | Identity + evidence refs mandatory |
| 10 | Human approvals (release, time verification, refunds) | `ApprovalRecord` | immutable | Release gate consumes these |
| 11 | Issue/PR links for automated work | `TicketWorkLink` | immutable | Carries idempotency key to prevent duplicates |
| 12 | Agent handoffs | `AuditLog(action=agent.handoff)` + workflow checkpoints | immutable | Mirrors MESSAGE_PROTOCOL handoffs into durable store |
| 13 | Review results (security/bug/a11y verdicts) | `ReviewResult` (audit-backed; commit-status refs) | immutable | Blocking vs advisory disposition recorded |
| 14 | Invoices and line items | `Invoice` | issued = immutable | Draft stage mutable-audited; issuance locks content |
| 15 | Payments & webhook events | `PaymentEvent` | immutable | Provider event id dedup |
| 16 | Refunds/credit notes/disputes | `CreditNote`, `Invoice(state=disputed…)` transitions in audit | immutable | Dispute thread references invoice version |
| 17 | Releases & cutover approvals | `Release` + gate evaluations | immutable | Preconditions embed acceptance/invoice/payment/approval ids |
| 18 | Maintenance history | `MaintenanceHistory`, `BackupRecord`, `MonitoringIncident` | immutable events | Corrections via new events |

## Cross-cutting rules

1. **Actor attribution**: every record stores actor type+id (`agent:<id>` / `human:<id>` /
   `system:<component>`).
2. **Input integrity**: untrusted inputs stored alongside their SHA-256 so later tampering is
   detectable even where content is purged.
3. **Correlation**: `ticket_id`, `tenant_id`, `workflow_run_id`, and invoice/release ids form a
   queryable chain from intake → delivery → support.
4. **Retention interplay**: immutability holds through the retention window; deletion after
   that follows [failure-retry.md §4](failure-retry.md) including crypto-shredding where row
   deletion is structurally impossible.
5. **Exportability**: all tenant-owned records are exportable in open formats on request per
   contract terms ([plan-lifecycle.md §5](plan-lifecycle.md)); export actions are themselves
   audited.

## Correction semantics

- Wrong time entry → reversing entry referencing original; both remain visible; invoice math
  consumes net values only after human verification.
- Misclassification → new `TicketDecision` superseding prior (linked), prior retained; state
  machine transition T10/T16 records the correction path.
- Invoice error pre-issuance → edit with audit trail; post-issuance → credit note/reissue
  (state machine §2 only).
