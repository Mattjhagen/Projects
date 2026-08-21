#!/usr/bin/env bash
set -euo pipefail

config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"
[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }

# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ROLE:?AGENT_ROLE is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${REPOSITORY:?REPOSITORY is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"
automation_enabled="${AUTOMATION_ENABLED:-false}"
report_script="$PROJECT_DIR/scripts/agent-report.sh"

case "$AGENT_ROLE:$AGENT_ID" in
  pm:pm-t310|developer:dev-r510|security:security-r410) ;;
  *) echo "Invalid AGENT_ROLE and AGENT_ID pair" >&2; exit 1 ;;
esac

issue="$(gh issue list --repo "$REPOSITORY" --state open \
  --label "agent:$AGENT_ROLE" --label "status:ready" \
  --limit 1 --json number --jq '.[0].number // empty')"

if [[ -z "$issue" ]]; then
  printf '%s\n' "Queue checked; no status:ready issue exists for agent:$AGENT_ROLE." |
    "$report_script" STATUS idle "No ready work in the queue"
  echo "No ready issue for agent:$AGENT_ROLE"
  exit 0
fi

echo "Next ready issue: #$issue"

if [[ "$automation_enabled" != "true" ]]; then
  printf '%s\n' "Issue #$issue is ready. Automation is disabled; manual inspection and claim are required." |
    "$report_script" STATUS ready "Ready issue found; awaiting manual session" "$issue"
  echo "Automation is disabled; inspect and claim the issue manually."
  exit 0
fi

"$PROJECT_DIR/scripts/claim-issue.sh" "$issue" "$AGENT_ROLE" "$AGENT_ID" "$REPOSITORY"
issue_url="$(gh issue view "$issue" --repo "$REPOSITORY" --json url --jq '.url')"

case "$AGENT_ROLE" in
  pm) role_file="project-manager" ;;
  developer) role_file="senior-developer" ;;
  security) role_file="cybersecurity-expert" ;;
esac

prompt="You are [$AGENT_ID], the $AGENT_ROLE agent. Read AGENTS.md and agents/$role_file.md. Work only on $issue_url. Follow the repository message protocol. Before your final response, write a complete host-local status using scripts/agent-report.sh. Do not merge or deploy."

cd "$PROJECT_DIR"
report_dir="$PROJECT_DIR/.agent-state/$AGENT_ID"
mkdir -p "$report_dir/runs"
run_id="$(date -u '+%Y%m%dT%H%M%SZ')"
run_log="$report_dir/runs/$run_id.log"
printf '%s\n' "OpenCode automation started. Output: $run_log" |
  "$report_script" STATUS running "Working on issue #$issue" "$issue" "$issue_url"

set +e
opencode run "$prompt" 2>&1 | tee "$run_log"
opencode_status="${PIPESTATUS[0]}"
set -e
chmod 600 "$run_log"

if [[ "$opencode_status" -ne 0 ]]; then
  printf '%s\n' "OpenCode exited with status $opencode_status. Inspect $run_log." |
    "$report_script" BLOCKED failed "OpenCode run failed for issue #$issue" "$issue" "$issue_url"
  exit "$opencode_status"
fi

if grep -Fq 'State: running' "$report_dir/latest.md"; then
  printf '%s\n' "OpenCode exited successfully but did not publish a structured final report. Inspect $run_log and GitHub." |
    "$report_script" STATUS needs-review "OpenCode run ended without a final agent report" "$issue" "$issue_url"
fi
