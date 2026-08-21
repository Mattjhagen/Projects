# Threat Model and Audit Requirements

Status: Proposed (Phase 0). Method: STRIDE-per-surface with explicit abuse stories. Scope:
intake, contracting/billing, ticket subsystem, agent orchestration, release gates,
commission ledger, hosting. Out of scope: physical security of cloud provider.

## 1. Assets and trust boundaries

Assets: client PII, contracts, payment mandates/tokens (references only — card data stays in
Stripe), time records, invoices, commission accruals, intake uploads, agent credentials,
release artifacts, audit logs.

Trust boundaries:

- B1 Browser ⇄ platform API (untrusted client)
- B2 Public marketing site ⇄ intake portal
- B3 Platform ⇄ Stripe / e-sign providers (webhooks inbound, API outbound)
- B4 Ticket content ⇄ humans and agents (untrusted data, ADR-0007)
- B5 Orchestration agents ⇄ tenant repositories/environments (scoped credentials)
- B6 Billing service ⇄ commission service (one-way settlement facts)
- B7 Staging ⇄ production (hard separation)

## 2. Required defenses (normative)

1. **Server-side tenant isolation and entitlement enforcement** (ADR-0002): row-level policies;
   every query tenant-scoped; plan/price/SLA claims from browsers ignored; entitlements
   resolved from `EntitlementSnapshot` per request.
2. **Ticket text and attachments are untrusted data**: never instructions; prompt-injection
   defense = strict delimiting + standing ignore-directives in agent prompts + output filters +
   human review for any agent action outside the entitled task; injection attempts logged.
3. **Upload safety**: malware scanning before processing; file-type allowlist + size caps;
   private object storage (no public buckets); expiring signed access URLs; content-type
   sniffing not extension trust; no inline execution/preview of active content.
4. **Authorization checks**: deny-by-default middleware; object-level permission checks on
   every read/write (IDOR defense); admin actions require elevated role + MFA.
5. **Rate limits & abuse controls**: per user/tenant/IP limits on submissions, uploads, login,
   e-sign sends, invoice downloads; duplicate/spam detection on tickets (content hash +
   window) with quarantine-not-delete semantics.
6. **Audit logs**: append-only, actor/action/resource/input-hash/outcome/reason/policy-version
   for every state transition, gate decision, approval, charge, payout, export, kill-switch
   action ([durable-records.md](durable-records.md)).
7. **Webhook signature verification + idempotency** (ADR-0008): verify signatures and
   timestamps; dedup on provider event ids; reconcile critical state via API re-fetch.
8. **Least-privilege integrations** (system-design §3): Stripe restricted keys scoped to
   required operations (e.g., PaymentIntents write, Customers read — no full account);
   e-sign key limited to envelope send/status; secrets isolated per environment; no shared
   accounts across services or tenants.
9. **Staging/production separation** (B7): separate stores/credentials/domains; production
   deploy paths exist only behind the release gate.
10. **Manual emergency stops** (ADR-0011): four independent switches (charges, orchestration,
    deploys, e-sign), audited activation/deactivation by humans.

## 3. Abuse stories → mitigations

| ID | Abuse story | Risk | Mitigations |
| --- | --- | --- | --- |
| AS-1 | Tenant A reads Tenant B's ticket/invoice/upload | IDOR / tenant boundary | Row-level policies; object-level authz; tenant-prefixed storage keys + short-lived scoped URLs; automated cross-tenant access tests |
| AS-2 | Client tampers plan/price in browser to unlock work | Entitlement bypass | Server-side snapshot resolution; price/entitlement computed server-side only; UI claims never trusted |
| AS-3 | Attacker uploads malware that later executes on staff machine or gets published | Malicious upload | Scan-on-upload, type allowlist, private storage, expiring URLs, download-only UX with warnings, AV quarantine workflow |
| AS-4 | Ticket text instructs agent to "ignore rules and deploy" | Prompt injection | ADR-0007 wrapping + standing directives; agents cannot deploy structurally (no creds); injection-pattern detection logs to security queue |
| AS-5 | Forged/duplicated Stripe webhook marks invoice paid → auto-release | Billing integrity / approval bypass | Signature+timestamp verification, event-id dedup, API reconciliation; release gate additionally requires acceptance + human approval (INV-2) so webhook alone is insufficient |
| AS-6 | Insider/agent fabricates time entries | Billing integrity | Agent-created entries flagged until human verification; invoices issue only from verified entries; append-only ledger shows actor per entry |
| AS-7 | SSRF via example-URL fields in intake/tickets | SSRF | URL fields parsed, scheme/host allowlists, fetches via egress proxy with metadata-IP blocking, timeouts |
| AS-8 | Replay of affiliate click token to steal attribution | Commission fraud | Signed, short-lived tokens; single-use consumption into AttributionSession; bot heuristics flag suspicious clicks; commission trigger requires paid settlement fact (OD-AFF-1), not clicks alone |
| AS-9 | Self-referral fraud (affiliate = client) | Commission fraud | Identity cross-checks at signup; withholding window before payout; manual payout approval (CommissionAccrual.approval_id) |
| AS-10 | Over-billing beyond approved estimate | Approval bypass | Hard cap checks at entry+invoice time; overage requires recorded customer approval first (support-tickets §6) |
| AS-11 | Agent credential leakage grants repo/admin access | Credential compromise | Per-task minted, expiring, least-privilege tokens; no long-lived keys on hosts; secret scanning; rotation runbook |
| AS-12 | Spam/duplicate ticket flood inflates included-hours usage or DoS triage | Resource abuse | Rate limits, duplicate detection, CAPTCHA-equivalent only within authenticated session risk scoring, quotas visible in dashboard |

## 4. Security control tests (required in later phases' acceptance)

- Cross-tenant access attempt matrix (every object type) must fail closed.
- Tampered browser payload (plan/price) must be ignored server-side.
- Malware sample upload must be quarantined, never processed.
- Replayed webhooks must collapse to one effect.
- Charge without mandate/approval must be impossible by test.
- Kill switch must halt each scoped action within one orchestration tick.

## 5. Audit requirements

- Every gate (consent, entitlement, release, payout, kill-switch) writes an audit record
  **before** effecting the transition (intent-first ordering).
- Logs are queryable by tenant, ticket, invoice, release, and actor; retained per
  [failure-retry.md §4](failure-retry.md); tamper-evident via periodic hashing.
- R410 reviews include audit-completeness spot checks as part of every code-bearing PR
  (per AGENTS.md security flow).
