# Plan Lifecycle Rules (Active / Suspended / Delinquent / Canceled / Expired)

Status: Proposed (Phase 0). Governs the 12-month hosting/maintenance obligation and how plan
state gates ticket work. Money states live in [state-machines.md §1–2](state-machines.md).

## 1. Plan states and entry/exit

| State | Entry | Exit |
| --- | --- | --- |
| active | Contract active + payment authorization effective + no delinquency | Any other state per triggers below |
| suspended | Manual suspension (abuse hold, risk, client request) or emergency stop on account | Human approval reinstates → active, or escalation to canceled |
| delinquent | Invoice overdue past grace (OD-PAY-2 default: 14 days) | Confirmed payment → active; prolonged delinquency (OD-PAY-2 default: 60 days) → canceled-or-suspended by human decision |
| canceled | Mutual termination, human cancellation, nonpayment threshold, or client closure | Terminal for service; retention/export duties continue |
| expired | 12-month term ends without renewal execution | Renewal executed → active (new term); else → canceled path with data-export window |

Renewal mechanics (OD-REN-1 defaults): renewal offer at day −30; auto-renew only if the
contract explicitly says so AND a valid billing authorization exists; otherwise manual.
Lapse handling in §4.

## 2. What each state permits

| Capability | active | suspended | delinquent | canceled | expired |
| --- | --- | --- | --- | --- | --- |
| Submit tickets (any class) | yes | yes (security/incidents prioritized) | yes | security reports only | security reports + incident reports during export window |
| Autonomous pipeline work (included) | yes | paused (T22/T23) | paused for billable/includable feature work; incidents/security proceed | blocked | blocked (except §3 carve-outs) |
| Billable/change-order work | yes | paused | paused until payment method restored | no | requires renewal/reactivation first |
| Charge attempts (mandated) | yes | no new charges | retry per policy; no new charges | no | renewal charge if authorized mandate exists |
| Hosting uptime obligation | full SLA | best-effort (no SLA credit accrual) | SLA continues through grace; then limited-mode hosting possible after notice | ends at cutover date per contract | ends at export window close |
| Backups & monitoring | full | backups continue; alerting continues; patching of security-critical items continues | full during grace | security patches only until final purge | same as canceled |
| Data export rights | yes | yes | yes | export window per contract (default 30 days post-cutover notice) | export window |

Security-critical patching never stops while any tenant data remains hosted — this is a
platform obligation independent of plan state.

## 3. Always-reportable carve-out

Incident and security-issue tickets are accepted and processed in **every** state, including
canceled/expired while data or hosting persists. Ordinary feature/content/new-feature work may
be blocked; safety work is not ([state-machines.md T24](state-machines.md), expedited path).
Agents may prepare fixes; humans approve any production action.

## 4. 12-month maintenance obligation

- Term starts at production cutover (`Release` deployed), recorded in
  `MaintenanceHistory` anchor row.
- Included monthly hours/credits come from `PlanVersion`; unused-hour policy is OD-BILL-6
  (default proposal: no rollover; non-authoritative).
- Obligations during term: security patches, platform updates, backups per SLA, monitoring,
  support scope per plan, content allowance per plan.
- Suspension/delinquency pauses included-work consumption but does not shorten the term;
  end date is fixed unless terminated early per contract.
- Near term-end: renewal flow (§1); failure to renew follows §5.

## 5. When final payment or renewal fails

Final payment fails (pre-cutover):

- Release gate stays shut (INV-2); no cutover without confirmed payment webhook + human
  approval. Staging preview may remain available read-only during grace.
- Retry policy per provider limits + human outreach task auto-created for PM.
- Default (OD-PAY-2): grace 14 days → engagement moves toward suspension/cancellation per
  human decision; work product retained per retention table until export window closes.

Renewal payment fails:

- Grace per OD-PAY-2; during grace, hosting continues in limited mode (no new work; security
  patching continues).
- After grace without cure: expired → canceled path; hosting ceases at export-window end;
  domain/DNS handover documented per contract terms ([plan-lifecycle.md §6](plan-lifecycle.md)).

## 6. Domain ownership, source-code ownership, data export (contract-required clauses)

- **Domain ownership**: registered to client or transferred to client control at/before
  cutover; platform holds technical management only under maintenance term; handover runbook
  required at termination.
- **Source-code ownership**: client owns delivered site source upon full payment; platform
  retains its internal tooling; delivery = repository transfer/archive per contract.
- **Data export**: machine-readable archive (site content + analytics owned by client +
  ticket history summary) available on request during term and export window; exports audited.
