#!/usr/bin/env bash
set -euo pipefail

title="${1:?Usage: submit-task.sh TITLE DESCRIPTION [PRIORITY]}"
description="${2:?Usage: submit-task.sh TITLE DESCRIPTION [PRIORITY]}"
priority="${3:-normal}"
config_file="${AGENT_CONFIG_FILE:-$HOME/.config/projects-agent.env}"

[[ -r "$config_file" ]] || { echo "Missing readable config: $config_file" >&2; exit 1; }
# shellcheck disable=SC1090
source "$config_file"

: "${AGENT_ROLE:?AGENT_ROLE is required}"
: "${AGENT_ID:?AGENT_ID is required}"
: "${REPOSITORY:?REPOSITORY is required}"
: "${PROJECT_DIR:?PROJECT_DIR is required}"

[[ "$AGENT_ROLE:$AGENT_ID" == "pm:pm-t310" ]] || {
  echo "Tasks may only be submitted through the T310 Project Manager host" >&2
  exit 1
}

case "$priority" in
  critical|high|normal) ;;
  *) echo "Priority must be critical, high, or normal" >&2; exit 1 ;;
esac

body="$(printf '## Human objective\n\n%s\n\n## Project Manager instructions\n\nClarify and scope this objective into an actionable development task. Do not implement it. Preserve this issue as the parent task for all downstream handoffs.\n\n## Submitted by\n\nHuman owner via T310.\n' "$description")"

issue_url="$(gh issue create --repo "$REPOSITORY" --title "[Intake] $title" \
  --body "$body" --label "agent:pm" --label "status:ready" \
  --label "priority:$priority" --label "type:feature")"
issue="${issue_url##*/}"

printf '%s\n' "Human objective submitted. T310 will scope issue #$issue on its next run." |
  "$PROJECT_DIR/scripts/agent-report.sh" STATUS queued "New Project Manager task queued" "$issue" "$issue_url"

printf '%s\n' "$issue_url"
