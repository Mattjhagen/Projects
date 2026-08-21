# Automated Three-Agent Workflow

## Goal

The human submits one objective. T310 scopes it, R510 implements it, R410 reviews security and bugs, and T310 verifies completion. No agent merges or deploys.

## Lifecycle

```text
Human intake (PM)
  -> development child (R510)
    -> pull request + security child (R410)
      -> pass: wake parent (T310)
      -> fail: return development child (R510)
  -> PM completion review
  -> human merge
```

## Required references

Child issue bodies use plain lines that agents and scripts can search:

```text
Parent task: #10
Development task: #11
Security task: #12
Pull request: #13
```

Never create a duplicate downstream issue when one of these references already exists.

## State transitions

| Actor | Input | Output |
| --- | --- | --- |
| Human | Objective | PM issue: `agent:pm`, `status:ready` |
| PM | New intake | Developer child ready; parent blocked/waiting |
| Developer | Developer child | PR and security child ready; developer child in review |
| Security | Clean PR | Security child done; parent ready; commit status successful |
| Security | Blocking finding | Developer child ready; security child blocked; commit status failed |
| PM | Parent returned ready | Completion evidence checked; parent done |
| Human | Passing PR | Merge decision |

`status:blocked` on a parent may mean it is deliberately waiting for its children. The comment history must distinguish waiting from an actual blocker.

## Merge gate

Every pull-request update sets `agent/security-review` to pending. R410 runs `scripts/security-verdict.sh` after reviewing the exact current head commit. A new commit resets the status to pending and requires a new review. Branch protection must require `validate` and `agent/security-review`.

## Failure behavior

- GitHub or model failure: report `BLOCKED`; do not invent a successful handoff.
- Dirty or stale worktree: runner stops before claiming an issue.
- Critical/high security finding: fail the security status and return work to R510.
- Missing references or ambiguous scope: ask T310; do not guess issue relationships.
- Human merge before a passing gate: record a process incident and perform post-merge validation, but do not describe it as a successful pre-merge gate.
