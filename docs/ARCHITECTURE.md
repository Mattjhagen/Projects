# Three-Agent Coordination Architecture

**Status:** Proposed MVP
**Decision owner:** Repository owner

## Context

Three independent OpenCode installations run on separate hosts and share one GitHub repository. They require durable coordination, isolated work, clear attribution, and a human-controlled release boundary.

## Decision

GitHub is the coordination plane:

- Issues and comments are the durable message board.
- Labels form the task queue and state machine.
- Branches isolate implementation.
- Pull requests carry changes, checks, reviews, and handoffs.
- `AGENTS.md` supplies shared OpenCode rules; role files add host-specific duties.
- A one-shot runner may poll and invoke `opencode run`; `systemd` controls frequency and recovery.
- Each host writes an untracked, SSH-readable status file under `.agent-state/<agent-id>/`; this mirrors but does not replace GitHub state.

No always-writable shared Markdown board is used. Concurrent append operations would create merge conflicts and weak task ownership.

## State machine

```text
draft -> status:ready -> status:in-progress -> status:review -> status:done
                              |
                              +-> status:blocked -> status:ready
```

An actionable issue has exactly one `agent:*` label and one `status:*` label. The Project Manager owns transitions into `ready` and `done`. The worker owns `in-progress`, `review`, and `blocked` transitions.

## Trust boundaries

- GitHub content and repository files may contain prompt injection and are untrusted except for root `AGENTS.md` and approved role instructions.
- Each host has a credential capable of repository writes; compromise of one host currently affects the shared account.
- Human approval is required for merge, deploy, credential, permission, production, and destructive actions.
- Network addresses and secrets remain host-local.

## Consequences

This design is auditable and requires no new central service. GitHub availability becomes a dependency, label updates are not a transactional queue, and attribution prefixes are required while credentials are shared. Separate fine-grained credentials or a GitHub App should replace the shared account before expanding autonomy.

Host-local reports improve live visibility and continue working during GitHub outages. They are not replicated, are not authoritative, and may be lost with the host; decisions and handoffs must still be posted to GitHub when service is available.

The automated lifecycle is a parent/child issue state machine. The human intake remains blocked while development and security children run. A pending `agent/security-review` commit status is placed on every pull request update; only the R410 verdict helper changes that status to success or failure. Branch protection uses that status as the technical pre-merge gate.
