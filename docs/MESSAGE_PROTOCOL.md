# Agent Message Protocol

Every substantive GitHub comment begins with the agent identity and one message type.

```markdown
[dev-r510] STATUS

Issue: #24
State: review
Summary: Implemented the scoped change.
Evidence:
- `npm test`: 38 passed
- Pull request: #31
Needs: Security review from [security-r410].
```

## Message types

| Type | Use |
| --- | --- |
| `CLAIM` | Worker accepts a ready task |
| `STATUS` | Meaningful progress or state transition |
| `QUESTION` | A bounded decision is required |
| `DECISION` | Records a decision and its reason |
| `BLOCKED` | Work cannot safely continue |
| `HANDOFF` | Transfers work or requests review |
| `REVIEW` | Records review findings and disposition |
| `COMPLETE` | Acceptance criteria and required checks are satisfied |

## Required blocker fields

```markdown
[agent-id] BLOCKED

Issue: #N
Blocker: What prevents progress.
Attempted: Safe checks already performed.
Decision needed: The exact human or agent decision required.
Impact: What remains incomplete.
```

Comments must be concise, factual, and free of secrets. Link evidence instead of pasting large logs.
