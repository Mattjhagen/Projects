# Installation and Operations Runbook

## Prerequisites

Each host must have `git`, `gh`, and `opencode`, an authenticated GitHub account, and a clean checkout at `/home/matt/Projects`.

The R410 GitHub credential must have read/write **Commit statuses** permission in addition to repository contents, issues, and pull requests so it can publish the `agent/security-review` verdict.

## 1. Install repository labels

Run once from an authenticated host:

```bash
cd /home/matt/Projects
scripts/bootstrap-labels.sh Mattjhagen/Projects
```

## 2. Configure a host

Install the matching tracked template with owner-only permissions:

```bash
mkdir -p /home/matt/.config
install -m 600 config/r510.env.example /home/matt/.config/projects-agent.env
```

Use `config/t310.env.example` on T310 and `config/r410.env.example` on R410.

Allowed role and identity pairs are:

| Host | `AGENT_ROLE` | `AGENT_ID` |
| --- | --- | --- |
| T310 | `pm` | `pm-t310` |
| R510 | `developer` | `dev-r510` |
| R410 | `security` | `security-r410` |

Then run:

```bash
cd /home/matt/Projects
scripts/agent-health-check.sh
```

Initialize and inspect the local report:

```bash
printf '%s\n' 'Host configuration completed.' |
  scripts/agent-report.sh STATUS ready 'Agent is configured and healthy'
scripts/show-agent-report.sh
```

## 3. Manual MVP

Leave `AUTOMATION_ENABLED=false`. Create one documentation issue, apply `agent:developer` and `status:ready`, and run:

```bash
scripts/agent-once.sh
```

The script prints the next issue but does not invoke OpenCode. Start OpenCode manually, complete the issue, and verify the full issue-to-PR-to-review cycle.

Use `scripts/start-agent.sh` instead of launching `opencode` directly for interactive sessions. It records session start and exit in the local status channel:

```bash
scripts/start-agent.sh
```

## 4. Enable one-shot automation

Only after the manual cycle succeeds, change `AUTOMATION_ENABLED=true`. The one-shot runner invokes OpenCode non-interactively with the selected issue. It does not merge or deploy.

Before enabling timers, protect `main` and require both `validate` and `agent/security-review`. Repository administration remains a human operation.

Install the service templates:

```bash
sudo cp systemd/opencode-agent.service /etc/systemd/system/
sudo cp systemd/opencode-agent.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-agent.timer
systemctl list-timers opencode-agent.timer
```

Submit work from T310:

```bash
scripts/submit-task.sh "Task title" "Desired outcome, constraints, and relevant context."
```

Follow progress without screenshots:

```bash
scripts/show-agent-report.sh
```

## Routine checks

```bash
scripts/agent-health-check.sh
systemctl status opencode-agent.timer
journalctl -u opencode-agent.service -n 100 --no-pager
gh issue list --repo Mattjhagen/Projects --label "agent:developer,status:ready"
scripts/show-agent-report.sh
```

From a controller with `agent-pm`, `agent-dev`, and `agent-security` SSH aliases, collect all reports with:

```bash
scripts/read-all-agent-reports.sh
```

## Updating

Disable the timer before updating the coordination code. Pull only with a clean worktree, rerun the health check, and re-enable the timer after review.
