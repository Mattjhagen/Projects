# System Design — Affiliate-to-Managed-Website Delivery Platform

Status: Proposed (Phase 0, design only). Target implementation surface: `Mattjhagen/purepulse-admin`
and related services. No production changes are authorized by this document.

## 1. Context and goals

The platform converts affiliate-sourced prospects into managed website clients served by an
agent pipeline (PM → developer → security review) under human authority, then keeps each
delivered site running under a 12-month hosting and maintenance agreement.

Goals:

- Traceable lead-to-cash lifecycle: every artifact links to its upstream cause.
- Human-only irreversible actions: legal signature, payment charge approval, merge, release,
  deploy. Agents prepare and propose; humans decide.
- Tenant isolation by construction: all data partitioned by tenant from day one.
- Ledger separation: client billing and affiliate commissions are separate stores with no
  shared write path.
- Auditable agent work: every automated action is recorded, attributable, idempotent, and
  resumable.

Non-goals (this phase): any charging, signing, deploying, or infrastructure change.

## 2. Subsystems

```text
+------------------+     +---------------------+     +----------------------+
| Attribution &    | --> | Intake & Scoping    | --> | Contracting &        |
| Affiliate Portal |     | (prospect portal)   |     | Billing Authorization|
+------------------+     +---------------------+     +----------------------+
                                                            |
                        consent + payment-authorization gate (hard stop)
                                                            v
+------------------+     +---------------------+     +----------------------+
| Delivery         | <-- | Agent Orchestration | <-- | Project Planning     |
| Environments     |     | (T310/R510/R410)    |     | (T310)               |
| (isolated per    |     +---------------------+     +----------------------+
|  tenant repo/env)            |
|                              v
|                    +---------------------+     +----------------------+
|                    | Staging Preview &   | --> | Invoicing from       |
|                    | Client Acceptance   |     | verified time records|
|                    +---------------------+     +----------+-----------+
|                                                           | confirmed payment webhook
|                                                           | + explicit human approval
+--> Release/Cutover Gate <-------------------------------- +
        |
        v
+------------------+     +---------------------+     +----------------------+
| Managed Hosting  | <-> | Support Tickets     | <-> | Maintenance & Renewal|
| & Monitoring     |     | (client dashboard)  |     | (12-month term)      |
+------------------+     +---------------------+     +----------------------+

Side ledger (separate store, no shared write path):
+-------------------------------+
| Affiliate Commission Ledger   |
+-------------------------------+
```

### 2.1 Attribution & affiliate portal

- Affiliates register, receive tracked referral links (`?ref=affiliate-code` plus signed
  click token; see threat model for replay limits).
- First-touch/last-touch policy is configurable; default is last non-direct click within a
  30-day attribution window (non-authoritative default pending decision OD-AFF-1 in
  [open-decisions.md](open-decisions.md)).
- Clicks land on the public marketing site and create a `ReferralClick` record; the prospect
  session carries an opaque attribution token into intake.

### 2.2 Intake & scoping

- Plain-language multi-step form: business goals, desired pages/features, visual preferences,
  colors, branding, asset uploads, examples/references, target audience, UI/UX expectations.
- Uploads go directly to private object storage via short-lived presigned URLs, are scanned
  before any processing, and are never executed or auto-published.
- Output: structured `ProspectIntake` plus a draft `ScopeProposal` generated for human PM
  review; the proposal lists assumptions, exclusions, estimated hours bands, and price caps.

### 2.3 Contracting & billing authorization

- Approved contract template rendered per client; **qualified human legal review required**
  before any template version becomes usable ([legal-review-checklist.md](legal-review-checklist.md)).
- E-signature integration is least-privilege and records evidence (envelope ID, status,
  signer identity claims, timestamps) but the platform itself performs no signing.
- Payment authorization: Stripe customer + saved payment method + explicit mandate covering
  USD 25/hour, estimate bands, caps, deposit policy, minimum billable increment, invoice
  cadence, and change-order rules (defaults proposed in open-decisions.md; none authoritative
  until the human owner decides).
- Hard gate: no planning ticket may enter `planned`, and no agent work may be scheduled, until
  both `contract.signed` and `payment_authorized` exist as durable, verified records.

### 2.4 Delivery environments

- One isolated repository/environment per client (naming convention defined in backlog Phase B;
  no repositories are created in Phase 0).
