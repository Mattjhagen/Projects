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
  pm:pm-t310|developer:dev-r510|security:security-r410|pm:pm-cloud|developer:dev-cloud|security:sec-cloud) ;;
  *) echo "Invalid AGENT_ROLE and AGENT_ID pair" >&2; exit 1 ;;
esac

current_branch="$(git -C "$PROJECT_DIR" branch --show-current)"
if [[ "$current_branch" != "main" || -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
  printf '%s\n' "Expected a clean main branch; found branch '$current_branch' or local changes. Manual recovery is required before claiming more work." |
    "$report_script" BLOCKED dirty-worktree "Agent worktree is not ready for automation"
  echo "Automation requires a clean main branch" >&2
  exit 1
fi

git -C "$PROJECT_DIR" fetch origin main --quiet
if [[ "$(git -C "$PROJECT_DIR" rev-parse main)" != "$(git -C "$PROJECT_DIR" rev-parse origin/main)" ]]; then
  if git -C "$PROJECT_DIR" merge-base --is-ancestor main origin/main; then
    git -C "$PROJECT_DIR" merge --ff-only origin/main --quiet
  else
    printf '%s\n' 'Local main has diverged from origin/main. Manual recovery is required.' |
      "$report_script" BLOCKED stale-main "Agent main branch has diverged"
    echo "Local main has diverged from origin/main" >&2
    exit 1
  fi
fi

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

prompt="You are [$AGENT_ID], the $AGENT_ROLE agent. Read AGENTS.md, agents/$role_file.md, and docs/AUTOMATED_WORKFLOW.md. Work only on $issue_url and its explicitly linked children or pull request. Perform the required cross-agent handoff. Follow the repository message protocol. Before your final response, write a complete host-local status using scripts/agent-report.sh. Do not merge or deploy."

cd "$PROJECT_DIR"
report_dir="$PROJECT_DIR/.agent-state/$AGENT_ID"
mkdir -p "$report_dir/runs"
run_id="$(date -u '+%Y%m%dT%H%M%SZ')-$$"
run_log="$report_dir/runs/$run_id.log"
touch "$run_log"
chmod 600 "$run_log"
printf '%s\n' "OpenCode automation started. Output: $run_log" |
  "$report_script" STATUS running "Working on issue #$issue" "$issue" "$issue_url"

max_passes="${OPENCODE_MAX_PASSES:-3}"
case "$max_passes" in
  1|2|3|4|5) ;;
  *) echo "OPENCODE_MAX_PASSES must be between 1 and 5" >&2; exit 1 ;;
esac

opencode_status=0
report_complete=false
for ((attempt = 1; attempt <= max_passes; attempt++)); do
  set +e
  if [[ "$attempt" -eq 1 ]]; then
    opencode run "$prompt" 2>&1 | tee -a "$run_log"
  else
    continuation="Continue the same issue and do not repeat completed discovery. Finish the required GitHub handoff and publish the mandatory final report with scripts/agent-report.sh before stopping. This is continuation $attempt of $max_passes."
    opencode run --continue "$continuation" 2>&1 | tee -a "$run_log"
  fi
  opencode_status="${PIPESTATUS[0]}"
  set -e

  if [[ "$opencode_status" -ne 0 ]]; then
    break
  fi
  if ! grep -Fq 'State: running' "$report_dir/latest.md"; then
    report_complete=true
    break
  fi
done

if [[ "$opencode_status" -ne 0 ]]; then
  printf '%s\n' "OpenCode exited with status $opencode_status. Inspect $run_log." |
    "$report_script" BLOCKED failed "OpenCode run failed for issue #$issue" "$issue" "$issue_url"
  gh issue edit "$issue" --repo "$REPOSITORY" \
    --remove-label status:in-progress --add-label status:blocked
  gh issue comment "$issue" --repo "$REPOSITORY" --body "[$AGENT_ID] BLOCKED

Issue: #$issue
Blocker: OpenCode exited with status $opencode_status.
Attempted: The automated run was captured in the host-local run log.
Decision needed: Inspect the agent report and run log, then return this issue to status:ready for retry.
Impact: No successful downstream handoff was recorded."
  exit "$opencode_status"
fi

if [[ "$report_complete" != "true" ]]; then
  printf '%s\n' "OpenCode exhausted $max_passes passes without publishing a structured final report. Inspect $run_log and GitHub." |
    "$report_script" STATUS needs-review "OpenCode run ended without a final agent report" "$issue" "$issue_url"
  gh issue edit "$issue" --repo "$REPOSITORY" \
    --remove-label status:in-progress --add-label status:blocked
  gh issue comment "$issue" --repo "$REPOSITORY" --body "[$AGENT_ID] BLOCKED

Issue: #$issue
Blocker: The automated run exhausted $max_passes bounded passes without publishing its mandatory final report.
Attempted: The initial session and its continuations were preserved in the host-local run log.
Decision needed: Inspect the report and log before returning the issue to status:ready.
Impact: The next handoff cannot be trusted or inferred."
fi
