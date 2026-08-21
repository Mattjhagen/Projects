# Projects Agent Workspace

This repository coordinates three independent OpenCode agents that collaborate through GitHub Issues and pull requests.

| Logical host | Role | Responsibility |
| --- | --- | --- |
| `agent-pm` | Project Manager | Plans work, assigns issues, resolves blockers, and verifies acceptance criteria |
| `agent-dev` | Senior Developer | Implements scoped changes, tests them, and opens pull requests |
| `agent-security` | Cybersecurity Expert | Reviews designs and pull requests, tracks findings, and blocks unsafe releases |

Network addresses and credentials are deliberately excluded from this public repository. Configure logical host aliases locally.

## How work moves

1. A human or the Project Manager creates an issue from the **Agent task** template.
2. The Project Manager applies exactly one `agent:*` label and `status:ready`.
3. The assigned agent claims the issue and changes the state to `status:in-progress`.
4. Code changes are made on an `agent/<role>/<issue>-<slug>` branch and submitted as a pull request.
5. CI runs. The security agent reviews code-bearing pull requests.
6. A human approves and performs the merge.
7. The merge handoff wakes the Project Manager, who verifies completion and changes the parent issue to `status:done`.

Submit a new objective to the Project Manager from T310 with:

```bash
scripts/submit-task.sh "Build the requested capability" "Describe the desired outcome and constraints."
```

When periodic automation is enabled, T310 scopes the intake, R510 implements the resulting development task, R410 performs security and bug review, and T310 verifies completion. See [Automated workflow](docs/AUTOMATED_WORKFLOW.md).

GitHub is the source of truth. Local chat history, terminal output, and unpushed branches are not durable project state.

## Start here

- [Shared agent rules](AGENTS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Message protocol](docs/MESSAGE_PROTOCOL.md)
- [Security policy](docs/SECURITY_POLICY.md)
- [Installation and operations](docs/RUNBOOK.md)

## Local agent reports

Each host maintains an untracked report at:

```text
/home/matt/Projects/.agent-state/<agent-id>/latest.md
```

The report mirrors the agent's latest structured GitHub status and can be read over SSH without screenshots. Session logs are stored under the same directory. GitHub remains the durable source of truth; local reports are an operational visibility channel.

## Managed projects

| Project | Repository | Site |
| --- | --- | --- |
| vibeCodesSpace | [Mattjhagen/vibeCodesSpace](https://github.com/Mattjhagen/vibeCodesSpace) | [vibecodes.space](https://vibecodes.space/) |
| Velour E-Commerce | [Mattjhagen/Morrow](https://github.com/Mattjhagen/Morrow) | [velour.live](https://velour.live/) |
| PurePulse portals | [Mattjhagen/purepulse-admin](https://github.com/Mattjhagen/purepulse-admin) | [login.purepulse.one](https://login.purepulse.one/) |
| PurePulse landing page | [Mattjhagen/PurePulse](https://github.com/Mattjhagen/PurePulse) | [purepulse.one](http://purepulse.one/) |
| PurePulse marketing | [Mattjhagen/PurePulseMarketing](https://github.com/Mattjhagen/PurePulseMarketing) | [marketing site](https://mattjhagen.github.io/PurePulseMarketing/) |

## MVP safety boundary

Automation may select and analyze tasks, create branches, commit, push, open pull requests, and record security verdicts. It may not merge, deploy, rotate credentials, modify branch protection, delete resources, or run destructive security tests without explicit human approval.