- Staging preview URL protected by authentication; client acceptance is an explicit recorded
  action, not implicit by timeout.
- Production cutover requires: (a) accepted staging preview, (b) final itemized invoice issued
  from verified time records, (c) confirmed payment webhook (signature-verified, idempotent),
  and (d) explicit human approval captured as an `ApprovalRecord`. All four are checked
  server-side at the gate.

### 2.5 Agent orchestration (T310 / R510 / R410)

- T310 produces a plan (issues/tasks with estimates and risk levels) only after the consent
  gate opens; plans reference contract version and entitlement snapshot IDs.
- R510 works exclusively inside the isolated client repository/environment; work items carry
  idempotency keys so retries cannot duplicate branches, issues, PRs, or time entries.
- R410 reviews security, privacy, dependency hygiene, correctness, regression, accessibility,
  and bugs; findings block release until dispositioned.
- Human merge/deploy/release always required. Agents never hold those credentials.

### 2.6 Managed hosting, support tickets, maintenance

- Delivered sites run on hosting selected per open-decision OD-HOST-1 (default proposal:
  single cloud provider with per-tenant isolation primitives; non-authoritative).
- Clients submit tickets through an authenticated dashboard; classification and entitlement
  are deterministic and server-side ([support-tickets.md](support-tickets.md)).
- Maintenance obligations run on a 12-month term from cutover with renewal behavior governed
  by [plan-lifecycle.md](plan-lifecycle.md).

## 3. Cross-cutting design rules

1. **Server-side authority**: plan versions, prices, entitlements, SLAs, and approvals are
   resolved server-side per request; browsers never assert them.
2. **Immutable financial facts**: time entries, invoices, payments, commission events, and
   audit logs are append-only; corrections are reversing entries, never edits.
3. **Idempotency everywhere automation acts**: every agent/integration write carries a
   deterministic idempotency key scoped to `(tenant_id, workflow_run_id, step)` 
   ([failure-retry.md](failure-retry.md)).
4. **Least privilege**: Stripe restricted keys limited to required scopes; e-sign API key
   limited to send/view envelope status; object storage access via short-lived credentials;
   agents get per-client scoped tokens that expire.
5. **Secrets isolation**: platform secrets live in the platform's secret manager; client
   environment secrets live per-environment; agents receive values only when a task explicitly
   requires them and never through prompts or tickets.
6. **Staging/production separation**: separate credentials, data stores, domains, and
   deployment targets; no production data copies into staging without documented masking.
7. **Manual emergency stops**: kill switches can pause agent orchestration, outbound charges,
   deployments, and e-sign sends independently; activation is audited and reversible only by
   a second human action.
8. **Accessibility**: WCAG 2.2 AA is the target for client-facing portals and delivered sites
   ([failure-retry.md §5](failure-retry.md)).

## 4. Lifecycle summary (end-to-end)

1. Affiliate publishes ad → prospect clicks tracked link → `ReferralClick` + attribution
   session created.
2. Prospect submits intake (+ scanned uploads) → `ProspectIntake`.
3. PM reviews, drafts `ScopeProposal` → prospect views plain-language scope.
4. Client signs approved contract (e-sign) → `Contract` state advances.
5. Client authorizes payment (mandate + saved method) → `BillingAuthorization` active.
6. Consent gate satisfied → T310 plan → R510 implementation in isolated env → R410 review.
7. Staging preview → client acceptance recorded.
8. Verified time entries roll up to itemized invoice → sent per cadence.
9. Payment webhook confirmed (verified + idempotent) → human approves cutover → release.
10. 12-month maintenance term begins → tickets flow through the support pipeline → renewal,
    suspension, termination per plan lifecycle.

## 5. Key invariants

- INV-1 No charge occurs without an effective `BillingAuthorization` and a matching approval
  rule (mandate, cap, or change order).
- INV-2 No release/cutover without acceptance + invoice issued + confirmed payment webhook +
  explicit human `ApprovalRecord`.
- INV-3 No cross-ledger writes: billing services cannot write commission rows; commission
  services cannot read billing PII beyond what settlement minimally requires (see
  [data-model.md §6](data-model.md)).
- INV-4 Every tenant-scoped query filters by `tenant_id` enforced at the storage/policy layer,
  not only in application code.
- INV-5 Every automatic transition has an audit record containing actor, reason, and inputs
  (including snapshot IDs).
