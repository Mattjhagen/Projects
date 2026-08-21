#!/usr/bin/env bash
set -euo pipefail

issue="${1:?Usage: claim-issue.sh ISSUE ROLE AGENT_ID [REPOSITORY]}"
role="${2:?Usage: claim-issue.sh ISSUE ROLE AGENT_ID [REPOSITORY]}"
agent_id="${3:?Usage: claim-issue.sh ISSUE ROLE AGENT_ID [REPOSITORY]}"
repository="${4:-Mattjhagen/Projects}"

case "$role:$agent_id" in
  pm:pm-t310|developer:dev-r510|security:security-r410) ;;
  *) echo "Invalid role and agent identity pair" >&2; exit 1 ;;
esac

labels="$(gh issue view "$issue" --repo "$repository" --json labels --jq '.labels[].name')"
grep -Fxq "agent:$role" <<<"$labels" || { echo "Issue is not assigned to agent:$role" >&2; exit 1; }
grep -Fxq "status:ready" <<<"$labels" || { echo "Issue is not status:ready" >&2; exit 1; }

gh issue edit "$issue" --repo "$repository" \
  --remove-label "status:ready" --add-label "status:in-progress"
gh issue comment "$issue" --repo "$repository" \
  --body "[$agent_id] CLAIM

Issue: #$issue
State: in-progress
Summary: Claimed by the $role agent."

echo "Claimed issue #$issue as $agent_id"
