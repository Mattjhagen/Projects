# Phase 0 — Affiliate-to-Managed-Website Delivery Platform (Design Only)

Phase 0 is a documentation-only deliverable for issue #14 under parent #13. It defines the
architecture, data model, state machines, threat model, backlog, and open decisions for a
commercial workflow in which:

1. An affiliate publishes an advertisement with a tracked referral link.
2. A prospective client follows it and completes a plain-language website intake
   (business goals, desired pages/features, visual preferences, colors, branding,
   assets/uploads, examples, target audience, UI/UX expectations).
3. The client reviews the resulting scope, signs an approved contract, and authorizes billing
   at USD 25/hour under defined estimates, caps, and change-order rules.
4. Only after required consent and payment authorization may T310 plan the project, R510
   implement it in an isolated client repository/environment, and R410 run security, privacy,
   dependency, correctness, regression, accessibility, and bug review.
5. The client receives a staging preview and acceptance step.
6. A final itemized invoice is issued from verified time records; release/production cutover
   occurs only after a confirmed payment webhook plus explicit human approval.
7. The delivered site remains under a 12-month hosting and maintenance agreement with defined
   SLA, backups, monitoring, patching, support scope, change requests, suspension, renewal,
   termination, domain ownership, source-code ownership, and data export terms.
8. Affiliate attribution/commission handling exists without mixing client billing and
   affiliate payout ledgers.

**Nothing in Phase 0 implements charging, contract signing, deployment, or production change.**
Contracts and templates require qualified human legal review. Agents never sign, accept terms,
approve time, charge a payment method, merge, release, or deploy.

## Document map

| Deliverable group (#14) | Document |
| --- | --- |
| 1. ADRs / system design | [adr.md](adr.md), [system-design.md](system-design.md) |
| 2. Data model (tenant isolation; separated ledgers) | [data-model.md](data-model.md) |
| 3. State machines (contract/order + ticket) | [state-machines.md](state-machines.md) |
| 4. Support-ticket subsystem | [support-tickets.md](support-tickets.md) |
| 5. Durable-record specification | [durable-records.md](durable-records.md) |
| 6. Threat model + audit requirements | [threat-model.md](threat-model.md) |
| 7. Failure/retry, disputes, retention, accessibility | [failure-retry.md](failure-retry.md) |
| 8. Plan lifecycle rules | [plan-lifecycle.md](plan-lifecycle.md) |
| 9. Legal-review checklist | [legal-review-checklist.md](legal-review-checklist.md) |
| 10. Phased backlog + acceptance criteria | [backlog.md](backlog.md) |
| 11. Open-decision register | [open-decisions.md](open-decisions.md) |

## References

- Parent scope: Mattjhagen/Projects issue #13, including its `[supervisor-codex]` DECISION comment.
- Development task: Mattjhagen/Projects issue #14.
- Coordination rules: [../AUTOMATED_WORKFLOW.md](../AUTOMATED_WORKFLOW.md),
  [../MESSAGE_PROTOCOL.md](../MESSAGE_PROTOCOL.md).
