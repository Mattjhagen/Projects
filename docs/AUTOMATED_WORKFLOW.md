# Automated Three-Agent Workflow

## Goal

The human submits one objective. T310 scopes it, R510 implements it, R410 reviews security and bugs, and T310 verifies completion. No agent merges or deploys.

## Lifecycle

```text
Human intake (PM)
  -> development child (R510)
    -> pull request + security child (R410)
      -> pass: parent waits for human merge
      -> fail: return development child (R510)
  -> human merge
  -> trusted merge handoff wakes parent (T310)
  -> PM completion review
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
| Security | Clean PR | Security child done; parent in review; commit status successful |
| Security | Blocking finding | Developer child ready; security child blocked; commit status failed |
| Human | Passing PR | Merge decision |
| Merge handoff | PR merged | Parent returned ready |
| PM | Parent returned ready | Merged result checked; parent done |

`status:blocked` on a parent may mean it is deliberately waiting for its children. The comment history must distinguish waiting from an actual blocker.

## Merge gate

Every pull-request update sets `agent/security-review` to pending using a `pull_request_target` workflow that executes trusted base-branch code and never checks out PR content. R410 runs `scripts/security-verdict.sh` after reviewing the exact current head commit. A new commit resets the status to pending and requires a new review. Branch protection must require `validate` and `agent/security-review`.

The R510 credential must not have Commit statuses write permission. Only the R410 credential and trusted GitHub workflow receive that permission. Because all hosts currently share one GitHub account, credential separation—not the visible account name—is the enforcement boundary.

After human merge, a separate trusted `pull_request_target` workflow extracts the numeric `Parent task: #N` reference from the PR body and returns that issue to `status:ready`. It never executes or evaluates PR-provided code.

## Failure behavior

- GitHub or model failure: report `BLOCKED`; do not invent a successful handoff.
- Dirty or stale worktree: runner stops before claiming an issue.
- Critical/high security finding: fail the security status and return work to R510.
- Missing references or ambiguous scope: ask T310; do not guess issue relationships.
- Human merge before a passing gate: record a process incident and perform post-merge validation, but do not describe it as a successful pre-merge gate.
