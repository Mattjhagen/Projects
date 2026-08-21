# State Machines

Status: Proposed (Phase 0). Three machines: contract/order lifecycle, invoice/payment
lifecycle, and the ticket lifecycle. Transitions are event-driven; every transition writes an
`AuditLog` record and, where financial entitlement is involved, references an
`EntitlementSnapshot`.

## 1. Contract / order lifecycle

Covers a client engagement from proposal to closed maintenance term.

```text
drafting ──(template approved + rendered)──> for_legal_review
for_legal_review ──(qualified human legal approval)──> ready_to_sign
for_legal_review ──(revision requested)─────────────> drafting
ready_to_sign ──(client e-signature completed, envelope verified)──> signed
signed ──(payment authorization active: mandate + method verified)──> active
```

- `drafting`: template render only from `ContractTemplate` with
  `legal_review_status = approved`; agents may prepare drafts; humans approve language.
- `ready_to_sign`: e-sign envelope may be sent (kill-switch `esign` permitting).
- `signed`: signature evidence stored (`esign_envelope_id`, status, timestamps). No work yet.
- `active`: **consent gate open.** T310 planning and any chargeable work become possible.
- From `active`:

```text
active ──(nonpayment → grace elapsed per OD-PAY-2)──> delinquent
active ──(manual suspension or abuse hold)──────────> suspended
active ──(12-month term ends without renewal)───────> expired
delinquent/suspended/expired/canceled ──(human decision / settlement / reinstatement)──> active | canceled
active|delinquent|suspended ──(mutual termination or human cancellation)──> canceled
canceled ──(retention/export duties per contract)──> archived
expired ──(renewal executed before/after lapse per OD-REN-1)──> active (new term)
```

Rules:

- `archived` retains only records required by retention policy; hosting ceases after data
  export window ([plan-lifecycle.md](plan-lifecycle.md)).
- Entering `delinquent`, `suspended`, `canceled`, or `expired` triggers plan-state propagation
  to all open tickets via [plan-lifecycle.md §3](plan-lifecycle.md).
- Reinstatement from `delinquent` requires confirmed payment; from `suspended` requires an
  explicit human `ApprovalRecord`.

## 2. Invoice / payment lifecycle

```text
draft ──(all time entries verified; line items locked)──> issued
issued ──(delivered per cadence OD-BILL-2)──> sent
sent ──(customer dispute within window)──> disputed
disputed ──(resolution: adjust via credit note/reversal, human-approved)──> sent | void
sent ──(signature-verified webhook + API reconciliation)──> paid
sent ──(due date passed)──> overdue
overdue ──(grace elapsed per OD-PAY-2)──> delinquent_account   [tenant-level flag]
paid ──(refund/chargeback per OD-PAY-1, human-approved)──> reversed
void ── terminal ; reversed ── terminal ; delinquent_account ──(payment)──> paid
```

Rules:

- An invoice may be issued only from `verified` time entries (`verified_status = verified`,
  human-verified per ADR-0005); estimates never convert directly into invoices.
- `paid` requires provider event id dedup + out-of-band API re-check of invoice state
  (ADR-0008), making it safe for the release gate to consume.
- Release cutover consumes `state ∈ {paid}` plus acceptance plus human approval.

## 3. Ticket lifecycle

Exactly the required chain (#14 acceptance criterion 3; #13 DECISION):

```text
submitted → validated → classified → entitled
                                   → approval-required
                                   → blocked
entitled → planned → in-development → security-review → human-release-approval
        → released → monitoring → closed
```

Full transition table:

| # | From | Event/Guard | To |
| --- | --- | --- | --- |
| T1 | — | Authenticated client submits ticket (category, impact, desired outcome, attachments) | `submitted` |
| T2 | submitted | Schema complete, tenant resolvable, snapshot captured, rate/duplicate checks pass | `validated` |
| T3 | submitted | Malformed input, spam/duplicate detected, or tenant unresolvable | `closed` (reason: rejected) |
| T4 | validated | Deterministic classifier (ADR-0004) assigns category, priority, risk | `classified` |
| T5 | classified | Entitlement = included ∧ risk low | `entitled` |
| T6 | classified | Entitlement = billable/out-of-plan/over-allowance/medium-risk; scope+estimate written | `approval-required` |
| T7 | classified | Ambiguous, high-risk, security incident needing human triage, or plan blocks category | `blocked` |
| T8 | approval-required | Customer/human approves scope & estimate (or change order countersigned) | `entitled` |
| T9 | approval-required | Customer declines or offer expires | `closed` (reason: declined/expired) |
| T10 | blocked | Human triage resolves ambiguity/risk or emergency exception granted | `entitled` |
| T11 | blocked | No path forward (out of service, canceled account) | `closed` (reason: not-actionable) |
| T12 | entitled | PM agent produces plan (tasks, estimates, risk) | `planned` |
| T13 | planned | Dev agent completes implementation in isolated environment; PR opened | `in-development` |
| T14 | in-development | R410 security/bug review verdict clean | `security-review` (passed → advance) |

Note on T14/T15 naming: `security-review` is itself the state in which review executes;
transition out occurs on verdict.

| # | From | Event/Guard | To |
| --- | --- | --- | --- |
| T15 | security-review | Verdict clean (commit status successful) | `human-release-approval` |
| T16 | security-review | Blocking finding | `in-development` (remediation loop) |
| T17 | human-release-approval | Explicit human approval recorded (`ApprovalRecord`) | `released` |
| T18 | human-release-approval | Human rejects or requests changes | `in-development` |
| T19 | released | Post-release checks run (monitoring green, smoke tests) | `monitoring` |
| T20 | monitoring | Observation window passes with no regression | `closed` (reason: resolved) |
| T21 | monitoring | Regression/customer reopen within window | `in-development` (linked follow-up) |
| T22 | any ≥ planned | Tenant enters suspended/delinquent/canceled/expired and work class is blockable | pause at current state → `blocked` (resumable) |
| T23 | blocked (lifecycle-paused) | Tenant returns active; entitlement re-evaluated against fresh snapshot | prior state |
| T24 | any | Security incident/outage override | expedited triage path (see below) |

Special paths:

- **Expedited security/outage path:** `classified` with category = security issue or incident
  severity high triggers immediate human notification. Agents may diagnose/prep fixes but take
  no destructive or irreversible production action; the machine still traverses
  `human-release-approval` before anything touches production.
- **Always-reportable:** incidents and security reports remain submittable (T1–T4 always run)
  even when ordinary feature work is lifecycle-blocked ([plan-lifecycle.md §3](plan-lifecycle.md)).

State legality: no transitions exist other than the table above (e.g., `submitted` cannot jump
to `planned`; `released` cannot occur without passing `human-release-approval`). The Phase 0
acceptance test suite must verify exactly this graph.

## 4. Machine-readable summary (ticket)

States (ordered): `submitted`, `validated`, `classified`, `entitled`, `approval-required`,
`blocked`, `planned`, `in-development`, `security-review`, `human-release-approval`,
`released`, `monitoring`, `closed`.

Terminal: `closed`. All other states reachable into `closed` only through legal transitions.
