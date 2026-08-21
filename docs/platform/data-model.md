# Data Model

Status: Proposed (Phase 0). Notation: entity lists with key fields; `PK` primary key, `FK`
logical foreign key. Physical choices (SQL engine, object store) are deferred per
[open-decisions.md](open-decisions.md) OD-HOST-1/OD-DATA-1; the model is storage-agnostic.

## 1. Conventions

- All tenant-owned entities carry `tenant_id` and are protected by storage-level tenant
  policies (ADR-0002).
- Financial facts (time entries, invoices, payments, commission events, snapshots, approvals,
  audit logs) are append-only (ADR-0009).
- Monetary amounts are integer minor units + ISO currency code.
- Timestamps are UTC with millisecond precision.

## 2. Attribution domain

### Affiliate
`affiliate_id PK`, `code UNIQUE`, `status (pending|approved|suspended|terminated)`,
`payout_terms_ref`, `contact`, `created_at`.

### ReferralClick
`click_id PK`, `affiliate_id FK`, `clicked_at`, `source_url`, `signed_token_hash`,
`suspected_bot bool`, `ip_prefix` (truncated for privacy), `user_agent_class`.
No PII beyond truncated network prefix; full IPs are not stored.

### AttributionSession
`session_id PK`, `first_click_id FK?`, `last_click_id FK?`, `window_expires_at`,
`prospect_id FK?`. Created from click; consumed by intake submission.

## 3. Prospect & scoping domain

### Prospect
`prospect_id PK`, `attribution_session_id FK`, `email_verified bool`, `created_at`.

### ProspectIntake
`intake_id PK`, `tenant_id?` (assigned on conversion), `prospect_id FK`,
`business_goals`, `desired_pages_features jsonb`, `visual_preferences`, `colors`,
`branding jsonb`, `examples jsonb`, `target_audience`, `uiux_expectations`,
`upload_ids []`, `submitted_at`, `schema_version`.

### IntakeUpload
`upload_id PK`, `intake_id FK`, `object_key` (private, tenant-prefixed), `mime_type`,
`size_bytes`, `sha256`, `scan_status (pending|clean|infected|error)`, `scan_provider_ref`,
`uploaded_at`, `purged_at?`.

### ScopeProposal
`proposal_id PK`, `intake_id FK`, `version`, `assumptions`, `exclusions`,
`estimated_hours_band`, `price_cap_minor`, `status (draft|shared|negotiated|superseded|converted)`,
`pm_actor_id`, `created_at`.

## 4. Contracting & billing domain (billing ledger — authoritative for client money)

### Tenant
`tenant_id PK`, `display_name`, `status (active|suspended|delinquent|canceled|expired)`,
`plan_id FK`, `contract_ids []`, `created_at`.

### Contract
`contract_id PK`, `tenant_id FK`, `template_id FK`, `template_version`, `esign_envelope_id`,
`esign_status`, `signed_document_ref`, `rate_minor (2500 default = USD 25.00/hour)`,
`currency`, `effective_from`, `term_months (12)`, `state` — see
[state-machines.md §1](state-machines.md), `created_at`.

### ContractTemplate
`template_id PK`, `version`, `legal_review_status (draft|in_review|approved|retired)`,
`reviewer_human_id`, `approved_at`, `document_ref`. Only `approved` versions are renderable.

### BillingAuthorization
`auth_id PK`, `tenant_id FK`, `stripe_customer_id`, `stripe_payment_method_id`,
`mandate_ref`, `scope (hourly_25 | change_orders | deposits | subscription_renewal)`,
`caps jsonb`, `state (requested|active|revoked|expired)`, `authorized_at`, `expires_at?`.
INV-1 depends on this table.

### PlanVersion
`plan_version_id PK`, `name`, `features jsonb`, `sla jsonb`, `included_hours_monthly int`,
`credits jsonb`, `maintenance_term_months int`, `approval_limits jsonb`, `spend_limit_minor`,
`effective_from`, `retired_at?`.

### EntitlementSnapshot
`snapshot_id PK`, `tenant_id FK`, `contract_id FK`, `plan_version_id FK`,
`frozen_json jsonb` (full copy of effective terms), `captured_at`, `reason`
(intake of ticket/change order/invoice/release). Immutable (ADR-0012).

