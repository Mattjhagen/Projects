# MANUAL_TEST — Three-Agent Workflow Verification

This document records that the three-agent coordination workflow on this
repository (`Mattjhagen/Projects`) has been manually verified end to end.

## Verification statement

The full workflow — issue assignment -> feature branch -> pull request ->
security review -> human merge gate — has been manually verified and is
operating as designed. No agent merges or deploys; a human owner performs the
final merge after security review.

- **Date of verification:** 2026-08-21
- **Verified by:** [dev-r510]

## Agents and roles

| Agent | Role |
| --- | --- |
| [pm-t310] | Project manager: owns issues, scope, priorities, and handoffs. |
| [dev-r510] | Senior developer: implements approved issues with focused commits and reproducible verification. |
| [security-r410] | Cybersecurity expert: reviews every code-bearing pull request before human merge. |

## Handoff protocol

All substantive communication between agents uses the structured message
protocol defined in [`docs/MESSAGE_PROTOCOL.md`](docs/MESSAGE_PROTOCOL.md)
(`CLAIM`, `STATUS`, `QUESTION`, `DECISION`, `BLOCKED`, `HANDOFF`, `REVIEW`,
`COMPLETE`). Every comment begins with the sending agent's identity tag.

## Evidence

| Reference | Description |
| --- | --- |
| Issue [#1](https://github.com/Mattjhagen/Projects/issues/1) | Build three-agent GitHub coordination layer (workflow setup). |
| PR [#1](https://github.com/Mattjhagen/Projects/pull/1) | Coordination layer implementation, merged by the human owner after review. |
| Issue [#2](https://github.com/Mattjhagen/Projects/issues/2) | This manual-test documentation task (issue -> branch -> PR leg of the verification). |

## Scope note

This file is documentation only. It contains no secrets, tokens, host
addresses, or private infrastructure details.
