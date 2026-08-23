# Agent status dashboard

A static, generated view of the three-agent pipeline (pm-t310, dev-r510, security-r410). GitHub remains the durable source of truth; the dashboard is a read-only visibility aid.

## Usage

```bash
scripts/dashboard-generate.sh            # renders .agent-state/dashboard/index.html
scripts/dashboard-smoke-test.sh          # offline fixture test, no network access
```

Open `.agent-state/dashboard/index.html` in a browser. The output path is untracked and never committed.

## Refresh behavior

- Manual only. There is no server, daemon, inbound port, or auto-refresh; re-run the script for a new snapshot.
- Every GitHub (`gh`) and SSH call is wrapped in `timeout` (10 seconds per call by default).
- Normal generation completes in seconds and stays well under the 60-second budget.

## Data sources

1. **GitHub (live at generation time):** the most recently updated open issue per `agent:*` label with its `status:*`/`type:*` labels, and combined commit statuses plus the `agent/security-review` context for recent open pull request heads.
2. **Host reports:** `.agent-state/<agent-id>/latest.md`, read through the same SSH host aliases used by `scripts/read-all-agent-reports.sh` (`agent-pm`, `agent-dev`, `agent-security`). No other access is widened.

Each agent row shows identity, role, latest handoff type/state, current issue or PR link, last report update time in UTC, summary line, blocker indicator, and the latest handoff reference. Host-report data carries its own timestamp so staleness stays visible next to live GitHub state.

## Failure behavior

| Situation | Result |
| --- | --- |
| All sources reachable | Dashboard written; exit 0 |
| Any single source unreachable, missing, or malformed | That source is marked `unavailable/stale`; dashboard still written; exit 1 |
| Output trips the forbidden-pattern gate | Nothing is written; exit 2 |

The forbidden-pattern gate rejects output containing token shapes (GitHub, AWS, Slack, bearer credentials), private key blocks, or private-infrastructure IP addresses. Matched content is never printed.

## Untrusted-input rule

All text sourced from issues, pull requests, or agent reports is HTML-escaped before rendering. Sourced content is never executed or interpolated as code.

## Configuration

Override defaults via environment variables (`DASHBOARD_REPO`, `DASHBOARD_OUTPUT`, `DASHBOARD_REPORT_FETCH=ssh|local`, `DASHBOARD_GH_TIMEOUT`, `DASHBOARD_SSH_TIMEOUT`, `DASHBOARD_PR_LIMIT`, `DASHBOARD_REMOTE_DIR`, `DASHBOARD_PROJECT_DIR`, `DASHBOARD_STATE_DIR`). See the header of `scripts/dashboard-generate.sh`. `local` report mode exists for offline testing only; production reads reports over SSH.

## Manual verification

1. `bash scripts/dashboard-smoke-test.sh` — all assertions pass.
2. `shellcheck scripts/dashboard-generate.sh scripts/dashboard-smoke-test.sh` — clean.
3. `bash scripts/dashboard-generate.sh` on a connected host — exits 0 or 1 (partial sources), writes the file, and marks any unreachable source explicitly.
4. Confirm the rendered file contains no secrets and no raw run logs.