### TimeEntry
`entry_id PK`, `tenant_id FK`, `ticket_id FK?`, `project_task_ref`, `actor_type
(agent:<id> | human:<id>)`, `idempotency_key UNIQUE`, `started_at`, `ended_at`,
`minutes int` (rounded to minimum billable increment per OD-BILL-5 at invoice time),
`classification (billable|included|non_billable)`, `verified_status
(unverified|verified|disputed)`, `verified_by_human_id?`, `created_at`.
Append-only; corrections via reversing entries referencing `entry_id`.

### ChangeOrder
`change_order_id PK`, `tenant_id FK`, `ticket_id FK?`, `scope_text`, `estimated_hours`,
`estimate_minor`, `cap_minor`, `state (draft|sent|approved|declined|expired|superseded)`,
`customer_approval_id FK?`, `created_at`.

### ApprovalRecord
`approval_id PK`, `tenant_id FK`, `kind (acceptance | release_cutover | time_verification |
change_order | estimate_overage | refund | suspension_lift | emergency_stop_change)`,
`subject_refs jsonb`, `human_identity`, `decision (approved|rejected)`, `decided_at`,
`evidence_refs jsonb`, `signature_or_auth_ref`. Append-only.

### Invoice
`invoice_id PK`, `tenant_id FK`, `number UNIQUE`, `period_start`, `period_end`,
`line_items jsonb` (each: entry refs, description, hours/minutes, rate, amount),
`subtotal_minor`, `tax_minor` (per OD-TAX-1), `total_minor`, `currency`,
`state` — see [state-machines.md §2](state-machines.md),
`issued_at`, `due_at`, `dispute_window_ends_at`.

### PaymentEvent
`payment_event_id PK`, `invoice_id FK`, `provider_event_id UNIQUE` (Stripe event id —
idempotency anchor), `type`, `amount_minor`, `currency`, `verified_signature bool`,
`reconciled_api_status`, `occurred_at`, `recorded_at`. Append-only.

### CreditNote / RefundRecord
`note_id PK`, `tenant_id FK`, `invoice_id FK?`, `reason_code`, `amount_minor`,
`approval_id FK`, `provider_ref`, `created_at`.

**Billing ledger write boundary:** only billing-domain services hold credentials to write any
table in this section.

## 5. Support-ticket domain

### Ticket
`ticket_id PK`, `tenant_id FK`, `external_ref UNIQUE` (human-readable ID), `submitted_by_user_id FK`,
`category_input`, `impact_input`, `desired_outcome`, `attachment_ids []`,
`state` — see [state-machines.md §3](state-machines.md),
`priority`, `risk_level (low|medium|high)`, `sla jsonb` (from snapshot),
`policy_version`, `created_at`, `closed_at?`.

### TicketSnapshotLink
`ticket_id FK`, `snapshot_id FK` — every decision references the exact entitlement snapshot used.

### TicketDecision
`decision_id PK`, `ticket_id FK`, `stage (validation|classification|entitlement|triage)`,
`result`, `reason_code`, `rule_refs []`, `policy_version`, `inputs_hash`, `decided_at`.
Append-only.

### TicketWorkLink
`work_link_id PK`, `ticket_id FK`, `kind (issue|branch|pull_request|workflow_run)`,
`external_system`, `external_id`, `idempotency_key UNIQUE`, `created_at`.

### ClientUser
`user_id PK`, `tenant_id FK`, `identity_subject UNIQUE`, `role (owner|member|viewer)`,
`mfa_enabled bool`, `created_at`. Authentication via platform IdP; no local passwords unless
OD-AUTH-1 decides otherwise.

### DashboardViewLog
`view_log_id PK`, `tenant_id FK`, `user_id FK`, `resource`, `purpose`, `at`. Supports
"no secrets/internal detail exposure" reviewability requirement.

## 6. Commission domain (separate commission ledger store)

Physically separate database/service from §4 (ADR-0003). Owns:

### CommissionAgreement
`agreement_id PK`, `affiliate_id FK`, `trigger_rule_version`, `rate_or_amount jsonb`,
`currency`, `effective_from`, `retired_at?`, `approved_by_human_id`.
Trigger rules reference only published settlement facts.

### SettlementFact (ingested, one-way)
`fact_id PK`, `source (billing_pubsub)`, `invoice_number`, `amount_paid_minor`,
`currency`, `paid_at`, `dedup_key UNIQUE (= provider event id or invoice+payment pair)`.
Contains no client PII beyond invoice number.

