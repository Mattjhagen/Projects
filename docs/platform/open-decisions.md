# Open-Decision Register

Status: Proposed (Phase 0). Every item is an open **QUESTION for the human owner**. Owner =
human. "Proposed default" values are engineering placeholders to make the design concrete;
**they are non-authoritative and must not be treated as decided** until the human owner
records a DECISION. Nothing in this register authorizes implementation.

Format per item: ID, question, why it matters, proposed default (non-authoritative), impact
of delay.

| ID | Decision (from #13) | Question for owner | Why it matters | Proposed default — NON-AUTHORITATIVE | Impact of remaining open |
| --- | --- | --- | --- | --- | --- |
| OD-JUR-1 | Jurisdiction | Which governing law/jurisdiction applies to client contracts, affiliate agreements, and platform ToS? | Drives contract clauses, tax treatment, dispute venue, data-protection regime | Single home jurisdiction of the business owner; US-style governing-law clause | Template legal review blocked; Phase C cannot finalize |
| OD-ESIGN-1 | Contract template & e-sign provider | Which base contract template source and which e-sign provider? | Determines integration work, audit-trail features, cost, enforceability | Use counsel-drafted template; mainstream e-sign API with full audit trail | Phase C design remains provider-agnostic stub |
| OD-BILL-2 | Invoice cadence | How often are invoices issued (weekly, biweekly, monthly; milestone-based)? | Cash flow, dispute-window sizing, delinquency triggers | Monthly arrears from verified time entries | Invoicing scheduler parameterized but unverified |
| OD-BILL-3 | Estimate & overage approval flow | Must overage approval be written/e-signed, dashboard-click, or email confirmation? What threshold triggers re-approval? | Prevents billing disputes; INV-1 depends on it | Written approval captured as ApprovalRecord in dashboard before overage work begins | Engine falls back to strictest option: always require dashboard approval |
| OD-DEP-1 | Deposit policy | Deposit percentage/amount before project start? Refundable under what conditions? | Up-front risk mitigation vs sales friction | 25% deposit at signing, applied to first invoice; non-refundable only after work begins per change record | Phase C cannot finalize mandate scope |
| OD-BILL-5 | Minimum billable increment | Smallest billable unit (e.g., 15 minutes)? Rounding direction? | Time-entry math, invoice fairness | 15-minute increments, rounded up within a task, capped per day | Invoice line-item logic stays configurable |
| OD-HOST-1 | Hosting infrastructure | Provider/region/topology for delivered sites and platform services (incl. object storage, DB)? | Cost, SLA feasibility, data residency (ties to OD-JUR-1/OD-TAX-1) | Single major cloud, per-tenant isolation primitives, region co-located with jurisdiction choice | Phase F architecture stays abstract |
| OD-SLA-1 | SLA levels | Uptime target, response/resolution times per severity, service credits? | Contract clause + monitoring thresholds + support staffing | 99.9% monthly uptime; response P1 1h / P2 4h / P3 1bd; credits tiered | Monitoring alert thresholds provisional |
| OD-SLA-2 | Support hours | Business hours/timezone; weekend/holiday coverage; emergency channel? | Staffing and expedited-path expectations | Mon–Fri business hours one timezone; P1 paging 24/7 | Dashboard messaging shows provisional hours |
| OD-AFF-1 | Affiliate commission trigger | Commission on lead, signed contract, initial deposit, or paid revenue share? Rate? Attribution window? Clawback period? | Core commission-ledger computation (ADR-0003) | Last-touch 30-day window; commission on collected payments only; 60-day clawback | Accrual engine ships with rule versioning but disabled |
| OD-PAY-1 | Refund & chargeback handling | Refund policy; contest-vs-settle stance for chargebacks; who approves refunds? | Financial controls; commission withholding behavior | Human-approved refunds; contest chargebacks with evidence pack; withhold commissions during dispute | Dispute workflow defaults to manual-only |
| OD-TAX-1 | Taxes | Sales/VAT/GST obligations, who is merchant of record, invoice tax lines? | Invoice legality, Stripe tax config | Owner consults accountant; platform renders tax-inclusive totals once rules provided | Tax fields remain zero-pending-human |
| OD-PAY-2 | Final payment / renewal failure behavior | Grace periods, cure deadlines, suspension timing, data-export window length on failure-to-pay or failed renewal? | Drives state machines §1–2 and plan lifecycle §5 | 14-day grace; 60-day to cancellation; 30-day export window | Defaults used only as design placeholders |

Also carried forward from #14 objective (same owner=human rule): none beyond the table above —
all twelve #13 decision areas are covered by OD-JUR-1, OD-ESIGN-1, OD-BILL-2, OD-BILL-3,
OD-DEP-1, OD-BILL-5, OD-HOST-1, OD-SLA-1, OD-SLA-2, OD-AFF-1, OD-PAY-1, OD-TAX-1, plus
failure-behavior OD-PAY-2.

## Process

- T310 may consolidate answers into DECISION comments on #13/#14; only the human owner's word
  decides.
- Any agent discovering a new blocking unknown must add it here as a QUESTION rather than
  choosing silently.
