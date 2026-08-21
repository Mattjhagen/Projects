# Legal-Review Checklist

Status: Proposed (Phase 0). Governing rule: **contracts and templates require qualified human
legal review; agents never sign contracts, accept terms, approve time, charge a payment
method, merge, release, or deploy.** This checklist is a design artifact, not legal advice.

## 1. Gate: template lifecycle

- [ ] Contract template drafted by/with qualified human legal counsel.
- [ ] Template version recorded in `ContractTemplate` with `legal_review_status` and named
      human reviewer.
- [ ] Only `approved` template versions are renderable by the platform (enforced server-side).
- [ ] Material changes produce a new version requiring fresh review; no in-place edits.
- [ ] Jurisdiction/governing-law clause matches OD-JUR-1 decision once made.

## 2. Required contract clauses (review targets)

- [ ] Scope description derived from approved ScopeProposal; exclusions explicit.
- [ ] Rate USD 25/hour; estimate bands and caps; change-order procedure with customer approval.
- [ ] Deposit policy (OD-DEP-1) and refund terms (OD-PAY-1).
- [ ] Minimum billable increment (OD-BILL-5) disclosed.
- [ ] Invoice cadence (OD-BILL-2), dispute window, late-payment consequences (OD-PAY-2).
- [ ] Taxes responsibility allocation (OD-TAX-1).
- [ ] Client consent to automated agent development pipeline with human gates (merge/deploy/
      release by humans only) described plainly.
- [ ] Acceptance process and deemed-acceptance absence (no silent acceptance).
- [ ] 12-month hosting/maintenance term: SLA (OD-SLA-1), support hours (OD-SLA-2), backups,
      monitoring, patching, response targets, suspension/renewal/termination mechanics.
- [ ] Domain ownership/transfer; source-code ownership on full payment; license residuals.
- [ ] Data export format/window; deletion/retention summary.
- [ ] Affiliate relationship disclosure to client where required (no client-side commission
      obligations — commissions are platform-affiliate only).
- [ ] Liability caps, warranties, confidentiality, data protection/privacy terms consistent
      with jurisdiction decision.
- [ ] Emergency stop / service suspension rights and notice periods.

## 3. Payment authorization artifacts

- [ ] Stripe mandate text reviewed: scope covers hourly work, change orders, deposits,
      renewals exactly as contracted; nothing broader.
- [ ] Authorization UI presents amount rules verbatim from contract.
- [ ] Revocation path documented and functional.
- [ ] Agents cannot alter mandate text or scope — enforced structurally.

## 4. E-signature requirements

- [ ] Provider supports audit trail (signer identity, IP/time metadata per provider policy,
      document hash).
- [ ] Envelope templates locked after legal approval; field edits disabled post-approval.
- [ ] Completed documents stored immutable + hash-referenced from `Contract`.

## 5. Human-only actions register

The following actions are performed exclusively by authorized humans; the platform records
and enforces this:

| Action | Enforced by |
| --- | --- |
| Approve contract language | `ContractTemplate.legal_review_status = approved` gate |
| Sign contract | e-sign flow executed by client human; countersignature by owner human |
| Verify/approve time before invoicing | `ApprovalRecord(kind=time_verification)` required |
| Charge payment method | Billing worker checks mandate + cap + approval chain (INV-1); kill-switch honors charges |
| Merge PR / deploy / release cutover | Branch protection + release gate consume human `ApprovalRecord`; agent credentials lack permissions |
| Approve affiliate payouts | Commission-side human `approval_id` on accruals |
| Activate/deactivate emergency stops | ADR-0011 dual-human rule |

## 6. Prohibited automations (hard failures if attempted)

- Auto-signing or auto-countersigning any document.
- Auto-approving time entries into billable status without human verification.
- Charging outside mandate/caps/approvals.
- Self-service merge/deploy by agent identities.
- Payout execution without recorded human payout approval.