### CommissionAccrual
`accrual_id PK`, `settlement_fact_id FK`, `agreement_id FK`, `computed_amount_minor`,
`state (pending|approved|payable|paid|reversed|withheld)` — withheld covers refund/chargeback
holds per OD-PAY-1, `computed_at`, `approval_id?` (commission-side human approval before payout).

### PayoutBatch / PayoutItem
`batch_id PK`, `period`, `state (open|approved|submitted|paid|failed)`,
`item_id PK`, `batch_id FK`, `accrual_id FK`, `amount_minor`, `provider_ref`, `attempts int`.

**Write-path separation:** billing services publish settlement facts to a queue the commission
service consumes; commission services hold no credentials against billing tables; billing
services hold none against commission tables. No shared service account exists. Reconciliation
jobs compare aggregates only.

## 7. Release & maintenance domain

### Release
`release_id PK`, `tenant_id FK`, `environment (staging|production)`, `artifact_ref`,
`preconditions jsonb` (acceptance id, invoice id, payment_event id, approval ids),
`gate_evaluations jsonb`, `deployed_by_human_id?`, `deployed_at?`, `rolled_back_at?`.

### MaintenanceHistory
`maintenance_id PK`, `tenant_id FK`, `kind (patch|backup_restore|monitoring_action|
certificate|platform_update)`, `ticket_id FK?`, `summary`, `performed_by (agent|human)`
+ actor id, `started_at`, `finished_at`, `evidence_refs jsonb`.

### BackupRecord
`backup_id PK`, `tenant_id FK`, `kind (site|data)`, `storage_ref`, `created_at`,
`verified_restore_at?`, `retention_until`. Per SLA terms in plan snapshot.

### MonitoringIncident
`incident_id PK`, `tenant_id FK`, `opened_at`, `detected_by (monitoring|human|client_ticket)`,
`severity`, `linked_ticket_id FK?`, `mitigated_at?`, `resolved_at?`, `postmortem_ref?`.

## 8. Cross-cutting records

### AuditLog
`audit_id PK`, `tenant_id FK?` (platform-level events may be null-tenant), `actor_type`,
`actor_id`, `action`, `resource`, `input_hash`, `outcome`, `reason_code?`,
`policy_version?`, `occurred_at`. Append-only, queryable, retained per
[failure-retry.md §4](failure-retry.md).

### WorkflowRun
`run_id PK`, `tenant_id FK?`, `kind`, `idempotency_key UNIQUE`, `state
(pending|running|awaiting_human|completed|failed|canceled)`, `checkpoint jsonb`,
`updated_at`. Durable state for ADR-0006 resumability.

### EmergencyStop
`stop_id PK`, `scope (charges|orchestration|deploys|esign)`, `active bool`, `activated_by_human_id`,
`activated_at`, `deactivated_by_human_id?`, `deactivated_at?`, `reason`.

### OutboxEvent
`event_id PK`, `aggregate`, `aggregate_id`, `type`, `payload jsonb`, `published_at?`,
`attempts int`. Transactional outbox for cross-service publication (billing → commission).

## 9. Relationship sketch

```text
Affiliate ──< ReferralClick >── AttributionSession ──< Prospect ──< ProspectIntake
ProspectIntake ──< IntakeUpload ; ProspectIntake ──< ScopeProposal ──> Contract
Tenant ──< Contract >── ContractTemplate ; Tenant ──< BillingAuthorization
Tenant ──< Ticket ──< TicketDecision >── EntitlementSnapshot >── Contract + PlanVersion
Ticket ──< TimeEntry ; Ticket ──< ChangeOrder ; Ticket ──< TicketWorkLink
TimeEntry ──< InvoiceLineItem (inside Invoice jsonb) ; Invoice ──< PaymentEvent
Invoice/PaymentEvent ─(outbox: minimal facts)→ SettlementFact ──< CommissionAccrual ──< PayoutItem
Tenant ──< Release ──< MaintenanceHistory ; Tenant ──< MonitoringIncident
Everything ──< AuditLog ; Automation ──< WorkflowRun ; Platform ──< EmergencyStop
```

## 10. Retention summary pointers

Deletion/retention rules per field class are specified in
[failure-retry.md §4](failure-retry.md); this model marks purgeable fields (`purged_at`,
`retention_until`) so enforcement is mechanical.
