# Pipeline validation

This document records one end-to-end validation of the automated three-agent
pipeline defined in `docs/AUTOMATED_WORKFLOW.md`, performed in this repository.
It was delivered by development task #28 under parent intake task #27.

## Objective

Validate the T310 -> R510 -> R410 -> merge-handoff pipeline by delivering one
small, verifiable repository change from a ready development issue through a
security-reviewed pull request.

## Stage-by-stage evidence

| Stage | Actor | Evidence |
| --- | --- | --- |
| Intake scoped | [pm-t310] | Parent task: <https://github.com/Mattjhagen/Projects/issues/27> |
| Development child ready | [pm-t310] | Development task: <https://github.com/Mattjhagen/Projects/issues/28> (`agent:developer`, `status:ready`) |
| Claim | [dev-r510] | <https://github.com/Mattjhagen/Projects/issues/28#issuecomment-5388255610> |
| Approach recorded | [dev-r510] | <https://github.com/Mattjhagen/Projects/issues/28#issuecomment-5388268456> |
| Branch created | [dev-r510] | `agent/developer/28-pipeline-validation` from up-to-date `origin/main`, clean worktree |
| Pull request opened | [dev-r510] | Pending |
| CI validate | GitHub Actions | Pending: repository `validate` job on the exact PR head commit |
| Security child created | [dev-r510] | Pending: single security-review issue referencing parent, development task, and pull request |
| Security review verdict | [security-r410] | Pending: REVIEW via `scripts/security-verdict.sh`; `agent/security-review` commit status on the same head commit |
| Human merge decision | Human owner | Pending; a human owns merges during the MVP |

## Merge gate and handoff

Per `docs/AUTOMATED_WORKFLOW.md`, every pull-request update sets
`agent/security-review` to pending. A new head commit requires a fresh review,
and branch protection requires both `validate` and `agent/security-review`.
After the human merge, the trusted merge-handoff workflow extracts the numeric
parent reference from the pull-request body and returns the parent issue to
`status:ready` for PM completion review. No agent merges or deploys.

## Final outcome

Pending: this section is completed after the security gate passes and the
human owner makes the merge decision.
