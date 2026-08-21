#!/usr/bin/env bash
set -euo pipefail

repository="${1:-Mattjhagen/Projects}"

command -v gh >/dev/null || { echo "gh is required" >&2; exit 1; }
gh auth status >/dev/null

labels=(
  "agent:pm|5319e7|Work for the Project Manager agent"
  "agent:developer|0969da|Work for the Senior Developer agent"
  "agent:security|d1242f|Work for the Cybersecurity Expert agent"
  "status:draft|d4c5f9|Task is not ready for an agent"
  "status:ready|0e8a16|Task is fully specified and ready"
  "status:in-progress|fbca04|An agent is actively working"
  "status:review|1d76db|Work is awaiting review"
  "status:blocked|b60205|Work requires a decision or dependency"
  "status:done|6f7780|Acceptance criteria are satisfied"
  "priority:critical|b60205|Immediate attention required"
  "priority:high|d93f0b|High-priority work"
  "priority:normal|c2e0c6|Normal-priority work"
  "type:feature|a2eeef|New capability"
  "type:bug|d73a4a|Incorrect behavior"
  "type:security|ee0701|Security-related work"
  "type:research|bfd4f2|Investigation or decision work"
)

for definition in "${labels[@]}"; do
  IFS='|' read -r name color description <<<"$definition"
  gh label create "$name" --repo "$repository" --color "$color" \
    --description "$description" --force
done

echo "Labels are configured for $repository"
